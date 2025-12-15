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

```bash
# PostgreSQL
docker exec the_zoo-postgres-1 pg_dump -U {service}_user -d {service}_db > core/postgres/seed/{service}.sql

# MySQL
docker exec the_zoo-mysql-1 mysqldump -u {service}_user -p{service}_pw {service}_db > core/mysql/sql/{service}.sql
```

Then update `init-databases.sh` to load the dump on startup.
