#!/bin/sh
set -e

# Unconditionally reset /data to match DB reset behavior
echo "Resetting /data directory..."
rm -rf /data/*

# Restore golden state (config, JWT keys, avatars)
if [ -d /golden-data ]; then
    # Only restore if golden-data has contents
    if [ -n "$(ls -A /golden-data 2>/dev/null)" ]; then
        echo "Restoring golden state (config, JWT keys, avatars)..."
        cp -r /golden-data/* /data/
        echo "Golden state restored"
    else
        echo "No golden state to restore"
    fi
fi

# Restore pre-baked git repositories
if [ ! -d /app/git-repositories-image ]; then
    echo "ERROR: /app/git-repositories-image not found in image"
    exit 1
fi

echo "Restoring git repositories from image..."
mkdir -p /data/git/repositories
cp -r /app/git-repositories-image/* /data/git/repositories/
echo "Git repositories restored"

# Start Gitea in the background
/usr/bin/entrypoint &
GITEA_PID=$!

# Wait for Gitea to be ready
echo "Waiting for Gitea to start..."
until wget -q -O /dev/null http://localhost:3000/ 2>/dev/null; do
    sleep 2
done

# Check if installation is needed
if grep -q "INSTALL_LOCK = false" /data/gitea/conf/app.ini 2>/dev/null; then
    echo "Running Gitea installation..."
    curl -X POST http://localhost:3000/ \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "db_type=postgres" \
      -d "db_host=postgres.zoo%3A5432" \
      -d "db_user=gitea_user" \
      -d "db_passwd=gitea_pw" \
      -d "db_name=gitea_db" \
      -d "ssl_mode=disable" \
      -d "charset=utf8" \
      -d "app_name=Gitea%3A+Git+with+a+cup+of+tea" \
      -d "repo_root_path=%2Fdata%2Fgit%2Frepositories" \
      -d "lfs_root_path=%2Fdata%2Fgit%2Flfs" \
      -d "run_user=git" \
      -d "domain=gitea.zoo" \
      -d "ssh_port=22" \
      -d "http_port=3000" \
      -d "app_url=http%3A%2F%2Fgitea.zoo%2F" \
      -d "log_root_path=%2Fdata%2Fgitea%2Flog" \
      -d "smtp_addr=stalwart%3A25" \
      -d "smtp_port=25" \
      -d "smtp_from=noreply%40gitea.zoo" \
      -d "mailer_enabled=on" \
      -d "enable_federated_avatar=on" \
      -d "enable_open_id_sign_in=on" \
      -d "enable_open_id_sign_up=on" \
      -d "default_allow_create_organization=on" \
      -d "default_enable_timetracking=on" \
      -d "no_reply_address=noreply.gitea.zoo" \
      -d "admin_name=admin" \
      -d "admin_passwd=admin123" \
      -d "admin_confirm_passwd=admin123" \
      -d "admin_email=admin%40gitea.zoo"
    
    # Wait for installation to complete and Gitea to restart
    sleep 5
    until wget -q -O /dev/null http://localhost:3000/api/v1/version 2>/dev/null; do
        echo "Waiting for Gitea to restart after installation..."
        sleep 2
    done
fi

echo "Gitea is ready, configuring OAuth2..."

# Run the OAuth2 configuration
/app/configure-oauth.sh

# Create users
/app/create-users.sh

# Import repositories if not already done
if [ ! -f /data/.repos-imported ]; then
    echo "Importing repositories and organizations..."
    /app/import-repos.sh && touch /data/.repos-imported
fi

# Wait for the Gitea process
wait $GITEA_PID