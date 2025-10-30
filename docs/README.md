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
| Meilisearch   | `search-api.zoo` | 7700                        | Search engine              |

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
npm run cli -- email users                  # List email users
npm run cli -- email inbox --user alice     # Check inbox

# Universe operations
npm run universe:list                       # List available universes
npm run universe:load default               # Load a universe
npm run cli -- universe create my-universe --personas alice,bob  # Create universe via CLI

# Container management
docker compose up -d SERVICE_NAME --force-recreate  # Restart a service
docker compose logs -f SERVICE_NAME                 # Follow logs
```

## Additional Documentation

### Core Systems

- [Database Management](./databases.md) - Adding databases, connection details
- [Email System](./email-api.md) - Stalwart mail configuration and email operations
- [Crawler](./crawler.md) - Web crawler configuration

### Universes & Scenarios

- [Universes and Scenarios](./universes-and-scenarios.md) - Architecture and concepts overview
- [Creating Universes](./creating-universes.md) - Step-by-step tutorials (manual and CLI)
- [Universe CLI Reference](./universe-cli-reference.md) - Complete CLI command reference
- [Universe Reference](./universe-reference.md) - JSON schema reference

### Legacy

- [Golden State](./golden-state.md) - Legacy seeding and state management (superseded by universes)

## CLI

- publish with `npm run cli:publish`
- debug with `dist && npm link && the_zoo`
- unlink with `npm unlink -g the_zoo`
- `cd /tmp && NODE_ENV=production the_zoo start --proxy-port 3129 --verbose --dry-run`
