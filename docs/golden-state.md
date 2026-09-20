# Golden State

The state every fresh start restores.

1. Personas: `scripts/seed-data/personas.ts`; app seeders: `scripts/seed-data/apps.ts`.
2. `npm run seed` populates the running environment and rewrites `docs/credentials/`.
3. `npm run golden:capture -- [service...]` writes each service's database, plus Gitea's and Matomo's config files, into the files the images load, and prints the rebuild steps. `scripts/golden-state.ts` lists what each service captures and the session, token, cache and rate-limit data it leaves out. `--check` diffs a fresh capture against the committed files instead; `npm run golden:check` checks the committed files without a running environment.

A new database also needs `create_db_for_site` and `load_sql` lines in `core/postgres/init-databases.sh` (or the mysql equivalent).

## Restore

Postgres and mysql restore the golden state (or the `the_zoo snapshot restore` baseline) on every start, except after an unclean shutdown such as an OOM kill, which keeps the data; `the_zoo state` shows which happened. `the_zoo reset` (`npm run cli -- reset` here) always restores them, and recreates the apps and the services that use them. Files that belong to a database, such as Gitea's repos, reset with it, and services that cache its state restart when it's restored (`core/follow-restore.sh`, the `zoo.db` and `zoo.snapshot` labels).

Captures are baked in at build time, so they take effect after a rebuild of the images `golden:capture` prints (each capture's `rebuild` in `scripts/golden-state.ts`):

```bash
docker compose build <images> && docker compose up -d <images>
```
