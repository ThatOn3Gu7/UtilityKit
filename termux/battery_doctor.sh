#!/usr/bin/env bash
# Termux home-screen widget shortcut: Battery Doctor
# Version: 1.0.0
#
# Shows battery status (termux-battery-status) and top CPU/MEM processes, then
# keeps the output on screen so a mobile user can read it after tapping the
# widget. Pipes through `less` when available, otherwise waits for a tap.
#
# Install: copy this file into ~/.shortcuts/ (or symlink it) and grant the
# Termux:Widget permission.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="$SCRIPT_DIR/../modules/_battery_doctor/_battery_doctor.sh"

if [[ ! -f "$TOOL" ]]; then
  echo "Battery Doctor tool not found at: $TOOL" >&2
  exit 1
fi

out="$($TOOL 2>&1)" || true

if command -v less >/dev/null 2>&1; then
  printf '%s\n' "$out" | less -R -F -X
else
  printf '%s\n' "$out"
  echo
  echo "Tap the notification or press Enter to dismiss."
  read -r _ || true
fi
