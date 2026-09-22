# Databases

Convention: `{service}_db`, `{service}_user`, `{service}_pw`.

- **PostgreSQL**: `postgres://{service}_user:{service}_pw@postgres.zoo/{service}_db`
- **MySQL**: `mysql://{service}_user:{service}_pw@mysql/{service}_db`

They restore on every start ([golden-state.md](golden-state.md#restore)).

## Adding a Database

1. Add `create_db_for_site "myservice"` to `core/postgres/init-databases.sh`.
2. Point the service at `postgres://myservice_user:myservice_pw@postgres.zoo/myservice_db`, label it `zoo.db=postgres` (`zoo.db=mysql` for MySQL), and if it caches database state or keeps files, wrap its entrypoint in `core/follow-restore.sh`, as gitea-zoo does.
3. `docker compose build postgres && docker compose up -d postgres`.
4. To keep its data, add it to `scripts/golden-state.ts` with `file: "core/postgres/seed/myservice.sql"`, capture ([golden-state.md](golden-state.md)), and load the capture with `load_sql "myservice" "/seed/myservice.sql"` after the `create_db_for_site` line.

MySQL loads only the dumps its Dockerfile copies: a new dump needs its path in the `COPY ... /tmp/sql/` list in `core/mysql/Dockerfile` and `create_db_for_site`/`load_sql` lines in `core/mysql/init-databases.sh`.
