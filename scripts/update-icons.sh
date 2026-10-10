#!/bin/sh
# Re-fetch the icons listed in manifest.txt from intellij-community.
#
# Usage: scripts/update-icons.sh [COMMIT]
#
# COMMIT defaults to the one pinned in scripts/COMMIT; passing another one
# updates the pin.  Only the listed paths are downloaded (a shallow, sparse,
# blob-filtered fetch).  icons/ is rebuilt from scratch, so it always matches
# the manifest exactly.  The icons are copied unmodified.
#
# Icon names (paths under icons/, without .svg):
#   platform/icons/src/expui/fileTypes/NAME.svg  ->  NAME
#   platform/icons/src/expui/DIR/NAME.svg        ->  DIR/NAME
#   any other listed file                         ->  NAME
# Size variants such as NAME@20x20.svg are skipped.

set -eu

here=$(cd "$(dirname "$0")" && pwd)
icons=$(dirname "$here")/icons
commit=${1:-$(cat "$here/COMMIT")}
expui=platform/icons/src/expui/

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo=$tmp/repo
out=$tmp/icons

git init -q "$repo"
git -C "$repo" remote add origin https://github.com/JetBrains/intellij-community.git
{
    echo /NOTICE.txt
    grep -v '^#' "$here/manifest.txt" | grep -v '^$' | while read -r path; do
        case $path in
            */) echo "/$path" ;;
            *) echo "/$path"; echo "/${path%.svg}_dark.svg" ;;
        esac
    done
} > "$tmp/patterns"
git -C "$repo" sparse-checkout set --no-cone --stdin < "$tmp/patterns"
git -C "$repo" fetch -q --depth 1 --filter=blob:none origin "$commit"
git -C "$repo" checkout -q FETCH_HEAD

mkdir -p "$out"
(cd "$repo" && find . -name '*.svg' ! -name '*@*' | sed 's|^\./||' | sort) |
while read -r path; do
    case $path in
        "$expui"fileTypes/*) name=${path#"$expui"fileTypes/} ;;
        "$expui"*) name=${path#"$expui"} ;;
        *) name=$(basename "$path") ;;
    esac
    if [ -e "$out/$name" ]; then
        echo "error: two upstream files map to icons/$name" >&2
        exit 1
    fi
    mkdir -p "$(dirname "$out/$name")"
    cp "$repo/$path" "$out/$name"
done

# The top-level LICENSE.txt now holds the terms for JetBrains' binary builds;
# icons/LICENSE.txt keeps the Apache 2.0 text that governs these sources.
cp "$repo/NOTICE.txt" "$out/"
cp "$icons/LICENSE.txt" "$icons/README.md" "$out/"

rm -rf "$icons"
mv "$out" "$icons"
echo "$commit" > "$here/COMMIT"
echo "Fetched $(find "$icons" -name '*.svg' | wc -l | tr -d ' ') SVG files at $commit."
