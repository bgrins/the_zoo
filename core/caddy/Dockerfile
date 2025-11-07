FROM caddy:2-builder AS builder

# Copy local modules first (small files, cache-friendly)
COPY caddy/modules/failinjector /failinjector
COPY caddy/modules/ondemanddocker /ondemanddocker
COPY caddy/modules/dockerstatus /dockerstatus

# Single build with all modules (cache mounts handle Go module caching)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build \
    --with github.com/caddyserver/replace-response \
    --with github.com/thezoo/failinjector=/failinjector \
    --with github.com/thezoo/ondemanddocker=/ondemanddocker \
    --with github.com/thezoo/dockerstatus=/dockerstatus

FROM alpine:latest

# Install docker CLI, curl, and CA certificates
RUN apk add --no-cache ca-certificates docker-cli curl libcap

# Copy custom-built Caddy binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
RUN setcap cap_net_bind_service=+ep /usr/bin/caddy

# Copy Caddy config
COPY caddy/Caddyfile /etc/caddy/Caddyfile

# Pre-populate root certificate for consistent test environment
RUN mkdir -p /root/.local/share/caddy/pki/authorities/local
COPY caddy/root.crt /root/.local/share/caddy/pki/authorities/local/
COPY caddy/root.key /root/.local/share/caddy/pki/authorities/local/
RUN chmod 644 /root/.local/share/caddy/pki/authorities/local/root.crt && \
    chmod 600 /root/.local/share/caddy/pki/authorities/local/root.key

# Match caddy:2 image setup
VOLUME /data
EXPOSE 80 443 2019

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
