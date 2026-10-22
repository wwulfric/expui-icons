#!/bin/sh
# Render docs/hero.png, the README's hero image, from scripts/hero.el.
#
# Usage: scripts/hero.sh
#
# Needs Emacs and Google Chrome (or Chromium; set CHROME to its binary).
# The image is 1600x1000 CSS pixels at 2x.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
chrome=${CHROME:-"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

emacs -Q --batch -L "$root" -l "$root/scripts/hero.el" \
      -f expui-icons-hero "$tmp/hero.html"
mkdir -p "$root/docs"
"$chrome" --headless=new --disable-gpu --hide-scrollbars \
          --force-device-scale-factor=2 --window-size=1600,1000 \
          --screenshot="$root/docs/hero.png" "file://$tmp/hero.html"
echo "Wrote docs/hero.png"
