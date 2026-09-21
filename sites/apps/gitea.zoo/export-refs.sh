#!/bin/sh
# Writes each repository's refs besides its default branch (branches and pull request heads
# made in the running zoo) as a git fast-export stream, DIR/OWNER/NAME.fast-export, which
# prepare-repos.sh imports at build time. Run by `npm run golden:capture -- gitea`.
# Usage: export-refs.sh DIR
set -eu

out=$1
rm -rf "$out"
mkdir -p "$out"
cd /data/git/repositories
for repo in */*.git; do
    head=$(git -C "$repo" symbolic-ref HEAD)
    refs=$(git -C "$repo" for-each-ref --format='%(refname)' | grep -vxF "$head" || true)
    [ -n "$refs" ] || continue
    mkdir -p "$out/${repo%/*}"
    # Parents on the default branch are referenced by ID, which the baked repository has
    # shellcheck disable=SC2086
    git -C "$repo" fast-export --show-original-ids --reference-excluded-parents $refs --not "$head" \
        > "$out/${repo%.git}.fast-export"
done
