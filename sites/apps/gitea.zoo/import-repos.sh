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

    # Repositories from the golden DB are already registered; leave their data in place
    if curl -sf -o /dev/null -u "admin:admin123" "http://localhost:3000/api/v1/repos/$owner/$name"; then
        continue
    fi

    echo "Registering repository: $owner/$name"

    description=$(jq -r ".repositories[] | select(.owner == \"$owner\" and .name == \"$name\") | .description // empty" /app/sample-data/import-data.json)

    # Adopting the existing git directory lets Gitea read its default branch, branches and
    # emptiness from the data itself. Adopted repos start private.
    curl -sf -X POST -u "admin:admin123" "http://localhost:3000/api/v1/admin/unadopted/$owner/$name"
    jq -n --arg description "$description" '{description: $description, private: false}' |
        curl -sf -o /dev/null -X PATCH -u "admin:admin123" -H "Content-Type: application/json" \
            -d @- "http://localhost:3000/api/v1/repos/$owner/$name"
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