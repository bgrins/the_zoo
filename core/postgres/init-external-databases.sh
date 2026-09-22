#!/bin/bash
# Loads the large downloaded dumps in /dumps. The Dockerfile runs this in
# its own step before seed/ is copied, so editing a local seed does not reload them.
set -euo pipefail

source /usr/local/bin/db-helpers.sh

wait_for_postgres

# Postmill (Reddit-like forum)
create_db_for_site "postmill"
load_sql "postmill" "/dumps/postmill.sql.xz"

# Set all forums as featured in postmill (the forums table only exists when seeded)
if [ "${ZOO_NO_SEED:-false}" != "true" ]; then
    echo "Setting all forums as featured in postmill..."
    PGPASSWORD="postmill_pw" psql -q -v ON_ERROR_STOP=1 -U postmill_user -d postmill_db > /dev/null <<-EOSQL
    UPDATE forums SET featured = true;
EOSQL
    echo "✓ Set all forums as featured in postmill"
fi
