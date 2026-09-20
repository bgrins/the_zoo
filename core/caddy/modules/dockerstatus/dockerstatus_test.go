package dockerstatus

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"maps"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"github.com/thezoo/dockerapi"
	"go.uber.org/zap"
)

// The expected strings are what `docker ps` printed for zoo containers before
// the module switched from the CLI to the API.
func TestDisplayPorts(t *testing.T) {
	tests := []struct {
		name  string
		ports []dockerapi.Port
		want  string
	}{
		{"none", nil, ""},
		{"protocols", []dockerapi.Port{{PrivatePort: 53, Type: "udp"}, {PrivatePort: 53, Type: "tcp"}}, "53/tcp, 53/udp"},
		{"ranges", []dockerapi.Port{
			{PrivatePort: 8074, Type: "tcp"}, {PrivatePort: 8065, Type: "tcp"},
			{PrivatePort: 8075, Type: "tcp"}, {PrivatePort: 8067, Type: "tcp"},
		}, "8065/tcp, 8067/tcp, 8074-8075/tcp"},
		{"published", []dockerapi.Port{
			{IP: "::", PrivatePort: 3128, PublicPort: 3128, Type: "tcp"},
			{IP: "0.0.0.0", PrivatePort: 3128, PublicPort: 3128, Type: "tcp"},
		}, "0.0.0.0:3128->3128/tcp, :::3128->3128/tcp"},
		{"remapped", []dockerapi.Port{
			{IP: "0.0.0.0", PrivatePort: 80, PublicPort: 8080, Type: "tcp"},
			{PrivatePort: 443, Type: "tcp"},
		}, "443/tcp, 0.0.0.0:8080->80/tcp"},
	}
	for _, tt := range tests {
		if got := displayPorts(tt.ports); got != tt.want {
			t.Errorf("%s: got %q, want %q", tt.name, got, tt.want)
		}
	}
}

func TestDisplayImage(t *testing.T) {
	id := "sha256:2cf7bcf4159b4e1b4d3c0d3f3ab5d1a0e9b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5"
	tests := []struct{ image, want string }{
		{id, "2cf7bcf4159b"},
		{"redis:7.4.7-alpine", "redis:7.4.7-alpine"},
		{"ghcr.io/bgrins/zoo-sites:sha-bbd91fc", "ghcr.io/bgrins/zoo-sites:sha-bbd91fc"},
		{"postgres:16@sha256:4ec37d2a07a0067f176fdcc9d4bb633a5724d2cc4f892c7a2046d054bb6939e5", "postgres:16"},
		{"docker.io/library/nginx:1.27", "nginx:1.27"},
		{"", "<no image>"},
	}
	for _, tt := range tests {
		if got := displayImage(tt.image, id); got != tt.want {
			t.Errorf("displayImage(%q) = %q, want %q", tt.image, got, tt.want)
		}
	}
}

func TestFormatStats(t *testing.T) {
	var s statsResponse
	s.CPUStats.CPUUsage.TotalUsage = 2e9
	s.PreCPUStats.CPUUsage.TotalUsage = 1e9
	s.CPUStats.SystemUsage = 20e9
	s.PreCPUStats.SystemUsage = 10e9
	s.CPUStats.OnlineCPUs = 4
	s.MemoryStats.Usage = 100 << 20
	s.MemoryStats.Limit = 1 << 30
	s.MemoryStats.Stats = map[string]uint64{"inactive_file": 50 << 20}
	s.BlkioStats.IoServiceBytesRecursive = []struct {
		Op    string `json:"op"`
		Value uint64 `json:"value"`
	}{{"read", 4100}, {"write", 1234567}}
	s.Networks = map[string]struct {
		RxBytes uint64 `json:"rx_bytes"`
		TxBytes uint64 `json:"tx_bytes"`
	}{"eth0": {1500, 999}, "eth1": {500, 0}}
	s.PidsStats.Current = 11

	want := ContainerStats{
		CPUPerc:  "40.00%",
		MemPerc:  "4.88%",
		MemUsage: "50MiB / 1GiB",
		NetIO:    "2kB / 999B",
		BlockIO:  "4.1kB / 1.23MB",
		PIDs:     "11",
	}
	if got := *formatStats(&s); got != want {
		t.Errorf("got %+v, want %+v", got, want)
	}
}

func TestDecimalSize(t *testing.T) {
	for size, want := range map[float64]string{
		999:     "999B",
		999499:  "999kB",
		999600:  "1MB",
		1234567: "1.23MB",
	} {
		if got := decimalSize(size); got != want {
			t.Errorf("decimalSize(%v) = %q, want %q", size, got, want)
		}
	}
}

func frame(stream byte, payload string) []byte {
	header := make([]byte, 8)
	header[0] = stream
	binary.BigEndian.PutUint32(header[4:], uint32(len(payload)))
	return append(header, payload...)
}

func TestDemuxLogs(t *testing.T) {
	var stream []byte
	stream = append(stream, frame(1, "listening on :80\n")...)
	stream = append(stream, frame(2, "warning: no config\n")...)
	stream = append(stream, frame(1, "ready\n")...)

	var out strings.Builder
	if err := demuxLogs(&out, bytes.NewReader(stream)); err != nil {
		t.Fatal(err)
	}
	if want := "listening on :80\nwarning: no config\nready\n"; out.String() != want {
		t.Errorf("got %q, want %q", out.String(), want)
	}

	if err := demuxLogs(&out, bytes.NewReader(stream[:len(stream)-2])); err == nil {
		t.Error("truncated stream was not reported")
	}
}

// hostDir is where the fake daemon's compose project lives on the host
const hostDir = "/home/dev/the_zoo"

// fakeDaemon serves the container endpoints the handlers use, for containers named
// {project}-{service}-1 that belong to the compose project in projects[name]
type fakeDaemon struct {
	projects map[string]string
	// list is the containers the list endpoint returns
	list []string

	mu       sync.Mutex
	logTails []string
	filters  []string
}

func (f *fakeDaemon) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()
	switch parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/containers/"), "/"); {
	case r.URL.Path == "/containers/json":
		f.filters = append(f.filters, r.URL.Query().Get("filters"))
		list := []dockerapi.ContainerSummary{}
		for _, name := range f.list {
			list = append(list, dockerapi.ContainerSummary{ID: name, Names: []string{"/" + name},
				Labels: map[string]string{"desktop.docker.io/binds/0/Source": hostDir + "/sites/static"}})
		}
		json.NewEncoder(w).Encode(list)
	case len(parts) == 2 && parts[1] == "json" && f.projects[parts[0]] != "":
		_, service, _ := strings.Cut(strings.TrimSuffix(parts[0], "-1"), "-")
		var info dockerapi.Container
		info.Config.Labels = map[string]string{
			"com.docker.compose.project":              f.projects[parts[0]],
			"com.docker.compose.service":              service,
			"com.docker.compose.project.working_dir":  hostDir,
			"com.docker.compose.project.config_files": hostDir + "/docker-compose.yaml",
			"zoo.description":                         "An app",
		}
		// Run by hand from a compose-built image: it inherits the project label only
		if !strings.HasPrefix(parts[0], "handrun-") {
			info.Config.Labels["com.docker.compose.oneoff"] = "False"
		}
		json.NewEncoder(w).Encode(info)
	case len(parts) == 2 && parts[1] == "logs" && f.projects[parts[0]] != "":
		f.logTails = append(f.logTails, r.URL.Query().Get("tail"))
		w.Header().Set("Content-Type", "application/vnd.docker.raw-stream")
		w.Write([]byte("log line\n"))
	default:
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte(`{"message":"No such container"}`))
	}
}

func serveFake(t *testing.T, f *fakeDaemon) *DockerStatus {
	// Unix socket paths are limited to about 100 bytes, which t.TempDir() can exceed on macOS
	dir, err := os.MkdirTemp("", "ds")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.RemoveAll(dir) })
	socket := filepath.Join(dir, "docker.sock")
	listener, err := net.Listen("unix", socket)
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewUnstartedServer(f)
	srv.Listener = listener
	srv.Start()
	t.Cleanup(srv.Close)
	return &DockerStatus{ProjectName: "zoo", docker: dockerapi.New(socket), logger: zap.NewNop(),
		statsCache: map[string]*ContainerStats{}}
}

func serveAPI(ds *DockerStatus, path string, header http.Header) (*httptest.ResponseRecorder, error) {
	w := httptest.NewRecorder()
	r := httptest.NewRequest(http.MethodGet, "http://system-api.zoo"+path, nil)
	r.Header = header
	return w, ds.ServeHTTP(w, r, caddyhttp.HandlerFunc(func(http.ResponseWriter, *http.Request) error { return nil }))
}

// requireError checks that the handler answered with the JSON error that status.zoo shows
func requireError(t *testing.T, w *httptest.ResponseRecorder, err error, code int, message string) {
	t.Helper()
	if err != nil {
		t.Fatalf("got error %v, want a %d response", err, code)
	}
	var body map[string]string
	if w.Code != code || json.Unmarshal(w.Body.Bytes(), &body) != nil || body["error"] != message {
		t.Errorf("got %d %q, want %d with error %q", w.Code, w.Body.String(), code, message)
	}
}

// Pages in the zoo browser can call system-api, so it must not reveal other projects' containers
func TestLogsOnlyForProjectContainers(t *testing.T) {
	f := &fakeDaemon{projects: map[string]string{"zoo-app-1": "zoo", "other-app-1": "other", "handrun-app-1": "zoo"}}
	ds := serveFake(t, f)

	for _, name := range []string{"other-app-1", "handrun-app-1", "missing-1"} {
		w, err := serveAPI(ds, "/api/container/"+name+"/logs", nil)
		requireError(t, w, err, http.StatusNotFound, fmt.Sprintf("no container %q in project zoo", name))
	}

	w, err := serveAPI(ds, "/api/container/zoo-app-1/logs?tail=100000", nil)
	if err != nil {
		t.Fatalf("logs for the project's container: %v", err)
	}
	if !strings.Contains(w.Body.String(), "log line") {
		t.Errorf("response %q doesn't hold the logs", w.Body.String())
	}
	if want := []string{"1000"}; strings.Join(f.logTails, ",") != strings.Join(want, ",") {
		t.Errorf("requested tails %v, want %v", f.logTails, want)
	}
}

func TestLogsWithheldForOAuthServices(t *testing.T) {
	f := &fakeDaemon{projects: map[string]string{"zoo-caddy-1": "zoo", "zoo-auth-zoo-1": "zoo", "zoo-hydra-1": "zoo"}}
	ds := serveFake(t, f)

	for _, service := range []string{"caddy", "auth-zoo", "hydra"} {
		w, err := serveAPI(ds, "/api/container/zoo-"+service+"-1/logs", nil)
		requireError(t, w, err, http.StatusForbidden, fmt.Sprintf("the logs of %s are withheld because they "+
			"can hold OAuth codes and tokens; see them with `docker compose logs %s`", service, service))
	}
	if len(f.logTails) != 0 {
		t.Errorf("fetched %d logs, want none", len(f.logTails))
	}
}

func TestCORSOnlyForStatusZoo(t *testing.T) {
	ds := serveFake(t, &fakeDaemon{})

	for origin, want := range map[string]string{
		"https://status.zoo":    "https://status.zoo",
		"http://status.zoo":     "http://status.zoo",
		"https://gadgetron.zoo": "",
		"":                      "",
	} {
		header := http.Header{}
		if origin != "" {
			header.Set("Origin", origin)
		}
		w, err := serveAPI(ds, "/api/containers", header)
		if err != nil {
			t.Fatal(err)
		}
		if got := w.Header().Get("Access-Control-Allow-Origin"); got != want {
			t.Errorf("origin %q: got Access-Control-Allow-Origin %q, want %q", origin, got, want)
		}
		if got := w.Header().Get("Vary"); got != "Origin" {
			t.Errorf("origin %q: got Vary %q, want Origin", origin, got)
		}
	}
}

func TestContainersOmitHostPaths(t *testing.T) {
	ds := serveFake(t, &fakeDaemon{projects: map[string]string{"zoo-app-1": "zoo"}, list: []string{"zoo-app-1"}})

	w, err := serveAPI(ds, "/api/containers", nil)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(w.Body.String(), hostDir) {
		t.Errorf("response %s holds the host path %s", w.Body.String(), hostDir)
	}
	var body struct{ Containers []Container }
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	want := map[string]string{
		"com.docker.compose.project": "zoo",
		"com.docker.compose.service": "app",
		"com.docker.compose.oneoff":  "False",
		"zoo.description":            "An app",
	}
	if len(body.Containers) != 1 || !maps.Equal(body.Containers[0].Labels, want) {
		t.Errorf("got containers %+v, want one with labels %v", body.Containers, want)
	}
}

func TestStatsListOnlyProjectContainers(t *testing.T) {
	f := &fakeDaemon{}
	ds := serveFake(t, f)

	if _, err := ds.getContainerStats("zoo"); err != nil {
		t.Fatal(err)
	}
	want := `{"label":["com.docker.compose.project=zoo","com.docker.compose.oneoff=False"]}`
	if len(f.filters) != 1 || f.filters[0] != want {
		t.Errorf("listed containers with filters %q, want %q", f.filters, want)
	}
}
