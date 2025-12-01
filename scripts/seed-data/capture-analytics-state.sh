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
docker exec the_zoo-mysql-1 mysqldump \
  -u analytics_user \
  -panalytics_pw \
  analytics_db \
  > core/mysql/sql/analytics_seed.sql

echo "✅ Database dump saved to core/mysql/sql/analytics_seed.sql"
echo "   Size: $(du -h core/mysql/sql/analytics_seed.sql | cut -f1)"

echo ""
echo "2️⃣ Capturing Matomo application data..."
# Only capture config.ini.php (other config files come with base Matomo image)
mkdir -p sites/apps/analytics.zoo/data-golden/config
docker cp the_zoo-analytics-zoo-1:/var/www/html/config/config.ini.php \
  sites/apps/analytics.zoo/data-golden/config/config.ini.php

echo "✅ Matomo config saved to sites/apps/analytics.zoo/data-golden/config/config.ini.php"

echo ""
echo "✨ Golden state captured successfully!"
echo ""
echo "Next steps:"
echo "1. Review the captured files"
echo "2. Commit to git: git add core/mysql/sql/analytics_seed.sql sites/apps/analytics.zoo/data-golden"
echo "3. Rebuild containers: docker compose up -d analytics-zoo --build"
