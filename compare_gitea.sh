#!/bin/bash

# Restore snapshot and compare with current database

DB_NAME="gitea_db"
SNAPSHOT_FILE="/var/lib/postgresql/snapshots/${DB_NAME}.sql.xz"
SNAPSHOT_DB="${DB_NAME}_snapshot"

echo "Restoring snapshot from $SNAPSHOT_FILE..."

# Drop and recreate snapshot database
docker compose exec -T postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS $SNAPSHOT_DB;" -c "CREATE DATABASE $SNAPSHOT_DB;"

# Restore snapshot
docker compose exec -T postgres sh -c "xz -dc $SNAPSHOT_FILE | psql -U postgres -d $SNAPSHOT_DB -q"

echo "Snapshot restored. Comparing databases..."

# Get snapshot counts
snapshot=$(docker compose exec -T postgres psql -U postgres -d $SNAPSHOT_DB -t -A -F'|' << 'EOF'
SELECT relname, n_live_tup FROM pg_stat_user_tables WHERE schemaname = 'public' ORDER BY relname;
EOF
)

# Get current counts
current=$(docker compose exec -T postgres psql -U postgres -d $DB_NAME -t -A -F'|' << 'EOF'
SELECT relname, n_live_tup FROM pg_stat_user_tables WHERE schemaname = 'public' ORDER BY relname;
EOF
)

# Compare using Python
python3 << PYTHON
import sys

snapshot_data = """$snapshot"""
current_data = """$current"""

# Parse snapshot
snapshot_dict = {}
for line in snapshot_data.strip().split('\n'):
    if '|' in line:
        table, count = line.strip().split('|')
        snapshot_dict[table] = int(count)

# Parse current
current_dict = {}
for line in current_data.strip().split('\n'):
    if '|' in line:
        table, count = line.strip().split('|')
        current_dict[table] = int(count)

# Find differences
all_tables = set(snapshot_dict.keys()) | set(current_dict.keys())
differences = []

for table in all_tables:
    snapshot_count = snapshot_dict.get(table, 0)
    current_count = current_dict.get(table, 0)
    if snapshot_count != current_count:
        diff = current_count - snapshot_count
        differences.append((table, snapshot_count, current_count, diff))

# Sort by absolute difference
differences.sort(key=lambda x: abs(x[3]), reverse=True)

if differences:
    print(f"{'Table':<40} {'Snapshot':<12} {'Current':<12} {'Diff':<12}")
    print("-" * 80)
    for table, snap, curr, diff in differences:
        sign = "+" if diff > 0 else ""
        print(f"{table:<40} {snap:<12} {curr:<12} {sign}{diff:<12}")
else:
    print("No differences found")
PYTHON

echo ""
echo "Cleaning up snapshot database..."
docker compose exec -T postgres psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS $SNAPSHOT_DB;"
