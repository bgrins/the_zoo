# Golden State

The state every fresh start restores.

1. Personas: `scripts/seed-data/personas.ts`; app seeders: `scripts/seed-data/apps.ts`.
2. `npm run seed` populates the running environment.
3. `npm run golden:capture -- [service...]` writes each service's database, plus Gitea's and Matomo's config files, into the files the images load, and prints the rebuild steps. `scripts/golden-state.ts` lists what each service captures and the session, token and rate-limit rows it leaves out. `--check` diffs a fresh capture against the committed files instead; `npm run golden:check` checks the committed files without a running environment.

A new database also needs `create_db_for_site` and `load_sql` lines in `core/postgres/init-databases.sh` (or the mysql equivalent).

## Restore

Postgres and mysql restore the golden state (or the `the_zoo snapshot restore` baseline) on every start, except after an unclean shutdown such as an OOM kill, which keeps the data; `the_zoo state` shows which happened. `the_zoo reset` (`npm run cli -- reset` here) restores them and restarts the services that use them. Files that belong to a database, such as Gitea's repos, reset with it (`core/follow-restore.sh`, the `zoo.db` and `zoo.snapshot` labels).

Captures are baked in at build time, so they take effect after a rebuild:

```bash
docker compose build postgres && docker compose up -d postgres
```
