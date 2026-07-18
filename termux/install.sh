#!/usr/bin/env bash
# Install Termux widget shortcuts into ~/.shortcuts/
# Version: 1.4.0
#
# Termux:Widget only reads ~/.shortcuts from the Termux APP's own home and only
# displays REAL files (no symlinks).
#
# IMPORTANT (proot / unrooted phones):
#   When opencode runs inside a proot Linux environment, $HOME is /root and any
#   file it creates is owned by uid 0. The Termux app runs as a different uid
#   (e.g. 10266) and proot's chown/setpriv cannot actually reassign file
#   ownership. The fix is ACCESS BITS, not ownership: make the .shortcuts dir
#   and the scripts world-readable + executable (mode 755). The app uid can then
#   read and execute them regardless of who owns them. (A root-owned 0700 dir is
#   what produced the "No such file or directory" widget error.)
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prefer the real Termux app home when present.
if [[ -d /data/data/com.termux/files/home ]]; then
  DEST="/data/data/com.termux/files/home/.shortcuts"
else
  DEST="${HOME}/.shortcuts"
fi

mkdir -p "$DEST"

SCRIPTS=(battery_doctor weather clipboard_history qr_scan)
count=0
for name in "${SCRIPTS[@]}"; do
  rm -f "$DEST/$name.sh"
  cp "$SRC_DIR/$name.sh" "$DEST/$name.sh"
  count=$((count + 1))
done

# World-readable + executable so the Termux app uid can use them even when the
# files are owned by root (proot cannot reassign ownership).
chmod 755 "$DEST"
chmod 755 "$DEST"/*.sh

echo "Installed $count shortcut(s) into $DEST"
echo "Place them via: home screen -> Widgets -> Termux:Widget"
