// Package dockerstatus provides a Caddy HTTP handler that exposes Docker container
// status information through a REST API. This replaces the status.zoo dashboard's
// direct Docker socket access by implementing the API endpoints within Caddy itself.
package dockerstatus

import (
	"context"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
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
)

// maxLogTail caps the lines a logs request returns
const maxLogTail = 1000

var (
	// statusOrigins are the pages that may read the API cross-origin
	statusOrigins = map[string]bool{"https://status.zoo": true, "http://status.zoo": true}

	// withheldLogs are the services whose logs can hold OAuth codes and tokens: Caddy's
	// access log records them in URLs, and auth-zoo and Hydra handle the flows
	withheldLogs = map[string]bool{"caddy": true, "auth-zoo": true, "hydra": true}

	// hostPathLabels hold paths on the Docker host
	hostPathLabels = map[string]bool{
		"com.docker.compose.project.working_dir":      true,
		"com.docker.compose.project.config_files":     true,
		"com.docker.compose.project.environment_file": true,
	}
)

func init() {
	caddy.RegisterModule(new(DockerStatus))
	httpcaddyfile.RegisterHandlerDirective("docker_status", parseCaddyfile)
}

// DockerStatus is a Caddy HTTP handler that provides Docker container status information
type DockerStatus struct {
	// ProjectName is the Docker Compose project name to filter containers
	ProjectName string `json:"project_name,omitempty"`

	logger *zap.Logger
	docker *dockerapi.Client

	// Detected from Caddy's own container on the first request when ProjectName is unset
	detectedProject string
	projectMutex    sync.Mutex

	// Cache for container stats to reduce Docker calls
	statsCache      map[string]*ContainerStats
	statsCacheMutex sync.RWMutex
	statsCacheTime  time.Time
	// Requests that miss the cache together share one collection, keyed by project
	statsGroup singleflight.Group
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
	Stats        *ContainerStats   `json:"stats,omitempty"`
}

// ContainerStats represents resource usage statistics for a container
type ContainerStats struct {
	CPUPerc  string `json:"cpuPerc"`
	MemPerc  string `json:"memPerc"`
	MemUsage string `json:"memUsage"`
	NetIO    string `json:"netIO"`
	BlockIO  string `json:"blockIO"`
	PIDs     string `json:"pids"`
}

// SystemMetrics represents system-wide Docker metrics
type SystemMetrics struct {
	Images    int               `json:"images"`
	Volumes   int               `json:"volumes"`
	Memory    map[string]string `json:"memory"`
	Timestamp int64             `json:"timestamp"`
}

// CaddyModule returns the Caddy module information
func (*DockerStatus) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "http.handlers.docker_status",
		New: func() caddy.Module { return new(DockerStatus) },
	}
}

// Provision sets up the module
func (ds *DockerStatus) Provision(ctx caddy.Context) error {
	ds.logger = ctx.Logger(ds)
	ds.docker = dockerapi.New(dockerapi.DefaultSocket)
	ds.statsCache = make(map[string]*ContainerStats)

	ds.logger.Info("docker_status module provisioned",
		zap.String("project_name", ds.ProjectName))

	return nil
}

// project returns the Docker Compose project to report on. Detection waits for the
// first request rather than Provision, so a slow Docker daemon can't keep Caddy from
// loading its config.
func (ds *DockerStatus) project(ctx context.Context) (string, error) {
	if ds.ProjectName != "" {
		return ds.ProjectName, nil
	}
	ds.projectMutex.Lock()
	defer ds.projectMutex.Unlock()
	if ds.detectedProject == "" {
		detectCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
		defer cancel()
		project, err := ds.docker.ProjectName(detectCtx)
		if err != nil {
			return "", fmt.Errorf("failed to detect Docker Compose project name: %w", err)
		}
		ds.detectedProject = project
	}
	return ds.detectedProject, nil
}

func projectFilter(project string) map[string][]string {
	return dockerapi.ProjectContainers(project)
}

// ServeHTTP implements the HTTP handler interface
func (ds *DockerStatus) ServeHTTP(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler) error {
	// Set JSON content type for all responses
	w.Header().Set("Content-Type", "application/json")

	// Other pages in the zoo browser must not read container details
	w.Header().Add("Vary", "Origin")
	if origin := r.Header.Get("Origin"); statusOrigins[origin] {
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
	}

	// Handle preflight requests
	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return nil
	}

	// Route based on the path
	switch {
	case r.URL.Path == "/ok":
		return ds.handleHealthCheck(w, r)
	case strings.HasPrefix(r.URL.Path, "/api/"):
	default:
		// Not our endpoint, pass to next handler
		return next.ServeHTTP(w, r)
	}

	project, err := ds.project(r.Context())
	if err != nil {
		ds.logger.Error("failed to determine project", zap.Error(err))
		return caddyhttp.Error(http.StatusServiceUnavailable, err)
	}
	switch {
	case r.URL.Path == "/api/containers":
		return ds.handleContainers(w, r, project)
	case strings.HasPrefix(r.URL.Path, "/api/container/") && strings.HasSuffix(r.URL.Path, "/logs"):
		return ds.handleContainerLogs(w, r, project)
	case r.URL.Path == "/api/system-metrics":
		return ds.handleSystemMetrics(w, r, project)
	default:
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
func (ds *DockerStatus) handleContainers(w http.ResponseWriter, r *http.Request, project string) error {
	// Check if stats are requested
	includeStats := r.URL.Query().Get("stats") == "true"

	// Get containers list
	containers, err := ds.getContainers(project)
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
		stats, err := ds.getContainerStats(project)
		if err != nil {
			ds.logger.Warn("failed to get container stats", zap.Error(err))
			// Don't fail the request, just omit stats
		} else {
			response["stats"] = stats
			for i := range containers {
				containers[i].Stats = stats[containers[i].Name]
			}
		}
	}

	return json.NewEncoder(w).Encode(response)
}

// handleContainerLogs returns logs for a specific container
func (ds *DockerStatus) handleContainerLogs(w http.ResponseWriter, r *http.Request, project string) error {
	// Extract container name from path
	parts := strings.Split(r.URL.Path, "/")
	if len(parts) < 4 {
		return caddyhttp.Error(http.StatusBadRequest, fmt.Errorf("invalid path"))
	}
	containerName := parts[3]

	// The whole log is buffered in memory, so keep it bounded
	tail := 50
	if n, err := strconv.Atoi(r.URL.Query().Get("tail")); err == nil && n >= 1 {
		tail = min(n, maxLogTail)
	}

	// Only this project's containers: other projects and unrelated containers share the daemon
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	info, err := ds.docker.InspectContainer(ctx, containerName)
	cancel()
	if dockerapi.IsNotFound(err) || (err == nil && !dockerapi.IsProjectContainer(info.Config.Labels, project)) {
		return writeError(w, http.StatusNotFound, fmt.Sprintf("no container %q in project %s", containerName, project))
	}
	if err != nil {
		ds.logger.Error("failed to inspect container for its logs", zap.String("container", containerName), zap.Error(err))
		return writeError(w, http.StatusBadGateway, fmt.Sprintf("failed to inspect container %q: %v", containerName, err))
	}
	if service := info.Config.Labels["com.docker.compose.service"]; withheldLogs[service] {
		return writeError(w, http.StatusForbidden, fmt.Sprintf(
			"the logs of %s are withheld because they can hold OAuth codes and tokens; see them with `docker compose logs %s`",
			service, service))
	}

	logs, err := ds.getContainerLogs(containerName, tail)
	if err != nil {
		ds.logger.Error("failed to get container logs",
			zap.String("container", containerName),
			zap.Error(err))
		return writeError(w, http.StatusBadGateway, err.Error())
	}

	return json.NewEncoder(w).Encode(map[string]interface{}{
		"logs":      logs,
		"container": containerName,
		"tail":      tail,
	})
}

// writeError answers with the message as JSON, which status.zoo shows. Caddy sends a
// returned error's status without its message.
func writeError(w http.ResponseWriter, code int, message string) error {
	w.WriteHeader(code)
	return json.NewEncoder(w).Encode(map[string]string{"error": message})
}

// handleSystemMetrics returns system-wide Docker metrics
func (ds *DockerStatus) handleSystemMetrics(w http.ResponseWriter, r *http.Request, project string) error {
	metrics, err := ds.getSystemMetrics(project)
	if err != nil {
		ds.logger.Error("failed to get system metrics", zap.Error(err))
		return caddyhttp.Error(http.StatusInternalServerError, err)
	}

	return json.NewEncoder(w).Encode(metrics)
}

// getContainers retrieves the list of containers for the project
func (ds *DockerStatus) getContainers(project string) ([]Container, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	list, err := ds.docker.ListContainers(ctx, true, projectFilter(project))
	if err != nil {
		return nil, fmt.Errorf("failed to list containers: %w", err)
	}

	containers := make([]Container, len(list))
	var wg sync.WaitGroup
	for i, c := range list {
		containers[i] = Container{
			ID:      truncateID(c.ID),
			Name:    containerName(c.Names),
			Image:   displayImage(c.Image, c.ImageID),
			Status:  c.Status,
			State:   c.State,
			Ports:   make(map[string]string),
			Created: time.Unix(c.Created, 0).String(),
		}
		if ports := displayPorts(c.Ports); ports != "" {
			containers[i].Ports["raw"] = ports
		}

		// Only inspect reports restarts and the start time. Its labels are the
		// container's own; Docker Desktop adds its own labels to list entries.
		wg.Add(1)
		go func(i int, id string) {
			defer wg.Done()
			info, err := ds.docker.InspectContainer(ctx, id)
			if err != nil {
				// e.g. the container was removed after it was listed
				ds.logger.Warn("failed to inspect container", zap.String("id", id), zap.Error(err))
				return
			}
			containers[i].Labels = publicLabels(info.Config.Labels)
			containers[i].RestartCount = info.RestartCount
			containers[i].StartedAt = info.State.StartedAt
		}(i, c.ID)
	}
	wg.Wait()

	return containers, nil
}

// publicLabels returns the labels without those that hold host paths, including Docker
// Desktop's bind mount labels
func publicLabels(labels map[string]string) map[string]string {
	public := make(map[string]string, len(labels))
	for key, value := range labels {
		if !hostPathLabels[key] && !strings.HasPrefix(key, "desktop.docker.io/") {
			public[key] = value
		}
	}
	return public
}

// truncateID shortens a container or image ID the way docker ps does
func truncateID(id string) string {
	id = strings.TrimPrefix(id, "sha256:")
	if len(id) > 12 {
		id = id[:12]
	}
	return id
}

// containerName returns the container's own name; other names are legacy link aliases like /a/b
func containerName(names []string) string {
	for _, name := range names {
		name = strings.TrimPrefix(name, "/")
		if !strings.Contains(name, "/") {
			return name
		}
	}
	return ""
}

// displayImage formats the image reference as docker ps does: image IDs are
// truncated, digests and the default docker.io/library/ prefix are dropped
func displayImage(image, imageID string) string {
	if image == "" {
		return "<no image>"
	}
	if truncateID(image) == truncateID(imageID) {
		return truncateID(image)
	}
	if i := strings.Index(image, "@"); i >= 0 {
		image = image[:i]
	}
	if rest := strings.TrimPrefix(image, "docker.io/"); rest != image {
		image = strings.TrimPrefix(rest, "library/")
	}
	return image
}

// displayPorts formats ports as docker ps does, e.g. "0.0.0.0:3128->3128/tcp, 8074-8075/tcp"
func displayPorts(ports []dockerapi.Port) string {
	type portGroup struct{ first, last uint16 }
	groups := make(map[string]*portGroup)
	var keys, result, hostMappings []string

	sorted := append([]dockerapi.Port(nil), ports...)
	sort.Slice(sorted, func(i, j int) bool {
		a, b := sorted[i], sorted[j]
		if a.PrivatePort != b.PrivatePort {
			return a.PrivatePort < b.PrivatePort
		}
		if a.IP != b.IP {
			return a.IP < b.IP
		}
		if a.PublicPort != b.PublicPort {
			return a.PublicPort < b.PublicPort
		}
		return a.Type < b.Type
	})

	for _, port := range sorted {
		key := port.Type
		if port.IP != "" {
			if port.PublicPort != port.PrivatePort {
				hostMappings = append(hostMappings,
					fmt.Sprintf("%s:%d->%d/%s", port.IP, port.PublicPort, port.PrivatePort, port.Type))
				continue
			}
			key = port.IP + "/" + port.Type
		}

		group := groups[key]
		if group == nil {
			groups[key] = &portGroup{port.PrivatePort, port.PrivatePort}
			keys = append(keys, key)
			continue
		}
		if port.PrivatePort == group.last+1 {
			group.last = port.PrivatePort
			continue
		}
		result = append(result, formatPortGroup(key, group.first, group.last))
		groups[key] = &portGroup{port.PrivatePort, port.PrivatePort}
	}
	for _, key := range keys {
		result = append(result, formatPortGroup(key, groups[key].first, groups[key].last))
	}
	return strings.Join(append(result, hostMappings...), ", ")
}

// formatPortGroup formats a port range keyed by "type" or "ip/type"
func formatPortGroup(key string, first, last uint16) string {
	ip, portType, published := strings.Cut(key, "/")
	if !published {
		portType = key
	}
	group := strconv.Itoa(int(first))
	if first != last {
		group = fmt.Sprintf("%s-%d", group, last)
	}
	if published {
		group = fmt.Sprintf("%s:%s->%s", ip, group, group)
	}
	return group + "/" + portType
}

// statsResponse is the subset of GET /containers/{id}/stats that docker stats uses
type statsResponse struct {
	Name        string   `json:"name"`
	CPUStats    cpuStats `json:"cpu_stats"`
	PreCPUStats cpuStats `json:"precpu_stats"`
	MemoryStats struct {
		Usage uint64            `json:"usage"`
		Limit uint64            `json:"limit"`
		Stats map[string]uint64 `json:"stats"`
	} `json:"memory_stats"`
	BlkioStats struct {
		IoServiceBytesRecursive []struct {
			Op    string `json:"op"`
			Value uint64 `json:"value"`
		} `json:"io_service_bytes_recursive"`
	} `json:"blkio_stats"`
	Networks map[string]struct {
		RxBytes uint64 `json:"rx_bytes"`
		TxBytes uint64 `json:"tx_bytes"`
	} `json:"networks"`
	PidsStats struct {
		Current uint64 `json:"current"`
	} `json:"pids_stats"`
}

type cpuStats struct {
	CPUUsage struct {
		TotalUsage  uint64   `json:"total_usage"`
		PercpuUsage []uint64 `json:"percpu_usage"`
	} `json:"cpu_usage"`
	SystemUsage uint64 `json:"system_cpu_usage"`
	OnlineCPUs  uint32 `json:"online_cpus"`
}

// getContainerStats retrieves resource usage statistics for the project's running containers
func (ds *DockerStatus) getContainerStats(project string) (map[string]*ContainerStats, error) {
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

	// Each collection waits a second for the daemon's samples of every container
	stats, err, _ := ds.statsGroup.Do(project, func() (interface{}, error) {
		return ds.collectStats(project)
	})
	if err != nil {
		return nil, err
	}
	return stats.(map[string]*ContainerStats), nil
}

// collectStats asks the daemon for the stats of the project's running containers and caches them
func (ds *DockerStatus) collectStats(project string) (map[string]*ContainerStats, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	running, err := ds.docker.ListContainers(ctx, false, projectFilter(project))
	if err != nil {
		return nil, fmt.Errorf("failed to get container stats: %w", err)
	}

	stats := make(map[string]*ContainerStats, len(running))
	var mu sync.Mutex
	var wg sync.WaitGroup
	for _, c := range running {
		wg.Add(1)
		go func(id string) {
			defer wg.Done()
			// Without streaming the daemon waits for a second sample so CPU usage has a baseline
			var s statsResponse
			query := url.Values{"stream": {"false"}}
			if err := ds.docker.GetJSON(ctx, "/containers/"+id+"/stats", query, &s); err != nil {
				ds.logger.Debug("failed to get container stats", zap.String("id", id), zap.Error(err))
				return
			}
			mu.Lock()
			stats[strings.TrimPrefix(s.Name, "/")] = formatStats(&s)
			mu.Unlock()
		}(c.ID)
	}
	wg.Wait()

	// Update cache
	ds.statsCacheMutex.Lock()
	ds.statsCache = stats
	ds.statsCacheTime = time.Now()
	ds.statsCacheMutex.Unlock()

	return stats, nil
}

// formatStats computes the values docker stats prints on Linux
func formatStats(s *statsResponse) *ContainerStats {
	var cpuPercent float64
	cpuDelta := float64(s.CPUStats.CPUUsage.TotalUsage) - float64(s.PreCPUStats.CPUUsage.TotalUsage)
	systemDelta := float64(s.CPUStats.SystemUsage) - float64(s.PreCPUStats.SystemUsage)
	onlineCPUs := float64(s.CPUStats.OnlineCPUs)
	if onlineCPUs == 0 {
		onlineCPUs = float64(len(s.CPUStats.CPUUsage.PercpuUsage))
	}
	if systemDelta > 0 && cpuDelta > 0 {
		cpuPercent = cpuDelta / systemDelta * onlineCPUs * 100
	}

	// Inactive page cache is reclaimable, so it doesn't count as used (cgroup v1 key, then v2)
	mem := s.MemoryStats
	used := float64(mem.Usage)
	if v, ok := mem.Stats["total_inactive_file"]; ok && v < mem.Usage {
		used = float64(mem.Usage - v)
	} else if v := mem.Stats["inactive_file"]; v < mem.Usage {
		used = float64(mem.Usage - v)
	}
	limit := float64(mem.Limit)
	var memPercent float64
	if limit != 0 {
		memPercent = used / limit * 100
	}

	var blkRead, blkWrite float64
	for _, entry := range s.BlkioStats.IoServiceBytesRecursive {
		if entry.Op == "" {
			continue
		}
		switch entry.Op[0] {
		case 'r', 'R':
			blkRead += float64(entry.Value)
		case 'w', 'W':
			blkWrite += float64(entry.Value)
		}
	}

	var rx, tx float64
	for _, network := range s.Networks {
		rx += float64(network.RxBytes)
		tx += float64(network.TxBytes)
	}

	return &ContainerStats{
		CPUPerc:  fmt.Sprintf("%.2f%%", cpuPercent),
		MemPerc:  fmt.Sprintf("%.2f%%", memPercent),
		MemUsage: binarySize(used) + " / " + binarySize(limit),
		NetIO:    decimalSize(rx) + " / " + decimalSize(tx),
		BlockIO:  decimalSize(blkRead) + " / " + decimalSize(blkWrite),
		PIDs:     strconv.FormatUint(s.PidsStats.Current, 10),
	}
}

// binarySize formats bytes like go-units BytesSize, e.g. "69.87MiB"
func binarySize(size float64) string {
	units := []string{"B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"}
	i := 0
	for size >= 1024 && i < len(units)-1 {
		size /= 1024
		i++
	}
	return fmt.Sprintf("%.4g%s", size, units[i])
}

// decimalSize formats bytes like go-units HumanSizeWithPrecision(size, 3), e.g. "4.89MB",
// except that values rounding up to 1000 move to the next unit where go-units prints "1e+03"
func decimalSize(size float64) string {
	units := []string{"B", "kB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"}
	i := 0
	for size >= 1000 && i < len(units)-1 {
		size /= 1000
		i++
	}
	formatted := fmt.Sprintf("%.3g", size)
	if formatted == "1e+03" && i < len(units)-1 {
		formatted = "1"
		i++
	}
	return formatted + units[i]
}

// getContainerLogs retrieves the last tail lines of a container's stdout and stderr
func (ds *DockerStatus) getContainerLogs(name string, tail int) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	query := url.Values{"stdout": {"1"}, "stderr": {"1"}, "tail": {strconv.Itoa(tail)}}
	resp, err := ds.docker.Do(ctx, http.MethodGet, "/containers/"+url.PathEscape(name)+"/logs", query)
	if err != nil {
		return "", fmt.Errorf("failed to get logs: %w", err)
	}
	defer resp.Body.Close()

	var logs strings.Builder
	// Only TTY containers send a raw stream; the others multiplex stdout and stderr
	if resp.Header.Get("Content-Type") == "application/vnd.docker.raw-stream" {
		_, err = io.Copy(&logs, resp.Body)
	} else {
		err = demuxLogs(&logs, resp.Body)
	}
	if err != nil {
		return "", fmt.Errorf("failed to read logs: %w", err)
	}
	return logs.String(), nil
}

// demuxLogs copies the payloads of a multiplexed log stream to w in order.
// Each frame is an 8-byte header (stream type, three zero bytes, big-endian
// uint32 payload size) followed by the payload.
func demuxLogs(w io.Writer, r io.Reader) error {
	var header [8]byte
	for {
		if _, err := io.ReadFull(r, header[:]); err != nil {
			if err == io.EOF {
				return nil
			}
			return err
		}
		if _, err := io.CopyN(w, r, int64(binary.BigEndian.Uint32(header[4:]))); err != nil {
			return err
		}
	}
}

// getSystemMetrics retrieves the project's image and volume counts and the host memory
func (ds *DockerStatus) getSystemMetrics(project string) (*SystemMetrics, error) {
	metrics := &SystemMetrics{
		Memory:    make(map[string]string),
		Timestamp: time.Now().Unix(),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	projectLabel := projectFilter(project)

	// Count the images the project's containers use. Image labels name whichever project
	// built a shared image, and images pulled or built by bake have none.
	containers, err := ds.docker.ListContainers(ctx, true, projectLabel)
	if err != nil {
		ds.logger.Warn("failed to list containers", zap.Error(err))
	}
	images := make(map[string]bool)
	for _, c := range containers {
		images[c.ImageID] = true
	}
	metrics.Images = len(images)

	var volumes struct {
		Volumes []struct{}
	}
	volumeFilter := dockerapi.Filters(map[string][]string{"label": {"com.docker.compose.project=" + project}})
	if err := ds.docker.GetJSON(ctx, "/volumes", volumeFilter, &volumes); err != nil {
		ds.logger.Warn("failed to list volumes", zap.Error(err))
	}
	metrics.Volumes = len(volumes.Volumes)

	var info struct {
		MemTotal int64
	}
	if err := ds.docker.GetJSON(ctx, "/info", nil, &info); err == nil && info.MemTotal > 0 {
		metrics.Memory["total"] = fmt.Sprintf("%.2f GB", float64(info.MemTotal)/1024/1024/1024)
	}

	return metrics, nil
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
