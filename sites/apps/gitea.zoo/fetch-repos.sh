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

# Additional sample repositories from import-data.json
echo "Creating additional sample repositories..."

# Bob's zoo-api-client
mkdir -p /app/git-data/bob
cd /tmp
git init zoo-api-client
cd zoo-api-client
git config user.email "bob@gitea.zoo"
git config user.name "Bob Smith"

cat > README.md << 'EOF'
# Zoo API Client

A TypeScript client library for interacting with Zoo services.

## Installation

```bash
npm install zoo-api-client
```

## Usage

```typescript
import { ZooClient } from 'zoo-api-client';

const client = new ZooClient({
  baseURL: 'http://api.zoo'
});

const result = await client.getAnimals();
```
EOF

mkdir -p src
cat > package.json << 'EOF'
{
  "name": "zoo-api-client",
  "version": "0.1.0",
  "description": "API client for Zoo services",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "test": "jest"
  },
  "devDependencies": {
    "@types/node": "^18.0.0",
    "typescript": "^5.0.0"
  }
}
EOF

cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true
  }
}
EOF

cat > src/index.ts << 'EOF'
export class ZooClient {
  private baseURL: string;

  constructor(config: { baseURL: string }) {
    this.baseURL = config.baseURL;
  }

  async getAnimals() {
    const response = await fetch(`${this.baseURL}/animals`);
    return response.json();
  }
}
EOF

git add .
git commit -m "Initial commit"
git clone --bare . /app/git-data/bob/zoo-api-client.git
cat > /app/git-data/bob/zoo-api-client.json << 'EOF'
{"owner": "bob", "name": "zoo-api-client", "description": "API client library for Zoo services", "private": false}
EOF
cd / && rm -rf /tmp/zoo-api-client

# Zoo Labs utilities
mkdir -p /app/git-data/zoo-labs
cd /tmp
git init zoo-utilities
cd zoo-utilities
git config user.email "admin@gitea.zoo"
git config user.name "Zoo Labs"

cat > README.md << 'EOF'
# Zoo Utilities

A collection of utility functions and helpers for Zoo applications.

## Features

- Authentication helpers
- Database utilities
- Common middleware
- Validation functions

## Installation

```bash
npm install @zoo-labs/utilities
```
EOF

mkdir -p lib
cat > package.json << 'EOF'
{
  "name": "@zoo-labs/utilities",
  "version": "1.2.0",
  "description": "Common utilities for Zoo applications",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "lint": "eslint ."
  }
}
EOF

cat > index.js << 'EOF'
module.exports = {
  auth: require('./lib/auth'),
  db: require('./lib/db'),
  validators: require('./lib/validators')
};
EOF

cat > lib/auth.js << 'EOF'
// Authentication utilities
module.exports = {
  generateToken: () => {
    return Math.random().toString(36).substring(2);
  },
  validateToken: (token) => {
    return token && token.length > 0;
  }
};
EOF

git add .
git commit -m "Initial commit"
git clone --bare . /app/git-data/zoo-labs/zoo-utilities.git
cat > /app/git-data/zoo-labs/zoo-utilities.json << 'EOF'
{"owner": "zoo-labs", "name": "zoo-utilities", "description": "Common utilities for Zoo applications", "private": false}
EOF
cd / && rm -rf /tmp/zoo-utilities

# Community awesome-zoo
mkdir -p /app/git-data/community
cd /tmp
git init awesome-zoo
cd awesome-zoo
git config user.email "community@gitea.zoo"
git config user.name "Zoo Community"

cat > README.md << 'EOF'
# Awesome Zoo 🦁

A curated list of awesome Zoo resources, tools, and projects.

## Contents

- [Official Resources](#official-resources)
- [Community Projects](#community-projects)
- [Tools](#tools)
- [Tutorials](#tutorials)

## Official Resources

- [Zoo Documentation](http://docs.zoo)
- [Zoo API Reference](http://api.zoo/docs)
- [Zoo Blog](http://blog.zoo)

## Community Projects

- [zoo-api-client](http://gitea.zoo/bob/zoo-api-client) - API client library
- [hello-zoo](http://gitea.zoo/alice/hello-zoo) - Simple starter project

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.
EOF

cat > CONTRIBUTING.md << 'EOF'
# Contributing to Awesome Zoo

Contributions are welcome! Please follow these guidelines:

1. Make sure the resource is actually awesome
2. Add it to the appropriate section
3. Keep descriptions concise
4. Check your spelling and grammar
EOF

git add .
git commit -m "Initial commit"
git clone --bare . /app/git-data/community/awesome-zoo.git
cat > /app/git-data/community/awesome-zoo.json << 'EOF'
{"owner": "community", "name": "awesome-zoo", "description": "A curated list of awesome Zoo resources", "private": false}
EOF
cd / && rm -rf /tmp/awesome-zoo

# Charlie's zoo-docker-templates
mkdir -p /app/git-data/charlie
cd /tmp
git init zoo-docker-templates
cd zoo-docker-templates
git config user.email "charlie@gitea.zoo"
git config user.name "Charlie Brown"

cat > README.md << 'EOF'
# Zoo Docker Templates

Ready-to-use Docker configurations for common Zoo services.

## Available Templates

- `webapp/` - Basic web application template
- `api/` - REST API service template
- `worker/` - Background worker template
- `database/` - Database configuration templates

## Usage

Copy the template you need and customize for your service:

```bash
cp -r webapp/ my-zoo-app/
cd my-zoo-app/
docker-compose up
```
EOF

mkdir -p webapp
cat > webapp/docker-compose.yml << 'EOF'
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    volumes:
      - .:/app
      - /app/node_modules
EOF

cat > webapp/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "start"]
EOF

git add .
git commit -m "Initial commit"
git clone --bare . /app/git-data/charlie/zoo-docker-templates.git
cat > /app/git-data/charlie/zoo-docker-templates.json << 'EOF'
{"owner": "charlie", "name": "zoo-docker-templates", "description": "Docker templates for Zoo services", "private": false}
EOF
cd / && rm -rf /tmp/zoo-docker-templates

echo "Repository fetching complete!"
ls -la /app/git-data/