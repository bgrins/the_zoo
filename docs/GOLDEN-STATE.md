# Golden State Management

Golden state represents the "known good" state of services that should be restored on each fresh start.

## Overview

The Zoo uses golden state to ensure a consistent starting point for development and testing. Golden state is captured once and restored automatically during startup.

## Centralized Seeding Process

The Zoo uses a centralized seeding system for consistent user data:

1. **User Personas**: Defined in `scripts/seed-data/personas.ts`
2. **App Seeders**: Each app has a seeder in `scripts/seed-data/apps.ts`
3. **Running Seeds**: Use `npm run seed` to populate all services
4. **Email Convention**: All users have `@snappymail.zoo` email addresses

After seeding, capture database state as described below.

## Database Golden State (PostgreSQL)

### Capturing Golden State

```bash
# Take a snapshot of a specific database (use --no-acl to skip permission grants)
docker exec the_zoo-postgres-1 pg_dump --no-acl -U {service}_user {service}_db > core/postgres/seed/{service}.sql

# Example for Auth service
docker exec the_zoo-postgres-1 pg_dump --no-acl -U auth_user auth_db > core/postgres/seed/auth.sql

# Example for Stalwart
docker exec the_zoo-postgres-1 pg_dump --no-acl -U stalwart_user stalwart_db > core/postgres/seed/stalwart.sql

# Example for Miniflux
docker exec the_zoo-postgres-1 pg_dump --no-acl -U miniflux_user miniflux_db > core/postgres/seed/miniflux.zoo.sql

# Example for Focalboard
docker exec the_zoo-postgres-1 pg_dump --no-acl -U focalboard_user focalboard_db > core/postgres/seed/focalboard.sql
```

### How It's Restored

- During PostgreSQL startup, all `.sql` files in `core/postgres/seed/` are automatically executed
- The `init-databases.sh` script loads these files in alphabetical order
- This happens before the container is marked as healthy

## File-Based Golden State

### Capturing Golden State

```bash
# Copy the current data directory to a golden state directory
cp -r sites/apps/{service}/data sites/apps/{service}/data-golden

# Example for SnappyMail
cp -r sites/apps/snappymail.zoo/data sites/apps/snappymail.zoo/data-golden
```

### How It's Restored

Services should copy their golden state during startup:

```bash
# Example from a docker-entrypoint.sh
if [ -d /golden-data ] && [ ! -f "$DATA_PATH/INSTALLED" ]; then
    cp -r /golden-data/* "$DATA_PATH/"
fi
```

## Service-Specific Notes

### Stalwart Mail Server

- Golden state: `core/postgres/seed/stalwart.sql`
- User creation: `core/stalwart/create-users.sh` (idempotent)
- Run `npm run seed` to create users via API

### SnappyMail

- Golden state: `sites/apps/snappymail.zoo/data-golden/`
- Includes: `SALT.php`, `INSTALLED`, domain configurations
- Restored via Docker volume mount

## Best Practices

1. **Use Centralized Seeding**: Always use `npm run seed` for user data
2. **Idempotent Scripts**: Ensure scripts can run multiple times safely
3. **Capture After Seeding**: Take snapshots after running seed scripts
4. **Minimal State**: Only include essential configuration and test data
