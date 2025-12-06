#!/bin/sh
# Healthcheck script that verifies:
# 1. Hydra is responding
# 2. OAuth clients have been created

# Check Hydra public endpoint
if ! wget -q -O /dev/null http://localhost:4444/health/ready 2>/dev/null; then
  echo "Hydra public endpoint not ready"
  exit 1
fi

# Check admin endpoint
if ! wget -q -O /dev/null http://localhost:4445/health/ready 2>/dev/null; then
  echo "Hydra admin endpoint not ready"
  exit 1
fi

# Verify the zoo-misc-app client exists (created by init-clients.sh)
if ! wget -q -O - http://localhost:4445/admin/clients/zoo-misc-app 2>/dev/null | grep -q "zoo-misc-app"; then
  echo "OAuth client zoo-misc-app not yet created"
  exit 1
fi

exit 0
