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

# Helper function to create a snapshot dump of a database
# Usage: create_snapshot "sitename"
create_snapshot() {
    local site=$1
    local db_name="${site}_db"
    local snapshot_file="/var/lib/postgresql/snapshots/${db_name}.sql.xz"

    echo "Creating snapshot dump $snapshot_file from $db_name..."
    mkdir -p /var/lib/postgresql/snapshots
    pg_dump -U postgres "$db_name" | xz -9 > "$snapshot_file"
    echo "✓ Created snapshot dump $snapshot_file ($(du -h "$snapshot_file" | cut -f1))"
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
create_snapshot "miniflux"

# Auth service (Hydra + auth.zoo users)
# Create empty database - both services will initialize their own tables
create_db_for_site "auth"
load_sql "auth" "/seed/auth.sql"
create_snapshot "auth"

# Stalwart mail server
create_db_for_site "stalwart"
load_sql "stalwart" "/seed/stalwart.sql"
create_snapshot "stalwart"

# Focalboard (Kanban board)
create_db_for_site "focalboard"
load_sql "focalboard" "/seed/focalboard.sql"
create_snapshot "focalboard"

# Gitea (Git server)
create_db_for_site "gitea"
load_sql "gitea" "/seed/gitea.sql"
create_snapshot "gitea"

# Planka (Project management)
create_db_for_site "planka"
create_snapshot "planka"

# Example: Add more databases here
# create_db_for_site "myapp"
# load_sql "myapp" "/seed/myapp_seed.sql"
# create_snapshot "myapp"

# =============================================================================

echo "All databases created successfully!"