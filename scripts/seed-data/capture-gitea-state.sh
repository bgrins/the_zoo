#!/bin/bash
# Capture Gitea's golden state (database + app data)

set -euo pipefail

GITEA_DATA_DIR="sites/apps/gitea.zoo/data-golden"

echo "🔍 Capturing Gitea golden state..."

# Ensure gitea is running
if [ -z "$(docker compose ps -q --status running gitea-zoo)" ]; then
    echo "Starting gitea-zoo..."
    docker compose --profile on-demand up -d gitea-zoo

    # Wait for Gitea to be ready
    echo "Waiting for Gitea to initialize..."
    sleep 10
    until docker compose exec -T gitea-zoo wget -q -O /dev/null http://localhost:3000/api/v1/version 2>/dev/null; do
        echo "Waiting for Gitea..."
        sleep 2
    done
fi

echo "✓ Gitea is running"

# 1. Capture database state
echo "📊 Capturing database state..."
docker compose exec -T postgres pg_dump --no-acl -U gitea_user gitea_db \
    --exclude-table-data=public.auth_token --exclude-table-data=public.session \
    > core/postgres/seed/gitea.sql
echo "✓ Database dump saved to core/postgres/seed/gitea.sql"

# 2. Capture app data (config, JWT keys, avatars)
echo "📁 Capturing app data..."
rm -rf "$GITEA_DATA_DIR"
mkdir -p "$GITEA_DATA_DIR"

# Export only the app data (not git repositories - those are fetched in Docker build)
docker compose exec -T gitea-zoo tar -czf /tmp/gitea-app-data.tar.gz \
    -C /data \
    gitea/conf \
    gitea/jwt \
    gitea/avatars

docker compose cp gitea-zoo:/tmp/gitea-app-data.tar.gz "$GITEA_DATA_DIR/"
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
echo ""
echo "Next steps (gitea.sql and data-golden are baked into images at build time):"
echo "1. Rebuild postgres: docker compose build postgres && docker compose up -d postgres"
echo "2. Rebuild gitea-zoo: docker compose up -d gitea-zoo --build"
