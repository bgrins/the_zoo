package ondemanddocker

import (
	"context"
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
	// restartingFor is how long the container reports restarting after the
	// start, as Docker does while a restart policy brings a crashed one back
	restartingFor time.Duration
	// exitAfter, if set, is how long after the start the container exits with exitCode
	exitAfter time.Duration
	exitCode  int

	mu        sync.Mutex
	missing   bool
	status    string
	health    string // overrides the health derived from readiness
	startedAt time.Time
	starts    int
	inspects  int
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
		f.startedAt = time.Now()
		w.WriteHeader(http.StatusNoContent)
	case base + "/json":
		f.inspects++
		var info dockerapi.Container
		info.State.Status = f.status
		sinceStart := time.Since(f.startedAt)
		if f.status == "running" {
			switch {
			case f.exitAfter > 0 && sinceStart >= f.exitAfter:
				info.State.Status = "exited"
				info.State.ExitCode = f.exitCode
			case sinceStart < f.restartingFor:
				info.State.Status = "restarting"
				info.State.ExitCode = f.exitCode
			}
		}
		ready := info.State.Status == "running" && sinceStart >= f.restartingFor+f.readyAfter
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

func (f *fakeContainer) inspectCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.inspects
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

// closedPort returns a port that nothing listens on
func closedPort(t *testing.T) int {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	return l.Addr().(*net.TCPAddr).Port
}

func serveRequest(ctx context.Context, od *OnDemandDocker, proxied *atomic.Int32) error {
	next := caddyhttp.HandlerFunc(func(http.ResponseWriter, *http.Request) error {
		proxied.Add(1)
		return nil
	})
	r := httptest.NewRequest(http.MethodGet, "http://app.zoo/", nil).WithContext(ctx)
	return od.ServeHTTP(httptest.NewRecorder(), r, next)
}

func requireStatus(t *testing.T, err error, code int) {
	t.Helper()
	var handlerErr caddyhttp.HandlerError
	if !errors.As(err, &handlerErr) || handlerErr.StatusCode != code {
		t.Fatalf("got error %#v, want a %d HandlerError", err, code)
	}
}

func waitFor(t *testing.T, what string, cond func() bool) {
	t.Helper()
	deadline := time.Now().Add(time.Second)
	for !cond() {
		if time.Now().After(deadline) {
			t.Fatalf("timed out waiting until %s", what)
		}
		time.Sleep(time.Millisecond)
	}
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
				go func() { errs <- serveRequest(context.Background(), od, &proxied) }()
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
	err := serveRequest(context.Background(), od, &proxied)

	requireStatus(t, err, http.StatusInternalServerError)
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
	if err := serveRequest(context.Background(), od, &proxied); err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if proxied.Load() != 1 {
		t.Error("request to an unhealthy running container was not proxied")
	}
	if f.startCount() != 0 {
		t.Error("running container was started again")
	}
}

// Site blocks for different ports of one container share its start and health
// wait, so a cold fan-out polls the daemon once per interval, not once per block.
func TestSiteBlocksShareHealthWait(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true, readyAfter: 200 * time.Millisecond}
	serve(t, f)

	const blocks = 40
	var proxied atomic.Int32
	errs := make(chan error, blocks)
	start := time.Now()
	for i := 0; i < blocks; i++ {
		od := &OnDemandDocker{ContainerName: "app", Port: 8100 + i, Timeout: 5, logger: zap.NewNop()}
		go func() { errs <- serveRequest(context.Background(), od, &proxied) }()
	}
	for i := 0; i < blocks; i++ {
		if err := <-errs; err != nil {
			t.Fatalf("request failed: %v", err)
		}
	}
	elapsed := time.Since(start)

	if got := f.startCount(); got != 1 {
		t.Errorf("container started %d times, want 1", got)
	}
	if got := proxied.Load(); got != blocks {
		t.Errorf("%d requests proxied, want %d", got, blocks)
	}
	// One wait inspects before and after the start, then once per poll
	if got, limit := f.inspectCount(), 2+int(elapsed/pollInterval); got > limit {
		t.Errorf("container inspected %d times in %v, want at most %d", got, elapsed, limit)
	}
}

// Without a healthcheck, each site block waits for its own port
func TestSiteBlocksWaitForOwnPort(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited"}
	serve(t, f)
	closed := &OnDemandDocker{ContainerName: "app", Port: closedPort(t), Timeout: 1, logger: zap.NewNop()}
	open := &OnDemandDocker{ContainerName: "app", Port: listen(t), Timeout: 5, logger: zap.NewNop()}

	var closedProxied, openProxied atomic.Int32
	closedErr := make(chan error, 1)
	go func() { closedErr <- serveRequest(context.Background(), closed, &closedProxied) }()
	// Once the closed port's request has started the container, it no longer checks the status cache
	waitFor(t, "the container is started", func() bool { return f.startCount() == 1 })

	if err := serveRequest(context.Background(), open, &openProxied); err != nil {
		t.Fatalf("request to the open port failed: %v", err)
	}
	requireStatus(t, <-closedErr, http.StatusGatewayTimeout)
	if openProxied.Load() != 1 || closedProxied.Load() != 0 {
		t.Errorf("proxied %d requests to the open port and %d to the closed port, want 1 and 0",
			openProxied.Load(), closedProxied.Load())
	}
	if got := f.startCount(); got != 1 {
		t.Errorf("container started %d times, want 1", got)
	}
}

// A client disconnecting abandons only its own wait: the start and wait it
// began carry on for the container's other site blocks.
func TestCancelledRequestLeavesSharedWait(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true, readyAfter: 200 * time.Millisecond}
	serve(t, f)
	first := &OnDemandDocker{ContainerName: "app", Port: 8100, Timeout: 5, logger: zap.NewNop()}
	second := &OnDemandDocker{ContainerName: "app", Port: 8101, Timeout: 5, logger: zap.NewNop()}

	var proxied atomic.Int32
	ctx, cancel := context.WithCancel(context.Background())
	firstErr := make(chan error, 1)
	go func() { firstErr <- serveRequest(ctx, first, &proxied) }()
	waitFor(t, "the container is started", func() bool { return f.startCount() == 1 })
	cancel()
	requireStatus(t, <-firstErr, statusClientClosedRequest)

	inspects := f.inspectCount()
	waitFor(t, "the container is polled again", func() bool { return f.inspectCount() > inspects })

	if err := serveRequest(context.Background(), second, &proxied); err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if got := proxied.Load(); got != 1 {
		t.Errorf("%d requests proxied, want 1", got)
	}
	if got := f.startCount(); got != 1 {
		t.Errorf("container started %d times, want 1", got)
	}
}

func TestExitedContainerFailsFast(t *testing.T) {
	for _, healthCheck := range []bool{true, false} {
		name := "port probe"
		if healthCheck {
			name = "healthcheck"
		}
		t.Run(name, func(t *testing.T) {
			f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: healthCheck,
				readyAfter: time.Hour, exitAfter: 100 * time.Millisecond, exitCode: 3}
			serve(t, f)
			od := &OnDemandDocker{ContainerName: "app", Port: 80, Timeout: 5, logger: zap.NewNop()}

			var proxied atomic.Int32
			start := time.Now()
			err := serveRequest(context.Background(), od, &proxied)
			elapsed := time.Since(start)

			requireStatus(t, err, http.StatusBadGateway)
			if !strings.Contains(err.Error(), "status exited, exit code 3") {
				t.Errorf("error %q doesn't report the exit code", err)
			}
			if elapsed > 400*time.Millisecond {
				t.Errorf("request took %v for a container that exited after %v", elapsed, f.exitAfter)
			}
			if proxied.Load() != 0 {
				t.Error("request was proxied to an exited container")
			}
		})
	}
}

func TestRestartingContainerIsWaitedOn(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true,
		restartingFor: 200 * time.Millisecond, exitCode: 3}
	serve(t, f)
	od := &OnDemandDocker{ContainerName: "app", Port: 80, Timeout: 5, logger: zap.NewNop()}

	var proxied atomic.Int32
	start := time.Now()
	if err := serveRequest(context.Background(), od, &proxied); err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if elapsed := time.Since(start); elapsed < f.restartingFor {
		t.Errorf("request was proxied after %v, while the container was restarting", elapsed)
	}
	if proxied.Load() != 1 {
		t.Error("request to a restarted container was not proxied")
	}
	if got := f.startCount(); got != 1 {
		t.Errorf("container started %d times, want 1", got)
	}
}
