# Gitea CLI Commands

CLI commands for managing Gitea repositories, users, and organizations in The Zoo.

## Usage

All commands use the Zoo proxy to access `gitea.zoo` and support the `--instance` flag for multi-instance setups.

**Note:** When using `npm run cli`, you must use `--` to separate npm arguments from CLI arguments.

### List Users

```bash
npm run cli -- gitea users
```

### Create User

```bash
npm run cli -- gitea create-user \
  --username alice \
  --email alice@gitea.zoo \
  --password alice123

# Create admin user
npm run cli -- gitea create-user \
  --username admin \
  --email admin@gitea.zoo \
  --password admin123 \
  --admin
```

### Create Organization

```bash
npm run cli -- gitea create-org \
  --name zoo-labs \
  --full-name "Zoo Labs" \
  --description "Official Zoo development organization" \
  --website "https://zoo-labs.zoo"
```

### Create Repository

```bash
# Create user repository
npm run cli -- gitea create-repo \
  --name my-project \
  --owner alice \
  --description "My awesome project"

# Create org repository
npm run cli -- gitea create-repo \
  --name utilities \
  --owner zoo-labs \
  --description "Common utilities" \
  --private
```

### Create Issue

```bash
npm run cli -- gitea create-issue \
  --owner alice \
  --repo my-project \
  --title "Fix bug in authentication" \
  --body "The login form doesn't validate email addresses properly"
```

### Add File to Repository

```bash
npm run cli -- gitea add-file \
  --owner alice \
  --repo my-project \
  --path README.md \
  --content "# My Project\n\nThis is my project" \
  --message "Add README"
```

## API Details

The CLI uses the Gitea REST API via the Zoo proxy:

- **Authentication**: Basic auth with username/password
- **Endpoint**: `https://gitea.zoo/api/v1/...`
- **Proxy**: Routes through `localhost:3128` (or `ZOO_PROXY_PORT`)

### Default Credentials

- Admin: `admin` / `admin123`
- Users: `{username}` / `{username}123`

## Implementation

The Gitea CLI follows the same pattern as the Email CLI:

1. Uses `curl --proxy` to access Gitea through Zoo proxy
2. Supports both Gitea API endpoints and CLI commands
3. Handles authentication with Basic Auth
4. Returns JSON responses for programmatic use

## Example: Populating a Universe

```bash
# Start Zoo with gitea
npm run cli -- start

# Create users
npm run cli -- gitea create-user --username alice --email alice@gitea.zoo --password alice123
npm run cli -- gitea create-user --username bob --email bob@gitea.zoo --password bob123

# Create organization
npm run cli -- gitea create-org --name startup --full-name "Startup Inc"

# Create repository
npm run cli -- gitea create-repo --name backend --owner startup --description "Backend API"

# Add initial file
npm run cli -- gitea add-file \
  --owner startup \
  --repo backend \
  --path README.md \
  --content "# Backend API" \
  --message "Initial commit"

# Create issue
npm run cli -- gitea create-issue \
  --owner startup \
  --repo backend \
  --title "Setup CI/CD pipeline" \
  --body "We need to configure GitHub Actions for automated testing"
```
