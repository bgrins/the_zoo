#!/usr/bin/env bash
set -euo pipefail

echo "📊 Capturing Matomo Analytics Golden State"
echo "==========================================="

# Check if containers are running
if ! docker compose ps mysql-analytics | grep -q "Up"; then
  echo "❌ mysql-analytics container is not running"
  echo "Start it with: docker compose --profile on-demand up -d mysql-analytics"
  exit 1
fi

if ! docker compose ps analytics-zoo | grep -q "Up"; then
  echo "❌ analytics-zoo container is not running"
  echo "Start it with: docker compose --profile on-demand up -d analytics-zoo"
  exit 1
fi

# Create directories
mkdir -p core/mysql-analytics/seed
mkdir -p sites/apps/analytics.zoo/data-golden

echo ""
echo "1️⃣ Capturing MySQL database state..."
docker exec the_zoo-mysql-analytics-1 mysqldump \
  -u analytics_user \
  -panalytics_pw \
  analytics_db \
  > core/mysql-analytics/seed/analytics.sql

echo "✅ Database dump saved to core/mysql-analytics/seed/analytics.sql"
echo "   Size: $(du -h core/mysql-analytics/seed/analytics.sql | cut -f1)"

echo ""
echo "2️⃣ Capturing Matomo application data..."
# Capture config, but exclude cache and tmp
docker exec the_zoo-analytics-zoo-1 tar -czf /tmp/matomo-golden.tar.gz \
  -C /var/www/html \
  --exclude='tmp' \
  --exclude='matomo.js' \
  config

# Extract from container
docker cp the_zoo-analytics-zoo-1:/tmp/matomo-golden.tar.gz /tmp/matomo-golden.tar.gz

# Extract to golden state directory
tar -xzf /tmp/matomo-golden.tar.gz -C sites/apps/analytics.zoo/data-golden/

# Cleanup
rm /tmp/matomo-golden.tar.gz
docker exec the_zoo-analytics-zoo-1 rm /tmp/matomo-golden.tar.gz

echo "✅ Matomo config saved to sites/apps/analytics.zoo/data-golden/"

echo ""
echo "✨ Golden state captured successfully!"
echo ""
echo "Next steps:"
echo "1. Review the captured files"
echo "2. Commit to git: git add core/mysql-analytics sites/apps/analytics.zoo/data-golden"
echo "3. Update mysql-analytics container to load seed on first start"
