#!/usr/bin/env bash
# Regenerate web/favicon.png and web/icons/Icon-*.png from web/icons/source.svg
# using headless Chrome (renders SVG accurately) and macOS sips for downscaling.
#
# Usage:  ./web/icons/regenerate.sh
# Run from the repository root or anywhere — the script chdirs to the repo.

set -euo pipefail

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[[ -x "$CHROME" ]] || { echo "Chrome not found at $CHROME" >&2; exit 1; }

cd "$(dirname "$0")/../.." # repo root
SRC_REL="web/icons/source.svg"
[[ -f "$SRC_REL" ]] || { echo "Missing $SRC_REL" >&2; exit 1; }
SRC_ABS="$(cd "$(dirname "$SRC_REL")" && pwd)/$(basename "$SRC_REL")"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Render the master at 1024×1024 by pointing Chrome straight at the SVG file.
# Wrapping the SVG in an HTML page introduces inline whitespace that can shift
# the artwork — passing the .svg directly avoids that.
"$CHROME" \
  --headless \
  --disable-gpu \
  --hide-scrollbars \
  --default-background-color=00000000 \
  --window-size=1024,1024 \
  --screenshot="$TMP/icon-1024.png" \
  "file://$SRC_ABS" >/dev/null 2>&1

# Downscale with sips (Lanczos by default; sharper than rendering Chrome at
# small target window sizes, which leaves the artwork undersized).
sips -z  64  64 "$TMP/icon-1024.png" --out web/favicon.png                 >/dev/null
sips -z 192 192 "$TMP/icon-1024.png" --out web/icons/Icon-192.png          >/dev/null
sips -z 512 512 "$TMP/icon-1024.png" --out web/icons/Icon-512.png          >/dev/null
sips -z 192 192 "$TMP/icon-1024.png" --out web/icons/Icon-maskable-192.png >/dev/null
sips -z 512 512 "$TMP/icon-1024.png" --out web/icons/Icon-maskable-512.png >/dev/null

echo "Regenerated:"
printf '  %s\n' \
  web/favicon.png \
  web/icons/Icon-192.png \
  web/icons/Icon-512.png \
  web/icons/Icon-maskable-192.png \
  web/icons/Icon-maskable-512.png
