# Database Management

Databases reset on every restart, except after a crash ([golden-state.md](golden-state.md#postgresql)).

## Adding a Database

1. Update `core/postgres/init-databases.sh`:
   ```bash
   create_db_for_site "myservice"
   ```

2. Add to `docker-compose.yaml`:
   ```yaml
   environment:
     - DATABASE_URL=postgres://myservice_user:myservice_pw@postgres.zoo/myservice_db
   ```

3. Rebuild: `docker compose build postgres && docker compose up -d postgres --force-recreate`

## Connection Strings

- **PostgreSQL**: `postgres://{service}_user:{service}_pw@postgres.zoo/{service}_db`
- **MySQL**: `mysql://{service}_user:{service}_pw@mysql/{service}_db`

## Capturing State

See [golden-state.md](golden-state.md#capture). A new service needs an entry in `scripts/golden-state.ts`.

The MySQL image loads only the dumps its Dockerfile copies. A new dump needs its path in the explicit `COPY ... /tmp/sql/` list in `core/mysql/Dockerfile` and `create_db_for_site` and `load_sql` lines in `core/mysql/init-databases.sh`.
