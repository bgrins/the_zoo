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

# Helper function to create a snapshot dump of a database
# Usage: create_snapshot "sitename"
create_snapshot() {
    local site=$1
    local db_name="${site}_db"
    local snapshot_file="/var/lib/mysql/snapshots/${db_name}.sql.xz"

    echo "Creating snapshot dump $snapshot_file from $db_name..."
    mkdir -p /var/lib/mysql/snapshots
    mysqldump -u root --socket=/tmp/mysql.sock "$db_name" | xz -9 > "$snapshot_file"
    echo "✓ Created snapshot dump $snapshot_file ($(du -h "$snapshot_file" | cut -f1))"
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
create_snapshot "vwa-classifieds"

# Northwind sample database (for phpMyAdmin exploration)
create_db_for_site "northwind"
load_sql "northwind" "/tmp/sql/northwind-schema.sql"
load_sql "northwind" "/tmp/sql/northwind-data.sql"
create_snapshot "northwind"

# Magento database for onestopshop.zoo
create_db_for_site "onestopshop"
load_sql "onestopshop" "/tmp/sql/magento_dump.sql"
create_snapshot "onestopshop"

# Example: Add more databases here
# create_db_for_site "myapp"
# load_sql "myapp" "/tmp/sql/myapp_seed.sql"

# =============================================================================

echo "All databases created successfully!"