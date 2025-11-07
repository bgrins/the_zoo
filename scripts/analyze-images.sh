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
echo "Generated: $(date +%m/%d/%Y)"
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

    # Get image size from docker
    IMAGE_SIZE=$(docker images "$IMAGE" --format "{{.Size}}")
    SIZE_BYTES=$(size_to_bytes "$IMAGE_SIZE")

    # Run dive with CI mode to get JSON output
    DIVE_OUTPUT="$TEMP_DIR/dive-output-$IMAGE_COUNT.txt"

    # Run dive in CI mode with source set to docker (suppresses interactive mode)
    # Capture both stdout and stderr, ignore exit code as dive may fail on some images
    set +e
    dive "$IMAGE" --ci --lowestEfficiency=0 --highestWastedBytes=100000000000 > "$DIVE_OUTPUT" 2>&1
    DIVE_EXIT=$?
    set -e

    if [ $DIVE_EXIT -ne 0 ] && ! grep -q "efficiency:" "$DIVE_OUTPUT"; then
        echo "  ⚠️  Dive analysis failed, using basic info only"
        echo "$SIZE_BYTES|$IMAGE|$IMAGE_SIZE|N/A|N/A" >> "$DATA_FILE"
        continue
    fi

    # Extract metrics from dive output
    EFFICIENCY="N/A"
    WASTED_SPACE="N/A"

    # Extract efficiency percentage
    if grep -q "efficiency:" "$DIVE_OUTPUT"; then
        EFFICIENCY=$(grep "efficiency:" "$DIVE_OUTPUT" | sed 's/.*efficiency:\s*//' | sed 's/\s*$//' | awk '{print $1}')
    fi

    # Extract wasted space (prefer the human-readable format in parentheses)
    if grep -q "wastedBytes:" "$DIVE_OUTPUT"; then
        # Try to extract the human-readable version in parentheses first
        if grep "wastedBytes:" "$DIVE_OUTPUT" | grep -q "("; then
            WASTED_SPACE=$(grep "wastedBytes:" "$DIVE_OUTPUT" | sed 's/.*(\(.*\))/\1/')
        else
            # Fall back to bytes
            WASTED_SPACE=$(grep "wastedBytes:" "$DIVE_OUTPUT" | sed 's/.*wastedBytes:\s*//' | awk '{print $1 " " $2}')
        fi
    fi

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

    # Table header
    printf "%-50s | %-12s | %-15s | %-12s\n" "Image" "Size" "Wasted Space" "Efficiency"
    printf "%-50s-+-%-12s-+-%-15s-+-%-12s\n" \
        "$(printf '%50s' | tr ' ' '-')" \
        "$(printf '%12s' | tr ' ' '-')" \
        "$(printf '%15s' | tr ' ' '-')" \
        "$(printf '%12s' | tr ' ' '-')"

    # Sort by size (descending) and format table rows
    sort -t'|' -k1 -rn "$DATA_FILE" | while IFS='|' read -r SIZE_BYTES IMAGE IMAGE_SIZE WASTED_SPACE EFFICIENCY; do
        # Truncate image name if too long
        if [ ${#IMAGE} -gt 48 ]; then
            IMAGE_DISPLAY="${IMAGE:0:45}..."
        else
            IMAGE_DISPLAY="$IMAGE"
        fi

        # Format efficiency with % sign
        if [ "$EFFICIENCY" != "N/A" ]; then
            EFFICIENCY="${EFFICIENCY}%"
        fi

        printf "%-50s | %-12s | %-15s | %-12s\n" "$IMAGE_DISPLAY" "$IMAGE_SIZE" "$WASTED_SPACE" "$EFFICIENCY"
    done

    echo ""
    echo "Report generated by: $(basename "$0")"
    echo "See https://github.com/wagoodman/dive for details on metrics"
} | tee "$OUTPUT_FILE"

echo ""
echo "Report saved to: $OUTPUT_FILE"
