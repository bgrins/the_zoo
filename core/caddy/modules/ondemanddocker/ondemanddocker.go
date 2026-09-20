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
// resource usage while maintaining a smooth developer experience. With
// ZOO_IDLE_STOP set, it also stops on-demand containers that have gone that long
// without requests.
//
// Performance characteristics:
// - First request to stopped container: ~2-3s (container startup time)
// - Subsequent requests: ~0.02s (cached status, no docker inspect overhead)
// - Cache duration: 5 minutes (configurable via cacheDuration constant)
package ondemanddocker

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/httpcaddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"github.com/thezoo/dockerapi"
	"go.uber.org/zap"
	"golang.org/x/sync/singleflight"
	"gopkg.in/yaml.v3"
)

const (
	// cacheDuration is how long to cache the container status to avoid repeated docker inspect calls
	cacheDuration = 5 * time.Minute

	// statusClientClosedRequest matches what reverse_proxy reports for canceled requests
	statusClientClosedRequest = 499

	// pollInterval is how often a port is probed while a container without a
	// healthcheck starts
	pollInterval = 50 * time.Millisecond

	// stoppedGrace is how long a container must stay exited before a wait gives
	// up on it; a restart or recreate passes through exited briefly
	stoppedGrace = time.Second
)

// sitesFile is the part of SITES.yaml that defines the service allowlist
type sitesFile struct {
	Sites []struct {
		Service  string `yaml:"service"`
		OnDemand bool   `yaml:"onDemand"`
		Heavy    bool   `yaml:"heavy"`
	} `yaml:"sites"`
}

var (
	sitesConfigPath = "/etc/caddy/SITES.yaml"

	// fallbackInterval is how often a waiting container is inspected in case
	// an event was missed
	fallbackInterval = time.Second

	docker = dockerapi.New(dockerapi.DefaultSocket)
	events = newEventWatcher(docker)

	// Recently ready site blocks, keyed by portKey: without a healthcheck, one port
	// accepting connections says nothing about the container's other ports
	statusCache = make(map[string]*cacheEntry)
	cacheMutex  sync.RWMutex

	// Global cache for discovered project name
	cachedProjectName string
	projectNameMutex  sync.RWMutex

	// Services that on_demand_docker may start, loaded from SITES.yaml, those
	// among them in the on-demand profile, which it may also stop, and those in
	// the heavy profile, whose containers exist only when asked for
	serviceAllowlist map[string]bool
	onDemandServices map[string]bool
	heavyServices    map[string]bool
	allowlistMutex   sync.RWMutex
	allowlistLoaded  bool
	sitesModTime     time.Time
	sitesSize        int64

	// Module instances are per site block and many can share one container, so
	// its start and health wait run once process-wide. Only a container without
	// a healthcheck is waited on per port.
	containerGroup singleflight.Group // keyed by resolved container name
	portGroup      singleflight.Group // keyed by portKey

	// errStopped means the container stopped while it was waited on. Docker
	// reports a container its restart policy brings back as restarting instead.
	errStopped = errors.New("container stopped")

	// errNoContainer means the service's container has not been created
	errNoContainer = errors.New("container does not exist")
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

	var config sitesFile
	if err := yaml.Unmarshal(configData, &config); err != nil {
		return fmt.Errorf("failed to parse SITES.yaml: %w", err)
	}

	allowlist := make(map[string]bool)
	onDemand := make(map[string]bool)
	heavy := make(map[string]bool)
	for _, site := range config.Sites {
		if site.Service != "" {
			allowlist[site.Service] = true
			if site.OnDemand {
				onDemand[site.Service] = true
			}
			if site.Heavy {
				heavy[site.Service] = true
			}
		}
	}

	allowlistMutex.Lock()
	serviceAllowlist = allowlist
	onDemandServices = onDemand
	heavyServices = heavy
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

// isOnDemandService reports whether SITES.yaml lists the service as on demand
func isOnDemandService(serviceName string) bool {
	allowlistMutex.RLock()
	defer allowlistMutex.RUnlock()
	return onDemandServices[serviceName]
}

// isHeavyService reports whether SITES.yaml lists the service as heavy
func isHeavyService(serviceName string) bool {
	allowlistMutex.RLock()
	defer allowlistMutex.RUnlock()
	return heavyServices[serviceName]
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

	idleAfter, err := idleStopAfter()
	if err != nil {
		return err
	}
	if idleAfter > 0 {
		// Module instances come and go with config reloads; the stopper runs once per process
		idleStopOnce.Do(func() {
			od.logger.Info("stopping on-demand containers when idle", zap.Duration("after", idleAfter))
			stopper := &idleStopper{after: idleAfter, started: now(), logger: od.logger}
			go stopper.run(context.Background())
		})
	}

	// Don't resolve container name here - it's resolved per request from the cached project name
	od.logger.Debug("on_demand_docker module provisioned",
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

	project := projectName(od.logger)
	if project == "" {
		return caddyhttp.Error(http.StatusInternalServerError,
			fmt.Errorf("failed to determine Docker Compose project name"))
	}
	events.start(project, od.logger)
	// Docker Compose names containers {project}-{service}-{number}
	container := fmt.Sprintf("%s-%s-1", project, od.ContainerName)

	release, err := activity.begin(r.Context(), container, od.logger)
	if err != nil {
		return caddyhttp.Error(statusClientClosedRequest, err)
	}
	defer release()

	// Check if we have a recent cached status indicating the container is running
	cacheKey := od.portKey(container)
	cacheMutex.RLock()
	entry, exists := statusCache[cacheKey]
	cacheMutex.RUnlock()

	// If we have a recent cache entry showing the container is running, skip the check
	if exists && entry.status == "running" && time.Since(entry.checkTime) < cacheDuration {
		od.logger.Debug("using cached status, container is running",
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
				delete(statusCache, cacheKey)
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

	deadline := time.Now().Add(time.Duration(od.Timeout) * time.Second)
	val, err := await(r, &containerGroup, container, func() (interface{}, error) {
		return od.ensureRunning(container, deadline)
	})
	if errors.Is(err, errNoContainer) {
		// Caddy sends an error's status without its message, and this one needs the client to act
		http.Error(w, od.missingContainerMessage(container), http.StatusServiceUnavailable)
		return nil
	}
	if err != nil {
		return err
	}
	// Without a healthcheck, the container is ready once this site's port accepts connections
	if state := val.(containerState); state.health == "" && od.Port != 0 {
		if _, err := await(r, &portGroup, od.portKey(container), func() (interface{}, error) {
			return od.waitForPort(container, state, deadline)
		}); err != nil {
			return err
		}
	}

	cacheMutex.Lock()
	statusCache[od.portKey(container)] = &cacheEntry{
		status:    "running",
		checkTime: time.Now(),
	}
	cacheMutex.Unlock()

	od.logger.Debug("passing request to next handler",
		zap.String("container", od.ContainerName))
	return next.ServeHTTP(w, r)
}

// await joins the flight for key. Flights run detached from any one request, so
// a client disconnecting only abandons its own wait. A failed flight's value is
// the HTTP status code to report with its error.
func await(r *http.Request, group *singleflight.Group, key string, fn func() (interface{}, error)) (interface{}, error) {
	select {
	case res := <-group.DoChan(key, fn):
		if res.Err != nil {
			return nil, caddyhttp.Error(res.Val.(int), res.Err)
		}
		return res.Val, nil
	case <-r.Context().Done():
		return nil, caddyhttp.Error(statusClientClosedRequest, r.Context().Err())
	}
}

// portKey identifies one site block's port of a container
func (od *OnDemandDocker) portKey(container string) string {
	return fmt.Sprintf("%s:%d", container, od.Port)
}

// ensureRunning starts the container if needed and waits until it runs and, if
// it has a healthcheck, until the check passes or fails. It returns the
// container's state.
func (od *OnDemandDocker) ensureRunning(container string, deadline time.Time) (interface{}, error) {
	startTime := time.Now()
	initial := inspectContainer(context.Background(), container)

	od.logger.Info("container status check",
		zap.String("container", od.ContainerName),
		zap.String("status", initial.status),
		zap.Error(initial.err))

	known := &initial
	if initial.status != "running" {
		od.logger.Info("container is not running, attempting to start",
			zap.String("container", od.ContainerName),
			zap.String("actual_container", container),
			zap.String("current_status", initial.status))

		if err := od.startContainer(container); errors.Is(err, errNoContainer) {
			od.logger.Warn("container does not exist",
				zap.String("container", od.ContainerName),
				zap.String("actual_container", container),
				zap.Bool("heavy", isHeavyService(od.ContainerName)))
			return http.StatusServiceUnavailable, err
		} else if err != nil {
			od.logger.Error("failed to start container",
				zap.String("container", od.ContainerName),
				zap.String("actual_container", container),
				zap.Error(err))
			return http.StatusInternalServerError, err
		}

		od.logger.Info("waiting for container to be ready",
			zap.String("container", od.ContainerName),
			zap.Int("timeout", od.Timeout))
		known = nil
	}

	state, err := od.waitForContainer(container, known, deadline, false, func(_ context.Context, s containerState) bool {
		return s.health != "starting"
	})
	if err != nil {
		return od.notReady(err)
	}

	switch state.health {
	case "healthy":
		od.logger.Info("container is healthy and ready",
			zap.String("container", od.ContainerName),
			zap.Duration("startup_time", time.Since(startTime)))
	case "unhealthy":
		// Let the app's own error reach the client
		od.logger.Warn("container health check is failing, proxying anyway",
			zap.String("container", od.ContainerName))
	}
	return state, nil
}

// waitForPort waits until the port accepts connections, starting from the state
// the container's start wait ended with
func (od *OnDemandDocker) waitForPort(container string, state containerState, deadline time.Time) (interface{}, error) {
	startTime := time.Now()
	if _, err := od.waitForContainer(container, &state, deadline, true, func(ctx context.Context, s containerState) bool {
		return od.isPortReady(ctx, s.ips)
	}); err != nil {
		return od.notReady(err)
	}

	od.logger.Info("container port is ready (no health check)",
		zap.String("container", od.ContainerName),
		zap.Int("port", od.Port),
		zap.Duration("startup_time", time.Since(startTime)))
	return nil, nil
}

// notReady logs why the container is not ready and returns the error with the HTTP status code to report
func (od *OnDemandDocker) notReady(err error) (interface{}, error) {
	od.logger.Error("container failed to become ready",
		zap.String("container", od.ContainerName),
		zap.Error(err))

	code := http.StatusGatewayTimeout
	if errors.Is(err, errStopped) {
		code = http.StatusBadGateway
	}
	return code, fmt.Errorf("container %s failed to become ready: %w", od.ContainerName, err)
}

// containerState is the subset of the container's inspect data used for readiness
type containerState struct {
	status   string // "not found" or "unknown" if the container could not be inspected
	exitCode int
	health   string // empty if the container has no health check
	ips      []string
	err      error // why the container could not be inspected
	// generation is the number of the container's events seen before the inspect
	generation uint64
}

// inspectContainer returns the container's status, health and IPs
func inspectContainer(ctx context.Context, container string) containerState {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	generation := events.generation(container)
	info, err := docker.InspectContainer(ctx, container)
	if dockerapi.IsNotFound(err) {
		return containerState{status: "not found", err: err, generation: generation}
	}
	if err != nil {
		return containerState{status: "unknown", err: err, generation: generation}
	}

	state := containerState{status: info.State.Status, exitCode: info.State.ExitCode, generation: generation}
	if h := info.State.Health; h != nil && h.Status != "none" {
		state.health = h.Status
	}
	for _, network := range info.NetworkSettings.Networks {
		if network.IPAddress != "" {
			state.ips = append(state.ips, network.IPAddress)
		}
	}
	return state
}

// startContainer starts the Docker container
func (od *OnDemandDocker) startContainer(container string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	err := docker.StartContainer(ctx, container)
	if dockerapi.IsNotFound(err) {
		return fmt.Errorf("%w: %s", errNoContainer, container)
	}
	if err != nil {
		return fmt.Errorf("failed to start container '%s': %w", container, err)
	}
	return nil
}

// missingContainerMessage tells the client how to create the service's container
func (od *OnDemandDocker) missingContainerMessage(container string) string {
	if isHeavyService(od.ContainerName) {
		return fmt.Sprintf("%s is a heavy app, so its container (%s) is created only on request: "+
			"run `the_zoo start --with-heavy` (CLI) or `docker compose --profile heavy up -d --no-start %s` (dev), then retry.",
			od.ContainerName, container, od.ContainerName)
	}
	return fmt.Sprintf("The container of %s (%s) does not exist: "+
		"run `the_zoo start` (CLI) or `docker compose --profile on-demand up -d --no-start %s` (dev), then retry.",
		od.ContainerName, container, od.ContainerName)
}

// waitForContainer waits until the container runs and ready accepts its state,
// the container stays stopped for stoppedGrace, or the deadline passes. It
// checks immediately, using state if provided. It inspects the container again
// when Docker reports an event for it, when a stopped container's grace period
// ends, and every fallbackInterval in case an event was missed. With probe set,
// ready tests something Docker doesn't report on, like a port accepting
// connections, and is retried every pollInterval. Errors carry the last state seen.
func (od *OnDemandDocker) waitForContainer(container string, state *containerState, deadline time.Time, probe bool, ready func(context.Context, containerState) bool) (containerState, error) {
	startTime := time.Now()
	ctx, cancel := context.WithDeadline(context.Background(), deadline)
	defer cancel()

	var stoppedSince time.Time
	inspectedAt := time.Now()
	for {
		if state == nil {
			s := inspectContainer(ctx, container)
			state = &s
			inspectedAt = time.Now()
		}

		od.logger.Debug("container status during wait",
			zap.String("container", od.ContainerName),
			zap.String("status", state.status),
			zap.String("health", state.health),
			zap.Duration("elapsed", time.Since(startTime)))

		stopped := state.status == "exited" || state.status == "dead"
		switch {
		case state.status == "running" && ready(ctx, *state):
			return *state, nil
		case !stopped:
			stoppedSince = time.Time{}
		case stoppedSince.IsZero():
			stoppedSince = time.Now()
		case time.Since(stoppedSince) >= stoppedGrace:
			return *state, fmt.Errorf("%w (status %s, exit code %d)", errStopped, state.status, state.exitCode)
		}

		wait, inspect := fallbackInterval-time.Since(inspectedAt), true
		if !stoppedSince.IsZero() {
			wait = min(wait, stoppedGrace-time.Since(stoppedSince))
		}
		if probe && state.status == "running" && pollInterval < wait {
			// Without an IP there is nothing to probe until an inspect finds one
			wait, inspect = pollInterval, len(state.ips) == 0
		}

		timer := time.NewTimer(wait)
		select {
		case <-ctx.Done():
			timer.Stop()
			return *state, fmt.Errorf("timed out after %v (last status %s, health %q, exit code %d)",
				time.Since(startTime).Round(time.Millisecond), state.status, state.health, state.exitCode)
		case <-events.changed(container, state.generation):
			timer.Stop()
			state = nil
		case <-timer.C:
			if inspect {
				state = nil
			}
		}
	}
}

// isPortReady checks if the container's port is accepting connections on any of its IPs
func (od *OnDemandDocker) isPortReady(ctx context.Context, ips []string) bool {
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

// projectName returns the Docker Compose project, from COMPOSE_PROJECT_NAME or
// else Caddy's own container, or "" if it can't be determined
func projectName(logger *zap.Logger) string {
	projectNameMutex.RLock()
	project := cachedProjectName
	projectNameMutex.RUnlock()
	if project != "" {
		return project
	}

	project = os.Getenv("COMPOSE_PROJECT_NAME")
	if project == "" {
		detected, err := detectProjectName()
		if err != nil {
			logger.Error("failed to detect Docker Compose project name", zap.Error(err))
			return ""
		}
		project = detected
	}

	projectNameMutex.Lock()
	cachedProjectName = project
	projectNameMutex.Unlock()
	return project
}

// detectProjectName reads the Docker Compose project from Caddy's own container
func detectProjectName() (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	return docker.ProjectName(ctx)
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
