#!/bin/bash

# Enron Email Dataset Preparation Script
# Downloads the CMU Enron dataset, curates top users, rewrites addresses,
# imports into Stalwart via JMAP, then dumps the DB for golden-state seeding.
#
# Prerequisites:
#   - Docker environment running (npm start)
#   - stalwart and postgres containers healthy
#   - curl, jq, xz available on host
#
# Usage:
#   ./scripts/uploads/enron-prepare.sh
#
# Output:
#   scripts/uploads/enron/stalwart_enron.sql.xz  (compressed SQL dump)
#   Ready for upload to R2

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENRON_DIR="${SCRIPT_DIR}/enron"
DOWNLOAD_URL="https://www.cs.cmu.edu/~enron/enron_mail_20150507.tar.gz"
TARBALL="${ENRON_DIR}/enron_mail_20150507.tar.gz"
EXTRACTED_DIR="${ENRON_DIR}/maildir"
PROCESSED_DIR="${ENRON_DIR}/processed"
OUTPUT_SQL="${ENRON_DIR}/stalwart_enron.sql.xz"

# Stalwart API (accessible via zoo proxy)
STALWART_API="https://mail-api.zoo"
ADMIN_PASSWORD="zoo-mail-admin-pw"

# Zoo proxy — load port from .env if present, fall back to default 3128
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ZOO_PROXY_PORT="${ZOO_PROXY_PORT:-$(grep -E '^ZOO_PROXY_PORT=' "${REPO_ROOT}/.env" 2>/dev/null | cut -d= -f2 || echo "3128")}"
CURL_OPTS="--proxy http://localhost:${ZOO_PROXY_PORT} -k --silent"

# Enron domain in zoo
ENRON_DOMAIN="enron.zoo"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Top 20 most interesting Enron mailboxes (by volume and relevance)
# Format: directory-name|display-name|email-localpart
ENRON_USERS=(
    "allen-p|Phillip Allen|phillip.allen"
    "bass-e|Eric Bass|eric.bass"
    "beck-s|Sally Beck|sally.beck"
    "blair-l|Lynn Blair|lynn.blair"
    "campbell-l|Larry Campbell|larry.campbell"
    "cash-m|Michelle Cash|michelle.cash"
    "dasovich-j|Jeff Dasovich|jeff.dasovich"
    "davis-d|Dana Davis|dana.davis"
    "delainey-d|David Delainey|david.delainey"
    "derrick-j|James Derrick Jr.|james.derrick"
    "farmer-d|Daren Farmer|daren.farmer"
    "germany-c|Chris Germany|chris.germany"
    "griffith-j|John Griffith|john.griffith"
    "haedicke-m|Mark Haedicke|mark.haedicke"
    "kaminski-v|Vince Kaminski|vince.kaminski"
    "kitchen-l|Louise Kitchen|louise.kitchen"
    "lavorato-j|John Lavorato|john.lavorato"
    "lay-k|Kenneth Lay|kenneth.lay"
    "shackleton-s|Sara Shackleton|sara.shackleton"
    "skilling-j|Jeff Skilling|jeff.skilling"
)

# Standard password for all Enron accounts
ENRON_PASSWORD="EnronZoo.123"

# Maximum emails to import per folder per account (set to 0 for unlimited)
MAX_EMAILS_PER_FOLDER=${MAX_EMAILS_PER_FOLDER:-50}

create_directories() {
    log "Creating directory structure..."
    mkdir -p "${ENRON_DIR}" "${PROCESSED_DIR}"
    success "Directory structure created"
}

download_dataset() {
    if [[ -f "${TARBALL}" ]]; then
        warn "Tarball already exists: ${TARBALL}"
        log "Skipping download. Delete the file to re-download."
        return 0
    fi

    log "Downloading Enron email dataset (~423 MB)..."
    log "Source: ${DOWNLOAD_URL}"
    curl -L -o "${TARBALL}" "${DOWNLOAD_URL}" --progress-bar -C - --retry 3 --retry-delay 5
    success "Download completed"
}

extract_dataset() {
    if [[ -d "${EXTRACTED_DIR}" ]]; then
        warn "Extracted directory already exists. Skipping extraction."
        return 0
    fi

    log "Extracting dataset..."
    cd "${ENRON_DIR}"
    tar -xzf "$(basename "${TARBALL}")"

    # The tarball extracts to enron_mail_20150507/maildir/
    if [[ -d "enron_mail_20150507/maildir" ]]; then
        mv enron_mail_20150507/maildir .
        rm -rf enron_mail_20150507
    fi

    success "Extraction completed"
}

rewrite_addresses() {
    log "Rewriting @enron.com addresses to @${ENRON_DOMAIN}..."

    for user_entry in "${ENRON_USERS[@]}"; do
        IFS='|' read -r dir_name display_name email_local <<< "$user_entry"

        local src_dir="${EXTRACTED_DIR}/${dir_name}"
        local dst_dir="${PROCESSED_DIR}/${email_local}"

        if [[ ! -d "$src_dir" ]]; then
            warn "User directory not found: ${src_dir}, skipping"
            continue
        fi

        log "  Processing ${display_name} (${dir_name})..."

        # Copy the user's maildir
        rm -rf "$dst_dir"
        cp -r "$src_dir" "$dst_dir"

        # Rewrite @enron.com to @enron.zoo in all email files
        find "$dst_dir" -type f | while read -r file; do
            # Only rewrite in header-relevant lines and body
            sed -i \
                -e 's/@enron\.com/@enron.zoo/gi' \
                "$file" 2>/dev/null || true
        done
    done

    success "Address rewriting completed"
}

create_stalwart_domain() {
    log "Creating domain ${ENRON_DOMAIN} in Stalwart..."
    local response
    response=$(curl $CURL_OPTS -o /dev/null -w "%{http_code}" \
        -u "admin:${ADMIN_PASSWORD}" \
        -X POST "${STALWART_API}/api/principal" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"domain\",
            \"name\": \"${ENRON_DOMAIN}\",
            \"description\": \"Enron email dataset domain\"
        }")

    if [[ "$response" == "200" || "$response" == "201" || "$response" == "409" ]]; then
        success "Domain ${ENRON_DOMAIN} ready"
    else
        error "Failed to create domain (HTTP ${response})"
        exit 1
    fi
}

create_stalwart_users() {
    log "Creating Enron user accounts..."

    for user_entry in "${ENRON_USERS[@]}"; do
        IFS='|' read -r dir_name display_name email_local <<< "$user_entry"
        local email="${email_local}@${ENRON_DOMAIN}"

        local salt
        salt=$(openssl rand -base64 12 | tr -d '=+/')
        local hashed_password
        hashed_password=$(openssl passwd -6 -salt "$salt" "$ENRON_PASSWORD")

        local response
        response=$(curl $CURL_OPTS -o /dev/null -w "%{http_code}" \
            -u "admin:${ADMIN_PASSWORD}" \
            -X POST "${STALWART_API}/api/principal" \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"individual\",
                \"name\": \"${email}\",
                \"description\": \"${display_name}\",
                \"secrets\": [\"${hashed_password}\"],
                \"emails\": [\"${email}\"],
                \"quota\": 0,
                \"roles\": [\"user\"],
                \"lists\": [],
                \"members\": [],
                \"memberOf\": [],
                \"enabledPermissions\": [],
                \"disabledPermissions\": [],
                \"externalMembers\": []
            }")

        if [[ "$response" == "200" || "$response" == "201" ]]; then
            log "  ✓ Created ${email}"
        elif [[ "$response" == "409" ]]; then
            log "  ✓ ${email} already exists"
        else
            warn "  ✗ Failed to create ${email} (HTTP ${response})"
        fi
    done

    success "User accounts created"
}

import_emails() {
    log "Importing emails via JMAP (Python script)..."

    # Prefer processed dir (rewritten addresses), fall back to raw extracted dir
    local dataset_dir="${PROCESSED_DIR}"
    if [[ ! -d "$dataset_dir" ]] || [[ -z "$(ls -A "$dataset_dir" 2>/dev/null)" ]]; then
        dataset_dir="${EXTRACTED_DIR}"
    fi

    if [[ ! -d "$dataset_dir" ]]; then
        error "No dataset directory found at ${PROCESSED_DIR} or ${EXTRACTED_DIR}"
        exit 1
    fi

    log "Using dataset: ${dataset_dir}"
    log "Max emails per folder: ${MAX_EMAILS_PER_FOLDER}"

    # The JMAP importer needs 'requests' — install if missing
    python3 -c "import requests" 2>/dev/null || {
        log "Installing Python requests library..."
        pip3 install --quiet requests
    }

    ZOO_PROXY_URL="http://localhost:${ZOO_PROXY_PORT}" \
    python3 "${SCRIPT_DIR}/enron-import-jmap.py" \
        --dataset "$dataset_dir" \
        --target-domain "${ENRON_DOMAIN}" \
        --password "${ENRON_PASSWORD}" \
        --max-per-folder "${MAX_EMAILS_PER_FOLDER}" \
        --verbose

    success "JMAP email import completed"
}

dump_database() {
    log "Dumping stalwart database with Enron data..."

    # Dump the stalwart_db from the postgres container
    docker compose exec -T postgres \
        pg_dump -U stalwart_user -d stalwart_db \
        --no-owner --no-privileges \
        > "${ENRON_DIR}/stalwart_enron.sql"

    log "Compressing dump..."
    xz -9 -f "${ENRON_DIR}/stalwart_enron.sql"

    local size
    size=$(du -h "${OUTPUT_SQL}" | cut -f1)
    success "Database dump created: ${OUTPUT_SQL} (${size})"

    # Copy into postgres seed dir so builds work without R2
    local seed_dest="${REPO_ROOT}/core/postgres/seed/stalwart_enron.sql.xz"
    cp "${OUTPUT_SQL}" "${seed_dest}"
    success "Copied to ${seed_dest} (local builds will use this automatically)"

    echo ""
    log "To also upload to R2 for shared/CI use, run:"
    echo "  rclone copy ${OUTPUT_SQL} r2:the-zoo/enron/ -v --progress"
    echo ""
    log "R2 URL (once uploaded):"
    echo "  https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/enron/stalwart_enron.sql.xz"
}

# Main execution
main() {
    log "=== Enron Email Dataset Preparation ==="
    echo ""

    create_directories
    download_dataset
    extract_dataset
    rewrite_addresses
    create_stalwart_domain
    create_stalwart_users
    import_emails
    dump_database

    echo ""
    success "=== Enron preparation complete! ==="
    echo ""
    log "Next steps:"
    echo "  1. Upload the SQL dump to R2 (see command above)"
    echo "  2. Build postgres with: ENRON_SEED=true docker compose build postgres"
    echo "  3. Restart: docker compose up -d"
    echo "  4. Login to snappymail.zoo with e.g. kenneth.lay@enron.zoo / ${ENRON_PASSWORD}"
}

main "$@"
