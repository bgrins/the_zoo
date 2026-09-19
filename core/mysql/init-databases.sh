#!/bin/bash
# Creates the databases seeded from repo-local files in seed/ and sql/. Large
# downloaded dumps are loaded earlier by init-external-databases.sh.
set -euo pipefail

source /usr/local/bin/db-helpers.sh

wait_for_mysql

echo "MySQL started, creating databases..."

# =============================================================================
# ADD YOUR DATABASES HERE
# =============================================================================

# Northwind sample database (for phpMyAdmin exploration)
create_db_for_site "northwind"
load_sql "northwind" "/tmp/sql/northwind-schema.sql"
load_sql "northwind" "/tmp/sql/northwind-data.sql"

# Matomo analytics (analytics.zoo)
create_db_for_site "analytics"
load_sql "analytics" "/tmp/sql/analytics_seed.sql"

# Example: Add more databases here
# create_db_for_site "myapp"
# load_sql "myapp" "/tmp/sql/myapp_seed.sql"

# =============================================================================

echo "All databases created successfully!"

compress_large_tables
flush_for_shutdown
