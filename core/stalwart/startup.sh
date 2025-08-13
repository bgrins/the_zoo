#!/bin/bash
set -e

echo "Starting Stalwart Mail Server..."

# Configuration file paths
CONFIG_FILE="/opt/stalwart-mail/etc/config.toml"
CONFIG_TEMPLATE="/usr/local/bin/config.toml"

# With PostgreSQL storage, we don't need to initialize the data directory
# Create the config directory if it doesn't exist
mkdir -p /opt/stalwart-mail/etc

# Always apply our custom config template
if [ -f "$CONFIG_TEMPLATE" ]; then
    echo "Applying custom configuration..."
    cp "$CONFIG_TEMPLATE" "$CONFIG_FILE"
fi

# Use the admin password from environment
# (Our config file has the password hash that matches this)

# Start Stalwart in background
echo "Starting Stalwart server..."
/usr/local/bin/stalwart-mail --config "$CONFIG_FILE" &
STALWART_PID=$!

# Wait for Stalwart to be ready
echo "Waiting for Stalwart to be ready..."
attempts=0
max_attempts=30
while ! nc -z localhost 8080; do
    sleep 2
    attempts=$((attempts + 1))
    if [ $attempts -ge $max_attempts ]; then
        echo "Stalwart failed to start within 60 seconds"
        exit 1
    fi
done

# Run user creation script
echo "Running user creation script..."
if [ -f "/usr/local/bin/create-users.sh" ]; then
    bash /usr/local/bin/create-users.sh
else
    echo "Warning: create-users.sh not found"
fi

# Wait for Stalwart process
echo "Stalwart Mail Server is running..."
wait $STALWART_PID