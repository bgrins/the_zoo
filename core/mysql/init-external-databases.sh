#!/bin/bash
# Loads the large downloaded dumps in /dumps. The Dockerfile runs this in
# its own step before the local seeds are copied, so editing one does not reload them.
set -euo pipefail

source /usr/local/bin/db-helpers.sh

wait_for_mysql

echo "MySQL started, creating databases..."

# Create root user for remote access
mysql -u root --socket=/tmp/mysql.sock -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'password'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'; FLUSH PRIVILEGES;"

# Classifieds site (vwa-classifieds.zoo)
create_db_for_site "vwa-classifieds"
load_sql "vwa-classifieds" "/dumps/classifieds_import.sql"
load_sql "vwa-classifieds" "/dumps/classifieds_restore.sql"

# Disable auto_cron - it causes slow POST requests because the container can't reach external sites
# (the preference table only exists when seeded)
if [ "${ZOO_NO_SEED:-false}" != "true" ]; then
    mysql -u root --socket=/tmp/mysql.sock -e "UPDATE \`vwa-classifieds_db\`.oc_t_preference SET s_value='0' WHERE s_name='auto_cron';"
    echo "✓ Disabled auto_cron for classifieds"
fi

# Magento database for onestopshop.zoo
create_db_for_site "onestopshop"
load_sql "onestopshop" "/dumps/magento_dump.sql.xz"

compress_large_tables
flush_for_shutdown
