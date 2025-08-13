#!/bin/sh
set -e

echo "Waiting for PostgreSQL..."
until hydra migrate sql -e --yes; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - executing migrations"

# UI server is now separate, not needed here

# Function to initialize clients in the background
init_clients() {
  echo "Waiting for Hydra to be ready before initializing clients..."
  sleep 5  # Give Hydra time to start
  
  # Wait for admin API to be ready
  until wget -q -O /dev/null http://localhost:4445/health/ready 2>/dev/null; do
    echo "Waiting for Hydra admin API..."
    sleep 2
  done
  
  # Run the client initialization script
  if [ -f /init-clients.sh ]; then
    sh /init-clients.sh
  fi
}

# Start client initialization in background
init_clients &

# No UI server to manage

echo "Starting Hydra..."
# Override cookie settings for development
export SERVE_COOKIES_SECURE=false
export DEV=true
exec hydra serve all --config /etc/hydra/hydra.yaml --dev