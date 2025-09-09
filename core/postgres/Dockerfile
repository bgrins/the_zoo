FROM postgres:16-alpine AS builder

# PostgreSQL configuration
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=zoopassword
ENV POSTGRES_DB=zoodb
ENV POSTGRES_HOST_AUTH_METHOD=md5

# Copy seed data and init script
COPY seed/ /seed/
COPY init-databases.sh /usr/local/bin/

# Accept build arg for no seeding
ARG ZOO_NO_SEED=false
ENV ZOO_NO_SEED=$ZOO_NO_SEED

# Initialize PostgreSQL with base configuration
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql && \
    su-exec postgres initdb -D /var/lib/postgresql/data && \
# Configure pg_hba.conf to allow md5 connections from Docker network
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf && \
# Start PostgreSQL server directly (no single-user mode needed)
    su-exec postgres pg_ctl -D /var/lib/postgresql/data -l /tmp/postgres.log start && \
# Wait for PostgreSQL to be ready using pg_isready
    until su-exec postgres pg_isready -q; do \
        echo "Waiting for PostgreSQL to be ready..." && \
        sleep 1; \
    done && \
# Now set password and create database using psql
    su-exec postgres psql -U postgres -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';" && \
    su-exec postgres psql -U postgres -c "CREATE DATABASE $POSTGRES_DB;" && \
# Run the database initialization script
    /usr/local/bin/init-databases.sh || (echo "Failed to initialize databases. Logs:" && cat /tmp/postgres.log && exit 1) && \
# Stop PostgreSQL cleanly
    su-exec postgres pg_ctl -D /var/lib/postgresql/data stop -m smart && \
# Wait for PostgreSQL to fully stop
    until ! su-exec postgres pg_isready -q 2>/dev/null; do \
        echo "Waiting for PostgreSQL to stop..." && \
        sleep 1; \
    done

FROM postgres:16-alpine

# Install rsync for faster file copying
RUN apk add --no-cache rsync

# Copy the golden state to a separate directory
COPY --from=builder /var/lib/postgresql/data /var/lib/postgresql/data-golden
# Also copy it to the working directory for first start
COPY --from=builder /var/lib/postgresql/data /var/lib/postgresql/data

# PostgreSQL configuration (must match builder stage)
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=zoopassword
ENV POSTGRES_DB=zoodb
ENV POSTGRES_HOST_AUTH_METHOD=md5

# Copy custom entrypoint script
COPY custom-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["postgres"]
