#!/bin/sh
# This script initializes OAuth2 clients after Hydra is running

set -e

HYDRA_ADMIN_URL="${HYDRA_ADMIN_URL:-http://localhost:4445}"

echo "Hydra admin API is ready!"

# Process the default-clients.json file
CLIENT_FILE="/clients/default-clients.json"

if [ -f "$CLIENT_FILE" ]; then
  echo "Processing clients from default-clients.json..."
  
  # Count the number of clients in the file
  client_count=$(jq '. | length' "$CLIENT_FILE")
  echo "Found $client_count client(s)"
  
  # Process each client in the array
  for i in $(seq 0 $((client_count - 1))); do
    # Extract the client data
    client_data=$(jq ".[$i]" "$CLIENT_FILE")
    client_id=$(echo "$client_data" | jq -r '.client_id')
    client_name=$(echo "$client_data" | jq -r '.client_name')
    
    echo "Processing client: $client_id ($client_name)"
    
    # Save client data to temporary file
    echo "$client_data" > /tmp/client-${client_id}.json
    
    # Check if client already exists
    if wget -q -O - "${HYDRA_ADMIN_URL}/admin/clients/${client_id}" 2>/dev/null | grep -q "${client_id}"; then
      echo "Client ${client_id} already exists, updating..."
      
      # Use curl to update the client with PUT
      if curl -s -X PUT \
        -H "Content-Type: application/json" \
        -d "@/tmp/client-${client_id}.json" \
        "${HYDRA_ADMIN_URL}/admin/clients/${client_id}" > /dev/null; then
        echo "Client ${client_id} updated successfully"
      else
        echo "Failed to update client ${client_id}"
      fi
    else
      echo "Creating client ${client_id}..."
      
      # POST the client data to Hydra admin API
      if wget -q -O - \
        --header="Content-Type: application/json" \
        --post-file=/tmp/client-${client_id}.json \
        "${HYDRA_ADMIN_URL}/admin/clients" 2>&1; then
        echo "Client ${client_id} created successfully"
      else
        echo "Failed to create client ${client_id}"
      fi
    fi
    
    # Clean up
    rm -f /tmp/client-${client_id}.json
  done
else
  echo "Error: default-clients.json not found at $CLIENT_FILE"
  exit 1
fi

echo "All OAuth2 clients have been processed"