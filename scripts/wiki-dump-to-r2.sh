#!/bin/bash
# Script to download, compress with xz, and store Simple English Wikipedia dump in R2

set -e

# Configuration
DUMP_URL="https://dumps.wikimedia.org/simplewiki/latest/simplewiki-latest-pages-articles.xml.bz2"
DATE=$(date +%Y%m%d-%H%M%S)
TEMP_DIR="/tmp/wiki-dump-${DATE}"
DRY_RUN=false

# Parse command line arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [--dry-run]"
    echo ""
    echo "Download and archive Simple English Wikipedia dump to R2"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be uploaded without actually uploading"
    echo "  --help, -h   Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Download the latest Wikipedia dump (~311 MiB)"
    echo "  2. Convert from bz2 to xz compression (~213 MiB)"
    echo "  3. Upload to R2 with versioned filename"
    echo "  4. Update latest.txt pointer"
    exit 0
fi

if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY RUN MODE - No files will be uploaded${NC}"
fi

echo -e "${BLUE}Starting Simple English Wikipedia dump archive process...${NC}"

# Error handler
cleanup() {
    echo -e "${BLUE}Cleaning up...${NC}"
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# Create temp directory
mkdir -p "${TEMP_DIR}"

# Download the dump with progress
echo "Downloading Wikipedia dump..."
if ! curl -L --progress-bar "${DUMP_URL}" -o "${TEMP_DIR}/simplewiki-latest-pages-articles.xml.bz2"; then
    echo -e "${RED}Error: Failed to download Wikipedia dump${NC}"
    exit 1
fi

# Verify download
if [ ! -f "${TEMP_DIR}/simplewiki-latest-pages-articles.xml.bz2" ]; then
    echo -e "${RED}Error: Downloaded file not found${NC}"
    exit 1
fi

# Decompress bz2
echo "Decompressing bz2..."
if ! bunzip2 -k "${TEMP_DIR}/simplewiki-latest-pages-articles.xml.bz2"; then
    echo -e "${RED}Error: Failed to decompress bz2 file${NC}"
    exit 1
fi

# Compress with xz
echo "Compressing with xz (this may take a few minutes)..."
if ! xz -6 -T0 "${TEMP_DIR}/simplewiki-latest-pages-articles.xml"; then
    echo -e "${RED}Error: Failed to compress with xz${NC}"
    exit 1
fi

# Get file size and hash of xz file
FILE_SIZE=$(stat -f%z "${TEMP_DIR}/simplewiki-latest-pages-articles.xml.xz" 2>/dev/null || stat -c%s "${TEMP_DIR}/simplewiki-latest-pages-articles.xml.xz")
FILE_HASH=$(shasum -a 256 "${TEMP_DIR}/simplewiki-latest-pages-articles.xml.xz" | cut -d' ' -f1)
SHORT_HASH=${FILE_HASH:0:12}

echo -e "${GREEN}File size: $(numfmt --to=iec-i --suffix=B ${FILE_SIZE} 2>/dev/null || echo ${FILE_SIZE} bytes)${NC}"
echo -e "${GREEN}SHA256: ${FILE_HASH}${NC}"

# Verify file is under 300 MiB
if [ ${FILE_SIZE} -gt 314572800 ]; then
    echo -e "${RED}Error: Compressed file is still too large (${FILE_SIZE} bytes > 300 MiB)${NC}"
    exit 1
fi

# Create versioned filename
ARCHIVE_NAME="simplewiki-${DATE}-${SHORT_HASH}.xml.xz"
ARCHIVE_PATH="archives/wiki-dumps/${ARCHIVE_NAME}"

# Upload to R2
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}[DRY RUN] Would upload:${NC}"
    echo "  File: ${TEMP_DIR}/simplewiki-latest-pages-articles.xml.xz"
    echo "  To: the-zoo/${ARCHIVE_PATH}"
    echo "  Command: npx wrangler r2 object put 'the-zoo/${ARCHIVE_PATH}' --file '${TEMP_DIR}/simplewiki-latest-pages-articles.xml.xz' --remote"
    echo ""
    echo -e "${YELLOW}[DRY RUN] Would create latest.txt:${NC}"
    echo "  Content: ${ARCHIVE_NAME}"
    echo "  To: the-zoo/archives/wiki-dumps/latest.txt"
    echo "  Command: npx wrangler r2 object put 'the-zoo/archives/wiki-dumps/latest.txt' --file '${TEMP_DIR}/latest.txt' --remote"
else
    echo "Uploading to R2..."
    if ! npx wrangler r2 object put "the-zoo/${ARCHIVE_PATH}" --file "${TEMP_DIR}/simplewiki-latest-pages-articles.xml.xz" --remote; then
        echo -e "${RED}Error: Failed to upload to R2${NC}"
        exit 1
    fi

    # Create and upload latest.txt
    echo "${ARCHIVE_NAME}" > "${TEMP_DIR}/latest.txt"
    if ! npx wrangler r2 object put "the-zoo/archives/wiki-dumps/latest.txt" --file "${TEMP_DIR}/latest.txt" --remote; then
        echo -e "${RED}Error: Failed to upload latest.txt${NC}"
        exit 1
    fi
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${GREEN}✓ Dry run complete!${NC}"
    echo ""
    echo -e "${YELLOW}Files that would be uploaded:${NC}"
    echo "  1. Archive: https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/${ARCHIVE_PATH}"
    echo "  2. Latest pointer: https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/archives/wiki-dumps/latest.txt"
else
    echo -e "${GREEN}✓ Archive complete!${NC}"
    echo ""
    echo "Archive uploaded to:"
    echo "  https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/${ARCHIVE_PATH}"
    echo ""
    echo "Latest pointer:"
    echo "  https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/archives/wiki-dumps/latest.txt"
    echo ""
    echo "To use in wiki.zoo Dockerfile:"
    echo "  curl -L https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/archives/wiki-dumps/\$(curl -s https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/archives/wiki-dumps/latest.txt)"
fi