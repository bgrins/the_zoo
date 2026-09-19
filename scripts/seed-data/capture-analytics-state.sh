#!/usr/bin/env bash
set -euo pipefail

echo "📊 Capturing Matomo Analytics Golden State"
echo "==========================================="

# Check if containers are running
if ! docker compose ps mysql | grep -q "Up"; then
  echo "❌ mysql container is not running"
  echo "Start it with: npm start"
  exit 1
fi

if ! docker compose ps analytics-zoo | grep -q "Up"; then
  echo "❌ analytics-zoo container is not running"
  echo "Start it with: docker compose --profile on-demand up -d analytics-zoo"
  exit 1
fi

# Create directories
mkdir -p sites/apps/analytics.zoo/data-golden

echo ""
echo "1️⃣ Capturing MySQL database state..."
docker compose exec -T mysql mysqldump \
  -h 127.0.0.1 \
  -u root \
  -ppassword \
  analytics_db \
  > core/mysql/sql/analytics_seed.sql

if [ $? -eq 0 ]; then
  echo "✅ Database dump saved to core/mysql/sql/analytics_seed.sql"
  echo "   Size: $(du -h core/mysql/sql/analytics_seed.sql | cut -f1)"
else
  echo "❌ Database dump failed!"
  exit 1
fi

echo ""
echo "2️⃣ Capturing Matomo application data..."
# Only capture config.ini.php (other config files come with base Matomo image)
mkdir -p sites/apps/analytics.zoo/data-golden/config
docker compose cp analytics-zoo:/var/www/html/config/config.ini.php \
  sites/apps/analytics.zoo/data-golden/config/config.ini.php

echo "✅ Matomo config saved to sites/apps/analytics.zoo/data-golden/config/config.ini.php"

echo ""
echo "✨ Golden state captured successfully!"
echo ""
echo "Next steps:"
echo "1. Review the captured files"
echo "2. Commit to git: git add core/mysql/sql/analytics_seed.sql sites/apps/analytics.zoo/data-golden"
echo "3. Rebuild mysql (analytics_seed.sql is baked into its image): docker compose build mysql && docker compose up -d mysql"
echo "4. Rebuild analytics-zoo: docker compose up -d analytics-zoo --build"
