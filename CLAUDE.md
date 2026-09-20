# The Zoo

Development-only simulated web environment. Apps run with .zoo domains inside Docker containers.

**This is NOT for production.** Security is deprioritized for developer convenience inside the isolated environment.

## Architecture

- All apps run inside Docker—never install/run/test on the host
- Apps have no internet access—downloads must happen in Dockerfile or volumes
- Access sites via `zoo-playwright` browser, `curl -k --proxy http://localhost:3128`, or docker commands
- Status page: http://status.zoo (inside container environment)

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

1. Custom Dockerfile: place in `sites/apps/DOMAIN.zoo/` and add a `docker-compose.yaml` service with `build: ./sites/apps/DOMAIN.zoo`. The generator takes the domain from the directory name and the port from `PORT` or `expose`; a `zoo.domains=domain.zoo[:port]` label overrides them. It fails when it can't find a port
2. External image: add to `docker-compose.yaml` with `zoo.domains=domain.zoo` label
3. Static sites: place in `sites/static/{domain}/dist/`

All apps need `profiles: ["on-demand"]`. After adding, run `npm run generate-config` and restart affected containers.

Pin Docker images to specific tags (not `:latest`). Use `scripts/docker-latest-version.sh` to find current versions.

## Databases

See [docs/databases.md](docs/databases.md) for setup and connection strings.

Convention: `{service}_db`, `{service}_user`, `{service}_pw`

Never manually modify database state. `npm run cli -- reset` restores the databases, and the app files that go with them, to the state built into the images (a restart does too, except after a crash); seed and init-script edits take effect only after a rebuild: `docker compose build postgres && docker compose up -d postgres`. See [docs/golden-state.md](docs/golden-state.md).

## Seeding

User personas in `scripts/seed-data/personas.ts`, app seeders in `scripts/seed-data/apps.ts`. Run `npm run seed`. Never add seed data to migration files.

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
