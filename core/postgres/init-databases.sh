#!/bin/bash
# Creates the databases seeded from repo-local dumps in seed/. Large downloaded
# dumps are loaded earlier by init-external-databases.sh.
set -euo pipefail

source /usr/local/bin/db-helpers.sh

wait_for_postgres

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

# Mattermost (Team messaging)
create_db_for_site "mattermost"
load_sql "mattermost" "/seed/mattermost.sql"

# Example: Add more databases here
# create_db_for_site "myapp"
# load_sql "myapp" "/seed/myapp_seed.sql"

# =============================================================================

echo "All databases created successfully!"
