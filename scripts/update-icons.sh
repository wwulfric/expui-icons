#!/bin/sh
# Re-fetch the icons listed in manifest.txt.
#
# Usage: scripts/update-icons.sh [--update-site] [COMMIT]
#
# Paths in the manifest come from intellij-community.  COMMIT defaults to
# the one pinned in scripts/COMMIT; passing another one updates the pin.
# Only the listed paths are downloaded (a shallow, sparse, blob-filtered
# fetch).
#
# Entries starting with site: come from https://intellij-icons.jetbrains.design,
# which has no versions, so site.lock pins the SHA-256 of every file
# downloaded from it.  A file that differs from site.lock, or a file
# added or removed, is an error unless --update-site is given, which
# rewrites site.lock.  Pass it after editing the site: entries.
#
# icons/ is rebuilt from scratch, so it always matches the manifest
# exactly.  The icons are copied unmodified.
#
# Icon names (paths under icons/, without .svg):
#   platform/icons/src/expui/fileTypes/NAME.svg  ->  NAME
#   platform/icons/src/expui/DIR/NAME.svg        ->  DIR/NAME
#   any other listed file                         ->  NAME
#   site:SET/SECTION/NAME                         ->  NAME
# Size variants such as NAME@20x20.svg are skipped.

set -eu

update_site=false
if [ "${1-}" = --update-site ]; then
    update_site=true
    shift
fi

here=$(cd "$(dirname "$0")" && pwd)
icons=$(dirname "$here")/icons
commit=${1:-$(cat "$here/COMMIT")}
expui=platform/icons/src/expui/
site=https://intellij-icons.jetbrains.design/icons

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo=$tmp/repo
out=$tmp/icons
entries=$tmp/entries

grep -v '^#' "$here/manifest.txt" | grep -v '^$' > "$entries" || true

git init -q "$repo"
git -C "$repo" remote add origin https://github.com/JetBrains/intellij-community.git
{
    echo /NOTICE.txt
    grep -v '^site:' "$entries" | while read -r path; do
        case $path in
            */) echo "/$path" ;;
            *) echo "/$path"; echo "/${path%.svg}_dark.svg" ;;
        esac
    done
} > "$tmp/patterns"
git -C "$repo" sparse-checkout set --no-cone --stdin < "$tmp/patterns"
git -C "$repo" fetch -q --depth 1 --filter=blob:none origin "$commit"
git -C "$repo" checkout -q FETCH_HEAD

# Download the site: entries into $tmp/site, keeping their paths.
mkdir -p "$tmp/site"
sed -n 's/^site://p' "$entries" | while read -r path; do
    for file in "$path.svg" "${path}_dark.svg"; do
        mkdir -p "$(dirname "$tmp/site/$file")"
        status=$(curl -sS -o "$tmp/site/$file" -w '%{http_code}' "$site/$file")
        case $status in
            200) ;;
            404)
                rm -f "$tmp/site/$file"
                if [ "$file" = "$path.svg" ]; then
                    echo "error: $site/$file not found" >&2
                    exit 1
                fi ;;
            *) echo "error: HTTP $status for $site/$file" >&2; exit 1 ;;
        esac
    done
done
(cd "$tmp/site" && find . -name '*.svg' | sed 's|^\./||' | LC_ALL=C sort |
     while read -r file; do shasum -a 256 "$file"; done) > "$tmp/site.lock"
lock=$here/site.lock
[ -f "$lock" ] || lock=/dev/null
if ! cmp -s "$tmp/site.lock" "$lock"; then
    if $update_site; then
        echo "Updating site.lock:"
        diff "$lock" "$tmp/site.lock" || true
    else
        echo "error: site icons differ from site.lock" \
             "(rerun with --update-site to accept):" >&2
        diff "$lock" "$tmp/site.lock" >&2 || true
        exit 1
    fi
fi

mkdir -p "$out"
{
    (cd "$repo" && find . -name '*.svg' ! -name '*@*' | sed 's|^\./|repo/|')
    (cd "$tmp/site" && find . -name '*.svg' | sed 's|^\./|site/|')
} | LC_ALL=C sort |
while read -r path; do
    case $path in
        repo/"$expui"fileTypes/*) name=${path#repo/"$expui"fileTypes/} ;;
        repo/"$expui"*) name=${path#repo/"$expui"} ;;
        *) name=$(basename "$path") ;;
    esac
    if [ -e "$out/$name" ]; then
        echo "error: two upstream files map to icons/$name" >&2
        exit 1
    fi
    mkdir -p "$(dirname "$out/$name")"
    cp "$tmp/$path" "$out/$name"
done

# The top-level LICENSE.txt now holds the terms for JetBrains' binary builds;
# icons/LICENSE.txt keeps the Apache 2.0 text that governs these sources.
cp "$repo/NOTICE.txt" "$out/"
cp "$icons/LICENSE.txt" "$icons/README.md" "$out/"

rm -rf "$icons"
mv "$out" "$icons"
echo "$commit" > "$here/COMMIT"
cp "$tmp/site.lock" "$here/site.lock"
echo "Fetched $(find "$icons" -name '*.svg' | wc -l | tr -d ' ') SVG files at $commit."
