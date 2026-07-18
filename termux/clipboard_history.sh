#!/usr/bin/env bash
# Termux home-screen widget shortcut: Clipboard History (list)
# Version: 1.0.0
#
# Shows the most recent clipboard entries (newest first) without prompting, so a
# mobile user can glance at history after tapping the widget. Use the main tool
# (`bash main.sh clipboard_history`) for interactive get/pin/add.
#
# Install: copy this file into ~/.shortcuts/ (or symlink it).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="$SCRIPT_DIR/../modules/_clipboard_history/_clipboard_history.sh"

if [[ ! -f "$TOOL" ]]; then
  echo "Clipboard History tool not found at: $TOOL" >&2
  exit 1
fi

out="$($TOOL list --max 20 2>&1)" || true

if command -v less >/dev/null 2>&1; then
  printf '%s\n' "$out" | less -R -F -X
else
  printf '%s\n' "$out"
  echo
  echo "Tap the notification or press Enter to dismiss."
  read -r _ || true
fi
