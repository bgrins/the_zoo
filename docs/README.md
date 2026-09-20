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

## Built Images

Every compose project on a host shares the built images, which are named `the_zoo-{service}` (the unseeded databases of `npm run start:fresh` use `the_zoo-{postgres,mysql}-noseed-true`). Worktrees and `ZOO_DEV=1` CLI instances therefore start without rebuilding. `npm start` and `npm run start:fresh` build under the project name `the_zoo`, so identical sources give identical images in every checkout.

A build from different sources replaces the images the other projects use, and their next `docker compose up` recreates the affected containers. For postgres and mysql that means a restore of the other build's golden data. `npm start` rebuilds from the current checkout, while `npm run start:quick` uses whatever was built last.

## Additional Docs

- [Database Management](./databases.md)
- [Golden State](./golden-state.md)
- [Email System](./email.md)
- [Analytics](./analytics.md)

## CLI Release Process

1. Bump version in `cli/package.json`
2. Commit and push to main (triggers `-dev` Docker images)
3. Tag that main commit: `git tag v0.10.0 && git push origin v0.10.0` (triggers release images). The tag must be `v` plus the version in `cli/package.json`, or the publish workflow fails. The workflow also waits for the commit's `tests` check, so tag a commit that Check has run on.
4. Wait for the tag's "Build and Publish Docker Images" run to finish; until then the `0.10.0` images don't exist.
5. Make any new image public. A new image's first push (for example `coredns`) creates its ghcr package as private, and CLI users can't pull from a private package. On the package's GitHub page, open Package settings and change the visibility to Public.
6. Publish: `npm run publish:cli`

Dev/debug:

```bash
npm run build:cli && (cd dist && npm link)  # Link globally
the_zoo --help
npm unlink -g the_zoo                       # Unlink when done
npm run publish:cli:dry                     # Dry-run publish
```
