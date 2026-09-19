package ondemanddocker

import (
	"encoding/json"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"github.com/thezoo/dockerapi"
	"go.uber.org/zap"
)

// fakeContainer serves the inspect and start endpoints of the Docker API for
// one container that becomes ready readyAfter it is started.
type fakeContainer struct {
	name        string
	healthCheck bool
	readyAfter  time.Duration

	mu      sync.Mutex
	missing bool
	status  string
	health  string // overrides the health derived from readiness
	readyAt time.Time
	starts  int
}

func (f *fakeContainer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()

	base := "/containers/" + f.name
	if f.missing || !strings.HasPrefix(r.URL.Path, base+"/") {
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte(`{"message":"No such container: ` + f.name + `"}`))
		return
	}

	switch r.URL.Path {
	case base + "/start":
		f.starts++
		f.status = "running"
		f.readyAt = time.Now().Add(f.readyAfter)
		w.WriteHeader(http.StatusNoContent)
	case base + "/json":
		ready := f.status == "running" && !time.Now().Before(f.readyAt)
		var info dockerapi.Container
		info.State.Status = f.status
		info.NetworkSettings.Networks = map[string]struct{ IPAddress string }{}
		if f.healthCheck {
			health := f.health
			if health == "" {
				health = "starting"
				if ready {
					health = "healthy"
				}
			}
			info.State.Health = &struct{ Status string }{health}
		}
		// Without a healthcheck, readiness is the port accepting connections,
		// so only hand out the IP once the container counts as ready
		if f.healthCheck || ready {
			info.NetworkSettings.Networks["zoo"] = struct{ IPAddress string }{"127.0.0.1"}
		}
		json.NewEncoder(w).Encode(info)
	default:
		http.NotFound(w, r)
	}
}

func (f *fakeContainer) startCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.starts
}

// serve points the module at a fake Docker API for the duration of the test
func serve(t *testing.T, f *fakeContainer) {
	// Unix socket paths are limited to about 100 bytes, which t.TempDir() can exceed on macOS
	dir, err := os.MkdirTemp("", "od")
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

	prev := docker
	docker = dockerapi.New(socket)
	t.Cleanup(func() { docker = prev })

	projectNameMutex.Lock()
	cachedProjectName = "test"
	projectNameMutex.Unlock()
	cacheMutex.Lock()
	statusCache = make(map[string]*cacheEntry)
	cacheMutex.Unlock()
}

// listen returns the port of a TCP listener standing in for the container's app
func listen(t *testing.T) int {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { l.Close() })
	go func() {
		for {
			conn, err := l.Accept()
			if err != nil {
				return
			}
			conn.Close()
		}
	}()
	return l.Addr().(*net.TCPAddr).Port
}

func serveRequest(od *OnDemandDocker, proxied *atomic.Int32) error {
	next := caddyhttp.HandlerFunc(func(http.ResponseWriter, *http.Request) error {
		proxied.Add(1)
		return nil
	})
	return od.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "http://app.zoo/", nil), next)
}

func TestConcurrentRequestsStartContainerOnce(t *testing.T) {
	for _, healthCheck := range []bool{true, false} {
		name := "port probe"
		if healthCheck {
			name = "healthcheck"
		}
		t.Run(name, func(t *testing.T) {
			f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: healthCheck, readyAfter: 100 * time.Millisecond}
			serve(t, f)
			od := &OnDemandDocker{ContainerName: "app", Port: listen(t), Timeout: 5, logger: zap.NewNop()}

			const requests = 20
			var proxied atomic.Int32
			errs := make(chan error, requests)
			start := time.Now()
			for i := 0; i < requests; i++ {
				go func() { errs <- serveRequest(od, &proxied) }()
			}
			for i := 0; i < requests; i++ {
				if err := <-errs; err != nil {
					t.Fatalf("request failed: %v", err)
				}
			}
			elapsed := time.Since(start)

			if got := f.startCount(); got != 1 {
				t.Errorf("container started %d times, want 1", got)
			}
			if got := proxied.Load(); got != requests {
				t.Errorf("%d requests proxied, want %d", got, requests)
			}
			// Readiness is polled every 50ms, so requests shouldn't linger long after the container is ready
			if elapsed > 400*time.Millisecond {
				t.Errorf("requests took %v for a container ready after %v", elapsed, f.readyAfter)
			}
		})
	}
}

func TestMissingContainer(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", missing: true}
	serve(t, f)
	od := &OnDemandDocker{ContainerName: "app", Port: 80, Timeout: 5, logger: zap.NewNop()}

	var proxied atomic.Int32
	err := serveRequest(od, &proxied)

	var handlerErr caddyhttp.HandlerError
	if !errors.As(err, &handlerErr) || handlerErr.StatusCode != http.StatusInternalServerError {
		t.Fatalf("got error %#v, want a 500 HandlerError", err)
	}
	if !strings.Contains(err.Error(), "container 'test-app-1' does not exist") {
		t.Errorf("error %q doesn't say the container does not exist", err)
	}
	if proxied.Load() != 0 {
		t.Error("request was proxied to a missing container")
	}
}

func TestRunningUnhealthyContainerIsProxied(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "running", healthCheck: true, health: "unhealthy"}
	serve(t, f)
	od := &OnDemandDocker{ContainerName: "app", Port: 80, Timeout: 5, logger: zap.NewNop()}

	var proxied atomic.Int32
	if err := serveRequest(od, &proxied); err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if proxied.Load() != 1 {
		t.Error("request to an unhealthy running container was not proxied")
	}
	if f.startCount() != 0 {
		t.Error("running container was started again")
	}
}
