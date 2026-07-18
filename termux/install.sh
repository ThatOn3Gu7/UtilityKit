#!/usr/bin/env bash
# Install Termux widget shortcuts into ~/.shortcuts/
# Version: 1.1.0
#
# NOTE: Termux:Widget does NOT reliably display symlinks, and it only scans the
# Termux app's own home directory (~/.shortcuts inside the Termux environment).
# So we COPY real files into the correct location rather than symlinking.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prefer the real Termux home when this runs inside Termux.
if [[ -d /data/data/com.termux/files/home ]]; then
  DEST="/data/data/com.termux/files/home/.shortcuts"
else
  DEST="${HOME}/.shortcuts"
fi

mkdir -p "$DEST"

count=0
for f in "$SRC_DIR"/*.sh; do
  name="$(basename "$f")"
  [[ "$name" == "install.sh" ]] && continue
  rm -f "$DEST/$name"
  cp "$f" "$DEST/$name"
  chmod 700 "$DEST/$name"
  echo "installed: $DEST/$name"
  count=$((count + 1))
done

echo
echo "Installed $count shortcut(s) into $DEST"
echo "Place them via: home screen -> Widgets -> Termux:Widget"
