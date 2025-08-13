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
	"encoding/json"
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
	"gopkg.in/yaml.v3"
)

const (
	// cacheDuration is how long to cache the container status to avoid repeated docker inspect calls
	cacheDuration = 5 * time.Minute
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
)

type cacheEntry struct {
	status    string
	checkTime time.Time
}

func init() {
	caddy.RegisterModule(OnDemandDocker{})
	httpcaddyfile.RegisterHandlerDirective("on_demand_docker", parseCaddyfile)
}

// loadServiceAllowlist loads the service allowlist from SITES.yaml
func loadServiceAllowlist() error {
	allowlistMutex.Lock()
	defer allowlistMutex.Unlock()
	
	// Only load once
	if allowlistLoaded {
		return nil
	}
	
	// Load from the mounted location
	configPath := "/etc/caddy/SITES.yaml"
	configData, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read SITES.yaml: %w", err)
	}
	
	var config SitesConfig
	if err := yaml.Unmarshal(configData, &config); err != nil {
		return fmt.Errorf("failed to parse SITES.yaml: %w", err)
	}
	
	// Store the full config
	sitesConfig = config
	
	// Build the allowlist from sites
	serviceAllowlist = make(map[string]bool)
	for _, site := range config.Sites {
		if site.Service != "" {
			serviceAllowlist[site.Service] = true
		}
	}
	
	// Also add services from the services section
	for serviceName := range config.Services {
		serviceAllowlist[serviceName] = true
	}
	
	allowlistLoaded = true
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
	
	// actualContainerName is the resolved container name (with project prefix if applicable)
	actualContainerName string
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
	
	// Load the service allowlist if not already loaded
	if err := loadServiceAllowlist(); err != nil {
		od.logger.Warn("failed to load service allowlist, will use dynamic validation",
			zap.Error(err))
	}
	
	// Don't resolve container name here - do it lazily on first request
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
	
	// Lazily resolve container name on first request
	if od.actualContainerName == "" {
		od.actualContainerName = od.resolveContainerName()
		if od.actualContainerName == "" {
			// Failed to resolve container name
			return caddyhttp.Error(http.StatusInternalServerError, 
				fmt.Errorf("failed to determine Docker Compose project name"))
		}
		od.logger.Debug("resolved container name",
			zap.String("container_name", od.ContainerName),
			zap.String("actual_container_name", od.actualContainerName))
	}
	
	// Check if we have a recent cached status indicating the container is running
	cacheMutex.RLock()
	entry, exists := statusCache[od.actualContainerName]
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
				delete(statusCache, od.actualContainerName)
				cacheMutex.Unlock()
				
				// Recheck the container status and handle it properly
				return od.handleRequest(w, r, next)
			}
		}
		return err
	}
	
	return od.handleRequest(w, r, next)
}

// handleRequest processes the request by checking container status and starting if needed
func (od *OnDemandDocker) handleRequest(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler) error {
	
	od.logger.Info("handling request for on-demand container",
		zap.String("container", od.ContainerName),
		zap.String("method", r.Method),
		zap.String("uri", r.RequestURI),
		zap.String("host", r.Host))
	
	// Check container status
	status, err := od.getContainerStatus()
	if err != nil {
		od.logger.Error("failed to get container status", 
			zap.String("container", od.ContainerName),
			zap.Error(err))
		return caddyhttp.Error(http.StatusInternalServerError, err)
	}
	
	// Update cache
	cacheMutex.Lock()
	statusCache[od.actualContainerName] = &cacheEntry{
		status:    status,
		checkTime: time.Now(),
	}
	cacheMutex.Unlock()
	
	od.logger.Info("container status check",
		zap.String("container", od.ContainerName),
		zap.String("status", status))
	
	// If container is not running, start it and wait
	if status != "running" {
		od.logger.Info("container is not running, attempting to start",
			zap.String("container", od.ContainerName),
			zap.String("actual_container", od.actualContainerName),
			zap.String("current_status", status))
		
		// Special handling for "not found" status
		if status == "not found" {
			od.logger.Warn("container does not exist",
				zap.String("container", od.ContainerName),
				zap.String("actual_container", od.actualContainerName),
				zap.String("hint", fmt.Sprintf("Run 'docker compose create %s' to create the container", od.ContainerName)))
		}
		
		// Start the container
		if err := od.startContainer(); err != nil {
			od.logger.Error("failed to start container",
				zap.String("container", od.ContainerName),
				zap.String("actual_container", od.actualContainerName),
				zap.Error(err))
			return caddyhttp.Error(http.StatusInternalServerError, err)
		}
		
		// Wait for container to be ready (this holds the connection open)
		od.logger.Info("waiting for container to be ready",
			zap.String("container", od.ContainerName),
			zap.Int("timeout", od.Timeout))
		
		if err := od.waitForContainer(); err != nil {
			od.logger.Error("container failed to become ready",
				zap.String("container", od.ContainerName),
				zap.Error(err))
			
			// Return a gateway timeout error since the container didn't start in time
			return caddyhttp.Error(http.StatusGatewayTimeout, 
				fmt.Errorf("container %s failed to become ready: %w", od.ContainerName, err))
		}
		
		od.logger.Info("container is now ready",
			zap.String("container", od.ContainerName))
		
		// Update cache to indicate container is now running
		cacheMutex.Lock()
		statusCache[od.actualContainerName] = &cacheEntry{
			status:    "running",
			checkTime: time.Now(),
		}
		cacheMutex.Unlock()
	} else {
		// Container is already running, but check if it's healthy
		healthy, err := od.isContainerHealthy()
		if err != nil {
			od.logger.Warn("error checking container health",
				zap.String("container", od.ContainerName),
				zap.Error(err))
		} else if !healthy {
			od.logger.Info("container is running but not yet healthy, waiting",
				zap.String("container", od.ContainerName))
			
			// Wait for container to become healthy
			if err := od.waitForContainer(); err != nil {
				od.logger.Error("container failed health check",
					zap.String("container", od.ContainerName),
					zap.Error(err))
				
				// Return a gateway timeout error since the container isn't healthy
				return caddyhttp.Error(http.StatusGatewayTimeout, 
					fmt.Errorf("container %s is unhealthy: %w", od.ContainerName, err))
			}
		}
	}
	
	// Container is running and ready, proceed with the request
	od.logger.Debug("passing request to next handler",
		zap.String("container", od.ContainerName))
	return next.ServeHTTP(w, r)
}

// getContainerStatus returns the current status of the container
func (od *OnDemandDocker) getContainerStatus() (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, "docker", "inspect", "--format", "{{.State.Status}}", od.actualContainerName)
	output, err := cmd.Output()
	if err != nil {
		// Container might not exist
		return "not found", nil
	}
	
	return strings.TrimSpace(string(output)), nil
}

// startContainer starts the Docker container
func (od *OnDemandDocker) startContainer() error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, "docker", "start", od.actualContainerName)
	output, err := cmd.CombinedOutput()
	if err != nil {
		outputStr := strings.TrimSpace(string(output))
		// Check if the error is because the container doesn't exist
		if strings.Contains(outputStr, "No such container") || strings.Contains(outputStr, "no such container") {
			return fmt.Errorf("container '%s' does not exist - it needs to be created first (e.g., 'docker compose create %s')", od.actualContainerName, od.ContainerName)
		}
		// Include the actual error output for better debugging
		return fmt.Errorf("failed to start container '%s': %s", od.actualContainerName, outputStr)
	}
	
	return nil
}

// waitForContainer waits for the container to be ready
func (od *OnDemandDocker) waitForContainer() error {
	startTime := time.Now()
	timeout := time.Duration(od.Timeout) * time.Second
	
	// First, wait for container to be running
	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			// Check if container is running
			status, err := od.getContainerStatus()
			if err != nil {
				return fmt.Errorf("error checking container status: %w", err)
			}
			
			od.logger.Debug("container status during wait",
				zap.String("container", od.ContainerName),
				zap.String("status", status),
				zap.Duration("elapsed", time.Since(startTime)))
			
			if status == "running" {
				// Container is running, now check if it's healthy
				healthy, err := od.isContainerHealthy()
				if err != nil {
					// If there's an error (e.g., container is unhealthy), return it immediately
					return fmt.Errorf("container health check failed: %w", err)
				}
				
				if healthy {
					od.logger.Info("container is healthy and ready",
						zap.String("container", od.ContainerName),
						zap.Duration("startup_time", time.Since(startTime)))
					return nil
				}
				
				// If health check returned nil error but not healthy, it means either:
				// 1. No health check configured - check port readiness
				// 2. Health check is "starting" - keep waiting
				// We can check this from the service allowlist
				hasHealthCheck := od.hasHealthCheck()
				
				// Only check port if there's no health check
				if !hasHealthCheck && od.isPortReady() {
					od.logger.Info("container port is ready (no health check)",
						zap.String("container", od.ContainerName),
						zap.Int("port", od.Port),
						zap.Duration("startup_time", time.Since(startTime)))
					return nil
				}
			}
			
			// Check timeout
			if time.Since(startTime) > timeout {
				return fmt.Errorf("timeout waiting for container to be ready after %v", timeout)
			}
		}
	}
}

// isContainerHealthy checks if the container has a health check and if it's healthy
func (od *OnDemandDocker) isContainerHealthy() (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	// Get detailed container information including health status
	cmd := exec.CommandContext(ctx, "docker", "inspect", "--format", "{{json .State.Health}}", od.actualContainerName)
	output, err := cmd.Output()
	if err != nil {
		return false, fmt.Errorf("failed to inspect container health: %w", err)
	}
	
	healthJSON := strings.TrimSpace(string(output))
	
	// If there's no health check configured, we need to check port readiness
	if healthJSON == "null" || healthJSON == "<no value>" {
		od.logger.Debug("container has no health check, will check port readiness",
			zap.String("container", od.ContainerName))
		return false, nil // Let the caller handle port checking
	}
	
	// Parse the health status to check for unhealthy state
	var health struct {
		Status string `json:"Status"`
	}
	if err := json.Unmarshal([]byte(healthJSON), &health); err != nil {
		od.logger.Warn("failed to parse health status",
			zap.String("container", od.ContainerName),
			zap.String("health", healthJSON),
			zap.Error(err))
		return false, nil
	}
	
	// Check the health status
	switch health.Status {
	case "healthy":
		return true, nil
	case "unhealthy":
		// Container is explicitly unhealthy - this is an error condition
		od.logger.Error("container is unhealthy",
			zap.String("container", od.ContainerName),
			zap.String("health", healthJSON))
		return false, fmt.Errorf("container health check is failing")
	default:
		// Status is "starting" or other states
		od.logger.Debug("container health check not yet passing",
			zap.String("container", od.ContainerName),
			zap.String("status", health.Status))
		return false, nil
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

// isPortReady checks if the container's port is accepting connections
func (od *OnDemandDocker) isPortReady() bool {
	if od.Port == 0 {
		// No port specified, assume ready
		od.logger.Debug("no port specified for readiness check",
			zap.String("container", od.ContainerName))
		return true
	}
	
	// Get container's IP address
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, "docker", "inspect", "--format", "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}", od.actualContainerName)
	output, err := cmd.Output()
	if err != nil {
		od.logger.Warn("failed to get container IP",
			zap.String("container", od.ContainerName),
			zap.Error(err))
		return false
	}
	
	containerIP := strings.TrimSpace(string(output))
	if containerIP == "" {
		od.logger.Warn("container has no IP address",
			zap.String("container", od.ContainerName))
		return false
	}
	
	// Try to connect to the port
	address := fmt.Sprintf("%s:%d", containerIP, od.Port)
	conn, err := net.DialTimeout("tcp", address, 1*time.Second)
	if err != nil {
		od.logger.Debug("port not ready yet",
			zap.String("container", od.ContainerName),
			zap.String("address", address),
			zap.Error(err))
		return false
	}
	conn.Close()
	
	od.logger.Debug("port is ready",
		zap.String("container", od.ContainerName),
		zap.String("address", address))
	return true
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