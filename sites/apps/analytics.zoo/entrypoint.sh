#!/bin/bash
set -e

# Restore golden config if this is first start (no config exists yet)
if [ -d "/golden-data/config" ] && [ ! -f "/var/www/html/config/config.ini.php" ]; then
    echo "Restoring Matomo golden state..."
    cp -r /golden-data/config /var/www/html/
    chown -R www-data:www-data /var/www/html/config
    echo "✅ Golden config restored"
fi

echo "Starting Apache..."
exec /entrypoint.sh "$@"
