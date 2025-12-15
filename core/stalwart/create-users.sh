#!/bin/bash
set -e

# This script can be run repeatedly to create/update users and domains
# It will skip existing users/domains and only create new ones
# To reset completely, dump the database first
#
# How to run this script:
# docker cp core/stalwart/create-users.sh the_zoo-stalwart-1:/tmp/create-users.sh
# docker compose exec stalwart bash /tmp/create-users.sh

echo "=== Stalwart User Management Script ==="
echo "This script is idempotent - it can be run multiple times safely"
echo ""

# Use admin password from environment or default
ADMIN_PASSWORD="${ADMIN_PASSWORD:-zoo-mail-admin-pw}"
echo "Using admin password: $ADMIN_PASSWORD"

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
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        echo "✓ Domain $domain created successfully"
    elif [ "$response" = "409" ]; then
        echo "✓ Domain $domain already exists"
    else
        echo "✗ Failed to create domain $domain (HTTP $response)"
        cat /tmp/response.txt
    fi
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
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        echo "✓ User $email created successfully"
    elif [ "$response" = "409" ]; then
        echo "✓ User $email already exists"
    else
        echo "✗ Failed to create user $email (HTTP $response)"
        cat /tmp/response.txt
    fi
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

# snappymail.zoo domain users
create_user "admin@snappymail.zoo" "snappyadmin123" "SnappyMail Admin"
create_user "user@snappymail.zoo" "snappyuser123" "SnappyMail User"
create_user "alex.chen@snappymail.zoo" "Password.123" "Alex Chen"
create_user "blake.sullivan@snappymail.zoo" "Password.123" "Blake Sullivan"

# Add new users above this line

echo ""
echo "=== User Management Complete ==="
echo ""
echo "To add new users or domains:"
echo "1. Edit this script and add new create_domain or create_user calls"
echo "2. Run: docker compose exec stalwart /usr/local/bin/create-users.sh"
echo ""
echo "To reset and start fresh:"
echo "1. Stop Stalwart: docker compose stop stalwart"
echo "2. Reset database: docker compose exec postgres psql -U stalwart_user -d stalwart_db -c 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'"
echo "3. Restart Stalwart: docker compose up -d stalwart"
echo "4. Run this script again"