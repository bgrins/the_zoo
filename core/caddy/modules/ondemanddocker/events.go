package ondemanddocker

import (
	"context"
	"sync"
	"time"

	"github.com/thezoo/dockerapi"
	"go.uber.org/zap"
)

// reconnectDelay is how long the watcher waits before resubscribing to events
var reconnectDelay = time.Second

// closed is a channel that is always ready
var closed = func() chan struct{} {
	ch := make(chan struct{})
	close(ch)
	return ch
}()

// eventWatcher follows the Docker events of the project's containers over one
// subscription per process. A container's readiness changes only when it
// starts, dies or finishes a health probe, so waiters inspect it again only
// once Docker reports one of those.
type eventWatcher struct {
	client *dockerapi.Client

	once   sync.Once
	cancel context.CancelFunc
	done   chan struct{}

	mu      sync.Mutex
	signals map[string]*signal
}

// signal counts the events a container has seen
type signal struct {
	generation uint64
	// next is closed at the next event, if anyone waits for it
	next chan struct{}
}

func newEventWatcher(client *dockerapi.Client) *eventWatcher {
	return &eventWatcher{client: client, done: make(chan struct{}), signals: make(map[string]*signal)}
}

// generation returns the number of events seen for the container, to pass to
// changed along with what was learned about the container after this call
func (w *eventWatcher) generation(container string) uint64 {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.signal(container).generation
}

// changed returns a channel that is closed once the container has seen more
// than generation events
func (w *eventWatcher) changed(container string, generation uint64) <-chan struct{} {
	w.mu.Lock()
	defer w.mu.Unlock()
	s := w.signal(container)
	if s.generation != generation {
		return closed
	}
	if s.next == nil {
		s.next = make(chan struct{})
	}
	return s.next
}

func (w *eventWatcher) signal(container string) *signal {
	s, ok := w.signals[container]
	if !ok {
		s = &signal{}
		w.signals[container] = s
	}
	return s
}

func (w *eventWatcher) notify(container string) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.bump(w.signal(container))
}

// notifyAll wakes every waiter, for when events may have been missed
func (w *eventWatcher) notifyAll() {
	w.mu.Lock()
	defer w.mu.Unlock()
	for _, s := range w.signals {
		w.bump(s)
	}
}

func (w *eventWatcher) bump(s *signal) {
	s.generation++
	if s.next != nil {
		close(s.next)
		s.next = nil
	}
}

// start subscribes to the project's events, unless the watcher already has
func (w *eventWatcher) start(project string, logger *zap.Logger) {
	w.once.Do(func() {
		ctx, cancel := context.WithCancel(context.Background())
		w.cancel = cancel
		go w.run(ctx, project, logger)
	})
}

// stop ends the subscription and waits until the watcher has stopped; a
// watcher stopped before it started never starts
func (w *eventWatcher) stop() {
	w.once.Do(func() { close(w.done) })
	if w.cancel != nil {
		w.cancel()
		<-w.done
	}
}

func (w *eventWatcher) run(ctx context.Context, project string, logger *zap.Logger) {
	defer close(w.done)
	filters := map[string][]string{
		"type":  {"container"},
		"event": {"start", "die", "health_status"},
		"label": {"com.docker.compose.project=" + project},
	}
	lost := false
	for {
		// Replaying the last second covers events while Docker sets up the subscription
		stream, err := w.client.Events(ctx, time.Now().Add(-time.Second), filters)
		if err == nil {
			if lost {
				logger.Info("Docker event subscription resumed")
				lost = false
			}
			// Waits that began while no subscription was open may have missed events
			w.notifyAll()
			err = w.follow(stream)
		}
		if ctx.Err() != nil {
			return
		}
		if !lost {
			logger.Warn("no Docker event subscription, waits poll containers until it resumes", zap.Error(err))
			lost = true
		}

		select {
		case <-ctx.Done():
			return
		case <-time.After(reconnectDelay):
		}
	}
}

// follow wakes the waiters of each container an event names until the stream ends
func (w *eventWatcher) follow(stream *dockerapi.EventStream) error {
	defer stream.Close()
	for {
		event, err := stream.Next()
		if err != nil {
			return err
		}
		if name := event.Actor.Attributes["name"]; name != "" {
			w.notify(name)
		}
	}
}
