#!/bin/bash

# Zoo Performance Benchmark Script
# Measures container sizes, startup times, and response latencies
#
# Examples:
#   ./scripts/benchmark/run.sh                        # Latest npx release
#   ZOO_VERSION=0.3.0 ./scripts/benchmark/run.sh      # Specific version
#   ./scripts/benchmark/run.sh --local                # Local dev (npm start)
#   ./scripts/benchmark/run.sh --local --sites-only   # Sites only, no restart
#   ./scripts/benchmark/run.sh --sites-only           # Sites only against running npx instance
#   ./scripts/benchmark/run.sh --local --reset-start-all  # Full reset before start
#
# Options:
#   --local           Run against local dev environment (npm start) instead of npx
#   --sites-only      Skip startup/restart timing, only benchmark site response times
#   --reset-start-all Use 'npm run reset-start-all' instead of 'npm start' (requires --local)
#
# Environment variables:
#   ZOO_PROXY_PORT - Port for the proxy (default: 3130 for npx, 3128 for local)
#   ZOO_VERSION    - Version to pin (e.g., 0.3.0). If unset, uses latest. Ignored with --local.

set -e

# Parse arguments
USE_LOCAL=false
SITES_ONLY=false
RESET_START_ALL=false
for arg in "$@"; do
  case $arg in
    --local)
      USE_LOCAL=true
      shift
      ;;
    --sites-only)
      SITES_ONLY=true
      shift
      ;;
    --reset-start-all)
      RESET_START_ALL=true
      shift
      ;;
  esac
done

# Set defaults based on mode
if [[ "$USE_LOCAL" == "true" ]]; then
  ZOO_PROXY_PORT="${ZOO_PROXY_PORT:-3128}"
  ZOO_MODE="local"
else
  ZOO_PROXY_PORT="${ZOO_PROXY_PORT:-3130}"
  ZOO_VERSION="${ZOO_VERSION:-}"
  if [[ -n "$ZOO_VERSION" ]]; then
    ZOO_PKG="the_zoo@$ZOO_VERSION"
  else
    ZOO_PKG="the_zoo"
  fi
  ZOO_MODE="npx ($ZOO_PKG)"
fi

OUTPUT_DIR="./zoo-benchmark-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "========================================"
echo "Zoo Performance Benchmark"
echo "========================================"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo "Mode: $ZOO_MODE"
echo "Proxy port: $ZOO_PROXY_PORT"
echo "Flags: sites-only=$SITES_ONLY, reset-start-all=$RESET_START_ALL"
echo ""

# Get system info
echo "Collecting system information..."
{
  echo "=== System Information ==="
  echo "Date: $(date -Iseconds)"
  echo ""
  
  echo "=== OS ==="
  if [[ -f /etc/os-release ]]; then
    cat /etc/os-release
  elif [[ "$(uname)" == "Darwin" ]]; then
    echo "macOS $(sw_vers -productVersion)"
  fi
  echo ""
  
  echo "=== CPU ==="
  if [[ "$(uname)" == "Darwin" ]]; then
    sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Apple Silicon"
  else
    grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs
  fi
  echo ""
  
  echo "=== Memory ==="
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 )) GB"
  else
    free -h | grep Mem | awk '{print $2}'
  fi
  echo ""
  
  echo "=== Docker ==="
  docker --version
  docker compose version 2>/dev/null || docker-compose --version
  echo ""
} > "$OUTPUT_DIR/system-info.txt"

cat "$OUTPUT_DIR/system-info.txt"

COLD_START_TIME="N/A"
RESTART_TIME="N/A"

if [[ "$SITES_ONLY" == "false" ]]; then
  # Stop Zoo if running
  echo ""
  echo "========================================"
  echo "Stopping Zoo (if running)..."
  echo "========================================"
  if [[ "$USE_LOCAL" == "true" ]]; then
    npm run stop 2>/dev/null || true
  else
    npx "$ZOO_PKG" stop --all 2>/dev/null || true
  fi
  sleep 2

  # Measure cold start time (core services)
  echo ""
  echo "========================================"
  echo "Measuring cold start time..."
  echo "========================================"

  echo "Starting Zoo and timing until proxy responds..."
  START_TIME=$(date +%s.%N)

  if [[ "$USE_LOCAL" == "true" ]]; then
    if [[ "$RESET_START_ALL" == "true" ]]; then
      npm run reset-start-all &
    else
      npm start &
    fi
  else
    ZOO_PROXY_PORT="$ZOO_PROXY_PORT" npx "$ZOO_PKG" start &
  fi
  ZOO_PID=$!

  # Wait for proxy to be ready
  echo "Waiting for proxy at localhost:$ZOO_PROXY_PORT..."
  PROXY_READY=false
  for i in {1..120}; do
    if curl -s --proxy "http://localhost:$ZOO_PROXY_PORT" -k https://home.zoo/ > /dev/null 2>&1; then
      PROXY_READY=true
      break
    fi
    sleep 0.5
  done

  END_TIME=$(date +%s.%N)
  COLD_START_TIME=$(echo "$END_TIME - $START_TIME" | bc)

  if [[ "$PROXY_READY" == "true" ]]; then
    echo "Core services ready in ${COLD_START_TIME}s"
  else
    echo "WARNING: Proxy not ready after 60s"
  fi

  wait $ZOO_PID 2>/dev/null || true

  {
    echo "=== Startup Times ==="
    echo "cold_start_core_services_seconds,$COLD_START_TIME"
  } > "$OUTPUT_DIR/startup-times.csv"

  # Give things a moment to settle
  sleep 3
fi

# Run site benchmarks
echo ""
echo "========================================"
echo "Running site benchmarks..."
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$OUTPUT_DIR/results.json" ZOO_PROXY_PORT="$ZOO_PROXY_PORT" "$SCRIPT_DIR/sites.sh" 2>&1 | tee "$OUTPUT_DIR/site-output.txt"

# Collect core service memory
echo ""
echo "========================================"
echo "Collecting core service memory..."
echo "========================================"

# Function to get container memory usage in MiB
get_container_memory() {
  local container="$1"
  local mem_str
  mem_str=$(docker stats --no-stream --format "{{.MemUsage}}" "$container" 2>/dev/null | awk '{print $1}')

  if [[ -n "$mem_str" ]]; then
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
  echo "null"
}

echo ""
echo "Service                 | Memory (MiB)"
echo "----------------------------------------"

# Build core_services JSON
CORE_JSON="{"
FIRST=true

for container in $(docker ps --filter "label=zoo.core=true" --format '{{.Names}}' | sort); do
  mem=$(get_container_memory "$container")
  printf "%-23s | %s\n" "$container" "$mem"

  if [[ "$FIRST" == "true" ]]; then
    FIRST=false
  else
    CORE_JSON="$CORE_JSON,"
  fi
  CORE_JSON="$CORE_JSON \"$container\": {\"memory_mib\": $mem}"
done

CORE_JSON="$CORE_JSON }"

echo "----------------------------------------"
echo ""

# Add core_services to results.json
if [[ -f "$OUTPUT_DIR/results.json" ]]; then
  # Use jq to add core_services key
  jq --argjson core "$CORE_JSON" '. + {core_services: $core}' "$OUTPUT_DIR/results.json" > "$OUTPUT_DIR/results.tmp.json"
  mv "$OUTPUT_DIR/results.tmp.json" "$OUTPUT_DIR/results.json"
fi

if [[ "$SITES_ONLY" == "false" ]]; then
  # Measure restart time
  echo ""
  echo "========================================"
  echo "Measuring full restart time..."
  echo "========================================"

  START_TIME=$(date +%s.%N)

  if [[ "$USE_LOCAL" == "true" ]]; then
    npm run reset
  else
    ZOO_PROXY_PORT="$ZOO_PROXY_PORT" npx "$ZOO_PKG" restart
  fi

  # Wait for proxy to be ready again
  echo "Waiting for proxy after restart..."
  PROXY_READY=false
  for i in {1..120}; do
    if curl -s --proxy "http://localhost:$ZOO_PROXY_PORT" -k https://home.zoo/ > /dev/null 2>&1; then
      PROXY_READY=true
      break
    fi
    sleep 0.5
  done

  END_TIME=$(date +%s.%N)
  RESTART_TIME=$(echo "$END_TIME - $START_TIME" | bc)

  if [[ "$PROXY_READY" == "true" ]]; then
    echo "Full restart completed in ${RESTART_TIME}s"
  else
    echo "WARNING: Proxy not ready after restart"
  fi

  echo "full_restart_seconds,$RESTART_TIME" >> "$OUTPUT_DIR/startup-times.csv"
fi


echo ""
echo "========================================"
echo "BENCHMARK COMPLETE"
echo "========================================"
echo ""
echo "Results saved to: $OUTPUT_DIR/"
echo ""
echo ""
cat "$OUTPUT_DIR/system-info.txt" | grep -E "(macOS|Ubuntu|Docker|GB|CPU|Intel|Apple|AMD)"
echo ""
echo "Cold start (core): ${COLD_START_TIME}s"
echo "Full restart: ${RESTART_TIME}s"
echo ""