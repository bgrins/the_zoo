// Package dockerstatus provides a Caddy HTTP handler that exposes Docker container
// status information through a REST API. This replaces the status.zoo dashboard's
// direct Docker socket access by implementing the API endpoints within Caddy itself.
package dockerstatus

import (
	"context"
	"encoding/json"
	"fmt"
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
)

func init() {
	caddy.RegisterModule(DockerStatus{})
	httpcaddyfile.RegisterHandlerDirective("docker_status", parseCaddyfile)
}

// DockerStatus is a Caddy HTTP handler that provides Docker container status information
type DockerStatus struct {
	// ProjectName is the Docker Compose project name to filter containers
	ProjectName string `json:"project_name,omitempty"`
	
	logger *zap.Logger
	
	// Cache for container stats to reduce Docker calls
	statsCache     map[string]*ContainerStats
	statsCacheMutex sync.RWMutex
	statsCacheTime  time.Time
}

// Container represents a Docker container with its status
type Container struct {
	ID           string            `json:"id"`
	Name         string            `json:"name"`
	Image        string            `json:"image"`
	Status       string            `json:"status"`
	State        string            `json:"state"`
	Ports        map[string]string `json:"ports"`
	Labels       map[string]string `json:"labels"`
	Created      string            `json:"created"`
	StartedAt    string            `json:"startedAt"`
	RestartCount int               `json:"restartCount"`
}

// ContainerStats represents resource usage statistics for a container
type ContainerStats struct {
	CPUPerc string `json:"cpuPerc"`
	MemPerc string `json:"memPerc"`
	MemUsage string `json:"memUsage"`
	NetIO   string `json:"netIO"`
	BlockIO string `json:"blockIO"`
	PIDs    string `json:"pids"`
}

// SystemMetrics represents system-wide Docker metrics
type SystemMetrics struct {
	Images     int               `json:"images"`
	Volumes    int               `json:"volumes"`
	Memory     map[string]string `json:"memory"`
	Timestamp  int64             `json:"timestamp"`
}

// CaddyModule returns the Caddy module information
func (DockerStatus) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "http.handlers.docker_status",
		New: func() caddy.Module { return new(DockerStatus) },
	}
}

// Provision sets up the module
func (ds *DockerStatus) Provision(ctx caddy.Context) error {
	ds.logger = ctx.Logger(ds)
	ds.statsCache = make(map[string]*ContainerStats)
	
	// If no project name specified, try to auto-detect it
	if ds.ProjectName == "" {
		// Try to detect the project name by looking at our own container
		projectName, err := ds.detectProjectName()
		if err != nil {
			return fmt.Errorf("failed to auto-detect Docker Compose project name: %w", err)
		}
		ds.ProjectName = projectName
	}
	
	ds.logger.Info("docker_status module provisioned", 
		zap.String("project_name", ds.ProjectName))
	
	return nil
}

// ServeHTTP implements the HTTP handler interface
func (ds *DockerStatus) ServeHTTP(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler) error {
	// Set JSON content type for all responses
	w.Header().Set("Content-Type", "application/json")
	
	// Set CORS headers to allow cross-origin requests
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
	
	// Handle preflight requests
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return nil
	}
	
	// Route based on the path
	switch {
	case r.URL.Path == "/ok":
		return ds.handleHealthCheck(w, r)
	case r.URL.Path == "/api/containers":
		return ds.handleContainers(w, r)
	case strings.HasPrefix(r.URL.Path, "/api/container/") && strings.HasSuffix(r.URL.Path, "/logs"):
		return ds.handleContainerLogs(w, r)
	case r.URL.Path == "/api/system-metrics":
		return ds.handleSystemMetrics(w, r)
	default:
		// Not our endpoint, pass to next handler
		return next.ServeHTTP(w, r)
	}
}

// handleHealthCheck responds to health check requests
func (ds *DockerStatus) handleHealthCheck(w http.ResponseWriter, r *http.Request) error {
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	return nil
}

// handleContainers returns the list of containers with optional stats
func (ds *DockerStatus) handleContainers(w http.ResponseWriter, r *http.Request) error {
	// Check if stats are requested
	includeStats := r.URL.Query().Get("stats") == "true"
	
	// Get containers list
	containers, err := ds.getContainers()
	if err != nil {
		ds.logger.Error("failed to get containers", zap.Error(err))
		return caddyhttp.Error(http.StatusInternalServerError, err)
	}
	
	// Prepare response
	response := map[string]interface{}{
		"containers": containers,
		"timestamp":  time.Now().Unix(),
	}
	
	// Add stats if requested
	if includeStats {
		stats, err := ds.getContainerStats()
		if err != nil {
			ds.logger.Warn("failed to get container stats", zap.Error(err))
			// Don't fail the request, just omit stats
		} else {
			response["stats"] = stats
		}
	}
	
	return json.NewEncoder(w).Encode(response)
}

// handleContainerLogs returns logs for a specific container
func (ds *DockerStatus) handleContainerLogs(w http.ResponseWriter, r *http.Request) error {
	// Extract container name from path
	parts := strings.Split(r.URL.Path, "/")
	if len(parts) < 4 {
		return caddyhttp.Error(http.StatusBadRequest, fmt.Errorf("invalid path"))
	}
	containerName := parts[3]
	
	// Get tail parameter
	tail := r.URL.Query().Get("tail")
	if tail == "" {
		tail = "50"
	}
	
	// Get logs
	logs, err := ds.getContainerLogs(containerName, tail)
	if err != nil {
		ds.logger.Error("failed to get container logs", 
			zap.String("container", containerName),
			zap.Error(err))
		return caddyhttp.Error(http.StatusInternalServerError, err)
	}
	
	return json.NewEncoder(w).Encode(map[string]interface{}{
		"logs":      logs,
		"container": containerName,
		"tail":      tail,
	})
}

// handleSystemMetrics returns system-wide Docker metrics
func (ds *DockerStatus) handleSystemMetrics(w http.ResponseWriter, r *http.Request) error {
	metrics, err := ds.getSystemMetrics()
	if err != nil {
		ds.logger.Error("failed to get system metrics", zap.Error(err))
		return caddyhttp.Error(http.StatusInternalServerError, err)
	}
	
	return json.NewEncoder(w).Encode(metrics)
}

// getContainers retrieves the list of containers for the project
func (ds *DockerStatus) getContainers() ([]Container, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	// Get containers filtered by project
	cmd := exec.CommandContext(ctx, "docker", "ps", "-a", 
		"--filter", fmt.Sprintf("label=com.docker.compose.project=%s", ds.ProjectName),
		"--format", "json")
	
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list containers: %w", err)
	}
	
	var containers []Container
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	
	for _, line := range lines {
		if line == "" {
			continue
		}
		
		var rawContainer map[string]interface{}
		if err := json.Unmarshal([]byte(line), &rawContainer); err != nil {
			ds.logger.Warn("failed to parse container JSON", 
				zap.String("line", line),
				zap.Error(err))
			continue
		}
		
		// Parse the container data
		container := Container{
			ID:        getString(rawContainer, "ID"),
			Name:      strings.TrimPrefix(getString(rawContainer, "Names"), "/"),
			Image:     getString(rawContainer, "Image"),
			Status:    getString(rawContainer, "Status"),
			State:     getString(rawContainer, "State"),
			Created:   getString(rawContainer, "CreatedAt"),
			StartedAt: getString(rawContainer, "StartedAt"),
		}
		
		// Parse ports
		container.Ports = make(map[string]string)
		if portsStr := getString(rawContainer, "Ports"); portsStr != "" {
			// Simple port parsing - could be enhanced
			container.Ports["raw"] = portsStr
		}
		
		// Get additional container details
		if details, err := ds.getContainerDetails(container.Name); err == nil {
			container.Labels = details.Labels
			container.RestartCount = details.RestartCount
		}
		
		containers = append(containers, container)
	}
	
	return containers, nil
}

// getContainerDetails retrieves detailed information about a container
func (ds *DockerStatus) getContainerDetails(name string) (*Container, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, "docker", "inspect", name)
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}
	
	var inspectData []map[string]interface{}
	if err := json.Unmarshal(output, &inspectData); err != nil {
		return nil, err
	}
	
	if len(inspectData) == 0 {
		return nil, fmt.Errorf("no container data")
	}
	
	data := inspectData[0]
	container := &Container{
		Labels: make(map[string]string),
	}
	
	// Extract labels
	if config, ok := data["Config"].(map[string]interface{}); ok {
		if labels, ok := config["Labels"].(map[string]interface{}); ok {
			for k, v := range labels {
				container.Labels[k] = fmt.Sprintf("%v", v)
			}
		}
	}
	
	// Extract restart count
	if state, ok := data["State"].(map[string]interface{}); ok {
		if restartCount, ok := state["RestartCount"].(float64); ok {
			container.RestartCount = int(restartCount)
		}
	}
	
	return container, nil
}

// getContainerStats retrieves resource usage statistics for all containers
func (ds *DockerStatus) getContainerStats() (map[string]*ContainerStats, error) {
	// Check cache
	ds.statsCacheMutex.RLock()
	if time.Since(ds.statsCacheTime) < 2*time.Second && len(ds.statsCache) > 0 {
		cachedStats := make(map[string]*ContainerStats)
		for k, v := range ds.statsCache {
			cachedStats[k] = v
		}
		ds.statsCacheMutex.RUnlock()
		return cachedStats, nil
	}
	ds.statsCacheMutex.RUnlock()
	
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, "docker", "stats", "--no-stream", "--format", "{{json .}}")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get container stats: %w", err)
	}
	
	stats := make(map[string]*ContainerStats)
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	
	for _, line := range lines {
		if line == "" {
			continue
		}
		
		var rawStats map[string]interface{}
		if err := json.Unmarshal([]byte(line), &rawStats); err != nil {
			continue
		}
		
		name := strings.TrimPrefix(getString(rawStats, "Name"), "/")
		stats[name] = &ContainerStats{
			CPUPerc:  getString(rawStats, "CPUPerc"),
			MemPerc:  getString(rawStats, "MemPerc"),
			MemUsage: getString(rawStats, "MemUsage"),
			NetIO:    getString(rawStats, "NetIO"),
			BlockIO:  getString(rawStats, "BlockIO"),
			PIDs:     getString(rawStats, "PIDs"),
		}
	}
	
	// Update cache
	ds.statsCacheMutex.Lock()
	ds.statsCache = stats
	ds.statsCacheTime = time.Now()
	ds.statsCacheMutex.Unlock()
	
	return stats, nil
}

// getContainerLogs retrieves logs for a specific container
func (ds *DockerStatus) getContainerLogs(name string, tail string) (string, error) {
	// Validate tail parameter
	if _, err := strconv.Atoi(tail); err != nil {
		tail = "50"
	}
	
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, "docker", "logs", name, "--tail", tail)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("failed to get logs: %w", err)
	}
	
	return string(output), nil
}

// getSystemMetrics retrieves system-wide Docker metrics
func (ds *DockerStatus) getSystemMetrics() (*SystemMetrics, error) {
	metrics := &SystemMetrics{
		Memory:    make(map[string]string),
		Timestamp: time.Now().Unix(),
	}
	
	// Count images
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, "docker", "image", "ls", 
		"--filter", "reference=thezoo-*", "-q")
	output, err := cmd.Output()
	if err == nil {
		lines := strings.Split(strings.TrimSpace(string(output)), "\n")
		metrics.Images = len(lines)
		if len(lines) == 1 && lines[0] == "" {
			metrics.Images = 0
		}
	}
	
	// Count volumes
	cmd = exec.CommandContext(ctx, "docker", "volume", "ls", 
		"--filter", fmt.Sprintf("label=com.docker.compose.project=%s", ds.ProjectName), "-q")
	output, err = cmd.Output()
	if err == nil {
		lines := strings.Split(strings.TrimSpace(string(output)), "\n")
		metrics.Volumes = len(lines)
		if len(lines) == 1 && lines[0] == "" {
			metrics.Volumes = 0
		}
	}
	
	// Get memory info from docker system info
	cmd = exec.CommandContext(ctx, "docker", "system", "info", "--format", "{{json .}}")
	output, err = cmd.Output()
	if err == nil {
		var info map[string]interface{}
		if err := json.Unmarshal(output, &info); err == nil {
			if memTotal, ok := info["MemTotal"].(float64); ok {
				metrics.Memory["total"] = fmt.Sprintf("%.2f GB", memTotal/1024/1024/1024)
			}
		}
	}
	
	return metrics, nil
}

// getString safely extracts a string value from a map
func getString(m map[string]interface{}, key string) string {
	if v, ok := m[key]; ok {
		return fmt.Sprintf("%v", v)
	}
	return ""
}

// detectProjectName attempts to auto-detect the Docker Compose project name
// by looking at the container labels of the current process
func (ds *DockerStatus) detectProjectName() (string, error) {
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

// parseCaddyfile unmarshals tokens from the Caddyfile into the module
func parseCaddyfile(h httpcaddyfile.Helper) (caddyhttp.MiddlewareHandler, error) {
	var ds DockerStatus
	
	// Skip the directive name
	if !h.Next() {
		return nil, h.ArgErr()
	}
	
	// Parse optional project name argument
	args := h.RemainingArgs()
	if len(args) > 0 {
		ds.ProjectName = args[0]
	}
	
	// Parse optional block
	for h.NextBlock(0) {
		switch h.Val() {
		case "project_name":
			if !h.Args(&ds.ProjectName) {
				return nil, h.Err("project_name requires a value")
			}
		default:
			return nil, h.Errf("unrecognized subdirective: %s", h.Val())
		}
	}
	
	return &ds, nil
}

// Interface guards
var (
	_ caddy.Provisioner           = (*DockerStatus)(nil)
	_ caddyhttp.MiddlewareHandler = (*DockerStatus)(nil)
)