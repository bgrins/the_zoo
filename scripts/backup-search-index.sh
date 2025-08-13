#!/bin/bash
# Create and download Meilisearch backup

set -e

echo "Creating Meilisearch backup..."

# Run backup script inside container
docker compose exec -T meilisearch sh < scripts/meili-backup.sh

# Get the latest backup file name
BACKUP_FILE=$(docker compose exec -T meilisearch sh -c 'ls -t /tmp/meilisearch-backup-*.gz 2>/dev/null | head -1')

if [ -z "$BACKUP_FILE" ]; then
  echo "Error: No backup file found"
  exit 1
fi

# Copy backup to host
echo "Copying backup to host..."
mkdir -p ./data/meilisearch
docker cp "thezoo-meilisearch-1:${BACKUP_FILE}" "./data/meilisearch/"

echo "Backup saved to: ./data/meilisearch/$(basename $BACKUP_FILE)"