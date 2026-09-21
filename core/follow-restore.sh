#!/bin/sh
# Keeps a service in step with the database it keeps its state in, then runs the service.
# Usage: follow-restore.sh [--every-start] DATABASE SERVICE [DIR...] -- COMMAND...
#
# The postgres and mysql entrypoints record each restore in /zoo-state/DATABASE. A later
# restore of DATABASE stops COMMAND, and the restart policy brings the service back, so it
# never runs on a replaced database with caches or files from the old one.
#
# The DIRs hold the service's files. When they are from an older restore (with --every-start,
# on every start) or the image's golden files changed, they are emptied and refilled from
# SERVICE.tar of the snapshot the database restored, or else the first DIR from ZOO_GOLDEN_DIR
# unless ZOO_NO_SEED=true. The first DIR, the path of the service's zoo.snapshot label, records
# the restore they match in .zoo-restore (read by `the_zoo snapshot save`) and a hash of the
# golden files in .zoo-golden. A .zoo-keep file there, left by `the_zoo snapshot save` after it
# archives the DIRs, makes the next start keep them unless the database was restored since.
set -eu

every_start=false
if [ "$1" = --every-start ]; then
    every_start=true
    shift
fi
database=$1
service=$2
shift 2
dirs=
while [ "$1" != -- ]; do
    dirs="$dirs $1"
    shift
done
shift

state=/zoo-state/$database

field() { sed -n "s/^$1=//p" "$state" 2>/dev/null || true; }

# Paths, modes, owners and contents of the golden files
golden_hash() {
    if [ -n "${ZOO_GOLDEN_DIR:-}" ] && [ "${ZOO_NO_SEED:-false}" != true ]; then
        (cd "$ZOO_GOLDEN_DIR" && find . -exec stat -c '%n %a %u %g' {} + && find . -type f -exec md5sum {} +) |
            sort | md5sum | cut -d' ' -f1
    fi
}

generation=$(field generation)
if [ -n "$dirs" ]; then
    first=${dirs# }
    first=${first%% *}
    golden=$(golden_hash)
    current=false
    if [ -n "$generation" ] && [ "$generation" = "$(cat "$first/.zoo-restore" 2>/dev/null || true)" ]; then
        current=true
    fi

    if $current && [ -f "$first/.zoo-keep" ]; then
        echo "Keeping$dirs, just saved as a snapshot"
        rm "$first/.zoo-keep"
        echo "$golden" > "$first/.zoo-golden"
    elif $every_start || ! $current || [ "$golden" != "$(cat "$first/.zoo-golden" 2>/dev/null || true)" ]; then
        # A DIR can sit inside another one
        for dir in $dirs; do
            [ ! -d "$dir" ] || find "$dir" -mindepth 1 -delete
        done
        for dir in $dirs; do
            mkdir -p "$dir"
        done
        source=$(field source)
        snapshot=/zoo-snapshots/${source#snapshot:}/$service.tar
        if [ "${source#snapshot:}" != "$source" ] && [ -f "$snapshot" ]; then
            echo "Restoring$dirs from snapshot ${source#snapshot:}"
            tar -xf "$snapshot" -C /
        elif [ -n "$golden" ]; then
            echo "Restoring$dirs from the golden state"
            cp -a "$ZOO_GOLDEN_DIR/." "$first/"
        else
            echo "Emptied$dirs"
        fi
        echo "$generation" > "$first/.zoo-restore"
        echo "$golden" > "$first/.zoo-golden"
    fi
fi

"$@" &
pid=$!
# Once stopping, wait for the service itself rather than the next check, so it exits
# within Docker's grace period
stopping=false
trap 'stopping=true; kill -TERM "$pid" 2>/dev/null || true' TERM INT
while ! $stopping && kill -0 "$pid" 2>/dev/null; do
    sleep 3 &
    wait $! || true
    $stopping && break
    latest=$(field generation)
    if [ -n "$latest" ] && [ "$latest" != "$generation" ]; then
        echo "$database was restored; stopping $service to start it again"
        kill -TERM "$pid" 2>/dev/null || true
        generation=$latest
    fi
done
status=0
wait "$pid" || status=$?
exit "$status"
