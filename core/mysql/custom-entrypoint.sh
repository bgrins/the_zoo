#!/bin/bash
# Always restore from golden backup on every start
if [ -f "/var/lib/mysql-golden.tar" ]; then
    echo "Restoring MySQL database from golden state..."
    start_time=$(date +%s)

    # Clear existing data (can't remove directory itself as it's a volume mount)
    rm -rf /var/lib/mysql/*

    # Extract from uncompressed tar backup
    tar -xf /var/lib/mysql-golden.tar -C /var/lib/
    chown -R mysql:mysql /var/lib/mysql

    end_time=$(date +%s)
    echo "Database restore completed in $((end_time - start_time)) seconds"
fi

# Call the original entrypoint
exec docker-entrypoint.sh "$@"