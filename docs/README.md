# The Zoo Documentation

- [Databases](./databases.md)
- [Golden State](./golden-state.md)
- [Email](./email.md)
- [Analytics](./analytics.md)

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

## Built Images

All compose projects on a host (worktrees, `ZOO_DEV=1` CLI instances) share the built `the_zoo-{service}` images; `start:fresh`'s unseeded databases are `the_zoo-{postgres,mysql}-noseed-true`. A build from other sources replaces them for every project, and each project's next `up` recreates the affected containers. `npm start` rebuilds from the current checkout; `npm run start:quick` uses whatever was built last.

## CLI Release

1. Bump `cli/package.json` and push to main (builds `-dev` images).
2. Tag that commit `v<version>` (it must match, and Check must have run on it) and push the tag.
3. Wait for the tag's publish run. Make any newly created ghcr package (e.g. `coredns`) public, then re-run its `release-smoke-test` job.
4. `npm run publish:cli` (checks every image is public for amd64 and arm64 first).

Local testing: `npm run build:cli && (cd dist && npm link)`, then `the_zoo --help`; `npm unlink -g the_zoo` when done. `npm run publish:cli:dry` does a dry run.
