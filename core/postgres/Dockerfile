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
    su-exec postgres pg_ctl -D /var/lib/postgresql/data -l /tmp/postgres.log start && \
    sleep 5 && \
    for i in {1..30}; do su-exec postgres pg_isready && break || sleep 2; done && \
    su-exec postgres pg_isready || (echo "PostgreSQL failed to start. Logs:" && cat /tmp/postgres.log && exit 1) && \
    su-exec postgres psql -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';" || (echo "Failed to set password. Logs:" && cat /tmp/postgres.log && exit 1) && \
    su-exec postgres psql -c "CREATE DATABASE $POSTGRES_DB;" || (echo "Failed to create database. Logs:" && cat /tmp/postgres.log && exit 1) && \
    /usr/local/bin/init-databases.sh || (echo "Failed to initialize databases. Logs:" && cat /tmp/postgres.log && exit 1) && \
    su-exec postgres pg_ctl -D /var/lib/postgresql/data stop && \
    sleep 5

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
