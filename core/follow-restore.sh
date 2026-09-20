#!/bin/sh
# Keeps a service's files in step with the database they belong to, then runs the service.
# Usage: follow-restore.sh [--every-start] DATABASE SERVICE DIR... -- COMMAND...
#
# The postgres and mysql entrypoints record each restore in /zoo-state/DATABASE. When the DIRs
# hold files from an older restore (with --every-start, on every start), they are emptied and
# refilled from SERVICE.tar of the snapshot the database restored, or else the first DIR from
# ZOO_GOLDEN_DIR unless ZOO_NO_SEED=true. The first DIR records which restore it matches;
# `the_zoo snapshot save` reads that record there, the path of the service's zoo.snapshot
# label. A later restore of DATABASE stops COMMAND, and the restart policy brings the service
# back to refill them.
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
first=${dirs# }
first=${first%% *}
marker=$first/.zoo-restore

field() { sed -n "s/^$1=//p" "$state" 2>/dev/null || true; }

generation=$(field generation)
if $every_start || [ -z "$generation" ] || [ "$generation" != "$(cat "$marker" 2>/dev/null || true)" ]; then
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
    elif [ -n "${ZOO_GOLDEN_DIR:-}" ] && [ "${ZOO_NO_SEED:-false}" != true ]; then
        echo "Restoring$dirs from the golden state"
        cp -a "$ZOO_GOLDEN_DIR/." "$first/"
    else
        echo "Emptied$dirs"
    fi
    echo "$generation" > "$marker"
fi

"$@" &
pid=$!
trap 'kill -TERM "$pid" 2>/dev/null || true' TERM INT
while kill -0 "$pid" 2>/dev/null; do
    sleep 3 &
    wait $! || true
    latest=$(field generation)
    if [ -n "$latest" ] && [ "$latest" != "$generation" ]; then
        echo "$database was restored; stopping $service to restore its files"
        kill -TERM "$pid" 2>/dev/null || true
        generation=$latest
    fi
done
status=0
wait "$pid" || status=$?
exit "$status"
