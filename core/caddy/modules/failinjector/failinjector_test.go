package failinjector

import (
	"context"
	"math/rand"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
)

func provision(t *testing.T, f *FailInjector) error {
	t.Helper()
	ctx, cancel := caddy.NewContext(caddy.Context{Context: context.Background()})
	t.Cleanup(cancel)
	return f.Provision(ctx)
}

// outcomes serves requests through f and reports which ones it failed
func outcomes(t *testing.T, f *FailInjector, requests int, header http.Header) []bool {
	t.Helper()
	next := caddyhttp.HandlerFunc(func(w http.ResponseWriter, r *http.Request) error {
		w.WriteHeader(http.StatusOK)
		return nil
	})
	failed := make([]bool, requests)
	for i := range failed {
		r := httptest.NewRequest(http.MethodGet, "http://app.zoo/", nil)
		for k, v := range header {
			r.Header[k] = v
		}
		w := httptest.NewRecorder()
		if err := f.ServeHTTP(w, r, next); err != nil {
			t.Fatal(err)
		}
		switch w.Code {
		case http.StatusInternalServerError:
			if body := w.Body.String(); body != "Intentional failure injected by fail_injector" {
				t.Fatalf("failed request has body %q", body)
			}
			failed[i] = true
		case http.StatusOK:
		default:
			t.Fatalf("got status %d", w.Code)
		}
	}
	return failed
}

func TestEnvConfig(t *testing.T) {
	for _, tc := range []struct {
		name, probability, seed string
		wantErr                 string
		wantProbability         float64
	}{
		{name: "probability", probability: "0.25", wantProbability: 0.25},
		{name: "unset", wantProbability: 0.7},
		{name: "probability not a number", probability: "high",
			wantErr: `invalid probability in CHAOS_MODE_FAIL_PROBABILITY env var: strconv.ParseFloat: parsing "high": invalid syntax`},
		{name: "probability above 1", probability: "1.5",
			wantErr: "CHAOS_MODE_FAIL_PROBABILITY must be between 0 and 1, got 1.500000"},
		{name: "negative probability", probability: "-0.1",
			wantErr: "CHAOS_MODE_FAIL_PROBABILITY must be between 0 and 1, got -0.100000"},
		{name: "seed not an integer", seed: "1.5",
			wantErr: `invalid seed in CHAOS_MODE_FAIL_SEED env var: strconv.ParseInt: parsing "1.5": invalid syntax`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("CHAOS_MODE_FAIL_PROBABILITY", tc.probability)
			t.Setenv("CHAOS_MODE_FAIL_SEED", tc.seed)

			f := &FailInjector{Probability: 0.7}
			err := provision(t, f)
			if tc.wantErr != "" {
				if err == nil || err.Error() != tc.wantErr {
					t.Fatalf("got error %v, want %q", err, tc.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if f.Probability != tc.wantProbability {
				t.Errorf("probability = %v, want %v", f.Probability, tc.wantProbability)
			}
		})
	}
}

// A fixed seed gives every site block the same failures in the same order
func TestSeedIsReproducible(t *testing.T) {
	const requests = 64
	want := make([]bool, requests)
	rng := rand.New(rand.NewSource(42))
	for i := range want {
		want[i] = rng.Float64() < 0.5
	}

	for _, tc := range []struct {
		name string
		env  string
		seed int64
	}{
		{name: "CHAOS_MODE_FAIL_SEED", env: "42"},
		{name: "configured seed", seed: 42},
		{name: "CHAOS_MODE_FAIL_SEED over configured seed", env: "42", seed: 7},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("CHAOS_MODE", "1")
			t.Setenv("CHAOS_MODE_FAIL_PROBABILITY", "0.5")
			t.Setenv("CHAOS_MODE_FAIL_SEED", tc.env)

			for block := 0; block < 2; block++ {
				f := &FailInjector{Seed: tc.seed}
				if err := provision(t, f); err != nil {
					t.Fatal(err)
				}
				got := outcomes(t, f, requests, nil)
				for i := range want {
					if got[i] != want[i] {
						t.Fatalf("site block %d: request %d failed = %v, want %v for seed 42", block, i, got[i], want[i])
					}
				}
			}
		})
	}
}

func TestEnabling(t *testing.T) {
	enabled, disabled := true, false
	for _, tc := range []struct {
		name      string
		chaosMode string
		enabled   *bool
		header    http.Header
		wantFail  bool
	}{
		{name: "CHAOS_MODE=1", chaosMode: "1", wantFail: true},
		{name: "CHAOS_MODE unset", wantFail: false},
		{name: "enabled overrides CHAOS_MODE", chaosMode: "0", enabled: &enabled, wantFail: true},
		{name: "disabled overrides CHAOS_MODE", chaosMode: "1", enabled: &disabled, wantFail: false},
		{name: "header enables", enabled: &disabled, header: http.Header{"X-Chaos-Mode": {"1"}}, wantFail: true},
		{name: "header disables", chaosMode: "1", header: http.Header{"X-Chaos-Mode": {"0"}}, wantFail: false},
		{name: "header sets probability", chaosMode: "1",
			header: http.Header{"X-Chaos-Mode-Fail-Probability": {"0"}}, wantFail: false},
		{name: "invalid header probability is ignored", chaosMode: "1",
			header: http.Header{"X-Chaos-Mode-Fail-Probability": {"2"}}, wantFail: true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("CHAOS_MODE", tc.chaosMode)
			t.Setenv("CHAOS_MODE_FAIL_PROBABILITY", "1")
			f := &FailInjector{Enabled: tc.enabled}
			if err := provision(t, f); err != nil {
				t.Fatal(err)
			}

			for i, failed := range outcomes(t, f, 10, tc.header) {
				if failed != tc.wantFail {
					t.Fatalf("request %d failed = %v, want %v", i, failed, tc.wantFail)
				}
			}
		})
	}
}

func TestUnmarshalCaddyfile(t *testing.T) {
	for _, tc := range []struct {
		name            string
		input           string
		wantErr         string
		wantProbability float64
		wantEnabled     *bool
	}{
		{name: "no options", input: `fail_injector`},
		{name: "empty block", input: "fail_injector {\n}"},
		{name: "options", input: "fail_injector {\n  probability 0.3\n  enabled false\n}",
			wantProbability: 0.3, wantEnabled: new(bool)},
		{name: "probability not a number", input: "fail_injector {\n  probability often\n}",
			wantErr: `probability must be a float: strconv.ParseFloat: parsing "often": invalid syntax`},
		{name: "enabled not a boolean", input: "fail_injector {\n  enabled maybe\n}",
			wantErr: `enabled must be a boolean: strconv.ParseBool: parsing "maybe": invalid syntax`},
		{name: "missing argument", input: "fail_injector {\n  probability\n}", wantErr: "wrong argument count"},
		{name: "unknown option", input: "fail_injector {\n  seed 1\n}", wantErr: `unrecognized subdirective "seed"`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var f FailInjector
			err := f.UnmarshalCaddyfile(caddyfile.NewTestDispenser(tc.input))
			if tc.wantErr != "" {
				if err == nil || !strings.HasPrefix(err.Error(), tc.wantErr) {
					t.Fatalf("got error %v, want %q", err, tc.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if f.Probability != tc.wantProbability {
				t.Errorf("probability = %v, want %v", f.Probability, tc.wantProbability)
			}
			if (f.Enabled == nil) != (tc.wantEnabled == nil) || (f.Enabled != nil && *f.Enabled != *tc.wantEnabled) {
				t.Errorf("enabled = %v, want %v", f.Enabled, tc.wantEnabled)
			}
		})
	}
}
