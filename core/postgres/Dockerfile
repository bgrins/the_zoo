# Build the data dir on the native build platform (avoids slow QEMU emulation in CI).
# The on-disk format only depends on endianness and alignment, which match on every
# 64-bit little-endian target (amd64, arm64).
FROM --platform=$BUILDPLATFORM postgres:16.10-alpine AS builder

# Postmill dump, kept compressed and streamed into psql
ADD --checksum=sha256:5eb0e12f167e6873b516a8f4a6caabd630229fa052a50f52173585d93dc71968 \
    https://pub-c02faf5a0de84bc3b61262b62a029c8a.r2.dev/reddit/postmill_dump_slim.sql.xz /dumps/postmill.sql.xz

# PostgreSQL configuration
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=zoopassword
ENV POSTGRES_DB=zoodb
ENV POSTGRES_HOST_AUTH_METHOD=md5

# Accept build arg for no seeding
ARG ZOO_NO_SEED=false
ENV ZOO_NO_SEED=$ZOO_NO_SEED

COPY fast-import.conf /tmp/fast-import.conf
COPY db-helpers.sh init-external-databases.sh /usr/local/bin/

# Load the downloaded dumps first: this step stays cached when seed/ changes.
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql && \
    su-exec postgres initdb -D /var/lib/postgresql/data && \
# Configure pg_hba.conf to allow md5 connections from Docker network
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf && \
# Backup clean postgresql.conf before modifying for fast import
    cp /var/lib/postgresql/data/postgresql.conf /tmp/postgresql.conf.clean && \
# Append fast import settings to postgresql.conf (includes Unix socket-only config)
    cat /tmp/fast-import.conf >> /var/lib/postgresql/data/postgresql.conf && \
# Start PostgreSQL server with optimized settings (Unix sockets only); waits until ready
    su-exec postgres pg_ctl -D /var/lib/postgresql/data -l /tmp/postgres.log start && \
    su-exec postgres psql -U postgres -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';" && \
    su-exec postgres psql -U postgres -c "CREATE DATABASE $POSTGRES_DB;" && \
    { /usr/local/bin/init-external-databases.sh || { echo "Failed to load external dumps. Logs:"; cat /tmp/postgres.log; exit 1; }; } && \
    su-exec postgres pg_ctl -D /var/lib/postgresql/data stop -m smart && \
# Drop the import WAL (over 1GB) so it is not stored in this cached layer
    su-exec postgres pg_resetwal -f /var/lib/postgresql/data

COPY seed/ /seed/
COPY init-databases.sh /usr/local/bin/

# Load the repo-local seeds on top, then snapshot the data dir into the golden tar.
RUN su-exec postgres pg_ctl -D /var/lib/postgresql/data -l /tmp/postgres.log start && \
    { /usr/local/bin/init-databases.sh || { echo "Failed to initialize databases. Logs:"; cat /tmp/postgres.log; exit 1; }; } && \
# Run CHECKPOINT to flush all data and reduce WAL files
    su-exec postgres psql -U postgres -c "CHECKPOINT;" && \
# Stop PostgreSQL cleanly (pg_ctl waits for shutdown)
    su-exec postgres pg_ctl -D /var/lib/postgresql/data stop -m smart && \
# Report directory sizes before cleanup
    echo "Directory sizes before cleanup:" && \
    du -sh /var/lib/postgresql/data/pg_wal /var/lib/postgresql/data && \
# Restore clean postgresql.conf (remove fast-import settings)
    cp /tmp/postgresql.conf.clean /var/lib/postgresql/data/postgresql.conf && \
# Reset WAL to minimal state (safe after clean CHECKPOINT + shutdown)
    su-exec postgres pg_resetwal -f /var/lib/postgresql/data && \
# Remove temporary files
    rm -rf /var/lib/postgresql/data/pg_stat_tmp/* && \
# Report final size
    echo "Final data directory size:" && \
    du -sh /var/lib/postgresql/data/pg_wal /var/lib/postgresql/data && \
# Create uncompressed tar backup (same pattern as MySQL) under a directory with the
# base image's owner and mode for /var/lib/postgresql, then drop the live data dir
    install -d -o postgres -g postgres -m 1777 /golden/postgresql && \
    tar -C /var/lib/postgresql -cf /golden/postgresql/data-golden.tar data && \
    rm -rf /var/lib/postgresql/data

FROM postgres:16.10-alpine

# Copy the uncompressed tar backup. --link keeps the layer independent of the base
# image, so all platforms share it; copying the postgresql directory entry along
# with the tar keeps /var/lib/postgresql's metadata, which --link would otherwise reset.
COPY --link --from=builder /golden/ /var/lib/

# PostgreSQL configuration (must match builder stage)
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=zoopassword
ENV POSTGRES_DB=zoodb
ENV POSTGRES_HOST_AUTH_METHOD=md5

# Copy custom entrypoint script
COPY custom-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["postgres"]
