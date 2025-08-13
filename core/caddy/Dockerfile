FROM caddy:2-builder AS builder

# First, create a dummy build to cache Go module downloads
# This layer will be cached unless xcaddy version or external modules change
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build \
    --with github.com/caddyserver/replace-response

# Now copy our local modules
COPY caddy/modules/failinjector /failinjector
COPY caddy/modules/ondemanddocker /ondemanddocker
COPY caddy/modules/dockerstatus /dockerstatus

# Build again with our local modules
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build \
    --with github.com/caddyserver/replace-response \
    --with github.com/thezoo/failinjector=/failinjector \
    --with github.com/thezoo/ondemanddocker=/ondemanddocker \
    --with github.com/thezoo/dockerstatus=/dockerstatus

FROM caddy:2

# Install docker CLI and curl for debugging
RUN apk add --no-cache docker-cli curl

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY caddy/Caddyfile /etc/caddy/Caddyfile

# Pre-populate root certificate for consistent test environment
# Caddy will generate intermediates automatically on startup
RUN mkdir -p /data/caddy/pki/authorities/local
COPY caddy/root.crt /data/caddy/pki/authorities/local/
COPY caddy/root.key /data/caddy/pki/authorities/local/
RUN chmod 644 /data/caddy/pki/authorities/local/root.crt && \
    chmod 600 /data/caddy/pki/authorities/local/root.key
