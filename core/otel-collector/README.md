# Trace collection

Caddy emits an OpenTelemetry span for every HTTP request it serves (see the
`zoo_tracing` snippet in `core/caddy/Caddyfile`). The collector receives them
via OTLP and writes newline-delimited OTLP JSON to `export/traces.json`
(rotated at 50MB, 3 backups kept).

Each span carries the standard HTTP attributes plus:

- `zoo.agent` — the proxy username that made the request, or `anonymous`.
  Set `PROXY_USERS=name:pass,name:pass,...` in `.env` and recreate the
  `proxy` and `caddy` containers to enable per-agent attribution
  (see [core/proxy/README.md](../proxy/README.md)).
- `zoo.client.ip` — the per-agent Squid outgoing IP.

The same identity is forwarded to apps as a `Baggage: proxy.user=<name>`
request header.

## Inspecting the raw file

```bash
jq -r '.resourceSpans[].scopeSpans[].spans[]
  | [(.attributes[] | select(.key=="zoo.agent") | .value.stringValue),
     (.attributes[] | select(.key=="server.address") | .value.stringValue),
     (.attributes[] | select(.key=="url.path") | .value.stringValue)]
  | @tsv' core/otel-collector/export/traces.json
```

## Viewing in Jaeger

Jaeger is intentionally not part of the zoo. To browse traces, run it locally
and replay the export file into its OTLP endpoint (each line of the file is a
complete OTLP request payload):

```bash
docker run --rm -d --name jaeger -p 16686:16686 -p 4318:4318 jaegertracing/jaeger:2.19.0

while IFS= read -r line; do
  curl -s -o /dev/null -X POST -H 'Content-Type: application/json' \
    -d "$line" http://localhost:4318/v1/traces
done < core/otel-collector/export/traces.json
```

Then open http://localhost:16686, pick the `zoo-caddy` service, and search.
Filter by agent with a tag query like `zoo.agent=alice`. Stop it with
`docker stop jaeger`.
