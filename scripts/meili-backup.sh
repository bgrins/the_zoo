#!/bin/bash
# Meilisearch backup - creates a compressed backup inside the container

# This script runs INSIDE the Meilisearch container
# Usage: docker compose exec -T meilisearch sh < scripts/meili-backup.sh

# Create dump via API
TASK=$(curl -s -X POST "http://localhost:7700/dumps" -H "Authorization: Bearer zooMasterKey123456789")
TASK_UID=$(echo $TASK | sed -n 's/.*"taskUid":\([0-9]*\).*/\1/p')

echo "Creating dump (task $TASK_UID)..."

# Wait for completion
while [ "$(curl -s "http://localhost:7700/tasks/$TASK_UID" -H "Authorization: Bearer zooMasterKey123456789" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')" != "succeeded" ]; do 
  echo -n "."
  sleep 1
done
echo " done"

# Get dump UID and compress
DUMP_UID=$(curl -s "http://localhost:7700/tasks/$TASK_UID" -H "Authorization: Bearer zooMasterKey123456789" | sed -n 's/.*"dumpUid":"\([^"]*\)".*/\1/p')
BACKUP_NAME="meilisearch-backup-$(date +%Y%m%d-%H%M%S).gz"
gzip -c "/meili_data/dumps/${DUMP_UID}.dump" > "/tmp/${BACKUP_NAME}"

echo "Backup created: /tmp/${BACKUP_NAME}"
ls -lh "/tmp/${BACKUP_NAME}"