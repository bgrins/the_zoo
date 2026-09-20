#!/bin/bash
# Restores the data dir on every start from the golden tar, or from snapshot $ZOO_BASELINE.
# After an unclean shutdown (an OOM kill or crash that restart: always recovers from) it keeps
# the data instead, so a crash doesn't silently reset every database mid-run. So does the start
# after `the_zoo snapshot save`, which leaves /zoo-state/postgres.keep.
# Each start is recorded in /zoo-state/postgres for `the_zoo state` and for the services whose
# files follow this database (core/follow-restore.sh).
set -euo pipefail

DATA=/var/lib/postgresql/data
GOLDEN=/var/lib/postgresql/data-golden.tar
STATE=/zoo-state/postgres

now_ms() {
    local us=${EPOCHREALTIME/./}
    echo $((us / 1000))
}
field() { sed -n "s/^$1=//p" "$STATE" 2>/dev/null || true; }

mkdir -p "$(dirname "$STATE")"
started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cluster_state=$(pg_controldata "$DATA" 2>/dev/null | sed -n 's/^Database cluster state: *//p' || true)
kept=
if [ -n "$cluster_state" ] && [ -f "$STATE.keep" ]; then
    echo "Keeping the data just saved as a snapshot"
    kept="snapshot save"
elif [ -n "$cluster_state" ] && [ "$cluster_state" != "shut down" ]; then
    echo "WARNING: PostgreSQL did not shut down cleanly (cluster state: $cluster_state)."
    echo "WARNING: Keeping its data instead of restoring. Restart postgres to reset it."
    kept="unclean shutdown (cluster state: $cluster_state)"
fi
rm -f "$STATE.keep"

if [ -n "$kept" ]; then
    generation=$(field generation)
    source=$(field source)
    restored_at=$(field restored_at)
    restore_seconds=$(field restore_seconds)
else
    source=golden
    tar=$GOLDEN
    if [ -n "${ZOO_BASELINE:-}" ]; then
        if [ -f "/zoo-snapshots/$ZOO_BASELINE/postgres.tar" ]; then
            source=snapshot:$ZOO_BASELINE
            tar=/zoo-snapshots/$ZOO_BASELINE/postgres.tar
        else
            echo "WARNING: Snapshot $ZOO_BASELINE has no postgres.tar; restoring the golden state"
        fi
    fi

    if [ "$source" = golden ]; then
        echo "Restoring PostgreSQL database from golden state..."
    else
        echo "Restoring PostgreSQL database from snapshot $ZOO_BASELINE..."
    fi
    start=$(now_ms)
    # The mount point itself can't be removed
    find "$DATA" -mindepth 1 -delete
    # Entries keep their ownership; docker-entrypoint.sh chowns anything not owned by postgres.
    # The golden tar holds data/, a snapshot the path from / (see `the_zoo snapshot save`).
    if [ "$source" = golden ]; then
        tar -xf "$tar" -C /var/lib/postgresql/
    else
        tar -xf "$tar" -C /
    fi
    elapsed=$(($(now_ms) - start))
    restore_seconds=$(printf '%d.%03d' $((elapsed / 1000)) $((elapsed % 1000)))
    echo "Database restore completed in $restore_seconds seconds"

    generation=$(cat /proc/sys/kernel/random/uuid)
    restored_at=$started_at
fi

cat > "$STATE.tmp" <<EOF
generation=$generation
source=$source
baseline=${ZOO_BASELINE:-}
restored_at=$restored_at
restore_seconds=$restore_seconds
started_at=$started_at
kept=$kept
EOF
mv "$STATE.tmp" "$STATE"

exec docker-entrypoint.sh "$@"
