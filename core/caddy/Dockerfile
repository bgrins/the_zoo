# Cross-compile on the build platform so multi-arch builds don't run Go under emulation
FROM --platform=$BUILDPLATFORM caddy:2.11.4-builder AS builder
ARG TARGETOS
ARG TARGETARCH

# Copy local modules first (small files, cache-friendly)
COPY modules/dockerapi /dockerapi
COPY modules/failinjector /failinjector
COPY modules/ondemanddocker /ondemanddocker
COPY modules/dockerstatus /dockerstatus

# Single build with all modules (cache mounts handle Go module caching)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH xcaddy build \
    --with github.com/caddyserver/replace-response@v0.0.0-20250618171559-80962887e4c6 \
    --with github.com/thezoo/failinjector=/failinjector \
    --with github.com/thezoo/ondemanddocker=/ondemanddocker \
    --with github.com/thezoo/dockerstatus=/dockerstatus \
    --replace github.com/thezoo/dockerapi=/dockerapi

FROM alpine:3.20

# The modules talk to the Docker API over the mounted socket, so no docker CLI.
# curl is used by tests that exec into this container; libcap provides setcap.
RUN apk add --no-cache ca-certificates curl libcap

# Copy custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy

# Copy Caddy config
COPY Caddyfile /etc/caddy/Caddyfile

# Pre-populate root certificate for consistent test environment
RUN mkdir -p /root/.local/share/caddy/pki/authorities/local
COPY root.crt /root/.local/share/caddy/pki/authorities/local/
COPY root.key /root/.local/share/caddy/pki/authorities/local/
RUN chmod 644 /root/.local/share/caddy/pki/authorities/local/root.crt && \
    chmod 600 /root/.local/share/caddy/pki/authorities/local/root.key

EXPOSE 80 443 2019

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
