# Database Management

Databases reset on every restart.

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

PostgreSQL: see [golden-state.md](golden-state.md#postgresql) for each service's capture command and seed file.

MySQL:

```bash
docker compose exec -T mysql mysqldump --no-tablespaces -u {service}_user -p{service}_pw {service}_db > core/mysql/sql/{service}.sql
```

The MySQL image loads only the dumps its Dockerfile copies. A new dump needs its path in the explicit `COPY ... /tmp/sql/` list in `core/mysql/Dockerfile` and `create_db_for_site` and `load_sql` lines in `core/mysql/init-databases.sh`. The dumps load at build time, so rebuild after each capture: `docker compose build mysql && docker compose up -d mysql`.
