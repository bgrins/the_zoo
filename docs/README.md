# The Zoo Documentation

## Service Endpoints

| Service       | Address      | Port       |
| ------------- | ------------ | ---------- |
| PostgreSQL    | postgres.zoo | 5432       |
| MySQL         | mysql        | 3306       |
| Redis         | redis.zoo    | 6379       |
| Stalwart Mail | stalwart     | 25, 587    |
| Stalwart API  | mail-api.zoo | 8080       |
| Squid Proxy   | proxy        | 3128       |
| Caddy         | caddy        | 80, 443    |
| Hydra OAuth2  | hydra        | 4444, 4445 |

## Database Connection Strings

- **PostgreSQL**: `postgres://{service}_user:{service}_pw@postgres.zoo/{service}_db`
- **MySQL**: `mysql://{service}_user:{service}_pw@mysql/{service}_db`

## Additional Docs

- [Database Management](./databases.md)
- [Golden State](./golden-state.md)
- [Email System](./email.md)
- [Analytics](./analytics.md)

## CLI Release Process

1. Bump version in `cli/package.json`
2. Commit and push to main (triggers `-dev` Docker images)
3. Tag: `git tag v0.0.X && git push origin v0.0.X` (triggers release images)
4. Publish: `npm run publish:cli`

Dev/debug:

```bash
npm run build:cli && npm link --prefix ./dist  # Link globally
the_zoo --help
npm unlink -g the_zoo                          # Unlink when done
npm run publish:cli:dry                        # Dry-run publish
```
