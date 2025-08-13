#!/bin/sh
set -e

echo "Preparing git repositories for Gitea..."

# Create the target directory structure
mkdir -p /app/gitea-repos

# Copy each repository to the correct location
find /app/git-data -name "*.json" -not -name "repos.json" | while read -r metadata_file; do
    repo_data=$(cat "$metadata_file")
    owner=$(echo "$repo_data" | jq -r '.owner')
    name=$(echo "$repo_data" | jq -r '.name')
    
    git_repo_path="${metadata_file%.json}.git"
    
    if [ -d "$git_repo_path" ]; then
        echo "Preparing repository: $owner/$name"
        mkdir -p "/app/gitea-repos/$owner"
        cp -r "$git_repo_path" "/app/gitea-repos/$owner/$name.git"
    fi
done

echo "Repository preparation complete!"
ls -la /app/gitea-repos/