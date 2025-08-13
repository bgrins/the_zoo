#!/bin/bash

# Wikipedia Simple English Download Script
# Downloads and organizes Wikipedia Simple English ZIM files

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${SCRIPT_DIR}"
WIKI_DIR="${BASE_DIR}/wikipedia"
SIMPLE_EN_DIR="${WIKI_DIR}/simple-en"

# File information
ZIM_FILE="wikipedia_en_simple_all_nopic_2024-06.zim"
DOWNLOAD_URL="https://download.kiwix.org/zim/wikipedia/${ZIM_FILE}"
TARGET_PATH="${SIMPLE_EN_DIR}/${ZIM_FILE}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create directory structure
create_directories() {
    log "Creating directory structure..."
    mkdir -p "${SIMPLE_EN_DIR}"
    
    
    success "Directory structure created at ${SIMPLE_EN_DIR}"
}

# Download file with progress
download_file() {
    if [[ -f "${TARGET_PATH}" ]]; then
        warn "File already exists: ${TARGET_PATH}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Download cancelled"
            return 0
        fi
    fi
    
    log "Downloading ${ZIM_FILE}..."
    log "Source: ${DOWNLOAD_URL}"
    log "Target: ${TARGET_PATH}"
    
    if curl -L -o "${TARGET_PATH}" "${DOWNLOAD_URL}" --progress-bar -C - --retry 3 --retry-delay 1; then
        success "Download completed successfully"
        
        # Show file info
        log "File information:"
        ls -lh "${TARGET_PATH}"
        
        # Generate checksums
        log "Generating checksums..."
        (
            cd "${SIMPLE_EN_DIR}"
            shasum -a 256 "${ZIM_FILE}" > "${ZIM_FILE}.sha256"
            md5 "${ZIM_FILE}" > "${ZIM_FILE}.md5"
        )
        success "Checksums generated"
        
        # Show upload instructions
        echo ""
        log "To upload to R2, run:"
        echo "  rclone copy ${WIKI_DIR}/ r2:the-zoo/wiki/ -v --progress"
        echo ""
        log "Files will be available at:"
        echo "  https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/wiki/wikipedia/simple-en/${ZIM_FILE}"
    else
        error "Download failed"
        return 1
    fi
}

# Main execution
main() {
    log "Starting Wikipedia Simple English download process"
    
    create_directories
    download_file
    
    success "Download process completed successfully!"
    log "Local files are at: ${SIMPLE_EN_DIR}"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo ""
        echo "Downloads Wikipedia Simple English ZIM file."
        echo "Use rclone commands (shown after download) to upload to R2."
        echo ""
        echo "Options:"
        echo "  --help, -h       Show this help message"
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac