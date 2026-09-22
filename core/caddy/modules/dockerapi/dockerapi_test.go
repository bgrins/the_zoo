package dockerapi

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// serve returns a client for a daemon answering with handler
func serve(t *testing.T, handler http.HandlerFunc) *Client {
	// Unix socket paths are limited to about 100 bytes, which t.TempDir() can exceed on macOS
	dir, err := os.MkdirTemp("", "dockerapi")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { os.RemoveAll(dir) })

	socket := filepath.Join(dir, "docker.sock")
	listener, err := net.Listen("unix", socket)
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewUnstartedServer(handler)
	srv.Listener = listener
	srv.Start()
	t.Cleanup(srv.Close)
	return New(socket)
}

func TestStartAndStopTreatNotModifiedAsSuccess(t *testing.T) {
	paths := make(chan string, 2)
	client := serve(t, func(w http.ResponseWriter, r *http.Request) {
		paths <- r.Method + " " + r.URL.Path
		w.WriteHeader(http.StatusNotModified)
	})

	if err := client.StartContainer(context.Background(), "app"); err != nil {
		t.Errorf("starting a running container failed: %v", err)
	}
	if err := client.StopContainer(context.Background(), "app"); err != nil {
		t.Errorf("stopping a stopped container failed: %v", err)
	}
	for _, want := range []string{"POST /containers/app/start", "POST /containers/app/stop"} {
		if got := <-paths; got != want {
			t.Errorf("sent %s, want %s", got, want)
		}
	}
}

func TestErrors(t *testing.T) {
	for _, tc := range []struct {
		name        string
		status      int
		body        string
		wantMessage string
		notFound    bool
	}{
		{"JSON message", http.StatusNotFound, `{"message":"No such container: app"}`, "No such container: app", true},
		{"plain text", http.StatusInternalServerError, "daemon broke\n", "daemon broke", false},
		{"empty body", http.StatusConflict, "", "409 Conflict", false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := serve(t, func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(tc.status)
				io.WriteString(w, tc.body)
			})

			_, err := client.InspectContainer(context.Background(), "app")
			var apiErr *Error
			if !errors.As(err, &apiErr) {
				t.Fatalf("got error %#v, want an *Error", err)
			}
			if apiErr.StatusCode != tc.status || apiErr.Message != tc.wantMessage {
				t.Errorf("got status %d and message %q, want %d and %q", apiErr.StatusCode, apiErr.Message, tc.status, tc.wantMessage)
			}
			if got := IsNotFound(fmt.Errorf("wrapped: %w", err)); got != tc.notFound {
				t.Errorf("IsNotFound = %v, want %v", got, tc.notFound)
			}
		})
	}

	if IsNotFound(nil) || IsNotFound(errors.New("dial unix: no such file or directory")) {
		t.Error("IsNotFound accepted an error that isn't a 404 from the daemon")
	}
}

func TestProjectName(t *testing.T) {
	hostname, err := os.Hostname()
	if err != nil {
		t.Fatal(err)
	}

	for _, tc := range []struct {
		name    string
		handler http.HandlerFunc
		want    string
		wantErr string
	}{
		{
			name: "compose container",
			handler: func(w http.ResponseWriter, r *http.Request) {
				io.WriteString(w, `{"Config":{"Labels":{"com.docker.compose.project":"the_zoo"}}}`)
			},
			want: "the_zoo",
		},
		{
			name: "not a container",
			handler: func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(http.StatusNotFound)
				io.WriteString(w, `{"message":"No such container: `+hostname+`"}`)
			},
			wantErr: "failed to inspect own container " + hostname + ": No such container: " + hostname,
		},
		{
			name: "container outside compose",
			handler: func(w http.ResponseWriter, r *http.Request) {
				io.WriteString(w, `{"Config":{"Labels":{}}}`)
			},
			wantErr: "container has no com.docker.compose.project label",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			paths := make(chan string, 1)
			client := serve(t, func(w http.ResponseWriter, r *http.Request) {
				paths <- r.URL.Path
				tc.handler(w, r)
			})

			project, err := client.ProjectName(context.Background())
			if path := <-paths; path != "/containers/"+hostname+"/json" {
				t.Errorf("inspected %s, want the container named by the hostname %s", path, hostname)
			}
			if tc.wantErr != "" {
				if err == nil || err.Error() != tc.wantErr {
					t.Fatalf("got error %v, want %q", err, tc.wantErr)
				}
				return
			}
			if err != nil || project != tc.want {
				t.Errorf("got %q, %v, want %q", project, err, tc.want)
			}
		})
	}
}

func TestEvents(t *testing.T) {
	since := time.Unix(1700000000, 5)
	queries := make(chan url.Values, 1)
	client := serve(t, func(w http.ResponseWriter, r *http.Request) {
		queries <- r.URL.Query()
		w.WriteHeader(http.StatusOK)
		w.(http.Flusher).Flush()
		io.WriteString(w, `{"Type":"container","Action":"start","Actor":{"ID":"abc","Attributes":{"name":"app"}}}`+"\n")
		io.WriteString(w, `{"Type":"container","Action":"health_status: healthy","Actor":{"ID":"abc","Attributes":{"name":"app"}}}`+"\n")
	})

	stream, err := client.Events(context.Background(), since, map[string][]string{"event": {"start"}})
	if err != nil {
		t.Fatal(err)
	}
	defer stream.Close()

	query := <-queries
	if got, want := query["since"], []string{"1700000000.000000005"}; fmt.Sprint(got) != fmt.Sprint(want) {
		t.Errorf("since = %v, want %v", got, want)
	}
	var filters map[string][]string
	if err := json.Unmarshal([]byte(query["filters"][0]), &filters); err != nil || fmt.Sprint(filters) != "map[event:[start]]" {
		t.Errorf("filters = %v (%v), want the given ones", query["filters"], err)
	}

	var actions []string
	for {
		event, err := stream.Next()
		if err != nil {
			if !errors.Is(err, io.EOF) {
				t.Errorf("stream ended with %v, want EOF", err)
			}
			break
		}
		if name := event.Actor.Attributes["name"]; name != "app" {
			t.Errorf("event for %q, want app", name)
		}
		actions = append(actions, event.Action)
	}
	if got := strings.Join(actions, ", "); got != "start, health_status: healthy" {
		t.Errorf("got events %s", got)
	}
}
