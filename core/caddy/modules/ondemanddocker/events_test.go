package ondemanddocker

import (
	"context"
	"sync/atomic"
	"testing"
	"time"

	"go.uber.org/zap"
)

// Without events, waits still see the container become ready by polling
func TestWaitsPollWithoutEvents(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true, readyAfter: 200 * time.Millisecond, noEvents: true}
	serve(t, f)
	fallbackInterval = 50 * time.Millisecond
	od := &OnDemandDocker{ContainerName: "app", Port: 80, Timeout: 5, logger: zap.NewNop()}

	var proxied atomic.Int32
	if err := serveRequest(context.Background(), od, &proxied); err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if proxied.Load() != 1 {
		t.Error("request was not proxied")
	}
}

// Events that happen while the subscription is down are not replayed, so
// resubscribing wakes every wait to inspect its container again
func TestResubscribingWakesWaits(t *testing.T) {
	f := &fakeContainer{name: "test-app-1", status: "exited", healthCheck: true, readyAfter: time.Hour}
	serve(t, f)
	od := &OnDemandDocker{ContainerName: "app", Port: 80, Timeout: 5, logger: zap.NewNop()}

	f.setEvents(false)
	var proxied atomic.Int32
	errs := make(chan error, 1)
	go func() { errs <- serveRequest(context.Background(), od, &proxied) }()
	// One inspect before the start and one after it
	waitFor(t, "the wait inspects the started container", func() bool { return f.inspectCount() == 2 })

	f.setHealth("healthy")
	f.setEvents(true)
	if err := <-errs; err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if proxied.Load() != 1 {
		t.Error("request was not proxied")
	}
}
