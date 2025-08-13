#!/bin/sh
set -e

echo "Starting Gitea data import..."

# Wait for Gitea to be fully ready
until su git -c "gitea admin user list" >/dev/null 2>&1; do
    echo "Waiting for Gitea to be ready..."
    sleep 2
done

# Check if data has already been imported by looking for a marker user
if su git -c "gitea admin user list" | grep -q "alice"; then
    echo "Data already imported, skipping..."
    exit 0
fi

echo "Creating users..."
# Create users from JSON data
jq -r '.users[] | @base64' /app/sample-data/import-data.json | while read -r user_data; do
    _jq() {
        echo "${user_data}" | base64 -d | jq -r "${1}"
    }
    
    username=$(_jq '.username')
    email=$(_jq '.email')
    password=$(_jq '.password')
    full_name=$(_jq '.full_name')
    is_admin=$(_jq '.is_admin')
    
    echo "Creating user: $username"
    if [ "$is_admin" = "true" ]; then
        su git -c "gitea admin user create --username '$username' --password '$password' --email '$email' --admin" || true
    else
        su git -c "gitea admin user create --username '$username' --password '$password' --email '$email'" || true
    fi
done

echo "Creating organizations..."
# Create organizations
jq -r '.organizations[] | @base64' /app/sample-data/import-data.json | while read -r org_data; do
    _jq() {
        echo "${org_data}" | base64 -d | jq -r "${1}"
    }
    
    name=$(_jq '.name')
    full_name=$(_jq '.full_name')
    description=$(_jq '.description')
    website=$(_jq '.website')
    location=$(_jq '.location')
    
    echo "Creating organization: $name"
    
    # Create org using API (Gitea CLI doesn't support org creation)
    curl -s -X POST "http://localhost:3000/api/v1/orgs" \
        -H "Content-Type: application/json" \
        -u "admin:admin123" \
        -d "{
            \"username\": \"$name\",
            \"full_name\": \"$full_name\",
            \"description\": \"$description\",
            \"website\": \"$website\",
            \"location\": \"$location\",
            \"visibility\": \"public\"
        }" || true
done

echo "Creating repositories..."
# Create repositories
jq -c '.repositories[]' /app/sample-data/import-data.json | while read -r repo; do
    owner=$(echo "$repo" | jq -r '.owner')
    name=$(echo "$repo" | jq -r '.name')
    description=$(echo "$repo" | jq -r '.description')
    private=$(echo "$repo" | jq -r '.private')
    readme=$(echo "$repo" | jq -r '.readme')
    
    echo "Creating repository: $owner/$name"
    
    # Initialize a temporary git repo
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    git init
    git config user.email "import@gitea.zoo"
    git config user.name "Import Bot"
    
    # Add README
    echo "$readme" > README.md
    git add README.md
    
    # Add other files
    echo "$repo" | jq -r '.files | to_entries[] | "\(.key)\n\(.value)"' | while read -r filename && read -r content; do
        # Skip if filename is empty or content is empty
        if [ -n "$filename" ] && [ -n "$content" ]; then
            # Create directory if needed
            mkdir -p "$(dirname "$filename")"
            echo "$content" > "$filename"
            git add "$filename"
        fi
    done
    
    # Commit
    git commit -m "Initial commit"
    
    # Create repo via API
    if [ "$owner" = "zoo-labs" ] || [ "$owner" = "community" ]; then
        # Create in organization
        curl -s -X POST "http://localhost:3000/api/v1/orgs/$owner/repos" \
            -H "Content-Type: application/json" \
            -u "admin:admin123" \
            -d "{
                \"name\": \"$name\",
                \"description\": \"$description\",
                \"private\": $private,
                \"auto_init\": false
            }" || true
        
        # Push to repo
        git remote add origin "http://admin:admin123@localhost:3000/$owner/$name.git"
    else
        # Create in user namespace
        curl -s -X POST "http://localhost:3000/api/v1/user/repos" \
            -H "Content-Type: application/json" \
            -u "$owner:${owner}123" \
            -d "{
                \"name\": \"$name\",
                \"description\": \"$description\",
                \"private\": $private,
                \"auto_init\": false
            }" || true
        
        # Push to repo
        git remote add origin "http://$owner:${owner}123@localhost:3000/$owner/$name.git"
    fi
    
    git push -u origin master || true
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
done

echo "Adding team members..."
# Add team members
jq -r '.teams[] | @base64' /app/sample-data/import-data.json | while read -r team_data; do
    _jq() {
        echo "${team_data}" | base64 -d | jq -r "${1}"
    }
    
    org=$(_jq '.org')
    team_name=$(_jq '.name')
    description=$(_jq '.description')
    permission=$(_jq '.permission')
    
    echo "Creating team: $org/$team_name"
    
    # Create team
    team_response=$(curl -s -X POST "http://localhost:3000/api/v1/orgs/$org/teams" \
        -H "Content-Type: application/json" \
        -u "admin:admin123" \
        -d "{
            \"name\": \"$team_name\",
            \"description\": \"$description\",
            \"permission\": \"$permission\",
            \"units\": [\"repo.code\", \"repo.issues\", \"repo.pulls\", \"repo.wiki\"]
        }")
    
    team_id=$(echo "$team_response" | jq -r '.id')
    
    if [ "$team_id" != "null" ]; then
        # Add members to team
        echo "$team_data" | base64 -d | jq -r '.members[]' | while read -r member; do
            echo "Adding $member to team $team_name"
            curl -s -X PUT "http://localhost:3000/api/v1/teams/$team_id/members/$member" \
                -u "admin:admin123" || true
        done
    fi
done

echo "Data import completed successfully!"