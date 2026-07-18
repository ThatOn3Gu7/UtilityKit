#!/usr/bin/env bash
# Install Termux widget shortcuts into ~/.shortcuts/
# Version: 1.2.0
#
# Termux:Widget only reads ~/.shortcuts from the Termux APP's own home and only
# displays REAL files (no symlinks). Those files must be OWNED by the Termux
# app uid (u0_aXXX, e.g. 10266) — NOT by root.
#
# Inside a proot Linux environment (e.g. running opencode under proot on an
# unrooted phone), $HOME is /root and any file we create is owned by uid 0,
# which the Termux app (a different uid) cannot read -> "No such file or
# directory". To fix this we detect that situation and re-create the files as
# the Termux app uid via setpriv.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate the Termux app home (real, on-device path).
if [[ -d /data/data/com.termux/files/home ]]; then
  DEST="/data/data/com.termux/files/home/.shortcuts"
else
  DEST="${HOME}/.shortcuts"
fi

# Detect the Termux app uid. If files created here end up root-owned while the
# app runs as a different uid, we must write as that uid.
APP_UID=""
if [[ -d /data/data/com.termux/files/home ]]; then
  # The app's uid owns its home dir on a normal install. If *we* are root in
  # proot, chown is a no-op, so find the app uid and use setpriv.
  APP_UID="$(stat -c '%u' /data/data/com.termux/files/home 2>/dev/null || true)"
  # If the home is already root-owned (proot), guess the common Termux uid.
  if [[ "$APP_UID" == "0" ]] && command -v setpriv >/dev/null 2>&1; then
    APP_UID="$(getent passwd | awk -F: '$1 ~ /^aid_u0_a[0-9]+$/ {print $3; exit}' 2>/dev/null || true)"
  fi
fi

install_one() {
  local name="$1"
  rm -f "$DEST/$name"
  cp "$SRC_DIR/$name" "$DEST/$name"
  chmod 700 "$DEST/$name"
}

if [[ -n "$APP_UID" && "$APP_UID" != "0" ]] && command -v setpriv >/dev/null 2>&1; then
  # Re-create as the Termux app uid so it can actually read/execute them.
  mkdir -p "$DEST"
  setpriv --reuid="$APP_UID" --regid="$APP_UID" --clear-groups env HOME="$DEST/.." bash -c '
    DEST="$1"; SRC="$2"
    mkdir -p "$DEST"
    for f in battery_doctor weather clipboard_history qr_scan; do
      rm -f "$DEST/$f.sh"
      cp "$SRC/$f.sh" "$DEST/$f.sh"
      chmod 700 "$DEST/$f.sh"
      echo "installed (uid='"$APP_UID"'): $DEST/$f.sh"
    done' _ "$DEST" "$SRC_DIR"
else
  mkdir -p "$DEST"
  for f in battery_doctor weather clipboard_history qr_scan; do
    install_one "$f.sh"
    echo "installed: $DEST/$f.sh"
  done
fi

echo
echo "Installed shortcuts into $DEST"
echo "Place them via: home screen -> Widgets -> Termux:Widget"
