#!/usr/bin/env bash
# Checks formatting, vets and race-tests the Caddy modules in core/caddy/modules
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

# Test with the Go version of the builder image core/caddy/Dockerfile builds Caddy with. That
# image is Alpine-based without cgo, which -race needs, so run the matching golang image.
builder=$(sed -n 's/^FROM .*\(caddy:[^ ]*-builder\).*/\1/p' "$root/core/caddy/Dockerfile")
if [ -z "$builder" ]; then
  echo "No caddy:*-builder image in core/caddy/Dockerfile" >&2
  exit 1
fi
builder_env=$(docker image inspect "$builder" --format '{{json .Config.Env}}' 2>/dev/null ||
  docker buildx imagetools inspect "$builder" --format '{{json .Image}}')
go_version=$(grep -m1 -o 'GOLANG_VERSION=[0-9.]*' <<< "$builder_env" | cut -d= -f2) || true
if [ -z "$go_version" ]; then
  echo "Could not read GOLANG_VERSION from $builder" >&2
  exit 1
fi
GO_IMAGE="golang:$go_version"
echo "Using $GO_IMAGE (the Go version of $builder)"

docker run --rm \
  -v "$root/core/caddy/modules:/modules:ro" \
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
    # go.work puts every module in one workspace
    attempt=1
    while ! go list -deps -test github.com/thezoo/... > /dev/null; do
      if [ "$attempt" -eq 3 ]; then
        echo "Go dependency download failed after $attempt attempts" >&2
        exit 1
      fi
      echo "Go dependency download failed (attempt $attempt/3); retrying" >&2
      sleep $((attempt * 2))
      attempt=$((attempt + 1))
    done
    go vet github.com/thezoo/... && go test -race github.com/thezoo/... || status=1
    exit $status
  '
