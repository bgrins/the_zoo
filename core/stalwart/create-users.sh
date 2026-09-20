#!/bin/bash
set -e

# startup.sh runs this on every start: it creates the domains and accounts below that don't
# exist yet. They are part of the golden state, so after adding one, capture it with
# `npm run golden:capture -- stalwart` (docs/golden-state.md).

echo "=== Stalwart User Management Script ==="
echo "This script is idempotent - it can be run multiple times safely"
echo ""

# Use admin password from environment or default
ADMIN_PASSWORD="${ADMIN_PASSWORD:-zoo-mail-admin-pw}"
echo "Using admin password: $ADMIN_PASSWORD"

# Stalwart answers 200 for both outcomes: {"data": id} on create, {"error": ...} otherwise
report_result() {
    local http_code="$1"
    local what="$2"
    if [ "$http_code" = "200" ] && jq -e 'has("data")' /tmp/response.txt >/dev/null; then
        echo "✓ $what created successfully"
    elif [ "$http_code" = "200" ] && jq -e '.error == "fieldAlreadyExists"' /tmp/response.txt >/dev/null; then
        echo "✓ $what already exists"
    else
        echo "✗ Failed to create $what (HTTP $http_code)"
        cat /tmp/response.txt
    fi
}

# Function to create a domain
create_domain() {
    local domain="$1"
    local description="$2"
    
    echo "Creating domain: $domain"
    
    response=$(curl -s -o /tmp/response.txt -w "%{http_code}" \
        -u "admin:$ADMIN_PASSWORD" \
        -X POST "http://localhost:8080/api/principal" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"domain\",
            \"name\": \"$domain\",
            \"description\": \"$description\"
        }")
    
    report_result "$response" "Domain $domain"
}

# Function to create a user
create_user() {
    local email="$1"
    local password="$2"
    local name="$3"
    
    echo "Creating user: $email"
    
    # Hash the password using SHA-512
    local salt=$(openssl rand -base64 12 | tr -d '=+/')
    local hashed_password=$(openssl passwd -6 -salt "$salt" "$password")
    
    # Use the correct POST endpoint for creating principals
    response=$(curl -s -o /tmp/response.txt -w "%{http_code}" \
        -u "admin:$ADMIN_PASSWORD" \
        -X POST "http://localhost:8080/api/principal" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"individual\",
            \"name\": \"$email\",
            \"description\": \"$name\",
            \"secrets\": [\"$hashed_password\"],
            \"emails\": [\"$email\"],
            \"quota\": 0,
            \"urls\": [],
            \"memberOf\": [],
            \"roles\": [\"user\"],
            \"lists\": [],
            \"members\": [],
            \"enabledPermissions\": [],
            \"disabledPermissions\": [],
            \"externalMembers\": []
        }")
    
    report_result "$response" "User $email"
}

echo ""
echo "=== Creating Domains ==="
# Create domains - add new domains here
create_domain "zoo" "Main Zoo domain"
create_domain "status.zoo" "Status application domain"
create_domain "snappymail.zoo" "SnappyMail webmail domain"

echo ""
echo "=== Creating Users ==="
# Create users - add new users here
# Format: create_user "email" "password" "Full Name"

# zoo domain users
create_user "user@zoo" "userpassword123" "Test User"
create_user "admin@zoo" "adminpassword123" "Admin User"
create_user "test@zoo" "testpassword123" "Test Account"
create_user "newuser@zoo" "newuserpassword123" "New User"

# status.zoo domain users
create_user "admin@status.zoo" "statusadmin123" "Status Admin"
create_user "user@status.zoo" "statususer123" "Status User"

# snappymail.zoo domain users. Persona mailboxes (<username>@snappymail.zoo) come from
# scripts/seed-data/personas.ts via npm run seed.
create_user "user@snappymail.zoo" "snappyuser123" "SnappyMail User"

# Add new users above this line

echo ""
echo "=== User Management Complete ==="