#!/bin/sh
set -e

# Create admin user if it doesn't exist
if ! su git -c "gitea admin user list" | grep -q "admin"; then
    echo "Creating admin user..."
    su git -c "gitea admin user create --username admin --password admin123 --email admin@gitea.zoo --admin"
fi

# Check if OAuth2 provider already exists; if so, make sure it has the current settings
source_id=$(su git -c "gitea admin auth list" | awk -F'\t' '$2 ~ /^auth\.zoo/ {print $1}')
if [ -n "$source_id" ]; then
    echo "OAuth2 provider 'auth.zoo' already exists (id $source_id), updating settings"
    su git -c "gitea admin auth update-oauth \
        --id '$source_id' \
        --auto-discover-url 'https://auth.zoo/.well-known/openid-configuration' \
        --scopes 'openid profile email'"
else
    echo "Waiting for auth.zoo to be ready..."
    # Wait for auth.zoo OpenID discovery endpoint to be available
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if wget -q -O /dev/null https://auth.zoo/.well-known/openid-configuration 2>/dev/null; then
            echo "auth.zoo is ready"
            break
        fi
        echo "Waiting for auth.zoo... (attempt $((attempt+1))/$max_attempts)"
        sleep 2
        attempt=$((attempt+1))
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo "ERROR: auth.zoo did not become ready in time"
        exit 1
    fi
    
    echo "Adding OAuth2 provider for auth.zoo..."
    su git -c "gitea admin auth add-oauth \
        --name 'auth.zoo' \
        --provider 'openidConnect' \
        --key 'gitea' \
        --secret 'gitea-oauth-secret' \
        --auto-discover-url 'https://auth.zoo/.well-known/openid-configuration' \
        --scopes 'openid profile email'"
fi

echo "OAuth2 configuration completed"