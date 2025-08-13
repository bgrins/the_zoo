#!/bin/sh
set -e

echo "Fetching git repositories during build..."

# Create directory for storing git data
mkdir -p /app/git-data

# Define repositories to fetch
cat > /app/git-data/repos.json << 'EOF'
{
  "repositories": [
    {
      "url": "https://github.com/expressjs/express.git",
      "owner": "alice",
      "name": "express-mirror",
      "description": "Mirror of Express.js - Fast, unopinionated, minimalist web framework",
      "branch": "master"
    },
    {
      "url": "https://github.com/visionmedia/debug.git",
      "owner": "bob",
      "name": "debug-mirror",
      "description": "Mirror of debug - A tiny JavaScript debugging utility",
      "branch": "master"
    },
    {
      "url": "https://github.com/tj/commander.js.git",
      "owner": "zoo-labs",
      "name": "commander-mirror",
      "description": "Mirror of Commander.js - node.js command-line interfaces made easy",
      "branch": "master"
    },
    {
      "url": "https://github.com/sindresorhus/awesome.git", 
      "owner": "community",
      "name": "awesome-mirror",
      "description": "Mirror of Awesome lists about all kinds of interesting topics",
      "branch": "main"
    },
    {
      "url": "https://github.com/gothinkster/realworld.git",
      "owner": "charlie",
      "name": "realworld-mirror", 
      "description": "Mirror of RealWorld example apps - The mother of all demo apps",
      "branch": "main"
    }
  ]
}
EOF

# Clone repositories as bare repos to save space
echo "Cloning repositories..."
jq -c '.repositories[]' /app/git-data/repos.json | while read -r repo; do
    url=$(echo "$repo" | jq -r '.url')
    owner=$(echo "$repo" | jq -r '.owner')
    name=$(echo "$repo" | jq -r '.name')
    branch=$(echo "$repo" | jq -r '.branch')
    
    echo "Fetching $owner/$name from $url"
    
    # Create owner directory
    mkdir -p "/app/git-data/$owner"
    
    # Clone as bare repository
    git clone --bare --depth 50 --single-branch --branch "$branch" "$url" "/app/git-data/$owner/$name.git" || {
        echo "Failed to clone $url, creating empty repo"
        git init --bare "/app/git-data/$owner/$name.git"
    }
    
    # Save metadata
    echo "$repo" > "/app/git-data/$owner/$name.json"
done

# Create a simple local repository as well
echo "Creating sample local repositories..."

# Hello Zoo repo
mkdir -p /app/git-data/alice
cd /tmp
git init hello-zoo
cd hello-zoo
git config user.email "alice@gitea.zoo"
git config user.name "Alice Johnson"

cat > README.md << 'EOF'
# Hello Zoo

Welcome to the Zoo! This is a simple demonstration repository.

## Getting Started

```bash
npm install
npm start
```

## Features

- Simple Express.js server
- Zoo-themed welcome page
- Integration examples

## Contributing

Feel free to submit pull requests!
EOF

cat > package.json << 'EOF'
{
  "name": "hello-zoo",
  "version": "1.0.0",
  "description": "Hello World for the Zoo",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

cat > index.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('<h1>Hello from the Zoo!</h1>');
});

app.listen(port, () => {
  console.log(`Hello Zoo app listening at http://localhost:${port}`);
});
EOF

git add .
git commit -m "Initial commit"
git clone --bare . /app/git-data/alice/hello-zoo.git

# Save metadata
cat > /app/git-data/alice/hello-zoo.json << 'EOF'
{
  "owner": "alice",
  "name": "hello-zoo",
  "description": "A simple Hello World application for the Zoo",
  "private": false
}
EOF

cd /
rm -rf /tmp/hello-zoo

echo "Repository fetching complete!"
ls -la /app/git-data/