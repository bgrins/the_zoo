// Package dockerapi is a minimal Docker Engine API client that talks to the
// daemon over its unix socket, covering only what the zoo's Caddy modules need.
package dockerapi

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

// DefaultSocket is where docker-compose.yaml mounts the Docker socket
const DefaultSocket = "/var/run/docker.sock"

// Client sends requests to the Docker Engine API. Requests are unversioned so
// the daemon answers with its current API version.
type Client struct {
	http *http.Client
}

// New returns a client for the daemon listening on the given unix socket
func New(socket string) *Client {
	return &Client{http: &http.Client{Transport: &http.Transport{
		DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
			var d net.Dialer
			return d.DialContext(ctx, "unix", socket)
		},
		// dockerstatus inspects and collects stats for every container concurrently
		MaxIdleConnsPerHost: 64,
		IdleConnTimeout:     90 * time.Second,
	}}}
}

// Error is a non-2xx/3xx response from the daemon
type Error struct {
	StatusCode int
	Message    string
}

func (e *Error) Error() string { return e.Message }

// IsNotFound reports whether the daemon answered 404, e.g. "No such container"
func IsNotFound(err error) bool {
	var apiErr *Error
	return errors.As(err, &apiErr) && apiErr.StatusCode == http.StatusNotFound
}

// Do sends a request and returns the response, or an *Error for status >= 400.
// The caller must close the response body.
func (c *Client) Do(ctx context.Context, method, path string, query url.Values) (*http.Response, error) {
	u := "http://docker" + path
	if len(query) > 0 {
		u += "?" + query.Encode()
	}
	req, err := http.NewRequestWithContext(ctx, method, u, nil)
	if err != nil {
		return nil, err
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode < 400 {
		return resp, nil
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
	var body struct {
		Message string `json:"message"`
	}
	if json.Unmarshal(data, &body) != nil || body.Message == "" {
		body.Message = strings.TrimSpace(string(data))
	}
	if body.Message == "" {
		body.Message = resp.Status
	}
	return nil, &Error{StatusCode: resp.StatusCode, Message: body.Message}
}

// GetJSON decodes the JSON response of a GET request into out
func (c *Client) GetJSON(ctx context.Context, path string, query url.Values, out interface{}) error {
	resp, err := c.Do(ctx, http.MethodGet, path, query)
	if err != nil {
		return err
	}
	defer closeBody(resp)
	return json.NewDecoder(resp.Body).Decode(out)
}

// closeBody drains the body so the connection can be reused
func closeBody(resp *http.Response) {
	_, _ = io.Copy(io.Discard, resp.Body)
	resp.Body.Close()
}

// Filters encodes list filters, e.g. {"label": {"a=b"}}, as the API's filters parameter
func Filters(filters map[string][]string) url.Values {
	data, _ := json.Marshal(filters)
	return url.Values{"filters": {string(data)}}
}

// Container is the subset of GET /containers/{id}/json used by the modules
type Container struct {
	RestartCount int
	State        struct {
		Status    string
		StartedAt string
		// Health is only present for containers with a healthcheck
		Health *struct {
			Status string
		}
	}
	Config struct {
		Labels map[string]string
	}
	NetworkSettings struct {
		Networks map[string]struct {
			IPAddress string
		}
	}
}

// ContainerSummary is an entry of GET /containers/json
type ContainerSummary struct {
	ID      string `json:"Id"`
	Names   []string
	Image   string
	ImageID string
	Created int64
	Ports   []Port
	Labels  map[string]string
	State   string
	Status  string
}

// Port is a container port as reported by GET /containers/json
type Port struct {
	IP          string
	PrivatePort uint16
	PublicPort  uint16
	Type        string
}

// InspectContainer returns the container's details
func (c *Client) InspectContainer(ctx context.Context, name string) (*Container, error) {
	var info Container
	if err := c.GetJSON(ctx, "/containers/"+url.PathEscape(name)+"/json", nil, &info); err != nil {
		return nil, err
	}
	return &info, nil
}

// StartContainer starts the container; starting a running container is not an error
func (c *Client) StartContainer(ctx context.Context, name string) error {
	resp, err := c.Do(ctx, http.MethodPost, "/containers/"+url.PathEscape(name)+"/start", nil)
	if err != nil {
		return err
	}
	closeBody(resp)
	return nil
}

// ListContainers lists containers matching filters, including stopped ones if all is set
func (c *Client) ListContainers(ctx context.Context, all bool, filters map[string][]string) ([]ContainerSummary, error) {
	query := url.Values{}
	if len(filters) > 0 {
		query = Filters(filters)
	}
	if all {
		query.Set("all", "1")
	}
	var list []ContainerSummary
	if err := c.GetJSON(ctx, "/containers/json", query, &list); err != nil {
		return nil, err
	}
	return list, nil
}

// ProjectName returns the Docker Compose project of the container this process runs in
func (c *Client) ProjectName(ctx context.Context) (string, error) {
	hostname, err := os.Hostname()
	if err != nil {
		return "", fmt.Errorf("failed to get hostname: %w", err)
	}

	// Docker sets the hostname to the container ID unless it is overridden
	var labels map[string]string
	if info, err := c.InspectContainer(ctx, hostname); err == nil {
		labels = info.Config.Labels
	} else {
		list, err := c.ListContainers(ctx, false, map[string][]string{"name": {"caddy"}})
		if err != nil {
			return "", fmt.Errorf("failed to find caddy container: %w", err)
		}
		if len(list) == 0 {
			return "", fmt.Errorf("no caddy container found")
		}
		labels = list[0].Labels
	}

	project := labels["com.docker.compose.project"]
	if project == "" {
		return "", fmt.Errorf("container has no com.docker.compose.project label")
	}
	return project, nil
}
