# Golden State

Captured state restored on each fresh start.

## Seeding

1. User personas defined in `scripts/seed-data/personas.ts`
2. App seeders in `scripts/seed-data/apps.ts`
3. Run `npm run seed` to populate services
4. Capture state as shown below

## Capture

`npm run golden:capture -- [service...]` dumps each service's database, plus Gitea's and Matomo's config files, from the running environment into the files the images load, then prints the rebuild steps. `scripts/golden-state.ts` lists what each service captures and the session, token and rate-limit rows it leaves out. `--check` diffs a fresh capture against the committed files instead of writing them; `npm run golden:check` checks the committed files without a running environment.

A new service's seed file also needs `create_db_for_site` and `load_sql` lines in `core/postgres/init-databases.sh`.

Restore: `docker compose restart postgres` resets every database to the state built into the image. The image loads the seed files at build time, so a new capture takes effect after a rebuild:

```bash
docker compose build postgres && docker compose up -d postgres
```

## Service Notes

| Service    | Golden State                                                         |
| ---------- | -------------------------------------------------------------------- |
| Stalwart   | `core/postgres/seed/stalwart.sql`                                    |
| Gitea      | `core/postgres/seed/gitea.sql` + `sites/apps/gitea.zoo/data-golden/` |
| SnappyMail | `sites/apps/snappymail.zoo/data-golden/`                             |
| Mattermost | `core/postgres/seed/mattermost.sql`                                  |
