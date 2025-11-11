#!/bin/bash
set -euo pipefail

# Postmill Database Analysis Script
# Analyzes the postmill database for data quality and optimization opportunities

echo "=========================================="
echo "Postmill Database Analysis Report"
echo "=========================================="
echo ""

# Check if postgres is running
if ! docker compose ps postgres | grep -q "Up"; then
    echo "Error: Postgres container is not running"
    exit 1
fi

echo "📊 Database Overview"
echo "===================="
docker compose exec postgres psql -U postgres -d postmill_db -t -c "
    SELECT
        'Total Size: ' || pg_size_pretty(pg_database_size('postmill_db')) ||
        E'\nTotal Forums: ' || (SELECT COUNT(*) FROM forums) ||
        E'\nTotal Users: ' || (SELECT COUNT(*) FROM users) ||
        E'\nTotal Submissions: ' || (SELECT COUNT(*) FROM submissions) ||
        E'\nTotal Comments: ' || (SELECT COUNT(*) FROM comments);
"
echo ""

echo "🏛️  Forum (Subreddit) Statistics"
echo "================================"
echo ""
echo "Top 15 Forums by Activity:"
docker compose exec postgres psql -U postmill_user -d postmill_db -c "
SELECT
    RPAD(f.name, 25) as forum,
    LPAD(COUNT(DISTINCT s.id)::text, 6) as subs,
    LPAD(COUNT(DISTINCT c.id)::text, 8) as comments,
    LPAD((COUNT(DISTINCT s.id) + COUNT(DISTINCT c.id))::text, 10) as total
FROM forums f
LEFT JOIN submissions s ON s.forum_id = f.id
LEFT JOIN comments c ON c.submission_id = s.id
GROUP BY f.id, f.name
ORDER BY (COUNT(DISTINCT s.id) + COUNT(DISTINCT c.id)) DESC
LIMIT 15;
" | tail -n +3
echo ""

echo "Top 10 Forums by Comment Data Size:"
docker compose exec postgres psql -U postmill_user -d postmill_db -c "
SELECT
    RPAD(f.name, 25) as forum,
    LPAD(COUNT(DISTINCT c.id)::text, 8) as comments,
    RPAD(pg_size_pretty(SUM(pg_column_size(c.body))::bigint), 12) as data_size
FROM forums f
LEFT JOIN submissions s ON s.forum_id = f.id
LEFT JOIN comments c ON c.submission_id = s.id
GROUP BY f.id, f.name
ORDER BY SUM(pg_column_size(c.body)) DESC NULLS LAST
LIMIT 10;
" | tail -n +3
echo ""

echo "📅 Forum Timeline:"
docker compose exec postgres psql -U postmill_user -d postmill_db -t -c "
SELECT
    'Oldest Forum: ' || TO_CHAR(MIN(created), 'YYYY-MM-DD') ||
    E'\nNewest Forum: ' || TO_CHAR(MAX(created), 'YYYY-MM-DD') ||
    E'\nFeatured Forums: ' || COUNT(*) FILTER (WHERE featured = true)
FROM forums;
"
echo ""

echo "👥 User Activity Analysis"
echo "========================="
docker compose exec postgres psql -U postmill_user -d postmill_db -t -c "
SELECT
    COUNT(DISTINCT u.id)::text || ' total users' ||
    E'\n' || COUNT(DISTINCT CASE WHEN s.id IS NULL AND c.id IS NULL AND sv.id IS NULL AND cv.id IS NULL THEN u.id END)::text ||
    ' users with NO activity (' ||
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN s.id IS NULL AND c.id IS NULL AND sv.id IS NULL AND cv.id IS NULL THEN u.id END) / COUNT(DISTINCT u.id), 1) || '%)'
FROM users u
LEFT JOIN submissions s ON s.user_id = u.id
LEFT JOIN comments c ON c.user_id = u.id
LEFT JOIN submission_votes sv ON sv.user_id = u.id
LEFT JOIN comment_votes cv ON cv.user_id = u.id;
"
echo ""

echo "🔍 Data Quality Checks"
echo "======================"
echo ""

echo -n "Forums with zero activity: "
docker compose exec postgres psql -U postmill_user -d postmill_db -t -c "
SELECT COUNT(*)
FROM forums f
LEFT JOIN submissions s ON s.forum_id = f.id
LEFT JOIN comments c ON c.submission_id = s.id
GROUP BY f.id
HAVING COUNT(DISTINCT s.id) = 0 AND COUNT(DISTINCT c.id) = 0;
"

echo -n "Hidden/archived forums: "
docker compose exec postgres psql -U postmill_user -d postmill_db -t -c "SELECT COUNT(*) FROM hidden_forums;"

echo -n "Orphaned comments (no submission): "
docker compose exec postgres psql -U postmill_user -d postmill_db -t -c "
SELECT COUNT(*)
FROM comments c
LEFT JOIN submissions s ON c.submission_id = s.id
WHERE s.id IS NULL;
"

echo -n "Soft-deleted comments: "
docker compose exec postgres psql -U postmill_user -d postmill_db -t -c "
SELECT COUNT(*) FROM comments WHERE visibility = 'soft_deleted';
"

echo -n "Trashed comments: "
docker compose exec postgres psql -U postmill_user -d postmill_db -t -c "
SELECT COUNT(*) FROM comments WHERE visibility = 'trashed';
"
echo ""

echo "💾 Table Size Breakdown"
echo "======================="
docker compose exec postgres psql -U postmill_user -d postmill_db -c "
SELECT
    RPAD(tablename, 25) as table_name,
    RPAD(pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)), 12) as total_size,
    RPAD(pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)), 12) as table_size,
    RPAD(pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)), 12) as index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
" | tail -n +3
echo ""

echo "=========================================="
echo "Report Complete"
echo "=========================================="
