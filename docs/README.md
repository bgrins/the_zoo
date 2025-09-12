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
- [Crawler](./crawler.md) - Web crawler configuration

## CLI

- publish with `npm run cli:publish`
- debug with `dist && npm link && the_zoo`
- unlink with `npm unlink -g the_zoo`
- `cd /tmp && NODE_ENV=production the_zoo start --proxy-port 3129 --verbose --dry-run`
