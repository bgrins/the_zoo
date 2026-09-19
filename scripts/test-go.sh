#!/usr/bin/env bash
# Checks formatting, vets and race-tests the Caddy modules in core/caddy/modules
set -euo pipefail

# The Go version of the caddy builder image in core/caddy/Dockerfile
GO_IMAGE=golang:1.26.8

modules="$(cd "$(dirname "$0")/../core/caddy/modules" && pwd)"

docker run --rm \
  -v "$modules:/modules:ro" \
  -v zoo-go-cache:/cache \
  -e GOMODCACHE=/cache/mod \
  -e GOCACHE=/cache/build \
  -w /modules \
  "$GO_IMAGE" sh -c '
    status=0
    unformatted=$(gofmt -l .)
    if [ -n "$unformatted" ]; then
      echo "Files need gofmt:" >&2
      echo "$unformatted" >&2
      status=1
    fi
    for module in */; do
      echo "== ${module%/}"
      (cd "$module" && go vet ./... && go test -race ./...) || status=1
    done
    exit $status
  '
