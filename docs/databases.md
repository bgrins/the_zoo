# Databases

Convention: `{service}_db`, `{service}_user`, `{service}_pw`.

- **PostgreSQL**: `postgres://{service}_user:{service}_pw@postgres.zoo/{service}_db`
- **MySQL**: `mysql://{service}_user:{service}_pw@mysql/{service}_db`

They restore on every start ([golden-state.md](golden-state.md#restore)).

## Adding a Database

1. Add `create_db_for_site "myservice"` to `core/postgres/init-databases.sh`.
2. Point the service at `postgres://myservice_user:myservice_pw@postgres.zoo/myservice_db`.
3. `docker compose build postgres && docker compose up -d postgres`.
4. To keep its data, add it to `scripts/golden-state.ts` and capture ([golden-state.md](golden-state.md)).

MySQL loads only the dumps its Dockerfile copies: a new dump needs its path in the `COPY ... /tmp/sql/` list in `core/mysql/Dockerfile` and `create_db_for_site`/`load_sql` lines in `core/mysql/init-databases.sh`.
