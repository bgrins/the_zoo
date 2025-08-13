#!/bin/sh
set -e

# Create admin user if it doesn't exist
if ! su git -c "gitea admin user list" | grep -q "admin"; then
    echo "Creating admin user..."
    su git -c "gitea admin user create --username admin --password admin123 --email admin@gitea.zoo --admin"
fi

# Check if OAuth2 provider already exists
if su git -c "gitea admin auth list" | grep -q "auth.zoo"; then
    echo "OAuth2 provider 'auth.zoo' already exists"
else
    echo "Waiting for auth.zoo to be ready..."
    # Wait for auth.zoo OpenID discovery endpoint to be available
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if wget -q -O /dev/null http://auth.zoo/.well-known/openid-configuration 2>/dev/null; then
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
        --auto-discover-url 'http://auth.zoo/.well-known/openid-configuration' \
        --use-custom-urls \
        --custom-auth-url 'http://auth.zoo/oauth2/auth' \
        --custom-token-url 'http://hydra:4444/oauth2/token' \
        --custom-profile-url 'http://hydra:4444/userinfo' \
        --custom-email-url 'http://hydra:4444/userinfo' \
        --scopes 'openid profile email'"
fi

echo "OAuth2 configuration completed"