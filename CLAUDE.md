# The Zoo

Development-only simulated web environment. Apps run with .zoo domains inside Docker containers.

**This is NOT for production.** Security is deprioritized for developer convenience inside the isolated environment.

## Architecture

- All apps run inside Docker—never install/run/test on the host
- Apps have no internet access—downloads must happen in Dockerfile or volumes
- Access sites via `zoo-playwright` browser, `curl -k --proxy http://localhost:3128`, or docker commands
- Every site is listed on https://home.zoo; `npm run cli -- status` shows the containers

## Key Commands

```bash
npm start                    # Start environment
npm run generate-config      # Update DNS & Caddy config
npm run cli -- --help        # CLI tools
npm run precommit            # Lint, format, typecheck
npm test                     # Run tests
npm test -- tests/path.ts    # Run specific test
npm run test:go              # gofmt, vet and race tests for the Caddy modules
```

## Adding Apps

1. Custom Dockerfile: place in `sites/apps/DOMAIN.zoo/` and add a `docker-compose.yaml` service with `build: ./sites/apps/DOMAIN.zoo`, `image: the_zoo-<service>`, `pull_policy: never` and a `zoo.domains=domain.zoo[:port]` label (port defaults to `PORT` or `expose`). Add it to `docker-compose.packages.yaml` (`ghcr.io/bgrins/the_zoo/<service>`) and the `.github/workflows/docker-publish.yml` matrix.
2. External image: add to `docker-compose.yaml` with `zoo.domains=domain.zoo` label
3. Static sites: place in `sites/static/{domain}/dist/`

All apps need `profiles: ["on-demand"]`, `TZ=UTC` in `environment`, a named volume or tmpfs for each volume the image declares, and a Matomo site ([docs/analytics.md](docs/analytics.md#adding-a-site); `generate-config` warns without one). After adding, run `npm run generate-config` and restart affected containers, the proxy included when `core/proxy/acls.conf` changes.

Built `the_zoo-*` images are shared by every checkout and worktree on the host: a build in one changes them for all.

Pin Docker images to specific tags (not `:latest`). Use `scripts/docker-latest-version.sh` to find current versions.

## Databases

See [docs/databases.md](docs/databases.md) for setup and connection strings.

Convention: `{service}_db`, `{service}_user`, `{service}_pw`

Never modify database state by hand. `npm run cli -- reset` restores the golden state built into the images (a restart does too, except after a crash). Seed and init-script edits need a rebuild of the database's image, e.g. `docker compose build postgres && docker compose up -d postgres`. See [docs/golden-state.md](docs/golden-state.md).

## Seeding

Personas in `scripts/seed-data/personas.ts`, app seeders in `scripts/seed-data/apps.ts`. `npm run seed` changes only the running env (and rewrites `docs/credentials/`); `npm run golden:capture` saves it. Never add seed data to migration files. Write tasks against absolute dates: the saved state stays put while the clock moves, so "11 months ago" drifts.

## Development Guidelines

- Fix root causes, no workarounds
- Ensure reproducibility—everything works from fresh startup
- Prefer boring technologies and existing patterns
- Use `git mv` when renaming files
- No app-specific linting—managed at repo root
- Terse commit messages focused on what changed

## Testing

- Be strict with assertions—the zoo should be deterministic
- Run specific tests when debugging, not the whole suite
- Add logging before raising timeouts

## Before Completing Tasks

1. Run `npm run precommit`
2. Add tests for bug fixes
3. Run `npm test`
