#!/bin/bash
# Check if we need to reset the database
# We skip reset if this appears to be a fresh container (no marker file)
if [ -d "/var/lib/postgresql/data-golden" ]; then
    if [ -f "/var/lib/postgresql/data/.container_start_marker" ]; then
        # Marker exists - this is a restart, need to reset
        need_reset=true
    else
        # No marker - this is first start, data is already golden
        touch "/var/lib/postgresql/data/.container_start_marker"
        chown postgres:postgres "/var/lib/postgresql/data/.container_start_marker"
        need_reset=false
    fi
    
    if [ "$need_reset" = "true" ]; then
        echo "Resetting PostgreSQL database to golden state..."
        start_time=$(date +%s)
        
        # Use rsync for faster copying
        # Remove directory completely to avoid glob expansion issues
        rm -rf /var/lib/postgresql/data
        rsync -a --inplace /var/lib/postgresql/data-golden/ /var/lib/postgresql/data/
        touch "/var/lib/postgresql/data/.container_start_marker"
        chown -R postgres:postgres /var/lib/postgresql/data
        
        end_time=$(date +%s)
        echo "Database reset completed in $((end_time - start_time)) seconds"
    else
        echo "Container first start - using pre-populated golden data"
    fi
fi

# Call the original entrypoint
exec docker-entrypoint.sh "$@"