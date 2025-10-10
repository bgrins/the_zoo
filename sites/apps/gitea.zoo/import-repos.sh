#!/bin/sh
set -e

echo "Starting repository and organization import..."

# Create organizations first
echo "Creating organizations..."
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

# Register ALL pre-baked repositories from Docker build
echo "Registering pre-baked repositories..."
find /data/git/repositories -name "*.git" -type d | while read -r repo_path; do
    # Extract owner and repo name from path
    # Format: /data/git/repositories/{owner}/{name}.git
    repo_rel_path=${repo_path#/data/git/repositories/}
    owner=$(dirname "$repo_rel_path")
    name=$(basename "$repo_rel_path" .git)

    # Skip if not a valid structure
    if [ "$owner" = "." ] || [ -z "$name" ]; then
        continue
    fi

    echo "Registering repository: $owner/$name"

    # Find metadata for this repo (from fetch-repos.sh)
    metadata_file="/app/sample-data/import-data.json"
    description=""
    private="false"

    # Try to find the description from sample data
    description=$(jq -r ".repositories[] | select(.owner == \"$owner\" and .name == \"$name\") | .description // empty" "$metadata_file")

    # If not found in sample data, check for a cached metadata file
    if [ -z "$description" ] && [ -f "/app/git-data/$owner/$name.json" ]; then
        description=$(jq -r '.description // empty' "/app/git-data/$owner/$name.json")
    fi

    # Save the existing repo data to temp location
    temp_repo="/tmp/$owner-$name.git"
    mv "/data/git/repositories/$owner/$name.git" "$temp_repo"

    # Create empty repository via API as the owner
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
            }" > /dev/null
    else
        # Create in user namespace (authenticate as the user)
        curl -s -X POST "http://localhost:3000/api/v1/user/repos" \
            -H "Content-Type: application/json" \
            -u "$owner:${owner}123" \
            -d "{
                \"name\": \"$name\",
                \"description\": \"$description\",
                \"private\": $private,
                \"auto_init\": false
            }" > /dev/null
    fi

    # Replace the empty repo with our existing data
    sleep 1  # Give Gitea time to create the empty repo
    rm -rf "/data/git/repositories/$owner/$name.git"
    mv "$temp_repo" "/data/git/repositories/$owner/$name.git"
done

# Add team members
echo "Adding team members..."
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

echo "Repository and organization import completed!"