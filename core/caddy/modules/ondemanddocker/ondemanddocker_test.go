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
	"slices"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"github.com/thezoo/dockerapi"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

// fakeContainer serves the parts of the Docker API the module uses for one
// container of the compose project "test" that becomes ready readyAfter it is
// started, reporting its transitions as events like Docker does.
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
	// restartAt, if set, is how long after the start the container reports exited
	// for restartFor, as it does while `docker restart` stops and starts it
	restartAt  time.Duration
	restartFor time.Duration
	// labels are added to the compose labels
	labels map[string]string

	mu        sync.Mutex
	missing   bool
	status    string
	health    string // overrides the health derived from readiness
	startedAt time.Time
	starts    int
	stops     int
	inspects  int
	// stopGate, if set, holds stop requests until it is closed
	stopGate chan struct{}
	// noEvents makes the events endpoint fail
	noEvents    bool
	subscribers map[*subscriber]bool
	timers      []*time.Timer
}

// subscriber is an open events stream
type subscriber struct {
	filters map[string][]string
	events  chan dockerapi.Event
	quit    chan struct{}
}

// wants applies the filters the module uses, so events it didn't ask for are not delivered
func (s *subscriber) wants(action string) bool {
	return slices.Contains(s.filters["type"], "container") &&
		slices.Contains(s.filters["label"], "com.docker.compose.project=test") &&
		slices.Contains(s.filters["event"], strings.SplitN(action, ":", 2)[0])
}

func (f *fakeContainer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/events" {
		f.serveEvents(w, r)
		return
	}

	f.mu.Lock()
	defer f.mu.Unlock()

	if r.URL.Path == "/containers/json" {
		var list []dockerapi.ContainerSummary
		if status, _, _ := f.stateLocked(); !f.missing && status == "running" {
			list = append(list, dockerapi.ContainerSummary{Names: []string{"/" + f.name}, Labels: f.labelsLocked(), State: status})
		}
		json.NewEncoder(w).Encode(list)
		return
	}

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
		f.emitLocked("start")
		f.scheduleEventsLocked()
		w.WriteHeader(http.StatusNoContent)
	case base + "/stop":
		f.stops++
		if gate := f.stopGate; gate != nil {
			f.mu.Unlock()
			<-gate
			f.mu.Lock()
		}
		f.status = "exited"
		f.emitLocked("die")
		w.WriteHeader(http.StatusNoContent)
	case base + "/json":
		f.inspects++
		var info dockerapi.Container
		var ready bool
		info.State.Status, info.State.ExitCode, ready = f.stateLocked()
		info.State.StartedAt = f.startedAt.Format(time.RFC3339Nano)
		info.Config.Labels = f.labelsLocked()
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

// stateLocked returns the status and exit code the container reports now, and whether it is ready
func (f *fakeContainer) stateLocked() (string, int, bool) {
	status, exitCode := f.status, 0
	sinceStart := time.Since(f.startedAt)
	if f.status == "running" {
		switch {
		case f.exitAfter > 0 && sinceStart >= f.exitAfter:
			status, exitCode = "exited", f.exitCode
		case sinceStart < f.restartingFor:
			status, exitCode = "restarting", f.exitCode
		case f.restartAt > 0 && sinceStart >= f.restartAt && sinceStart < f.restartAt+f.restartFor:
			status, exitCode = "exited", 137
		}
	}
	return status, exitCode, status == "running" && sinceStart >= f.restartingFor+f.readyAfter
}

func (f *fakeContainer) labelsLocked() map[string]string {
	labels := map[string]string{"com.docker.compose.project": "test", "com.docker.compose.service": "app"}
	for k, v := range f.labels {
		labels[k] = v
	}
	return labels
}

// scheduleEventsLocked reports the transitions that follow a start when they happen
func (f *fakeContainer) scheduleEventsLocked() {
	at := func(d time.Duration, action string) {
		f.timers = append(f.timers, time.AfterFunc(d, func() {
			f.mu.Lock()
			defer f.mu.Unlock()
			f.emitLocked(action)
		}))
	}
	if f.restartingFor > 0 {
		f.emitLocked("die")
		at(f.restartingFor, "start")
	}
	if f.restartAt > 0 {
		at(f.restartAt, "die")
		at(f.restartAt+f.restartFor, "start")
	}
	if f.exitAfter > 0 {
		at(f.exitAfter, "die")
	}
	if f.healthCheck && f.health == "" {
		at(f.restartingFor+f.readyAfter, "health_status: healthy")
	}
}

func (f *fakeContainer) emitLocked(action string) {
	f.emitForLocked(f.name, action)
}

func (f *fakeContainer) emitForLocked(container, action string) {
	event := dockerapi.Event{Type: "container", Action: action}
	event.Actor.Attributes = map[string]string{"name": container}
	for s := range f.subscribers {
		if s.wants(action) {
			s.events <- event
		}
	}
}

func (f *fakeContainer) serveEvents(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	if f.noEvents {
		f.mu.Unlock()
		http.Error(w, "events are unavailable", http.StatusInternalServerError)
		return
	}
	s := &subscriber{events: make(chan dockerapi.Event, 100), quit: make(chan struct{})}
	json.Unmarshal([]byte(r.URL.Query().Get("filters")), &s.filters)
	if f.subscribers == nil {
		f.subscribers = make(map[*subscriber]bool)
	}
	f.subscribers[s] = true
	f.mu.Unlock()
	defer func() {
		f.mu.Lock()
		delete(f.subscribers, s)
		f.mu.Unlock()
	}()

	w.WriteHeader(http.StatusOK)
	w.(http.Flusher).Flush()
	encoder := json.NewEncoder(w)
	for {
		select {
		case event := <-s.events:
			encoder.Encode(event)
			w.(http.Flusher).Flush()
		case <-s.quit:
			return
		case <-r.Context().Done():
			return
		}
	}
}

// setHealth changes the health the container reports, as a finished probe does
func (f *fakeContainer) setHealth(health string) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.health = health
	f.emitLocked("health_status: " + health)
}

// setEvents ends the open events streams and makes the endpoint fail while
// disabled, as when the daemon restarts
func (f *fakeContainer) setEvents(enabled bool) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.noEvents = !enabled
	if !enabled {
		for s := range f.subscribers {
			close(s.quit)
			delete(f.subscribers, s)
		}
	}
}

func (f *fakeContainer) subscriberCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return len(f.subscribers)
}

func (f *fakeContainer) startCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.starts
}

func (f *fakeContainer) stopCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.stops
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
	t.Cleanup(func() {
		f.mu.Lock()
		defer f.mu.Unlock()
		for _, timer := range f.timers {
			timer.Stop()
		}
	})

	prevDocker, prevEvents, prevActivity := docker, events, activity
	prevFallback, prevReconnect := fallbackInterval, reconnectDelay
	docker = dockerapi.New(socket)
	events = newEventWatcher(docker)
	activity = newActivityTracker()
	// Waits must learn of changes from events; polling would hide a missed one
	fallbackInterval = time.Hour
	reconnectDelay = 10 * time.Millisecond
	t.Cleanup(func() {
		events.stop()
		docker, events, activity = prevDocker, prevEvents, prevActivity
		fallbackInterval, reconnectDelay = prevFallback, prevReconnect
	})

	projectNameMutex.Lock()
	cachedProjectName = "test"
	projectNameMutex.Unlock()
	cacheMutex.Lock()
	statusCache = make(map[string]*cacheEntry)
	cacheMutex.Unlock()

	events.start("test", zap.NewNop())
	f.mu.Lock()
	noEvents := f.noEvents
	f.mu.Unlock()
	if !noEvents {
		waitFor(t, "the module subscribes to events", func() bool { return f.subscriberCount() == 1 })
		// The watcher handles an event only once it has set up the subscription
		f.mu.Lock()
		f.emitForLocked("test-other-1", "start")
		f.mu.Unlock()
		waitFor(t, "the module follows events", func() bool { return events.generation("test-other-1") > 0 })
	}
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
	return serveRequestTo(ctx, od, next)
}

func serveRequestTo(ctx context.Context, od *OnDemandDocker, next caddyhttp.Handler) error {
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
	deadline := time.Now().Add(5 * time.Second)
	for !cond() {
		if time.Now().After(deadline) {
			t.Fatalf("timed out waiting until %s", what)
		}
		time.Sleep(time.Millisecond)
	}
}

// observed returns a logger that records its messages
func observed() (*zap.Logger, *observer.ObservedLogs) {
	core, logs := observer.New(zap.InfoLevel)
	return zap.New(core), logs
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
			// Readiness arrives as an event or, for a port, a probe every pollInterval,
			// so requests shouldn't linger long after the container is ready
			if limit := f.readyAfter + 10*pollInterval; elapsed > limit {
				t.Errorf("requests took %v for a container ready after %v, want at most %v", elapsed, f.readyAfter, limit)
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
// wait, so a cold fan-out inspects the container a few times, not once per block.
func TestSiteBlocksShareHealthWait(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true, readyAfter: 200 * time.Millisecond}
	serve(t, f)

	const blocks = 40
	var proxied atomic.Int32
	errs := make(chan error, blocks)
	for i := 0; i < blocks; i++ {
		od := &OnDemandDocker{ContainerName: "app", Port: 8100 + i, Timeout: 5, logger: zap.NewNop()}
		go func() { errs <- serveRequest(context.Background(), od, &proxied) }()
	}
	for i := 0; i < blocks; i++ {
		if err := <-errs; err != nil {
			t.Fatalf("request failed: %v", err)
		}
	}

	if got := f.startCount(); got != 1 {
		t.Errorf("container started %d times, want 1", got)
	}
	if got := proxied.Load(); got != blocks {
		t.Errorf("%d requests proxied, want %d", got, blocks)
	}
	// One wait inspects before and after the start, on the start event if it
	// arrives after that, and on the health event
	if got := f.inspectCount(); got > 4 {
		t.Errorf("container inspected %d times, want at most 4", got)
	}
}

// Without a healthcheck, each site block waits for its own port
func TestSiteBlocksWaitForOwnPort(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited"}
	serve(t, f)
	// Listen first, so the closed port can't be handed out again for the open one
	open := &OnDemandDocker{ContainerName: "app", Port: listen(t), Timeout: 5, logger: zap.NewNop()}
	closed := &OnDemandDocker{ContainerName: "app", Port: closedPort(t), Timeout: 1, logger: zap.NewNop()}

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
// began carry on for the requests that joined them.
func TestCancelledRequestLeavesSharedWait(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true, readyAfter: time.Hour}
	serve(t, f)
	logger, logs := observed()
	first := &OnDemandDocker{ContainerName: "app", Port: 8100, Timeout: 5, logger: logger}
	second := &OnDemandDocker{ContainerName: "app", Port: 8101, Timeout: 5, logger: logger}

	var proxied atomic.Int32
	ctx, cancel := context.WithCancel(context.Background())
	firstErr, secondErr := make(chan error, 1), make(chan error, 1)
	go func() { firstErr <- serveRequest(ctx, first, &proxied) }()
	waitFor(t, "the first request starts the container", func() bool { return f.startCount() == 1 })
	go func() { secondErr <- serveRequest(context.Background(), second, &proxied) }()
	// The request joins the wait right after logging this
	waitFor(t, "the second request joins the wait", func() bool {
		return logs.FilterMessage("handling request for on-demand container").Len() == 2
	})

	cancel()
	requireStatus(t, <-firstErr, statusClientClosedRequest)
	f.setHealth("healthy")

	if err := <-secondErr; err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if got := proxied.Load(); got != 1 {
		t.Errorf("%d requests proxied, want 1", got)
	}
	if got := f.startCount(); got != 1 {
		t.Errorf("container started %d times, want 1", got)
	}
}

// Requests that join a wait share the deadline of the request that began it
func TestJoinedRequestSharesDeadline(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true, readyAfter: time.Hour}
	serve(t, f)
	first := &OnDemandDocker{ContainerName: "app", Port: 8100, Timeout: 1, logger: zap.NewNop()}
	second := &OnDemandDocker{ContainerName: "app", Port: 8101, Timeout: 5, logger: zap.NewNop()}

	var proxied atomic.Int32
	firstErr := make(chan error, 1)
	start := time.Now()
	go func() { firstErr <- serveRequest(context.Background(), first, &proxied) }()
	waitFor(t, "the container is started", func() bool { return f.startCount() == 1 })

	err := serveRequest(context.Background(), second, &proxied)
	elapsed := time.Since(start)

	requireStatus(t, err, http.StatusGatewayTimeout)
	requireStatus(t, <-firstErr, http.StatusGatewayTimeout)
	// Its own 5s timeout would end the joined request well after this
	if elapsed > 3*time.Second {
		t.Errorf("joined request failed after %v, want about the first request's 1s timeout", elapsed)
	}
	if !strings.Contains(err.Error(), `last status running, health "starting"`) {
		t.Errorf("error %q doesn't report the last state", err)
	}
}

// Without a healthcheck, a ready port doesn't vouch for the container's other ports
func TestReadyPortDoesNotCacheOtherPorts(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited"}
	serve(t, f)
	open := &OnDemandDocker{ContainerName: "app", Port: listen(t), Timeout: 5, logger: zap.NewNop()}
	closed := &OnDemandDocker{ContainerName: "app", Port: closedPort(t), Timeout: 1, logger: zap.NewNop()}

	var openProxied, closedProxied atomic.Int32
	if err := serveRequest(context.Background(), open, &openProxied); err != nil {
		t.Fatalf("request to the open port failed: %v", err)
	}
	requireStatus(t, serveRequest(context.Background(), closed, &closedProxied), http.StatusGatewayTimeout)
	if closedProxied.Load() != 0 {
		t.Error("request to a closed port was proxied on the strength of another port")
	}
}

// A port is probed without inspecting the container each time
func TestPortProbeLeavesDockerAlone(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited"}
	serve(t, f)
	od := &OnDemandDocker{ContainerName: "app", Port: closedPort(t), Timeout: 1, logger: zap.NewNop()}

	var proxied atomic.Int32
	requireStatus(t, serveRequest(context.Background(), od, &proxied), http.StatusGatewayTimeout)
	// Before and after the start, and on the start event if it arrives after that
	if got := f.inspectCount(); got > 3 {
		t.Errorf("container inspected %d times while its port was probed for 1s, want at most 3", got)
	}
}

// docker restart and compose recreates show exited briefly; a wait rides it out
func TestRestartDuringWaitIsWaitedOut(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true,
		readyAfter: 500 * time.Millisecond, restartAt: 100 * time.Millisecond, restartFor: 300 * time.Millisecond}
	serve(t, f)
	od := &OnDemandDocker{ContainerName: "app", Port: 80, Timeout: 5, logger: zap.NewNop()}

	var proxied atomic.Int32
	if err := serveRequest(context.Background(), od, &proxied); err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if proxied.Load() != 1 {
		t.Error("request was not proxied after the restart")
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
			// It gives up once the container has stayed exited for stoppedGrace, long before the timeout
			if min, max := f.exitAfter+stoppedGrace, time.Duration(od.Timeout)*time.Second/2; elapsed < min || elapsed > max {
				t.Errorf("request took %v for a container that exited after %v, want %v to %v", elapsed, f.exitAfter, min, max)
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
