#!/bin/bash
set -euo pipefail

# Script to analyze all Docker images in docker-compose.yaml using dive
# Requires: dive, docker, yq (or jq for parsing YAML)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yaml"
OUTPUT_FILE="${1:-$PROJECT_ROOT/docs/image-analysis-report.txt}"

echo "==================================================================="
echo "Docker Image Analysis Report"
echo "==================================================================="
echo ""

# Check if dive is installed
if ! command -v dive &> /dev/null; then
    echo "ERROR: 'dive' is not installed."
    echo "Install it from: https://github.com/wagoodman/dive"
    echo ""
    echo "macOS: brew install dive"
    echo "Linux: wget https://github.com/wagoodman/dive/releases/download/v0.12.0/dive_0.12.0_linux_amd64.deb && sudo dpkg -i dive_0.12.0_linux_amd64.deb"
    exit 1
fi

# Extract actual images from docker compose
# This will include both pulled images and locally built ones
echo "Extracting images from docker compose..."

# Check if docker compose project exists
if ! docker compose -f "$COMPOSE_FILE" config &> /dev/null; then
    echo "ERROR: Could not parse docker-compose.yaml"
    exit 1
fi

# Get images from docker compose (includes both pulled and built images)
IMAGES=$(docker compose -f "$COMPOSE_FILE" images --format json 2>/dev/null | jq -r '.[] | .Repository + ":" + .Tag' | sort -u)

if [ -z "$IMAGES" ]; then
    echo "No images found"
    exit 1
fi

echo "Found $(echo "$IMAGES" | wc -l | tr -d ' ') unique images"
echo ""

# Create temporary directory for dive output
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Analyze each image and store data in temp file
IMAGE_COUNT=0
DATA_FILE="$TEMP_DIR/image-data.txt"

# Function to convert size to bytes for sorting
size_to_bytes() {
    local size="$1"
    local number=$(echo "$size" | sed 's/[^0-9.]*//g')
    local unit=$(echo "$size" | sed 's/[0-9.]*//g' | tr '[:lower:]' '[:upper:]')

    case "$unit" in
        GB|G) echo "$number * 1024 * 1024 * 1024" | bc | cut -d. -f1 ;;
        MB|M) echo "$number * 1024 * 1024" | bc | cut -d. -f1 ;;
        KB|K) echo "$number * 1024" | bc | cut -d. -f1 ;;
        B|*) echo "$number" | cut -d. -f1 ;;
    esac
}

# Function to convert bytes to human readable format
bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc)GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc)MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=1; $bytes / 1024" | bc)kB"
    else
        echo "${bytes}B"
    fi
}

while IFS= read -r IMAGE; do
    if [ -z "$IMAGE" ]; then
        continue
    fi

    IMAGE_COUNT=$((IMAGE_COUNT + 1))
    echo "[$IMAGE_COUNT] Analyzing: $IMAGE"

    # Check if image exists locally
    if ! docker image inspect "$IMAGE" &> /dev/null; then
        echo "  ⚠️  Image not found locally, skipping..."
        echo "0|$IMAGE|NOT FOUND|N/A|N/A" >> "$DATA_FILE"
        continue
    fi

    # Run dive with JSON output to get all metrics
    DIVE_JSON="$TEMP_DIR/dive-output-$IMAGE_COUNT.json"

    # Run dive with JSON output
    set +e
    dive "$IMAGE" --json "$DIVE_JSON" > /dev/null 2>&1
    DIVE_EXIT=$?
    set -e

    if [ $DIVE_EXIT -ne 0 ] || [ ! -f "$DIVE_JSON" ]; then
        echo "  ⚠️  Dive analysis failed"
        echo "0|$IMAGE|N/A|N/A|N/A" >> "$DATA_FILE"
        continue
    fi

    # Extract metrics from JSON using jq
    SIZE_BYTES=$(jq -r '.image.sizeBytes' "$DIVE_JSON")
    WASTED_BYTES=$(jq -r '.image.inefficientBytes' "$DIVE_JSON")
    EFFICIENCY_SCORE=$(jq -r '.image.efficiencyScore' "$DIVE_JSON")

    IMAGE_SIZE=$(bytes_to_human "$SIZE_BYTES")
    WASTED_SPACE=$(bytes_to_human "$WASTED_BYTES")

    # Convert efficiency to percentage
    EFFICIENCY=$(echo "$EFFICIENCY_SCORE * 100" | bc -l | xargs printf "%.4f")

    echo "  ✓ Size: $IMAGE_SIZE, Efficiency: $EFFICIENCY%, Wasted: $WASTED_SPACE"

    # Store: size_bytes|image_name|image_size|wasted_space|efficiency
    echo "$SIZE_BYTES|$IMAGE|$IMAGE_SIZE|$WASTED_SPACE|$EFFICIENCY" >> "$DATA_FILE"

done <<< "$IMAGES"

# Generate sorted table report
{
    echo "==================================================================="
    echo "Docker Image Analysis Report"
    echo "Generated: $(date)"
    echo "Total images analyzed: $IMAGE_COUNT"
    echo "==================================================================="
    echo ""

    # Find the longest image name for dynamic column width
    MAX_NAME_LEN=50
    while IFS='|' read -r _ IMAGE _ _ _; do
        NAME_LEN=${#IMAGE}
        if [ "$NAME_LEN" -gt "$MAX_NAME_LEN" ]; then
            MAX_NAME_LEN=$NAME_LEN
        fi
    done < "$DATA_FILE"

    # Table header
    printf "%-${MAX_NAME_LEN}s | %-12s | %-15s | %-12s\n" "Image" "Size" "Wasted Space" "Efficiency"
    printf "%-${MAX_NAME_LEN}s-+-%-12s-+-%-15s-+-%-12s\n" \
        "$(printf "%${MAX_NAME_LEN}s" | tr ' ' '-')" \
        "$(printf '%12s' | tr ' ' '-')" \
        "$(printf '%15s' | tr ' ' '-')" \
        "$(printf '%12s' | tr ' ' '-')"

    # Sort by size (descending) and format table rows
    TOTAL_BYTES=0
    sort -t'|' -k1 -rn "$DATA_FILE" | while IFS='|' read -r SIZE_BYTES IMAGE IMAGE_SIZE WASTED_SPACE EFFICIENCY; do
        # Format efficiency with % sign
        if [ "$EFFICIENCY" != "N/A" ]; then
            EFFICIENCY="${EFFICIENCY}%"
        fi

        printf "%-${MAX_NAME_LEN}s | %-12s | %-15s | %-12s\n" "$IMAGE" "$IMAGE_SIZE" "$WASTED_SPACE" "$EFFICIENCY"
    done

    # Calculate total size
    TOTAL_BYTES=$(awk -F'|' '$1 ~ /^[0-9]+$/ {sum += $1} END {print sum}' "$DATA_FILE")
    TOTAL_SIZE=$(bytes_to_human "$TOTAL_BYTES")

    echo ""
    printf "%-${MAX_NAME_LEN}s   %-12s\n" "Total:" "$TOTAL_SIZE"
    echo ""
    echo "Report generated by: $(basename "$0")"
    echo "See https://github.com/wagoodman/dive for details on metrics"
} | tee "$OUTPUT_FILE"

echo ""
echo "Report saved to: $OUTPUT_FILE"
