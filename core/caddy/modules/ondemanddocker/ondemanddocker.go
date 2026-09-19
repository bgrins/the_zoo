// Package ondemanddocker implements a Caddy HTTP handler that automatically starts
// Docker containers when they receive incoming requests.
//
// Goals:
// 1. Start stopped containers on-demand when accessed via HTTP/HTTPS
// 2. Hold connections open during container startup to provide seamless experience
// 3. Wait for containers to be healthy before forwarding requests
// 4. Minimize latency for subsequent requests through intelligent caching
// 5. Support configurable timeouts for container startup
//
// The module addresses the challenge of keeping all containers running in a 
// development environment by only starting them when actually needed. This reduces
// resource usage while maintaining a smooth developer experience.
//
// Performance characteristics:
// - First request to stopped container: ~2-3s (container startup time)
// - Subsequent requests: ~0.02s (cached status, no docker inspect overhead)
// - Cache duration: 5 minutes (configurable via cacheDuration constant)
package ondemanddocker

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/httpcaddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"go.uber.org/zap"
	"golang.org/x/sync/singleflight"
	"gopkg.in/yaml.v3"
)

const (
	// cacheDuration is how long to cache the container status to avoid repeated docker inspect calls
	cacheDuration = 5 * time.Minute

	sitesConfigPath = "/etc/caddy/SITES.yaml"

	// statusClientClosedRequest matches what reverse_proxy reports for canceled requests
	statusClientClosedRequest = 499
)

// SitesConfig represents the structure of SITES.yaml
type SitesConfig struct {
	Comment  []string `yaml:"_comment"`
	Sites    []Site   `yaml:"sites"`
	Services map[string]struct {
		HasHealthCheck bool `yaml:"hasHealthCheck"`
	} `yaml:"services"`
}

// Site represents a single site configuration
type Site struct {
	Domain      string `yaml:"domain"`
	Type        string `yaml:"type"`
	Port        interface{} `yaml:"port"`
	Service     string `yaml:"service"`
	Description string `yaml:"description,omitempty"`
	Icon        string `yaml:"icon,omitempty"`
	HasOAuth    bool   `yaml:"hasOAuth"`
	HTTPSOnly   bool   `yaml:"httpsOnly,omitempty"`
}

var (
	// Global cache for container statuses to avoid repeated docker inspect calls
	statusCache = make(map[string]*cacheEntry)
	cacheMutex  sync.RWMutex
	
	// Global cache for discovered project name
	cachedProjectName string
	projectNameMutex  sync.RWMutex
	
	// Global service configuration loaded from SITES.yaml
	sitesConfig      SitesConfig
	serviceAllowlist map[string]bool
	allowlistMutex   sync.RWMutex
	allowlistLoaded  bool
	sitesModTime     time.Time
	sitesSize        int64

	// Module instances are per site block and many can share one container,
	// so start/readiness work is coalesced process-wide.
	readyGroup singleflight.Group // keyed by readinessKey
	startGroup singleflight.Group // keyed by resolved container name
)

type cacheEntry struct {
	status    string
	checkTime time.Time
}

func init() {
	caddy.RegisterModule(OnDemandDocker{})
	httpcaddyfile.RegisterHandlerDirective("on_demand_docker", parseCaddyfile)
}

// loadServiceAllowlist loads the service allowlist from SITES.yaml, re-reading
// it whenever the file has changed so `caddy reload` picks up new services.
func loadServiceAllowlist() error {
	info, err := os.Stat(sitesConfigPath)
	if err != nil {
		return fmt.Errorf("failed to stat SITES.yaml: %w", err)
	}

	allowlistMutex.RLock()
	unchanged := allowlistLoaded && info.ModTime().Equal(sitesModTime) && info.Size() == sitesSize
	allowlistMutex.RUnlock()
	if unchanged {
		return nil
	}

	configData, err := os.ReadFile(sitesConfigPath)
	if err != nil {
		return fmt.Errorf("failed to read SITES.yaml: %w", err)
	}

	var config SitesConfig
	if err := yaml.Unmarshal(configData, &config); err != nil {
		return fmt.Errorf("failed to parse SITES.yaml: %w", err)
	}

	// Build the allowlist from sites
	allowlist := make(map[string]bool)
	for _, site := range config.Sites {
		if site.Service != "" {
			allowlist[site.Service] = true
		}
	}

	// Also add services from the services section
	for serviceName := range config.Services {
		allowlist[serviceName] = true
	}

	allowlistMutex.Lock()
	sitesConfig = config
	serviceAllowlist = allowlist
	sitesModTime = info.ModTime()
	sitesSize = info.Size()
	allowlistLoaded = true
	allowlistMutex.Unlock()
	return nil
}

// isServiceAllowed checks if a service is in the allowlist
func isServiceAllowed(serviceName string) bool {
	allowlistMutex.RLock()
	defer allowlistMutex.RUnlock()
	
	// If allowlist is not loaded, allow all services (fallback to old behavior)
	if !allowlistLoaded || len(serviceAllowlist) == 0 {
		return true
	}
	
	return serviceAllowlist[serviceName]
}

// OnDemandDocker is a Caddy HTTP handler that starts Docker containers on demand
type OnDemandDocker struct {
	// ContainerName is the name of the container to manage
	ContainerName string `json:"container_name,omitempty"`
	
	// Port is the port to check for readiness (optional, will be extracted from upstream if not specified)
	Port int `json:"port,omitempty"`
	
	// Timeout is the maximum time to wait for the container to be ready (in seconds)
	Timeout int `json:"timeout,omitempty"`
	
	logger *zap.Logger
}

// CaddyModule returns the Caddy module information.
func (OnDemandDocker) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "http.handlers.on_demand_docker",
		New: func() caddy.Module { return new(OnDemandDocker) },
	}
}

// Provision sets up the module.
func (od *OnDemandDocker) Provision(ctx caddy.Context) error {
	od.logger = ctx.Logger(od)
	
	// Set default timeout if not specified
	if od.Timeout == 0 {
		od.Timeout = 30
	}
	
	if err := loadServiceAllowlist(); err != nil {
		od.logger.Warn("failed to load service allowlist, will use dynamic validation",
			zap.Error(err))
	}
	
	// Don't resolve container name here - it's resolved per request from the cached project name
	od.logger.Info("on_demand_docker module provisioned",
		zap.String("container_name", od.ContainerName),
		zap.Int("timeout", od.Timeout))
	
	return nil
}

// Validate ensures the module's configuration is valid.
func (od *OnDemandDocker) Validate() error {
	if od.ContainerName == "" {
		return fmt.Errorf("container_name is required")
	}
	
	// If allowlist is loaded, validate against it
	allowlistMutex.RLock()
	defer allowlistMutex.RUnlock()
	
	if allowlistLoaded && len(serviceAllowlist) > 0 {
		if !serviceAllowlist[od.ContainerName] {
			return fmt.Errorf("container '%s' is not in the service allowlist", od.ContainerName)
		}
	}
	
	return nil
}

// ServeHTTP implements the HTTP handler interface.
func (od *OnDemandDocker) ServeHTTP(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler) error {
	// Check if service is allowed
	if !isServiceAllowed(od.ContainerName) {
		od.logger.Error("container not in allowlist",
			zap.String("container_name", od.ContainerName))
		return caddyhttp.Error(http.StatusForbidden, 
			fmt.Errorf("container '%s' is not in the service allowlist", od.ContainerName))
	}
	
	container := od.resolveContainerName()
	if container == "" {
		return caddyhttp.Error(http.StatusInternalServerError,
			fmt.Errorf("failed to determine Docker Compose project name"))
	}

	// Check if we have a recent cached status indicating the container is running
	cacheMutex.RLock()
	entry, exists := statusCache[container]
	cacheMutex.RUnlock()
	
	// If we have a recent cache entry showing the container is running, skip the check
	if exists && entry.status == "running" && time.Since(entry.checkTime) < cacheDuration {
		od.logger.Info("using cached status, container is running",
			zap.String("container", od.ContainerName),
			zap.Duration("cache_age", time.Since(entry.checkTime)))
		
		// Try to serve the request, but if it fails, invalidate the cache
		err := next.ServeHTTP(w, r)
		if err != nil {
			// Check if this is a connection/proxy error that might indicate the container is down
			errStr := err.Error()
			if strings.Contains(errStr, "dial tcp") || strings.Contains(errStr, "connection refused") || 
			   strings.Contains(errStr, "no such host") || strings.Contains(errStr, "server misbehaving") {
				od.logger.Warn("proxy error detected with cached running status, invalidating cache",
					zap.String("container", od.ContainerName),
					zap.Error(err))
				
				// Invalidate the cache entry
				cacheMutex.Lock()
				delete(statusCache, container)
				cacheMutex.Unlock()

				// Recheck the container status and handle it properly
				return od.handleRequest(w, r, next, container)
			}
		}
		return err
	}

	return od.handleRequest(w, r, next, container)
}

// handleRequest waits until the container is ready, starting it if needed, then passes the request on
func (od *OnDemandDocker) handleRequest(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler, container string) error {
	od.logger.Info("handling request for on-demand container",
		zap.String("container", od.ContainerName),
		zap.String("method", r.Method),
		zap.String("uri", r.RequestURI),
		zap.String("host", r.Host))

	// The shared start/wait runs detached from any one request, so a client
	// disconnecting only abandons its own wait.
	ch := readyGroup.DoChan(od.readinessKey(container), func() (interface{}, error) {
		return od.ensureReady(container)
	})
	select {
	case res := <-ch:
		if res.Err != nil {
			return caddyhttp.Error(res.Val.(int), res.Err)
		}
	case <-r.Context().Done():
		return caddyhttp.Error(statusClientClosedRequest, r.Context().Err())
	}

	od.logger.Debug("passing request to next handler",
		zap.String("container", od.ContainerName))
	return next.ServeHTTP(w, r)
}

// readinessKey groups requests that share a readiness condition. The port
// only matters when readiness is decided by probing it.
func (od *OnDemandDocker) readinessKey(container string) string {
	if od.Port == 0 || od.hasHealthCheck() {
		return container
	}
	return fmt.Sprintf("%s:%d", container, od.Port)
}

// ensureReady starts the container if needed and waits for it to become ready.
// On failure it returns the HTTP status code to report with the error.
func (od *OnDemandDocker) ensureReady(container string) (interface{}, error) {
	state := inspectContainer(context.Background(), container)

	od.logger.Info("container status check",
		zap.String("container", od.ContainerName),
		zap.String("status", state.status))

	switch {
	case state.status == "running" && state.health == "unhealthy":
		od.logger.Warn("container is running but its health check is failing, proxying anyway",
			zap.String("container", od.ContainerName))
	case state.status != "running":
		od.logger.Info("container is not running, attempting to start",
			zap.String("container", od.ContainerName),
			zap.String("actual_container", container),
			zap.String("current_status", state.status))

		if state.status == "not found" {
			od.logger.Warn("container does not exist",
				zap.String("container", od.ContainerName),
				zap.String("actual_container", container),
				zap.String("hint", fmt.Sprintf("Run 'docker compose create %s' to create the container", od.ContainerName)))
		}

		if _, err, _ := startGroup.Do(container, func() (interface{}, error) {
			return nil, od.startContainer(container)
		}); err != nil {
			od.logger.Error("failed to start container",
				zap.String("container", od.ContainerName),
				zap.String("actual_container", container),
				zap.Error(err))
			return http.StatusInternalServerError, err
		}

		od.logger.Info("waiting for container to be ready",
			zap.String("container", od.ContainerName),
			zap.Int("timeout", od.Timeout))

		if err := od.waitForContainer(container, nil); err != nil {
			od.logger.Error("container failed to become ready",
				zap.String("container", od.ContainerName),
				zap.Error(err))
			return http.StatusGatewayTimeout,
				fmt.Errorf("container %s failed to become ready: %w", od.ContainerName, err)
		}

		od.logger.Info("container is now ready",
			zap.String("container", od.ContainerName))
	default:
		if err := od.waitForContainer(container, &state); err != nil {
			od.logger.Error("container failed health check",
				zap.String("container", od.ContainerName),
				zap.Error(err))
			return http.StatusGatewayTimeout,
				fmt.Errorf("container %s is unhealthy: %w", od.ContainerName, err)
		}
	}

	cacheMutex.Lock()
	statusCache[container] = &cacheEntry{
		status:    "running",
		checkTime: time.Now(),
	}
	cacheMutex.Unlock()

	return nil, nil
}

// containerState is the subset of docker inspect output used for readiness
type containerState struct {
	status string // "not found" if the container could not be inspected
	health string // empty if the container has no health check
	ips    []string
}

// inspectContainer returns the container's status, health and IPs from one docker inspect
func inspectContainer(ctx context.Context, container string) containerState {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "docker", "inspect", "--format",
		"{{.State.Status}}|{{if .State.Health}}{{.State.Health.Status}}{{end}}|{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}",
		container)
	output, err := cmd.Output()
	if err != nil {
		return containerState{status: "not found"}
	}

	parts := strings.SplitN(strings.TrimSpace(string(output)), "|", 3)
	if len(parts) != 3 {
		return containerState{status: "not found"}
	}
	return containerState{status: parts[0], health: parts[1], ips: strings.Fields(parts[2])}
}

// startContainer starts the Docker container
func (od *OnDemandDocker) startContainer(container string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "docker", "start", container)
	output, err := cmd.CombinedOutput()
	if err != nil {
		outputStr := strings.TrimSpace(string(output))
		// Check if the error is because the container doesn't exist
		if strings.Contains(outputStr, "No such container") || strings.Contains(outputStr, "no such container") {
			return fmt.Errorf("container '%s' does not exist - it needs to be created first (e.g., 'docker compose create %s')", container, od.ContainerName)
		}
		// Include the actual error output for better debugging
		return fmt.Errorf("failed to start container '%s': %s", container, outputStr)
	}

	return nil
}

// waitForContainer polls until the container is ready or the timeout expires.
// It checks immediately, using state if provided, before waiting on the ticker.
func (od *OnDemandDocker) waitForContainer(container string, state *containerState) error {
	startTime := time.Now()
	timeout := time.Duration(od.Timeout) * time.Second
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()

	hasHealthCheck := od.hasHealthCheck()
	for {
		if state == nil {
			s := inspectContainer(ctx, container)
			state = &s
		}

		od.logger.Debug("container status during wait",
			zap.String("container", od.ContainerName),
			zap.String("status", state.status),
			zap.String("health", state.health),
			zap.Duration("elapsed", time.Since(startTime)))

		if state.status == "running" {
			switch state.health {
			case "healthy":
				od.logger.Info("container is healthy and ready",
					zap.String("container", od.ContainerName),
					zap.Duration("startup_time", time.Since(startTime)))
				return nil
			case "unhealthy":
				od.logger.Error("container is unhealthy",
					zap.String("container", od.ContainerName))
				return fmt.Errorf("container health check is failing")
			}

			// Only probe the port if there's no health check to wait for
			if !hasHealthCheck && od.isPortReady(ctx, state.ips) {
				od.logger.Info("container port is ready (no health check)",
					zap.String("container", od.ContainerName),
					zap.Int("port", od.Port),
					zap.Duration("startup_time", time.Since(startTime)))
				return nil
			}
		}

		select {
		case <-ctx.Done():
			return fmt.Errorf("timeout waiting for container to be ready after %v", timeout)
		case <-ticker.C:
		}
		state = nil
	}
}

// hasHealthCheck returns whether the container has a health check configured
func (od *OnDemandDocker) hasHealthCheck() bool {
	allowlistMutex.RLock()
	defer allowlistMutex.RUnlock()

	if !allowlistLoaded {
		return false
	}

	if service, exists := sitesConfig.Services[od.ContainerName]; exists {
		return service.HasHealthCheck
	}

	return false
}

// isPortReady checks if the container's port is accepting connections on any of its IPs
func (od *OnDemandDocker) isPortReady(ctx context.Context, ips []string) bool {
	if od.Port == 0 {
		// No port specified, assume ready
		od.logger.Debug("no port specified for readiness check",
			zap.String("container", od.ContainerName))
		return true
	}

	if len(ips) == 0 {
		od.logger.Warn("container has no IP address",
			zap.String("container", od.ContainerName))
		return false
	}

	dialer := net.Dialer{Timeout: time.Second}
	for _, ip := range ips {
		address := net.JoinHostPort(ip, strconv.Itoa(od.Port))
		conn, err := dialer.DialContext(ctx, "tcp", address)
		if err != nil {
			od.logger.Debug("port not ready yet",
				zap.String("container", od.ContainerName),
				zap.String("address", address),
				zap.Error(err))
			continue
		}
		conn.Close()

		od.logger.Debug("port is ready",
			zap.String("container", od.ContainerName),
			zap.String("address", address))
		return true
	}
	return false
}

// resolveContainerName determines the actual container name to use based on COMPOSE_PROJECT_NAME
func (od *OnDemandDocker) resolveContainerName() string {
	// First check if we already have a cached project name
	projectNameMutex.RLock()
	if cachedProjectName != "" {
		projectNameMutex.RUnlock()
		return fmt.Sprintf("%s-%s-1", cachedProjectName, od.ContainerName)
	}
	projectNameMutex.RUnlock()
	
	// Check environment variable
	projectName := os.Getenv("COMPOSE_PROJECT_NAME")
	if projectName == "" {
		// Try to auto-detect the project name from the caddy container
		detectedName, err := detectProjectName()
		if err != nil {
			// Log error and return empty string - the caller will handle this
			od.logger.Error("failed to detect Docker Compose project name", 
				zap.Error(err))
			return ""
		}
		projectName = detectedName
	}
	
	// Cache the project name for future use
	projectNameMutex.Lock()
	cachedProjectName = projectName
	projectNameMutex.Unlock()
	
	// Return the standard Docker Compose naming pattern
	// Docker Compose uses: {project_name}-{service_name}-{container_number}
	return fmt.Sprintf("%s-%s-1", projectName, od.ContainerName)
}

// detectProjectName attempts to auto-detect the Docker Compose project name
// by looking at the container labels of the current process
func detectProjectName() (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	// First, try to get our hostname which should be the container ID
	hostname, err := os.Hostname()
	if err != nil {
		return "", fmt.Errorf("failed to get hostname: %w", err)
	}
	
	// Get container info using the hostname (which is the container ID in Docker)
	cmd := exec.CommandContext(ctx, "docker", "inspect", hostname, "--format", "{{index .Config.Labels \"com.docker.compose.project\"}}")
	output, err := cmd.Output()
	if err != nil {
		// If that fails, try to find the caddy container by name pattern
		cmd = exec.CommandContext(ctx, "docker", "ps", "-q", "--filter", "name=caddy")
		containerIDs, err := cmd.Output()
		if err != nil {
			return "", fmt.Errorf("failed to find caddy container: %w", err)
		}
		
		ids := strings.TrimSpace(string(containerIDs))
		if ids == "" {
			return "", fmt.Errorf("no caddy container found")
		}
		
		// Get the first container ID
		containerID := strings.Split(ids, "\n")[0]
		
		// Get the project label from this container
		cmd = exec.CommandContext(ctx, "docker", "inspect", containerID, "--format", "{{index .Config.Labels \"com.docker.compose.project\"}}")
		output, err = cmd.Output()
		if err != nil {
			return "", fmt.Errorf("failed to inspect container: %w", err)
		}
	}
	
	projectName := strings.TrimSpace(string(output))
	if projectName == "" {
		return "", fmt.Errorf("container has no com.docker.compose.project label")
	}
	
	return projectName, nil
}

// parseCaddyfile unmarshals tokens from the Caddyfile into the module.
func parseCaddyfile(h httpcaddyfile.Helper) (caddyhttp.MiddlewareHandler, error) {
	var od OnDemandDocker
	
	// Parse the container name (required first argument)
	if !h.Next() {
		return nil, h.ArgErr()
	}
	
	args := h.RemainingArgs()
	if len(args) < 1 || len(args) > 2 {
		return nil, h.Err("expected one or two arguments: container_name [port]")
	}
	od.ContainerName = args[0]
	
	// If port is provided as second argument
	if len(args) == 2 {
		port, err := strconv.Atoi(args[1])
		if err != nil {
			return nil, h.Errf("invalid port value: %v", err)
		}
		od.Port = port
	}
	
	// Parse optional block
	for h.NextBlock(0) {
		switch h.Val() {
		case "timeout":
			var timeoutStr string
			if !h.Args(&timeoutStr) {
				return nil, h.Err("timeout requires an integer argument")
			}
			timeout, err := strconv.Atoi(timeoutStr)
			if err != nil {
				return nil, h.Errf("invalid timeout value: %v", err)
			}
			od.Timeout = timeout
		case "port":
			var portStr string
			if !h.Args(&portStr) {
				return nil, h.Err("port requires an integer argument")
			}
			port, err := strconv.Atoi(portStr)
			if err != nil {
				return nil, h.Errf("invalid port value: %v", err)
			}
			od.Port = port
		default:
			return nil, h.Errf("unrecognized subdirective: %s", h.Val())
		}
	}
	
	return &od, nil
}

// Interface guards
var (
	_ caddy.Provisioner           = (*OnDemandDocker)(nil)
	_ caddy.Validator             = (*OnDemandDocker)(nil)
	_ caddyhttp.MiddlewareHandler = (*OnDemandDocker)(nil)
)