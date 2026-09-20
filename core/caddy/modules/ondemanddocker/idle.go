package ondemanddocker

import (
	"context"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/thezoo/dockerapi"
	"go.uber.org/zap"
)

// idleStopEnv names the duration after which a container without requests is
// stopped; idle containers are left running when it is empty or zero
const idleStopEnv = "ZOO_IDLE_STOP"

var (
	// now is the clock for idle stops
	now = time.Now

	activity = newActivityTracker()

	idleStopOnce sync.Once
)

// idleStopAfter parses ZOO_IDLE_STOP
func idleStopAfter() (time.Duration, error) {
	value := os.Getenv(idleStopEnv)
	if value == "" {
		return 0, nil
	}
	after, err := time.ParseDuration(value)
	if err != nil || after < 0 {
		return 0, fmt.Errorf("%s must be a duration like 4h, got %q", idleStopEnv, value)
	}
	return after, nil
}

// activityTracker records the requests of each container, so the idle stopper
// leaves alone containers that are in use
type activityTracker struct {
	mu         sync.Mutex
	containers map[string]*containerActivity
}

type containerActivity struct {
	// active counts requests in progress. reverse_proxy returns only once an
	// upgraded connection such as a websocket closes, so open ones count too.
	active int
	// last is when the last request began or ended
	last time.Time
	// stopping is closed once an idle stop of the container has finished
	stopping chan struct{}
}

func newActivityTracker() *activityTracker {
	return &activityTracker{containers: make(map[string]*containerActivity)}
}

func (a *activityTracker) get(container string) *containerActivity {
	c, ok := a.containers[container]
	if !ok {
		c = &containerActivity{}
		a.containers[container] = c
	}
	return c
}

// begin records a request to the container and returns the function that ends
// it. A request that arrives during an idle stop waits for the stop to finish,
// then starts the container again like any request to a stopped one.
func (a *activityTracker) begin(ctx context.Context, container string, logger *zap.Logger) (func(), error) {
	for {
		a.mu.Lock()
		c := a.get(container)
		stopping := c.stopping
		if stopping == nil {
			c.active++
			c.last = now()
			a.mu.Unlock()
			return func() {
				a.mu.Lock()
				c.active--
				c.last = now()
				a.mu.Unlock()
			}, nil
		}
		a.mu.Unlock()

		logger.Info("waiting for the idle container to stop before starting it again",
			zap.String("container", container))
		select {
		case <-stopping:
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}
}

// beginStop marks the container as stopping unless a request is in progress
// or has been since cutoff. endStop must follow.
func (a *activityTracker) beginStop(container string, cutoff time.Time) bool {
	a.mu.Lock()
	defer a.mu.Unlock()
	c := a.get(container)
	if c.active > 0 || c.last.After(cutoff) || c.stopping != nil {
		return false
	}
	c.stopping = make(chan struct{})
	return true
}

func (a *activityTracker) endStop(container string) {
	a.mu.Lock()
	defer a.mu.Unlock()
	c := a.get(container)
	close(c.stopping)
	c.stopping = nil
}

// idleStopper stops on-demand containers that have had no requests for a while
type idleStopper struct {
	after   time.Duration
	started time.Time
	logger  *zap.Logger
}

func (s *idleStopper) run(ctx context.Context) {
	ticker := time.NewTicker(max(min(s.after/4, time.Minute), time.Second))
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.stopIdle(ctx)
		}
	}
}

// stopIdle stops the project's running on-demand containers that have been
// idle for longer than s.after
func (s *idleStopper) stopIdle(ctx context.Context) {
	cutoff := now().Add(-s.after)
	// This process can't tell whether a container had requests before it started
	if s.started.After(cutoff) {
		return
	}
	if err := loadServiceAllowlist(); err != nil {
		s.logger.Warn("not stopping idle containers without knowing which are on demand", zap.Error(err))
		return
	}
	project := projectName(s.logger)
	if project == "" {
		return
	}

	listCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	containers, err := docker.ListContainers(listCtx, false, dockerapi.ProjectContainers(project))
	if err != nil {
		s.logger.Warn("failed to list containers to stop idle ones", zap.Error(err))
		return
	}
	for _, c := range containers {
		if len(c.Names) == 0 || c.Labels["zoo.core"] == "true" || !isOnDemandService(c.Labels["com.docker.compose.service"]) {
			continue
		}
		s.stopIfIdle(ctx, strings.TrimPrefix(c.Names[0], "/"), cutoff)
	}
}

func (s *idleStopper) stopIfIdle(ctx context.Context, container string, cutoff time.Time) {
	inspectCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	info, err := docker.InspectContainer(inspectCtx, container)
	cancel()
	if err != nil {
		s.logger.Warn("failed to inspect container to check whether it is idle",
			zap.String("container", container), zap.Error(err))
		return
	}
	// A container started some other way, e.g. by `docker compose up`, is in use
	if started, err := time.Parse(time.RFC3339Nano, info.State.StartedAt); err != nil || started.After(cutoff) {
		return
	}

	if !activity.beginStop(container, cutoff) {
		return
	}
	defer activity.endStop(container)

	// The next request must find the container stopped, not trust the cache
	cacheMutex.Lock()
	for key := range statusCache {
		if strings.HasPrefix(key, container+":") {
			delete(statusCache, key)
		}
	}
	cacheMutex.Unlock()

	s.logger.Info("stopping idle container",
		zap.String("container", container),
		zap.Duration("idle_stop_after", s.after))

	stopCtx, cancel := context.WithTimeout(ctx, time.Minute)
	defer cancel()
	if err := docker.StopContainer(stopCtx, container); err != nil {
		s.logger.Error("failed to stop idle container", zap.String("container", container), zap.Error(err))
	}
}
