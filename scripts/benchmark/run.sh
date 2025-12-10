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
OUTPUT_FILE="$OUTPUT_DIR/site-results.json" ZOO_PROXY_PORT="$ZOO_PROXY_PORT" "$SCRIPT_DIR/sites.sh" 2>&1 | tee "$OUTPUT_DIR/site-output.txt"

echo ""
echo "========================================"
echo "Measuring runtime memory usage..."
echo "========================================"

{
  echo "=== Container Memory Usage ==="
  echo ""
  echo "CONTAINER,MEMORY"
  docker stats --no-stream --format "{{.Name}},{{.MemUsage}}" | grep -E "(zoo|stalwart|caddy|coredns|squid|mysql|postgres|redis|hydra)" | sed 's| / [0-9.]*GiB||g' | sort
} > "$OUTPUT_DIR/memory-usage.csv"

# Calculate total memory
TOTAL_MEM=0
while IFS=',' read -r name mem; do
  if [[ "$mem" =~ ^[0-9] ]]; then
    val=$(echo "$mem" | sed 's/[^0-9.]//g')
    if [[ "$mem" == *GiB* ]]; then
      val=$(echo "$val * 1024" | bc)
    fi
    TOTAL_MEM=$(echo "$TOTAL_MEM + $val" | bc)
  fi
done < "$OUTPUT_DIR/memory-usage.csv"

if (( $(echo "$TOTAL_MEM >= 1024" | bc -l) )); then
  TOTAL_MEM_FMT=$(printf "%.2f GiB" $(echo "$TOTAL_MEM / 1024" | bc -l))
else
  TOTAL_MEM_FMT=$(printf "%.1f MiB" $TOTAL_MEM)
fi

echo ""
echo "Memory usage:"
column -t -s',' "$OUTPUT_DIR/memory-usage.csv"
echo "---"
echo "TOTAL: $TOTAL_MEM_FMT"

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