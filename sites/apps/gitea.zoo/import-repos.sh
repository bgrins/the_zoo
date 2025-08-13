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

# Register pre-existing repositories in the database
echo "Registering pre-existing repositories..."
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
    
    # Find metadata for this repo
    metadata_file="/app/sample-data/import-data.json"
    description=""
    private="false"
    
    # Try to find the description from sample data
    description=$(jq -r ".repositories[] | select(.owner == \"$owner\" and .name == \"$name\") | .description // empty" "$metadata_file")
    
    # If not found in sample data, check for a cached metadata file
    if [ -z "$description" ] && [ -f "/app/git-data/$owner/$name.json" ]; then
        description=$(jq -r '.description // empty' "/app/git-data/$owner/$name.json")
    fi
    
    # Create repo entry via API
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
    fi
done

# Also create repositories from sample-data.json that aren't git repos
echo "Creating additional sample repositories..."
jq -c '.repositories[]' /app/sample-data/import-data.json | while read -r repo; do
    owner=$(echo "$repo" | jq -r '.owner')
    name=$(echo "$repo" | jq -r '.name')
    
    # Check if this repo already exists as a git repo
    if [ -d "/data/git/repositories/$owner/$name.git" ]; then
        echo "Repository $owner/$name already exists as git repo"
        continue
    fi
    
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
    echo "$repo" | jq -r '.files | to_entries[] | @base64' | while read -r entry; do
        filename=$(echo "$entry" | base64 -d | jq -r '.key')
        content=$(echo "$entry" | base64 -d | jq -r '.value')
        
        if [ -n "$filename" ] && [ -n "$content" ]; then
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