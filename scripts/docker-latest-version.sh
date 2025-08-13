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
  
  # Find version tags with same digest
  echo "Searching for matching version tags..."
  TAGS_RESPONSE=$(curl -s "https://hub.docker.com/v2/repositories/${NAMESPACE}/${IMAGE_NAME}/tags/?page_size=100")
  if [ -z "$TAGS_RESPONSE" ]; then
    echo "Error: Failed to fetch tags from Docker Hub" >&2
    exit 1
  fi
  
  # Match version tags (starting with number) excluding pre-release versions
  MATCHING_TAGS=$(echo "$TAGS_RESPONSE" | \
    jq -r --arg digest "${LATEST_DIGEST}" \
    '.results[] | select(.digest == $digest and (.name | test("^[0-9]+\\.")) and (.name | test("(alpha|beta|rc|preview|dev|nightly|unstable|testing|experimental)"; "i") | not)) | .name' | \
    sort -V 2>/dev/null || echo "$TAGS_RESPONSE" | \
    jq -r --arg digest "${LATEST_DIGEST}" \
    '.results[] | select(.digest == $digest and (.name | test("^[0-9]+\\."))) | .name' | \
    sort)
  
  if [ -z "${MATCHING_TAGS}" ]; then
    echo "No version tags found matching latest"
  else
    echo ""
    echo "Version tags matching latest:"
    echo "${MATCHING_TAGS}" | sed 's/^/  /'
    FIRST_TAG=$(echo "${MATCHING_TAGS}" | head -1)
    echo ""
    echo "Recommended: ${IMAGE}:${FIRST_TAG}"
  fi
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
  # Get all tags except digest tags, in reverse order since newer versions tend to be at the end
  ALL_TAGS=$(crane ls -O "${IMAGE}")
  # Use tail -r on BSD/macOS, fall back to sed for other systems
  TAG_LIST=$(echo "$ALL_TAGS" | { tail -r 2>/dev/null || sed '1!G;h;$!d'; })
  TAG_COUNT=$(echo "$TAG_LIST" | wc -l | tr -d ' ')
  echo " found ${TAG_COUNT} tags"
  
  # Only check first 50 tags to avoid excessive runtime
  echo "Checking up to 50 tags for matching digest..."
  
  MATCHING_TAGS=()
  CHECKED=0
  MAX_TO_CHECK=50
  MAX_MATCHES=5
  
  while IFS= read -r TAG && [ $CHECKED -lt $MAX_TO_CHECK ]; do
    CHECKED=$((CHECKED + 1))
    printf "Checking tag %d: %-30s " "$CHECKED" "$TAG"
    
    if TAG_DIGEST=$(crane digest "${IMAGE}:${TAG}" 2>/dev/null) && \
       [ "${TAG_DIGEST}" = "${LATEST_DIGEST}" ] && \
       [ "${TAG}" != "latest" ]; then
      printf "✓\n"
      MATCHING_TAGS+=("${TAG}")
      
      # Stop after finding enough matches
      if [ ${#MATCHING_TAGS[@]} -ge $MAX_MATCHES ]; then
        echo "Found $MAX_MATCHES matching tags, stopping search."
        break
      fi
    else
      printf "\n"
    fi
  done <<< "$TAG_LIST"
  
  if [ ${#MATCHING_TAGS[@]} -eq 0 ]; then
    echo "No version tags found matching latest"
  else
    echo ""
    echo "Version tags matching latest:"
    for tag in "${MATCHING_TAGS[@]}"; do
      echo "  $tag"
    done
    echo ""
    echo "Recommended: ${IMAGE}:${MATCHING_TAGS[0]}"
  fi
fi