# Golden State

Captured state restored on each fresh start.

## Seeding

1. User personas defined in `scripts/seed-data/personas.ts`
2. App seeders in `scripts/seed-data/apps.ts`
3. Run `npm run seed` to populate services
4. Capture state as shown below

## PostgreSQL

Capture:

```bash
docker exec the_zoo-postgres-1 pg_dump --no-acl -U {service}_user {service}_db > core/postgres/seed/{service}.sql
```

Restore: `.sql` files in `core/postgres/seed/` run automatically on startup via `init-databases.sh`.

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
