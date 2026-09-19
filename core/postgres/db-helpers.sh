#!/bin/bash
# Helpers sourced by init-external-databases.sh and init-databases.sh.

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

# Helper function to load a SQL file (plain or .xz) into a database
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
    if [[ "$sql_file" == *.xz ]]; then
        # Stream instead of decompressing to disk, which would put the full dump in a layer
        xzcat "$sql_file" | PGPASSWORD="$db_pass" psql -q -v ON_ERROR_STOP=1 -U "$db_user" -d "$db_name" -f - > /dev/null
    else
        PGPASSWORD="$db_pass" psql -q -v ON_ERROR_STOP=1 -U "$db_user" -d "$db_name" -f "$sql_file" > /dev/null
    fi
    echo "✓ Loaded SQL file into $db_name"
}

wait_for_postgres() {
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
}
