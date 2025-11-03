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

# Helper function to load SQL file into a database
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
    mysql -u root --socket=/tmp/mysql.sock "$db_name" < "$sql_file"
    echo "✓ Loaded SQL file into $db_name"
}

# Wait for MySQL to be ready
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

echo "MySQL started, creating databases..."

# Create root user for remote access
mysql -u root --socket=/tmp/mysql.sock -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'password'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'; FLUSH PRIVILEGES;"

# =============================================================================
# ADD YOUR DATABASES HERE
# =============================================================================

# Classifieds site (vwa-classifieds.zoo)
create_db_for_site "vwa-classifieds"
load_sql "vwa-classifieds" "/tmp/sql/classifieds_import.sql"
load_sql "vwa-classifieds" "/tmp/sql/classifieds_restore.sql"

# Northwind sample database (for phpMyAdmin exploration)
create_db_for_site "northwind"
load_sql "northwind" "/tmp/sql/northwind-schema.sql"
load_sql "northwind" "/tmp/sql/northwind-data.sql"

# Magento database for onestopshop.zoo
create_db_for_site "onestopshop"
load_sql "onestopshop" "/tmp/sql/magento_dump.sql"
create_snapshot "onestopshop"

# Matomo analytics (analytics.zoo)
create_db_for_site "analytics"
create_snapshot "analytics"

# Example: Add more databases here
# create_db_for_site "myapp"
# load_sql "myapp" "/tmp/sql/myapp_seed.sql"

# =============================================================================

echo "All databases created successfully!"

# =============================================================================
# COMPRESSION
# =============================================================================

echo "Compressing large tables to reduce disk usage..."

# Compress tables larger than threshold to reduce image size
COMPRESSION_THRESHOLD_MB=60

mysql -u root --socket=/tmp/mysql.sock -N -e "
  SELECT CONCAT(table_schema, '.', table_name) AS full_table_name,
         ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
  FROM information_schema.tables
  WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')
    AND (data_length + index_length) / 1024 / 1024 > $COMPRESSION_THRESHOLD_MB
    AND engine = 'InnoDB'
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

# =============================================================================
# CLEANUP AND OPTIMIZATION
# =============================================================================

echo "Running cleanup and optimization..."

# Purge binary logs (if any were created despite --skip-log-bin)
# This ensures we don't bake unnecessary binlogs into the image
mysql -u root --socket=/tmp/mysql.sock -e "RESET MASTER;" 2>/dev/null || true

# Flush logs and tables to ensure clean shutdown
mysql -u root --socket=/tmp/mysql.sock -e "FLUSH LOGS; FLUSH TABLES;"

echo "✓ Cleanup complete"