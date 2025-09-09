#!/bin/bash
# This script runs after cloud-init completes

set -e

LOG_FILE="/var/log/zoo-startup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "$(date): Starting Zoo setup..."

# Wait for cloud-init to complete
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
  echo "Waiting for cloud-init..."
  sleep 5
done

# Run setup if not already done
if [ ! -d /opt/zoo/the_zoo ]; then
  echo "Running initial setup..."
  /opt/zoo/setup.sh
else
  echo "Zoo already set up, starting services..."
  cd /opt/zoo/the_zoo
  docker compose -f docker-compose.yaml -f deploy/docker-compose.override.yaml up -d
fi

# Enable and start the systemd service
systemctl enable the-zoo
systemctl start the-zoo

echo "$(date): Zoo setup complete!"
echo "Proxy is available on port 3128"