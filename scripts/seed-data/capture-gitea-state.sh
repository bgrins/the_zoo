#!/bin/bash
# Capture Gitea's golden state (database + app data)

set -euo pipefail

GITEA_CONTAINER="the_zoo-gitea-zoo-1"
POSTGRES_CONTAINER="the_zoo-postgres-1"
GITEA_DATA_DIR="sites/apps/gitea.zoo/data-golden"

echo "🔍 Capturing Gitea golden state..."

# Ensure gitea is running
if ! docker ps --format '{{.Names}}' | grep -q "^${GITEA_CONTAINER}$"; then
    echo "Starting gitea-zoo..."
    docker compose --profile on-demand up -d gitea-zoo

    # Wait for Gitea to be ready
    echo "Waiting for Gitea to initialize..."
    sleep 10
    until docker exec "$GITEA_CONTAINER" wget -q -O /dev/null http://localhost:3000/api/v1/version 2>/dev/null; do
        echo "Waiting for Gitea..."
        sleep 2
    done
fi

echo "✓ Gitea is running"

# 1. Capture database state
echo "📊 Capturing database state..."
docker exec "$POSTGRES_CONTAINER" pg_dump --no-acl -U gitea_user gitea_db > core/postgres/seed/gitea.sql
echo "✓ Database dump saved to core/postgres/seed/gitea.sql"

# 2. Capture app data (config, JWT keys, avatars)
echo "📁 Capturing app data..."
rm -rf "$GITEA_DATA_DIR"
mkdir -p "$GITEA_DATA_DIR"

# Export only the app data (not git repositories - those are fetched in Docker build)
docker exec "$GITEA_CONTAINER" tar -czf /tmp/gitea-app-data.tar.gz \
    -C /data \
    gitea/conf \
    gitea/jwt \
    gitea/avatars

docker cp "$GITEA_CONTAINER:/tmp/gitea-app-data.tar.gz" "$GITEA_DATA_DIR/"
cd "$GITEA_DATA_DIR" && tar -xzf gitea-app-data.tar.gz && rm gitea-app-data.tar.gz
cd - > /dev/null

echo "✓ App data saved to $GITEA_DATA_DIR"
du -sh "$GITEA_DATA_DIR" 2>/dev/null || true

echo ""
echo "✅ Gitea golden state captured successfully!"
echo ""
echo "Contents:"
echo "  - Database: core/postgres/seed/gitea.sql"
echo "  - App data: $GITEA_DATA_DIR"
echo "    - gitea/conf/app.ini (config with INSTALL_LOCK=true)"
echo "    - gitea/jwt/private.pem (JWT signing key)"
echo "    - gitea/avatars/* (user/org avatars)"
echo ""
echo "Note: Git repositories are baked into Docker image (not in golden state)"
echo "Note: /data is wiped on every startup; import-repos.sh registers repos missing from the DB"
