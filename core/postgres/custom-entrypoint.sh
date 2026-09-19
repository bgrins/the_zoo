#!/bin/bash
# Always restore from golden backup on every start
if [ -f "/var/lib/postgresql/data-golden.tar" ]; then
    echo "Restoring PostgreSQL database from golden state..."
    start_time=$(date +%s)

    # Clear existing data (can't remove directory itself as it's a volume mount)
    rm -rf /var/lib/postgresql/data/*

    # Extract from uncompressed tar backup (same pattern as MySQL). Entries keep their
    # ownership; docker-entrypoint.sh chowns anything not owned by postgres.
    tar -xf /var/lib/postgresql/data-golden.tar -C /var/lib/postgresql/

    end_time=$(date +%s)
    echo "Database restore completed in $((end_time - start_time)) seconds"
fi

# Call the original entrypoint
exec docker-entrypoint.sh "$@"