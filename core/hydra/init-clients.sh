#!/bin/sh
# Creates the OAuth2 clients in default-clients.json, and updates a client only when its
# config changed: an update re-hashes the secret, which would churn the golden auth_db.
# Hydra doesn't return secrets, so each client carries a hash of its config in metadata.

set -e

HYDRA_ADMIN_URL="${HYDRA_ADMIN_URL:-http://localhost:4445}"
CLIENT_FILE="/clients/default-clients.json"

if [ ! -f "$CLIENT_FILE" ]; then
  echo "Error: default-clients.json not found at $CLIENT_FILE"
  exit 1
fi

jq -c '.[]' "$CLIENT_FILE" | while read -r client; do
  client_id=$(echo "$client" | jq -r '.client_id')
  config_hash=$(echo "$client" | jq -cS . | sha256sum | cut -d' ' -f1)
  body=$(echo "$client" | jq -c --arg hash "$config_hash" '.metadata = {config_sha256: $hash}')

  status=$(curl -s -o /tmp/client.json -w '%{http_code}' "${HYDRA_ADMIN_URL}/admin/clients/${client_id}")
  if [ "$status" = "200" ] && [ "$(jq -r '.metadata.config_sha256 // empty' /tmp/client.json)" = "$config_hash" ]; then
    echo "Client ${client_id} is up to date"
  elif [ "$status" = "200" ]; then
    if echo "$body" | curl -sf -o /dev/null -X PUT -H "Content-Type: application/json" -d @- \
      "${HYDRA_ADMIN_URL}/admin/clients/${client_id}"; then
      echo "Client ${client_id} updated"
    else
      echo "Failed to update client ${client_id}"
    fi
  elif [ "$status" = "404" ]; then
    if echo "$body" | curl -sf -o /dev/null -X POST -H "Content-Type: application/json" -d @- \
      "${HYDRA_ADMIN_URL}/admin/clients"; then
      echo "Client ${client_id} created"
    else
      echo "Failed to create client ${client_id}"
    fi
  else
    echo "Failed to look up client ${client_id} (HTTP $status)"
  fi
done
rm -f /tmp/client.json

echo "All OAuth2 clients have been processed"
