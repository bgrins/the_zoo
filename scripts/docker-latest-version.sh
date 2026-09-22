#!/usr/bin/env bash

# Find what version the "latest" tag points to for Docker images
# Uses Docker Hub API for Docker Hub images, falls back to crane for others
#
# Usage: docker-latest-version.sh <image>
# Example: docker-latest-version.sh nginx
#          docker-latest-version.sh mcr.microsoft.com/dotnet/runtime

set -euo pipefail

# Check dependencies
for cmd in jq curl; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: $cmd is required but not installed" >&2
    exit 1
  fi
done

if [ $# -eq 0 ]; then
  echo "Usage: docker-latest-version.sh <image>" >&2
  echo "Example: docker-latest-version.sh nginx" >&2
  echo "         docker-latest-version.sh gcr.io/distroless/static" >&2
  exit 1
fi

IMAGE="$1"

# Version tags (1.27.3, v2.3.0; not 1.27-alpine or 2.0.0-rc1) from stdin, newest first
version_tags() {
  jq -R -s -r 'split("\n") | map(select(test("^v?[0-9]+(\\.[0-9]+)*$")))
    | sort_by(ltrimstr("v") | split(".") | map(tonumber)) | reverse | .[]'
}

# The most specific of the version tags on stdin: 1.27.3 rather than 1.27 or 1
most_specific() {
  jq -R -s -r 'split("\n") | map(select(length > 0))
    | sort_by(ltrimstr("v") | split(".") | map(tonumber) | [length, .]) | last // empty'
}

report() {
  local matching="$1"
  if [ -z "${matching}" ]; then
    echo "No version tags found matching latest"
    return
  fi
  echo ""
  echo "Version tags matching latest:"
  echo "${matching}" | sed 's/^/  /'
  echo ""
  echo "Recommended: ${IMAGE}:$(echo "${matching}" | most_specific)"
}

# Detect if it's a Docker Hub image
# Docker Hub images don't have a domain or have docker.io domain
if [[ ! "${IMAGE}" =~ ^[^/]+\.[^/]+/ ]] || [[ "${IMAGE}" =~ ^docker\.io/ ]]; then
  # Remove docker.io prefix if present
  IMAGE="${IMAGE#docker.io/}"

  # Parse image name for Docker Hub
  if [[ "${IMAGE}" == *"/"* ]]; then
    NAMESPACE="${IMAGE%/*}"
    IMAGE_NAME="${IMAGE##*/}"
  else
    NAMESPACE="library"
    IMAGE_NAME="${IMAGE}"
  fi

  echo "Checking ${IMAGE}:latest..."

  # Get digest for latest tag
  RESPONSE=$(curl -s "https://hub.docker.com/v2/repositories/${NAMESPACE}/${IMAGE_NAME}/tags/latest")
  if [ -z "$RESPONSE" ]; then
    echo "Error: Failed to fetch data from Docker Hub" >&2
    exit 1
  fi

  LATEST_DIGEST=$(echo "$RESPONSE" | jq -r '.digest // empty')

  if [ -z "${LATEST_DIGEST}" ]; then
    echo "Error: Could not get digest for latest tag" >&2
    exit 1
  fi

  echo "Latest digest: ${LATEST_DIGEST}"

  # Tags pushed with latest are among the most recently updated
  echo "Searching for matching version tags..."
  TAGS_RESPONSE=$(curl -s "https://hub.docker.com/v2/repositories/${NAMESPACE}/${IMAGE_NAME}/tags/?page_size=100&ordering=last_updated")
  if [ -z "$TAGS_RESPONSE" ]; then
    echo "Error: Failed to fetch tags from Docker Hub" >&2
    exit 1
  fi

  report "$(echo "$TAGS_RESPONSE" |
    jq -r --arg digest "${LATEST_DIGEST}" '.results[] | select(.digest == $digest) | .name' |
    version_tags)"
else
  # For non-Docker Hub registries, use crane
  if ! command -v crane &> /dev/null; then
    echo "Error: crane is required for non-Docker Hub registries but not installed" >&2
    echo "Install crane from: https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md" >&2
    exit 1
  fi

  echo "Non-Docker Hub registry detected, using crane..."

  echo -n "Getting digest for ${IMAGE}:latest..."
  if ! LATEST_DIGEST=$(crane digest "${IMAGE}:latest" 2>&1); then
    echo " FAILED"
    echo "Error: Failed to get digest for ${IMAGE}:latest" >&2
    echo "$LATEST_DIGEST" >&2
    exit 1
  fi
  echo " done"

  echo "Latest digest: ${LATEST_DIGEST}"

  echo -n "Fetching tag list..."
  TAG_LIST=$(crane ls -O "${IMAGE}" | version_tags)
  TAG_COUNT=$(echo "$TAG_LIST" | grep -c . || true)
  echo " found ${TAG_COUNT} version tags"

  # Only check the newest 50 to avoid excessive runtime
  echo "Checking up to 50 tags for matching digest..."

  MATCHING_TAGS=""
  CHECKED=0
  MAX_TO_CHECK=50

  while IFS= read -r TAG && [ -n "$TAG" ] && [ $CHECKED -lt $MAX_TO_CHECK ]; do
    CHECKED=$((CHECKED + 1))
    printf "Checking tag %d: %-30s " "$CHECKED" "$TAG"

    if TAG_DIGEST=$(crane digest "${IMAGE}:${TAG}" 2>/dev/null) && \
       [ "${TAG_DIGEST}" = "${LATEST_DIGEST}" ]; then
      printf "✓\n"
      MATCHING_TAGS+="${TAG}"$'\n'
    else
      printf "\n"
    fi
  done <<< "$TAG_LIST"

  report "${MATCHING_TAGS%$'\n'}"
fi
