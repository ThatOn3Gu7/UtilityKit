#!/usr/bin/env bash
# Install Termux widget shortcuts into ~/.shortcuts/
# Version: 2.0.0
#
# Termux:Widget only reads ~/.shortcuts from the Termux APP's own home and only
# displays REAL files (no symlinks).
#
# IMPORTANT (proot / unrooted phones):
#   When opencode runs inside a proot Linux environment, $HOME is /root and any
#   file it creates is owned by uid 0. The Termux app runs as a different uid
#   (e.g. 10266) and proot's chown/setpriv cannot actually reassign ownership.
#   The fix is access bits, not ownership: make the .shortcuts dir and the
#   scripts world-readable + executable (mode 755) so the app uid can read and
#   run them regardless of who owns them.
#
# These shortcuts are intentionally SELF-CONTAINED (no UtilityKit tool
# dependency). UtilityKit's tools are interactive and expect a live terminal,
# which widget taps do not provide. See README.md.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  count=$((count + 1))
done

chmod 755 "$DEST"
chmod 755 "$DEST"/*.sh

echo "Installed $count shortcut(s) into $DEST"
echo "Place them via: home screen -> Widgets -> Termux:Widget"
