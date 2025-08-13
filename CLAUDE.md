# The Zoo

You are in "The Zoo", a **development-only** simulated web environment implemented in a monorepo. We build full-featured web apps with the .zoo domain, using a variety of backend technologies and approaches.

**IMPORTANT**: This is a development environment designed for rapid prototyping and testing. It intentionally prioritizes developer experience over security and production readiness. DO NOT use any of these configurations or approaches in production environments.

The zoo environment is created from scratch at each startup. Domains are listed in docker-compose.yaml labels and can be seen on http://status.zoo inside the container environment.

## Quick Start

Before you begin, read these essential files:

- `docker-compose.yaml` - Container and service definitions
- `package.json` - Available npm commands
- `scripts/` - Helper scripts
- `core/caddy/Caddyfile` - Available sites

The Squid proxy binds to port 3128 on the host by default - this is the "only" port that gets bound to the host. However, environemnt can override this with the `ZOO_PROXY_PORT` environment variable. You can confirm the exact port at startup for reference with future commands using:

`docker compose ps proxy --format json | jq -r '.Publishers[0].PublishedPort'`

## Environment & Architecture

### Docker Environment

- **All apps run inside Docker. Do not install or run apps on the host** - Never install/run/test apps on the host machine
- Container naming: `{PROJECT_NAME}-SERVICE_NAME-1` (e.g., `thezoo-stalwart-1`)
- Apps cannot connect to the internet - downloads must happen in Dockerfile or ahead of time in volumes

### Accessing Sites

- Zoo domains do NOT run on the host network
- Access sites via:
  - The `zoo-playwright` browser (preconfigured with proxy)
  - Shared scripts in `./scripts`
  - `curl -k --proxy http://localhost:3128`
  - Direct docker commands

### Database Setup

Databases must be explicitly configured for each service. See [Database Management](../docs/databases.md) for details.

Standard naming convention:

- Database: `{service_name}_db`
- User: `{service_name}_user`
- Password: `{service_name}_pw`

### Database Seeding Process

The Zoo uses a centralized seeding system for consistent user data across all services:

1. **Seed Scripts**: User personas are defined in `scripts/seed-data/personas.ts` with consistent usernames/passwords
2. **App Seeders**: Each app has a seeder in `scripts/seed-data/apps.ts` that creates users via APIs
3. **Email Convention**: All users have `@snappymail.zoo` email addresses for consistency across services
4. **Running Seeds**: Use `npm run seed` to populate all services with test users
5. **Capturing State**: After seeding, database dumps are captured and baked into container images

**Important**: Never add seed data directly to migration files. Always use the centralized seeding process to ensure consistency.

### Crawler

For information on configuring and using the web crawler, see [Crawler Documentation](../docs/crawler.md).

## Development Workflow

### Adding New Apps

1. For static sites: place in `sites/static/{domain}/dist/`
2. For web services: add them in `docker-compose.yaml`

- All apps MUST have `profiles: ["on-demand"]` for on-demand startup
- If a you have a custom Dockerfile, put it in `sites/apps/DOMAIN.zoo` and the DNS will be set up automatically
- If you need to assign a custom domain or are using a remote image, use the `zoo.domains` label in docker-compose.
  - Use format `zoo.domains=domain.zoo` for default ports
  - Use format `zoo.domains=domain.zoo:PORT` to specify custom ports

2. Run `npm run generate-config` to update DNS & Caddy, then restart all affected containers (`docker compose up -d SERVICE_NAME --force-recreate` usually works well).
3. Add basic integration test in `tests/sites`

When adding an external docker image - grab the latest current version but pin it to a tag for consistent pulling. We want to use the current-latest version of docker images, NOT `:latest`. There's a helper script in `scripts/docker-latest-version.sh` to help with discovering this for new images.

### On-Demand Container Startup

Containers with `profiles: ["on-demand"]` don't start automatically. They're managed by Caddy's `on_demand_docker` module:

1. **Initial Setup**: `npm start` creates all containers (including on-demand) without starting them
2. **On Access**: When a domain is accessed, Caddy automatically starts the container
3. **Important**: The container must exist before it can be started on-demand
4. **Manual Start**: Use `docker compose --profile on-demand up -d SERVICE_NAME --force-recreate` if needed

### Comments policy

- Only write high-value comments if at all.
- NEVER talk to the user through comments in code — use the chat for that.
- You don't need pointless comments, assume people reading the code are smart.

### Zoo-Specific Development Guidelines

- **Development Environment Only** - This is not designed for production use
- **No production builds** - Apps run in development mode with hot reloading (tsx watch etc)
- **Use ESM and modern APIs** when in Node.js
- **Prefer boring technologies** unless requested otherwise
- **Follow existing patterns** for containers, frameworks, and languages
- **Use `git mv` instead of `mv` when renaming files**
- **No app-specific linting or formatting rules** - The project manages these from the top directories
- **Ensure reproducibility** - No one-off state mutations to fix issues — everything should work from fresh startup
- **Fix the root cause** - No workarounds.
- **Security within Zoo containers** - Security is deprioritized for developer convenience inside the isolated Zoo environment. However, maintain strict security for any code that runs on the host machine or could affect the host system.
- **If you don't know, look online** - When it occurs to you that you need to research something that you don’t know, actually research it online rather than pulling it or from memory or hallucinating.

### Commit Messages

- Keep commit messages terse and to the point
- Focus on what changed, not process details
- Don't include checklists or status updates (e.g., "tests passing", "linting complete")
- Reference issues by number when applicable (e.g., "Fix authentication bug (#177)")

### Postgres Troubleshooting

- Never forcefully modify database state or manually create databases. Instead restart postgres so that it runs the creation step on its own.

### Testing & Debugging

- When writing tests, do not add lenient conditions around assertions and return values. The zoo should be deterministic - do not be shy about asserting exactly what is supposed to happen.
- When writing tests, DO NOT BE LAZY. Examples include hardcode things to make a failing test pass, or skipping a failing test. If you are certain the test is invalid say so and propose a change but do not do it as a shortcut to get the test to path.
- When debugging a specific test failure, prefer to run just that test versus a whole suite.
- When encountering potential issues, let's start with adding logging/error handling instead of resorting to raising timeouts

Essential commands:

- `npm run test:smoke` - Minimal smoke tests (~1 second)
- `npm run test tests/path/to/test.ts` Run an individual test.
- `npm run test:integration` - Full system tests (~30 seconds)
- `npm run precommit` - Fix all linting and formatting issues and then check for linting / formatting / typescript issues

Manual testing:

- Use `zoo-playwright` MCP browser (preconfigured to operate through the forward proxy).
- Debug individual sites with provided scripts

## Pre-Completion Checklist

Before considering any task complete:

1. ✓ Run `npm run fix` auto-fix linting and formatting issues (`npm run precommit` will also do this and will run as a git commit hook automatically, but it's good practice to fix at checkpoints).
2. ✓ Add test cases for any bug fixes
3. ✓ Run `npm run test` to run the full test suite

## CLI Commands

- Use `./dist/bin/thezoo.js` command for many scripts to automate the environment. `npm run cli -- --help` will give usage instructions
- Example commands for debugging:
  - Postgres: `npm run cli shell postgres -- -c "SELECT version();"`
  - Redis: `npm run cli shell redis -- -c "INFO"`
  - Stalwart: `npm run cli shell stalwart -- server list-config`

## Development Tools

`gh` available for GitHub operations
