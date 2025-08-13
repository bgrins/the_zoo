package failinjector

import (
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"strconv"

	"github.com/caddyserver/caddy/v2"
	"github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	"github.com/caddyserver/caddy/v2/caddyconfig/httpcaddyfile"
	"github.com/caddyserver/caddy/v2/modules/caddyhttp"
	"go.uber.org/zap"
)

func init() {
	caddy.RegisterModule(FailInjector{})
	httpcaddyfile.RegisterHandlerDirective("fail_injector", parseCaddyfile)
}


// FailInjector is a Caddy HTTP handler module that injects failures
// based on random probability for testing fault tolerance
type FailInjector struct {
	Probability float64 `json:"probability,omitempty"` // For random mode
	Seed        int64   `json:"seed,omitempty"`        // Random seed (deprecated, use FAIL_SEED env var)
	Enabled     *bool   `json:"enabled,omitempty"`     // Override CHAOS_MODE check when set

	rng    *rand.Rand
	logger *zap.Logger
}

// CaddyModule returns the Caddy module information.
func (FailInjector) CaddyModule() caddy.ModuleInfo {
	return caddy.ModuleInfo{
		ID:  "http.handlers.fail_injector",
		New: func() caddy.Module { return new(FailInjector) },
	}
}

// Provision implements caddy.Provisioner.
func (f *FailInjector) Provision(ctx caddy.Context) error {
	f.logger = ctx.Logger(f)


	// Set up probability from CHAOS_MODE_FAIL_PROBABILITY environment variable
	if envProb := os.Getenv("CHAOS_MODE_FAIL_PROBABILITY"); envProb != "" {
		parsedProb, err := strconv.ParseFloat(envProb, 64)
		if err != nil {
			return fmt.Errorf("invalid probability in CHAOS_MODE_FAIL_PROBABILITY env var: %v", err)
		}
		if parsedProb < 0 || parsedProb > 1 {
			return fmt.Errorf("CHAOS_MODE_FAIL_PROBABILITY must be between 0 and 1, got %f", parsedProb)
		}
		f.Probability = parsedProb
		f.logger.Info("using probability from CHAOS_MODE_FAIL_PROBABILITY environment variable",
			zap.Float64("probability", f.Probability))
	}

	// Set up RNG with seed from CHAOS_MODE_FAIL_SEED environment variable or fallback
	var seed int64
	if envSeed := os.Getenv("CHAOS_MODE_FAIL_SEED"); envSeed != "" {
		parsedSeed, err := strconv.ParseInt(envSeed, 10, 64)
		if err != nil {
			return fmt.Errorf("invalid seed in CHAOS_MODE_FAIL_SEED env var: %v", err)
		}
		seed = parsedSeed
		f.logger.Info("using seed from CHAOS_MODE_FAIL_SEED environment variable",
			zap.Int64("seed", seed))
	} else if f.Seed != 0 {
		// Fallback to configured seed for backward compatibility
		seed = f.Seed
	} else {
		seed = rand.Int63()
	}

	f.rng = rand.New(rand.NewSource(seed))

	return nil
}

// Validate implements caddy.Validator.
func (f *FailInjector) Validate() error {
	if f.Probability < 0 || f.Probability > 1 {
		return fmt.Errorf("probability must be between 0 and 1")
	}
	return nil
}

// ServeHTTP implements caddyhttp.MiddlewareHandler.
func (f *FailInjector) ServeHTTP(w http.ResponseWriter, r *http.Request, next caddyhttp.Handler) error {
	// Check if fail injection is enabled
	// If Enabled is explicitly set, use that value
	// Otherwise, check CHAOS_MODE environment variable
	enabled := false
	if f.Enabled != nil {
		enabled = *f.Enabled
	} else {
		enabled = os.Getenv("CHAOS_MODE") == "1"
	}
	
	// Allow override via X-Chaos-Mode header (1 = enabled, 0 = disabled)
	if chaosMode := r.Header.Get("X-Chaos-Mode"); chaosMode != "" {
		enabled = chaosMode == "1"
		f.logger.Debug("using chaos mode from header",
			zap.String("mode", chaosMode),
			zap.Bool("enabled", enabled))
	}
	
	if !enabled {
		return next.ServeHTTP(w, r)
	}

	// Get probability from environment variable if set, otherwise use configured value
	probability := f.Probability
	if envProb := os.Getenv("CHAOS_MODE_FAIL_PROBABILITY"); envProb != "" {
		if parsedProb, err := strconv.ParseFloat(envProb, 64); err == nil && parsedProb >= 0 && parsedProb <= 1 {
			probability = parsedProb
		}
	}
	
	// Allow override via X-Chaos-Mode-Fail-Probability header
	if chaosProb := r.Header.Get("X-Chaos-Mode-Fail-Probability"); chaosProb != "" {
		if parsedProb, err := strconv.ParseFloat(chaosProb, 64); err == nil && parsedProb >= 0 && parsedProb <= 1 {
			probability = parsedProb
			f.logger.Debug("using chaos mode fail probability from header",
				zap.Float64("probability", probability))
		}
	}
	
	shouldFail := f.rng.Float64() < probability

	if shouldFail {
		f.logger.Info("failing request (random)",
			zap.Float64("probability", probability))
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Intentional failure injected by fail_injector"))
		return nil
	}

	return next.ServeHTTP(w, r)
}

// UnmarshalCaddyfile implements caddyfile.Unmarshaler.
func (f *FailInjector) UnmarshalCaddyfile(d *caddyfile.Dispenser) error {
	for d.Next() {
		for d.NextBlock(0) {
			switch d.Val() {
			case "probability":
				if !d.NextArg() {
					return d.ArgErr()
				}
				val, err := strconv.ParseFloat(d.Val(), 64)
				if err != nil {
					return d.Errf("probability must be a float: %v", err)
				}
				f.Probability = val
			case "enabled":
				if !d.NextArg() {
					return d.ArgErr()
				}
				val, err := strconv.ParseBool(d.Val())
				if err != nil {
					return d.Errf("enabled must be a boolean: %v", err)
				}
				f.Enabled = &val
			default:
				return d.Errf("unrecognized subdirective %q", d.Val())
			}
		}
	}
	return nil
}

// parseCaddyfile unmarshals tokens from h into a new Middleware.
func parseCaddyfile(h httpcaddyfile.Helper) (caddyhttp.MiddlewareHandler, error) {
	var f FailInjector
	err := f.UnmarshalCaddyfile(h.Dispenser)
	return &f, err
}

// Interface guards
var (
	_ caddy.Provisioner           = (*FailInjector)(nil)
	_ caddy.Validator             = (*FailInjector)(nil)
	_ caddyhttp.MiddlewareHandler = (*FailInjector)(nil)
	_ caddyfile.Unmarshaler       = (*FailInjector)(nil)
)