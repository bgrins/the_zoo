# Golden State

The state every fresh start restores.

1. Personas: `scripts/seed-data/personas.ts`; app seeders: `scripts/seed-data/apps.ts`; the content the personas share (Gitea issues and pull requests, Mattermost posts, Miniflux feeds), dated as written: `scripts/seed-data/content.ts`.
2. `npm run seed` populates the running environment and rewrites `docs/credentials/`. It builds on the state the golden images load, so it doesn't reproduce that state from an unseeded environment.
3. `npm run golden:capture -- [service...]` writes each service's database, plus the files its capture lists, into the files the images load, and prints the rebuild steps. `scripts/golden-state.ts` lists what each service captures and the session, token, cache and rate-limit data it leaves out. `--check` diffs a fresh capture against the committed files instead; `npm run golden:check` checks the committed files without a running environment.

Gitea's branches and pull request refs beyond the baked repositories are captured as git fast-export streams in `sites/apps/gitea.zoo/git-golden/`, which the image imports at build time. Focalboard's files (the built-in templates' images, and uploads) are captured into `sites/apps/focalboard.zoo/data-golden/`, which docker-compose.yaml mounts.

Where tasks depend on dates, harnesses should pin the browser's time zone and clock: Mattermost follows the browser's time zone, and Gitea shows relative times.

## Restore

Postgres and mysql restore the golden state (or the `the_zoo snapshot restore` baseline) on every start, except after an unclean shutdown such as an OOM kill, which keeps the data; `the_zoo state` shows which happened. `the_zoo reset` (`npm run cli -- reset` here) always restores them, and recreates the apps and the services that use them. Files that belong to a database, such as Gitea's repos, reset with it, and services that cache its state restart when it's restored (`core/follow-restore.sh`, the `zoo.db` and `zoo.snapshot` labels).

Captures are baked in at build time, so they take effect after a rebuild of the images `golden:capture` prints (each capture's `rebuild` in `scripts/golden-state.ts`):

```bash
docker compose build <images> && docker compose up -d <images>
```
