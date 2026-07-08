# Squid Proxy Authentication

Optional basic authentication for the proxy, with per-user traffic attribution.

## Setup

Set `PROXY_USERS` (comma-separated `name:password` pairs) in `.env`:

```bash
PROXY_USERS=alice:alice-pw,bob:bob-pw
```

```bash
docker compose up -d proxy --build
```

Each user is assigned a dedicated outgoing IP (`172.20.251.101`, `.102`, ...
in list order), so Caddy can attribute requests to the user in OpenTelemetry
traces (see the `zoo_tracing` snippet in `core/caddy/Caddyfile` and the trace
UI at https://jaeger.zoo).

## Usage

```bash
curl -L -k --proxy http://alice:alice-pw@localhost:3128 http://example.zoo
```

In Firefox (configured per the manual browsing setup in the root README), the
proxy authentication dialog appears on first navigation — enter one of the
`PROXY_USERS` credentials.

## Notes

- `PROXY_USERS` unset = no authentication required (default); all traffic is
  attributed as `anonymous`
- When `PROXY_USERS` is set, authentication is required — there is no
  anonymous fallback (browsers only send proxy credentials after a challenge,
  so an anonymous fallback would silently break attribution)
