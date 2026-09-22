#!/bin/sh
set -e

echo "Starting SnappyMail configuration..."

# core/follow-restore.sh, which compose runs first, has restored /var/lib/snappymail
chown -R www-data:www-data /var/lib/snappymail/

# Wait for SnappyMail to be ready
echo "Waiting for SnappyMail directories to be created..."
timeout=30
while [ ! -d "/var/lib/snappymail/_data_/_default_/domains" ] && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo "Warning: SnappyMail directories not created within timeout"
fi

# Create necessary directories
mkdir -p /var/lib/snappymail/_data_/_default_/domains
mkdir -p /var/lib/snappymail/_data_/_default_/configs

# Copy configuration files from mounted config directory
if [ -f "/config/domains/zoo.json" ]; then
    echo "Copying zoo domain configuration..."
    cp /config/domains/zoo.json /var/lib/snappymail/_data_/_default_/domains/zoo.json
fi

if [ -f "/config/application.ini" ]; then
    echo "Copying application configuration..."
    cp /config/application.ini /var/lib/snappymail/_data_/_default_/configs/application.ini
fi

# Set admin password hash if provided
if [ -n "$ADMIN_PASS" ] && [ -f "/var/lib/snappymail/_data_/_default_/configs/application.ini" ]; then
    echo "Setting admin password..."
    # SnappyMail uses PHP's password_hash/password_verify (bcrypt)
    ADMIN_HASH=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_DEFAULT);")
    # Escape special chars for sed (bcrypt hashes contain $ and /)
    ADMIN_HASH_ESCAPED=$(printf '%s\n' "$ADMIN_HASH" | sed 's/[&/\$]/\\&/g')
    sed -i "s/admin_password = \"\"/admin_password = \"$ADMIN_HASH_ESCAPED\"/" /var/lib/snappymail/_data_/_default_/configs/application.ini
fi

# Set permissions
chown -R www-data:www-data /var/lib/snappymail/_data_

echo "SnappyMail configuration complete!"

# Start the original entrypoint
exec "$@"