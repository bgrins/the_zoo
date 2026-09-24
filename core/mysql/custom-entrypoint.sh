#!/bin/bash
# Restores the data dir on every start from the golden tar, or from snapshot $ZOO_BASELINE.
# After an unclean shutdown (an OOM kill or crash that restart: always recovers from) it keeps
# the data instead, so a crash doesn't silently reset every database mid-run. So does the start
# after `the_zoo snapshot save`, which leaves /zoo-state/mysql.keep.
# Each start is recorded in /zoo-state/mysql for `the_zoo state` and for the services whose
# files follow this database (core/follow-restore.sh).
set -euo pipefail

DATA=/var/lib/mysql
GOLDEN=/var/lib/mysql-golden.tar
STATE=/zoo-state/mysql
# mysqld removes its pid file on a clean shutdown. Kept in the data dir, a leftover one marks
# data that was not shut down cleanly, even in a new container.
PID_FILE=$DATA/mysqld.pid

now_ms() { date +%s%3N; }
field() { sed -n "s/^$1=//p" "$STATE" 2>/dev/null || true; }

mkdir -p "$(dirname "$STATE")"
started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

kept=
if [ -d "$DATA/mysql" ] && [ -f "$STATE.keep" ]; then
    echo "Keeping the data just saved as a snapshot"
    kept="snapshot save"
elif [ -f "$PID_FILE" ]; then
    echo "WARNING: MySQL did not shut down cleanly ($PID_FILE was left behind)."
    echo "WARNING: Keeping its data instead of restoring; the_zoo reset restores it."
    kept="unclean shutdown ($PID_FILE left behind)"
fi
# A kept pid file stays until mysqld rewrites it, so a crash before then still keeps the data
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
        if [ -s "/zoo-snapshots/$ZOO_BASELINE/mysql.tar" ]; then
            source=snapshot:$ZOO_BASELINE
            tar=/zoo-snapshots/$ZOO_BASELINE/mysql.tar
        else
            echo "ERROR: Snapshot $ZOO_BASELINE has no mysql.tar; refusing to restore the golden state" >&2
            exit 1
        fi
    fi

    if [ "$source" = golden ]; then
        echo "Restoring MySQL database from golden state..."
    else
        echo "Restoring MySQL database from snapshot $ZOO_BASELINE..."
    fi
    start=$(now_ms)
    # As PID 1 without a trap, the shell would ignore a stop until the grace period ran out and
    # the database was killed mid-start. A stop here is safe: the next start restores again.
    trap 'exit 143' INT TERM
    # The mount point itself can't be removed
    find "$DATA" -mindepth 1 -delete
    # Entries keep their ownership; docker-entrypoint.sh chowns anything not owned by mysql.
    # The golden tar holds mysql/, a snapshot the path from / (see `the_zoo snapshot save`).
    if [ "$source" = golden ]; then
        tar -xf "$tar" -C /var/lib/
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

if [ "${1:-}" = mysqld ]; then
    set -- "$@" --pid-file="$PID_FILE"
fi
exec docker-entrypoint.sh "$@"
