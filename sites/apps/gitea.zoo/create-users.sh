#!/bin/sh
set -e

echo "Creating Gitea users..."

# Check if users already exist
if su git -c "gitea admin user list" | grep -q "alice"; then
    echo "Users already created, skipping..."
    exit 0
fi

# Create admin user first
echo "Creating admin user..."
su git -c "gitea admin user create --username 'admin' --password 'admin123' --email 'admin@gitea.zoo' --admin --must-change-password=false" || true

# Create users from JSON data
jq -c '.users[]' /app/sample-data/import-data.json | while IFS= read -r user; do
    username=$(echo "$user" | jq -r '.username')
    email=$(echo "$user" | jq -r '.email')
    password=$(echo "$user" | jq -r '.password')
    full_name=$(echo "$user" | jq -r '.full_name')
    is_admin=$(echo "$user" | jq -r '.is_admin')
    
    echo "Creating user: $username"
    if [ "$is_admin" = "true" ]; then
        su git -c "gitea admin user create --username '$username' --password '$password' --email '$email' --admin --must-change-password=false" || true
    else
        su git -c "gitea admin user create --username '$username' --password '$password' --email '$email' --must-change-password=false" || true
    fi
done

echo "User creation completed!"