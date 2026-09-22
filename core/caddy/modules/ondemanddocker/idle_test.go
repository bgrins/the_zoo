package ondemanddocker

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	_ "github.com/caddyserver/caddy/v2/modules/caddyhttp/reverseproxy"
	"go.uber.org/zap"
)

type fakeClock struct {
	mu  sync.Mutex
	now time.Time
}

func (c *fakeClock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.now
}

func (c *fakeClock) Advance(d time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.now = c.now.Add(d)
}

// useClock replaces the idle stop clock for the duration of the test
func useClock(t *testing.T) *fakeClock {
	clock := &fakeClock{now: time.Now()}
	prev := now
	now = clock.Now
	t.Cleanup(func() { now = prev })
	return clock
}

// useSites points the module at a SITES.yaml for the duration of the test
func useSites(t *testing.T, content string) {
	path := filepath.Join(t.TempDir(), "SITES.yaml")
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	reset := func() {
		allowlistMutex.Lock()
		defer allowlistMutex.Unlock()
		allowlistLoaded, serviceAllowlist, onDemandServices, heavyServices = false, nil, nil, nil
	}
	prev := sitesConfigPath
	sitesConfigPath = path
	reset()
	t.Cleanup(func() {
		sitesConfigPath = prev
		reset()
	})
}

const onDemandSites = `
sites:
  - domain: app.zoo
    service: app
    onDemand: true
`

// idleSetup serves a running, healthy on-demand container whose stopper stops it after an hour idle
func idleSetup(t *testing.T, f *fakeContainer) (*fakeClock, *idleStopper, *OnDemandDocker) {
	serve(t, f)
	useSites(t, onDemandSites)
	clock := useClock(t)
	stopper := &idleStopper{after: time.Hour, started: now(), logger: zap.NewNop()}
	od := &OnDemandDocker{ContainerName: "app", Port: 80, Timeout: 5, logger: zap.NewNop()}
	return clock, stopper, od
}

func TestIdleStopAfter(t *testing.T) {
	for value, want := range map[string]time.Duration{"": 0, "0": 0, "4h": 4 * time.Hour, "90m": 90 * time.Minute} {
		t.Setenv("ZOO_IDLE_STOP", value)
		if got, err := idleStopAfter(); got != want || err != nil {
			t.Errorf("ZOO_IDLE_STOP=%q gave %v, %v, want %v", value, got, err, want)
		}
	}
	for _, value := range []string{"4", "-1h", "soon"} {
		t.Setenv("ZOO_IDLE_STOP", value)
		want := fmt.Sprintf("ZOO_IDLE_STOP must be a duration like 4h, got %q", value)
		if _, err := idleStopAfter(); err == nil || err.Error() != want {
			t.Errorf("ZOO_IDLE_STOP=%q gave error %v, want %q", value, err, want)
		}
	}
}

func TestIdleContainerIsStoppedAndStartedAgain(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "running", healthCheck: true}
	clock, stopper, od := idleSetup(t, f)

	var proxied atomic.Int32
	if err := serveRequest(context.Background(), od, &proxied); err != nil {
		t.Fatalf("request failed: %v", err)
	}
	clock.Advance(59 * time.Minute)
	stopper.stopIdle(context.Background())
	if got := f.stopCount(); got != 0 {
		t.Fatalf("container stopped %d times after 59 minutes idle, want 0", got)
	}

	clock.Advance(2 * time.Minute)
	stopper.stopIdle(context.Background())
	if got := f.stopCount(); got != 1 {
		t.Fatalf("container stopped %d times after 61 minutes idle, want 1", got)
	}

	// The status cache still says running; the request must start the container anyway
	if err := serveRequest(context.Background(), od, &proxied); err != nil {
		t.Fatalf("request after the idle stop failed: %v", err)
	}
	if got := f.startCount(); got != 1 {
		t.Errorf("container started %d times after the idle stop, want 1", got)
	}
	if got := proxied.Load(); got != 2 {
		t.Errorf("%d requests proxied, want 2", got)
	}
}

func TestIdleStopSparesContainers(t *testing.T) {
	for _, tc := range []struct {
		name  string
		sites string
		f     *fakeContainer
		// processAge is how long the stopper has been running
		processAge time.Duration
	}{
		{
			name:       "core service",
			sites:      onDemandSites,
			f:          &fakeContainer{name: "test-app-1", status: "running", labels: map[string]string{"zoo.core": "true"}},
			processAge: 2 * time.Hour,
		},
		{
			// It inherits the image's compose labels, but compose didn't create it
			name:       "container run by hand from a compose-built image",
			sites:      onDemandSites,
			f:          &fakeContainer{name: "test-app-1", status: "running", labels: map[string]string{"com.docker.compose.oneoff": ""}},
			processAge: 2 * time.Hour,
		},
		{
			name:       "service without the on-demand profile",
			sites:      "sites:\n  - domain: app.zoo\n    service: app\n",
			f:          &fakeContainer{name: "test-app-1", status: "running"},
			processAge: 2 * time.Hour,
		},
		{
			name:       "container started recently some other way",
			sites:      onDemandSites,
			f:          &fakeContainer{name: "test-app-1", status: "running", startedAt: time.Now().Add(-30 * time.Minute)},
			processAge: 2 * time.Hour,
		},
		{
			name:       "container with a docker compose exec session",
			sites:      onDemandSites,
			f:          &fakeContainer{name: "test-app-1", status: "running", execIDs: []string{"4f2d1c"}},
			processAge: 2 * time.Hour,
		},
		{
			name:       "requests before the process started are unknown",
			sites:      onDemandSites,
			f:          &fakeContainer{name: "test-app-1", status: "running"},
			processAge: 30 * time.Minute,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			serve(t, tc.f)
			useSites(t, tc.sites)
			useClock(t)
			stopper := &idleStopper{after: time.Hour, started: now().Add(-tc.processAge), logger: zap.NewNop()}

			stopper.stopIdle(context.Background())
			if got := tc.f.stopCount(); got != 0 {
				t.Errorf("container stopped %d times, want 0", got)
			}
		})
	}
}

// A request that outlasts the idle period keeps the container running
func TestIdleStopWaitsForRequestsInProgress(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "running", healthCheck: true}
	clock, stopper, od := idleSetup(t, f)

	entered, finish := make(chan struct{}), make(chan struct{})
	errs := make(chan error, 1)
	go func() {
		errs <- serveRequestTo(context.Background(), od, caddyhttp.HandlerFunc(func(http.ResponseWriter, *http.Request) error {
			close(entered)
			<-finish
			return nil
		}))
	}()
	<-entered

	clock.Advance(2 * time.Hour)
	stopper.stopIdle(context.Background())
	if got := f.stopCount(); got != 0 {
		t.Fatalf("container stopped %d times during a request, want 0", got)
	}

	close(finish)
	if err := <-errs; err != nil {
		t.Fatalf("request failed: %v", err)
	}
	// Idle time counts from the end of the request
	clock.Advance(59 * time.Minute)
	stopper.stopIdle(context.Background())
	if got := f.stopCount(); got != 0 {
		t.Fatalf("container stopped %d times 59 minutes after a request ended, want 0", got)
	}
	clock.Advance(2 * time.Minute)
	stopper.stopIdle(context.Background())
	if got := f.stopCount(); got != 1 {
		t.Errorf("container stopped %d times 61 minutes after a request ended, want 1", got)
	}
}

// A request during an idle stop waits for it, then starts the container again
func TestRequestDuringIdleStopStartsContainerAgain(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "running", healthCheck: true, stopGate: make(chan struct{})}
	clock, stopper, od := idleSetup(t, f)
	openGate := sync.OnceFunc(func() { close(f.stopGate) })
	// A held stop would keep the fake Docker API from shutting down
	t.Cleanup(openGate)
	logger, logs := observed()
	od.logger = logger

	clock.Advance(2 * time.Hour)
	stopped := make(chan struct{})
	go func() {
		stopper.stopIdle(context.Background())
		close(stopped)
	}()
	waitFor(t, "the stop is requested", func() bool { return f.stopCount() == 1 })

	var proxied atomic.Int32
	errs := make(chan error, 1)
	go func() { errs <- serveRequest(context.Background(), od, &proxied) }()
	waitFor(t, "the request waits for the stop", func() bool {
		return logs.FilterMessage("waiting for the idle container to stop before starting it again").Len() == 1
	})

	openGate()
	<-stopped
	if err := <-errs; err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if got := f.startCount(); got != 1 {
		t.Errorf("container started %d times after the stop, want 1", got)
	}
	if got := proxied.Load(); got != 1 {
		t.Errorf("%d requests proxied, want 1", got)
	}
}

// reverse_proxy holds the request until an upgraded connection closes, so an
// open websocket counts as a request in progress
func TestIdleStopWaitsForUpgradedConnections(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "running", healthCheck: true}
	clock, stopper, _ := idleSetup(t, f)
	addr := startCaddy(t, upgradeEchoServer(t))

	conn, err := net.Dial("tcp", addr)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	fmt.Fprint(conn, "GET / HTTP/1.1\r\nHost: app.zoo\r\nConnection: Upgrade\r\nUpgrade: echo\r\n\r\n")
	reader := bufio.NewReader(conn)
	resp, err := http.ReadResponse(reader, nil)
	if err != nil {
		t.Fatal(err)
	}
	if resp.StatusCode != http.StatusSwitchingProtocols {
		t.Fatalf("got status %d, want 101", resp.StatusCode)
	}
	fmt.Fprint(conn, "ping\n")
	if line, err := reader.ReadString('\n'); line != "ping\n" {
		t.Fatalf("read %q, %v through the upgraded connection, want the echo", line, err)
	}

	clock.Advance(2 * time.Hour)
	stopper.stopIdle(context.Background())
	if got := f.stopCount(); got != 0 {
		t.Fatalf("container stopped %d times with an open upgraded connection, want 0", got)
	}

	conn.Close()
	waitFor(t, "the container is stopped once the connection has closed", func() bool {
		clock.Advance(2 * time.Hour)
		stopper.stopIdle(context.Background())
		return f.stopCount() == 1
	})
}

// upgradeEchoServer returns the address of a backend that accepts any protocol
// upgrade and then echoes what it receives
func upgradeEchoServer(t *testing.T) string {
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
			go func() {
				defer conn.Close()
				reader := bufio.NewReader(conn)
				req, err := http.ReadRequest(reader)
				if err != nil {
					return
				}
				fmt.Fprintf(conn, "HTTP/1.1 101 Switching Protocols\r\nConnection: Upgrade\r\nUpgrade: %s\r\n\r\n", req.Header.Get("Upgrade"))
				io.Copy(conn, reader)
			}()
		}
	}()
	return l.Addr().String()
}

// startCaddy runs Caddy with the module in front of reverse_proxy to backend
// and returns the address it listens on
func startCaddy(t *testing.T, backend string) string {
	config := fmt.Sprintf(`{
		"admin": {"disabled": true, "config": {"persist": false}},
		"logging": {"logs": {"default": {"level": "ERROR"}}},
		"apps": {"http": {"servers": {"zoo": {
			"listen": ["127.0.0.1:0"],
			"automatic_https": {"disable": true},
			"routes": [{"handle": [
				{"handler": "on_demand_docker", "container_name": "app", "port": 80, "timeout": 5},
				{"handler": "reverse_proxy", "upstreams": [{"dial": %q}]}
			]}]
		}}}}
	}`, backend)
	if err := caddy.Load([]byte(config), true); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if err := caddy.Stop(); err != nil {
			t.Error(err)
		}
	})

	app, err := caddy.ActiveContext().App("http")
	if err != nil {
		t.Fatal(err)
	}
	return app.(*caddyhttp.App).Servers["zoo"].Listeners()[0].Addr().String()
}
