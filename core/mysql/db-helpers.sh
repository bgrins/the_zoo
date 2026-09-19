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

    mysql -u root --socket=/tmp/mysql.sock <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`$db_name\`
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_unicode_ci;

        CREATE USER IF NOT EXISTS '$db_user'@'%' IDENTIFIED BY '$db_pass';
        GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'%';
        FLUSH PRIVILEGES;
EOSQL

    echo "✓ Created database $db_name with user $db_user"
}

# Helper function to load a SQL file (plain or .xz) into a database
# Usage: load_sql "sitename" "/path/to/file.sql"
load_sql() {
    local site=$1
    local sql_file=$2
    local db_name="${site}_db"

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
        xz -dc "$sql_file" | mysql -u root --socket=/tmp/mysql.sock "$db_name"
    else
        mysql -u root --socket=/tmp/mysql.sock "$db_name" < "$sql_file"
    fi
    echo "✓ Loaded SQL file into $db_name"
}

wait_for_mysql() {
    echo "Waiting for MySQL to start..."
    for i in {60..0}; do
        if mysql -u root --socket=/tmp/mysql.sock -e "SELECT 1" &> /dev/null; then
            break
        fi
        sleep 1
    done

    if [ "$i" = 0 ]; then
        echo "MySQL failed to start"
        exit 1
    fi
}

# Compress tables larger than the threshold to reduce image size. Already
# compressed tables are skipped so each build step only rebuilds its own tables.
compress_large_tables() {
    local threshold_mb=60

    echo "Compressing large tables to reduce disk usage..."

    mysql -u root --socket=/tmp/mysql.sock -N -e "
      SELECT CONCAT(table_schema, '.', table_name) AS full_table_name,
             ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
      FROM information_schema.tables
      WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
        AND (data_length + index_length) / 1024 / 1024 > $threshold_mb
        AND engine = 'InnoDB'
        AND row_format <> 'Compressed'
      ORDER BY (data_length + index_length) DESC;
    " | while read -r table size; do
        db_name=$(echo "$table" | cut -d'.' -f1)
        table_name=$(echo "$table" | cut -d'.' -f2)

        echo "  Compressing $table (${size}MB)..."
        mysql -u root --socket=/tmp/mysql.sock "$db_name" -e "
          ALTER TABLE \`$table_name\` ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;
        " 2>&1 | grep -v "Warning: Using a password" || true
    done

    echo "✓ Compression complete"
}

# Purge binary logs (if any were created despite --skip-log-bin) and flush
# logs and tables so the server shuts down cleanly.
flush_for_shutdown() {
    echo "Running cleanup and optimization..."
    mysql -u root --socket=/tmp/mysql.sock -e "RESET MASTER;" 2>/dev/null || true
    mysql -u root --socket=/tmp/mysql.sock -e "FLUSH LOGS; FLUSH TABLES;"
    echo "✓ Cleanup complete"
}
