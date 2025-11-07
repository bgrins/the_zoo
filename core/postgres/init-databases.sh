#!/bin/bash
set -euo pipefail

# Helper function to create a database with standardized naming convention
# Usage: create_db_for_site "sitename"
# Creates: sitename_db, sitename_user, sitename_pw
create_db_for_site() {
    local site=$1
    local db_name="${site}_db"
    local db_user="${site}_user"
    local db_pass="${site}_pw"
    
    echo "Creating database for site: $site"
    
    psql -q -v ON_ERROR_STOP=1 -U postgres <<-EOSQL
        -- Drop existing connections
        SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = '$db_name' AND pid <> pg_backend_pid();
        
        -- Drop if exists for idempotency
        DROP DATABASE IF EXISTS "$db_name";
        DROP USER IF EXISTS "$db_user";
        
        -- Create user and database
        CREATE USER "$db_user" WITH PASSWORD '$db_pass';
        CREATE DATABASE "$db_name" OWNER "$db_user";
        GRANT ALL PRIVILEGES ON DATABASE "$db_name" TO "$db_user";
EOSQL
    
    # Grant schema privileges
    psql -q -v ON_ERROR_STOP=1 -U postgres -d "$db_name" <<-EOSQL
        GRANT ALL ON SCHEMA public TO "$db_user";
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "$db_user";
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "$db_user";
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO "$db_user";
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TYPES TO "$db_user";
EOSQL
    
    echo "✓ Created database $db_name with user $db_user"
}

# Helper function to load SQL file into a database
# Usage: load_sql "sitename" "/path/to/file.sql"
load_sql() {
    local site=$1
    local sql_file=$2
    local db_name="${site}_db"
    local db_user="${site}_user"
    local db_pass="${site}_pw"

    # Skip loading if ZOO_NO_SEED is set
    if [ "${ZOO_NO_SEED:-false}" = "true" ]; then
        echo "Skipping seed data for $db_name (ZOO_NO_SEED is set)"
        return
    fi

    # Check if SQL file exists
    if [ ! -f "$sql_file" ]; then
        echo "⚠️  SQL file $sql_file not found, skipping seed for $db_name"
        return
    fi

    echo "Loading $sql_file into $db_name..."
    PGPASSWORD="$db_pass" psql -q -v ON_ERROR_STOP=1 -U "$db_user" -d "$db_name" -f "$sql_file"
    echo "✓ Loaded SQL file into $db_name"
}

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
for i in {60..0}; do
    if pg_isready -U postgres &> /dev/null; then
        break
    fi
    sleep 1
done

if [ "$i" = 0 ]; then
    echo "PostgreSQL failed to start"
    exit 1
fi

echo "PostgreSQL started, creating databases..."

# =============================================================================
# ADD YOUR DATABASES HERE
# =============================================================================

# Example databases with seed data

# Miniflux RSS reader
create_db_for_site "miniflux"
load_sql "miniflux" "/seed/miniflux.zoo.sql"

# Auth service (Hydra + auth.zoo users)
# Create empty database - both services will initialize their own tables
create_db_for_site "auth"
load_sql "auth" "/seed/auth.sql"

# Stalwart mail server
create_db_for_site "stalwart"
load_sql "stalwart" "/seed/stalwart.sql"

# Focalboard (Kanban board)
create_db_for_site "focalboard"
load_sql "focalboard" "/seed/focalboard.sql"

# Gitea (Git server)
create_db_for_site "gitea"
load_sql "gitea" "/seed/gitea.sql"

# Planka (Project management)
create_db_for_site "planka"

# Example: Add more databases here
# create_db_for_site "myapp"
# load_sql "myapp" "/seed/myapp_seed.sql"
# create_snapshot "myapp"

# =============================================================================

echo "All databases created successfully!"

# =============================================================================
# COMPRESSION
# =============================================================================

echo "Optimizing database with compression..."

# First, check if LZ4 compression is available
LZ4_AVAILABLE=$(psql -U postgres -d zoodb -tAc "SELECT COUNT(*) FROM pg_available_extensions WHERE name = 'pg_lz4';" 2>/dev/null || echo "0")

# Default to pglz (built-in) if lz4 is not available
COMPRESSION_METHOD="pglz"
if command -v pg_config >/dev/null 2>&1; then
    if pg_config --configure | grep -q "with-lz4"; then
        COMPRESSION_METHOD="lz4"
        echo "  Using LZ4 compression (faster)"
    else
        echo "  Using pglz compression (built-in)"
    fi
fi

# Set compression threshold (in MB)
COMPRESSION_THRESHOLD_MB=10

# Find all databases created by our scripts (excluding system databases)
DATABASES=$(psql -U postgres -tAc "
    SELECT datname
    FROM pg_database
    WHERE datname NOT IN ('postgres', 'template0', 'template1', 'zoodb')
    AND datname LIKE '%_db';
")

# Process each database
for DB in $DATABASES; do
    echo "  Processing database: $DB"

    # Find large tables in this database
    LARGE_TABLES=$(psql -U postgres -d "$DB" -tAc "
        SELECT schemaname || '.' || tablename
        FROM pg_tables
        WHERE schemaname = 'public'
        AND pg_total_relation_size(schemaname||'.'||tablename) > ${COMPRESSION_THRESHOLD_MB} * 1024 * 1024;
    ")

    if [ -z "$LARGE_TABLES" ]; then
        echo "    No large tables found (threshold: ${COMPRESSION_THRESHOLD_MB}MB)"
        continue
    fi

    # For each large table, find TEXT/BYTEA columns and set compression
    for TABLE_FULL in $LARGE_TABLES; do
        TABLE_NAME=$(echo "$TABLE_FULL" | cut -d'.' -f2)
        TABLE_SIZE=$(psql -U postgres -d "$DB" -tAc "SELECT pg_size_pretty(pg_total_relation_size('$TABLE_FULL'));")

        echo "    Processing table: $TABLE_NAME ($TABLE_SIZE)"

        # Find compressible columns (TEXT, VARCHAR, BYTEA, JSON, JSONB, XML)
        COLUMNS=$(psql -U postgres -d "$DB" -tAc "
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = '$TABLE_NAME'
            AND data_type IN ('text', 'bytea', 'json', 'jsonb', 'xml', 'character varying');
        ")

        if [ -z "$COLUMNS" ]; then
            continue
        fi

        # Set compression on each column
        for COLUMN in $COLUMNS; do
            echo "      Setting $COMPRESSION_METHOD compression on column: $COLUMN"
            psql -U postgres -d "$DB" -c "
                ALTER TABLE $TABLE_NAME ALTER COLUMN $COLUMN SET COMPRESSION $COMPRESSION_METHOD;
            " 2>&1 | grep -v "^ALTER TABLE$" || true
        done

        # VACUUM FULL to apply compression to existing data
        echo "      Running VACUUM FULL to compress existing data..."
        psql -U postgres -d "$DB" -c "VACUUM FULL $TABLE_NAME;" 2>&1 | grep -v "^VACUUM$" || true
    done
done

echo "✓ Compression optimization complete"

# =============================================================================