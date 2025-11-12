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
    
    psql -q -v ON_ERROR_STOP=1 -U postgres > /dev/null <<-EOSQL
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
    psql -q -v ON_ERROR_STOP=1 -U postgres -d "$db_name" > /dev/null <<-EOSQL
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
    PGPASSWORD="$db_pass" psql -q -v ON_ERROR_STOP=1 -U "$db_user" -d "$db_name" -f "$sql_file" > /dev/null
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

# Postmill (Reddit-like forum)
create_db_for_site "postmill"
load_sql "postmill" "/seed/postmill.sql"

# Set all forums as featured in postmill
echo "Setting all forums as featured in postmill..."
PGPASSWORD="postmill_pw" psql -q -v ON_ERROR_STOP=1 -U postmill_user -d postmill_db > /dev/null <<-EOSQL
    UPDATE forums SET featured = true;
EOSQL
echo "✓ Set all forums as featured in postmill"

# Example: Add more databases here
# create_db_for_site "myapp"
# load_sql "myapp" "/seed/myapp_seed.sql"
# create_snapshot "myapp"

# =============================================================================

echo "All databases created successfully!"