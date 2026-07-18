#!/usr/bin/env bash
# Install Termux widget shortcuts into ~/.shortcuts/
# Version: 1.0.0
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.shortcuts"

mkdir -p "$DEST"

count=0
for f in "$SRC_DIR"/*.sh; do
  name="$(basename "$f")"
  [[ "$name" == "install.sh" ]] && continue
  ln -sf "$f" "$DEST/$name"
  echo "linked: $DEST/$name -> $f"
  count=$((count + 1))
done

echo
echo "Installed $count shortcut(s) into $DEST"
echo "Place them via: home screen -> Widgets -> Termux:Widget"
