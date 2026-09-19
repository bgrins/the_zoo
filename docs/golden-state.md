# Golden State

Captured state restored on each fresh start.

## Seeding

1. User personas defined in `scripts/seed-data/personas.ts`
2. App seeders in `scripts/seed-data/apps.ts`
3. Run `npm run seed` to populate services
4. Capture state as shown below

## PostgreSQL

Capture a service's database into the seed file that `core/postgres/init-databases.sh` loads:

```bash
docker compose exec -T postgres pg_dump --no-acl {flags} -U {service}_user {service}_db > core/postgres/seed/{file}
```

The flags leave out the session, login-token and audit rows that logins create, so repeated captures don't churn (the tables stay, empty):

| `{service}` | `{file}`           | `{flags}`                                                                        |
| ----------- | ------------------ | -------------------------------------------------------------------------------- |
| auth        | `auth.sql`         |                                                                                  |
| focalboard  | `focalboard.sql`   | `--exclude-table-data=public.sessions`                                           |
| gitea       | `gitea.sql`        | `--exclude-table-data=public.auth_token --exclude-table-data=public.session`     |
| mattermost  | `mattermost.sql`   | `--exclude-table-data=public.sessions --exclude-table-data=public.audits`        |
| miniflux    | `miniflux.zoo.sql` | `--exclude-table-data=public.sessions --exclude-table-data=public.user_sessions` |
| stalwart    | `stalwart.sql`     | see below                                                                        |

For Gitea, `scripts/seed-data/capture-gitea-state.sh` runs this dump and also captures the app data.

Stalwart needs a filter instead of flags: its tables `public.m` and `public.y` mix expiring rate-limit counters with data that must stay, and the first byte of each key names the entry's kind. The filter drops the RCPT (`0x02`), authentication (`0x05`), SMTP (`0x06`), authenticated HTTP (`0x08`) and anonymous HTTP (`0x09`) rate-limit rows from the dump and keeps every other row, such as the Bayes (`0x11`) and trusted-reply (`0x13`) entries. It edits the dump, not the live database:

```bash
docker compose exec -T postgres pg_dump --no-acl -U stalwart_user stalwart_db \
  | awk '/^COPY public\.[my] /{copy=1} /^\\\.$/{copy=0} !(copy && /^\\\\x0[25689]/)' \
  > core/postgres/seed/stalwart.sql
```

A new service's seed file also needs `create_db_for_site` and `load_sql` lines in `core/postgres/init-databases.sh`.

Restore: `docker compose restart postgres` resets every database to the state built into the image. The image loads the seed files at build time, so a new capture takes effect after a rebuild:

```bash
docker compose build postgres && docker compose up -d postgres
```

## File-Based State

Capture:

```bash
cp -r sites/apps/{service}/data sites/apps/{service}/data-golden
```

Restore in entrypoint:

```bash
if [ -d /golden-data ] && [ ! -f "$DATA_PATH/INSTALLED" ]; then
    cp -r /golden-data/* "$DATA_PATH/"
fi
```

## Service Notes

| Service    | Golden State                                                         |
| ---------- | -------------------------------------------------------------------- |
| Stalwart   | `core/postgres/seed/stalwart.sql`                                    |
| Gitea      | `core/postgres/seed/gitea.sql` + `sites/apps/gitea.zoo/data-golden/` |
| SnappyMail | `sites/apps/snappymail.zoo/data-golden/`                             |
| Mattermost | `core/postgres/seed/mattermost.sql`                                  |
