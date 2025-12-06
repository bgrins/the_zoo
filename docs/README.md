# The Zoo Documentation

## Quick Reference

### Service Endpoints

| Service       | Internal Address | Port                        | Purpose                    |
| ------------- | ---------------- | --------------------------- | -------------------------- |
| PostgreSQL    | `postgres.zoo`   | 5432                        | Primary database           |
| MySQL         | `mysql`          | 3306                        | Alternative database       |
| Redis         | `redis.zoo`      | 6379                        | Cache/sessions             |
| Stalwart Mail | `stalwart`       | 25 (SMTP), 587 (SMTP+Auth)  | Email server               |
| Stalwart API  | `mail-api.zoo`   | 8080                        | Mail management API        |
| Squid Proxy   | `proxy`          | 3128                        | HTTP proxy (bound to host) |
| Caddy         | `caddy`          | 80/443                      | Web server/reverse proxy   |
| Hydra OAuth2  | `hydra`          | 4444 (public), 4445 (admin) | OAuth2 provider            |

### Database Connection Strings

**PostgreSQL**: `postgres://{service}_user:{service}_pw@postgres.zoo/{service}_db`\
**MySQL**: `mysql://{service}_user:{service}_pw@mysql/{service}_db`

Example: `postgres://wiki_user:wiki_pw@postgres.zoo/wiki_db`

### Essential Commands

```bash
# Generate/update configuration after adding services
npm run generate-config

# Run tests
npm run test:smoke      # Quick smoke tests
npm run test            # Full test suite
npm run precommit       # Fix linting/formatting

# Database operations
docker exec thezoo-postgres-1 psql -U postgres -c "\l"  # List databases
docker exec thezoo-postgres-1 psql -U {service}_user -d {service}_db  # Connect to database

# Email operations
npm run cli email users                    # List email users
npm run cli email check --user user@zoo    # Check inbox

# Container management
docker compose up -d SERVICE_NAME --force-recreate  # Restart a service
docker compose logs -f SERVICE_NAME                 # Follow logs
```

## Additional Documentation

- [Database Management](./databases.md) - Adding databases, connection details
- [Golden State](./golden-state.md) - Seeding and state management
- [Caddy](./caddy.md) - On demand containers, chaos mode, network details
- [Email System](./email.md) - Stalwart mail configuration

## CLI

### Releasing a New Version

The release process coordinates npm package publishing with Docker image tagging:

1. **Update the CLI version** in `cli/package.json`:
   ```bash
   # Edit cli/package.json and bump the version (e.g., 0.0.6 -> 0.0.7)
   ```

2. **Commit and push to main**:
   ```bash
   git add cli/package.json
   git commit -m "Bump CLI version to 0.0.7"
   git push origin main
   ```
   This triggers CI to build and push Docker images tagged with `0.0.7-dev` and `latest`.

3. **Create and push a git tag**:
   ```bash
   git tag v0.0.7
   git push origin v0.0.7
   ```
   This triggers CI to build and push Docker images tagged with `0.0.7` (release version).

4. **Publish to npm**:
   ```bash
   npm run cli:publish
   ```
   The build script stamps the CLI version into `docker-compose.packages.yaml`, so the npm package pulls the matching Docker images.

### How Versioning Works

- **Docker images** are tagged based on git ref:
  - Branch push (main): `latest`, `main`, `{version}-dev`
  - Tag push (v*): `{version}` (e.g., `0.0.7`)
- **npm package** has the version hardcoded as the default in `docker-compose.packages.yaml`
- Users can override with `ZOO_IMAGE_TAG` env var (e.g., `ZOO_IMAGE_TAG=0.0.7-dev`)

### Development & Debugging

```bash
# Build CLI to dist/ and link globally for testing
npm run build:cli && cd dist && npm link

# Now you can run the CLI from anywhere
the_zoo --help

# Unlink when done
npm unlink -g the_zoo

# Test production mode locally
cd /tmp && NODE_ENV=production the_zoo start --proxy-port 3129 --verbose --dry-run

# Dry-run npm publish to see what would be included
npm run publish:cli:dry
```
