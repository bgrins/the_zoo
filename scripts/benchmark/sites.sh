#!/bin/bash

# Zoo Site Benchmark Script
# Measures cold start and warm response times for each site using curl
#
# Usage:
#   ./sites.sh                          # Test all sites
#   ./sites.sh classifieds.zoo          # Test single site
#   ./sites.sh classifieds postmill     # Test multiple sites (partial match)
#   ./sites.sh --cold classifieds       # Stop container first for true cold start
#
# Environment variables:
#   ZOO_PROXY_PORT - Port for the proxy (default: 3128)
#   OUTPUT_FILE    - Path to write JSON results

set -e

ZOO_PROXY_PORT="${ZOO_PROXY_PORT:-3128}"
PROXY_URL="http://localhost:$ZOO_PROXY_PORT"

# Parse --cold flag
COLD_START=false
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--cold" ]]; then
    COLD_START=true
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]}"

# All available sites (from SITES.yaml, excluding api/admin)
ALL_SITES=(
  "analytics.zoo"
  "auth.zoo"
  "classifieds.zoo"
  "excalidraw.zoo"
  "focalboard.zoo"
  "gitea.zoo"
  "miniflux.zoo"
  "misc.zoo"
  "northwind.zoo"
  "onestopshop.zoo"
  "paste.zoo"
  "postmill.zoo"
  "snappymail.zoo"
  "wiki.zoo"
)

# Filter sites based on arguments
if [[ $# -gt 0 ]]; then
  SITES=()
  for arg in "$@"; do
    for site in "${ALL_SITES[@]}"; do
      if [[ "$site" == *"$arg"* ]]; then
        SITES+=("$site")
      fi
    done
  done
  if [[ ${#SITES[@]} -eq 0 ]]; then
    echo "No sites matched: $*"
    echo "Available sites: ${ALL_SITES[*]}"
    exit 1
  fi
else
  SITES=("${ALL_SITES[@]}")
fi

echo "============================================================"
echo "Zoo Site Benchmark (curl)"
echo "============================================================"
echo ""
echo "Proxy: $PROXY_URL"
echo ""
echo "NOTE: Ensure Zoo was just started fresh to get accurate"
echo "      cold start measurements."
echo ""

# Arrays to store results
declare -a RESULTS_SITE
declare -a RESULTS_COLD
declare -a RESULTS_WARM
declare -a RESULTS_STATUS
declare -a RESULTS_MEMORY

# Function to measure request time
measure_request() {
  local site="$1"
  local url="https://${site}/"

  # Use curl with timing, follow redirects, ignore SSL errors
  # -w outputs timing info, -o discards body, -s silent mode
  local result
  result=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" \
    --proxy "$PROXY_URL" \
    -k \
    --connect-timeout 120 \
    --max-time 120 \
    "$url" 2>/dev/null) || result="000 0"

  echo "$result"
}

# Function to get container memory usage in MiB
get_container_memory() {
  local site="$1"

  # Find container by zoo.domains label (e.g., "paste.zoo:8080" or "wiki.zoo")
  local container
  container=$(docker ps --filter "label=zoo.domains" --format '{{.Names}}' | while read -r name; do
    domains=$(docker inspect "$name" --format '{{index .Config.Labels "zoo.domains"}}' 2>/dev/null)
    # Check if site matches (handle port suffix like "paste.zoo:8080")
    if [[ "$domains" == "$site" || "$domains" == "$site:"* ]]; then
      echo "$name"
      break
    fi
  done)

  if [[ -n "$container" ]]; then
    # Get memory usage
    local mem_str
    mem_str=$(docker stats --no-stream --format "{{.MemUsage}}" "$container" 2>/dev/null | awk '{print $1}')

    if [[ -n "$mem_str" ]]; then
      # Parse value and unit (e.g., "156.4MiB" or "1.2GiB")
      local value unit
      value=$(echo "$mem_str" | sed 's/[^0-9.]//g')
      unit=$(echo "$mem_str" | sed 's/[0-9.]//g')

      case "$unit" in
        GiB) echo "$(echo "$value * 1024" | bc | cut -d. -f1)" ;;
        MiB) echo "$value" | cut -d. -f1 ;;
        KiB) echo "$(echo "$value / 1024" | bc | cut -d. -f1)" ;;
        *) echo "$value" | cut -d. -f1 ;;
      esac
      return
    fi
  fi

  echo "null"
}

echo "Site                    | Cold Start (ms) | Warm (ms) | Memory (MiB) | Status"
echo "-------------------------------------------------------------------------------"

for site in "${SITES[@]}"; do
  # Stop container if requested (for true cold start via on-demand)
  if [[ "$COLD_START" == "true" ]]; then
    # Map site to container name
    service_name="${site%.zoo}"
    service_name="${service_name//./-}"

    # Find the actual container (handles naming variations)
    container=$(docker ps -a --format '{{.Names}}' | grep -E "(${service_name}|vwa-${service_name})" | head -1)

    if [[ -n "$container" ]]; then
      docker stop "$container" >/dev/null 2>&1 || true
      sleep 1
    fi
  fi

  # Cold start request
  cold_result=$(measure_request "$site")
  cold_status=$(echo "$cold_result" | awk '{print $1}')
  cold_time=$(echo "$cold_result" | awk '{print $2}')
  cold_ms=$(echo "$cold_time * 1000" | bc | cut -d. -f1)

  # Small delay to ensure container is ready
  sleep 1

  # Warm response request
  warm_result=$(measure_request "$site")
  warm_status=$(echo "$warm_result" | awk '{print $1}')
  warm_time=$(echo "$warm_result" | awk '{print $2}')
  warm_ms=$(echo "$warm_time * 1000" | bc | cut -d. -f1)

  # Determine status
  if [[ "$cold_status" =~ ^2[0-9][0-9]$ ]] || [[ "$cold_status" =~ ^3[0-9][0-9]$ ]]; then
    status="OK"
  else
    status="ERR:$cold_status"
    cold_ms="FAIL"
    warm_ms="FAIL"
  fi

  # Get memory usage for this container
  memory=$(get_container_memory "$site")

  # Store results
  RESULTS_SITE+=("$site")
  RESULTS_COLD+=("$cold_ms")
  RESULTS_WARM+=("$warm_ms")
  RESULTS_STATUS+=("$status")
  RESULTS_MEMORY+=("$memory")

  # Print row
  printf "%-23s | %15s | %9s | %12s | %s\n" "$site" "$cold_ms" "$warm_ms" "$memory" "$status"

  # Small delay between sites
  sleep 0.5
done

echo "------------------------------------------------------------"
echo ""

# Output JSON results to stdout if OUTPUT_FILE is set
if [[ -n "$OUTPUT_FILE" ]]; then
  {
    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"proxy_port\": $ZOO_PROXY_PORT,"
    echo "  \"sites\": {"
    for i in "${!RESULTS_SITE[@]}"; do
      site="${RESULTS_SITE[$i]}"
      cold="${RESULTS_COLD[$i]}"
      warm="${RESULTS_WARM[$i]}"
      mem="${RESULTS_MEMORY[$i]}"

      # Handle FAIL values
      if [[ "$cold" == "FAIL" ]]; then
        cold="null"
      fi
      if [[ "$warm" == "FAIL" ]]; then
        warm="null"
      fi

      comma=","
      if [[ $i -eq $((${#RESULTS_SITE[@]} - 1)) ]]; then
        comma=""
      fi

      echo "    \"$site\": {\"cold_start_ms\": $cold, \"warm_response_ms\": $warm, \"memory_mib\": $mem}$comma"
    done
    echo "  }"
    echo "}"
  } > "$OUTPUT_FILE"
  echo "Results saved to: $OUTPUT_FILE"
fi
