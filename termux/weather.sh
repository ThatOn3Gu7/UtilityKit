#!/usr/bin/env bash
# Termux home-screen widget shortcut: Weather
# Version: 1.0.0
#
# Fetches current weather (wttr.in) for the default/cached location in concise
# form and holds it on screen for mobile reading.
#
# Install: copy this file into ~/.shortcuts/ (or symlink it).
#
# Edit LOC below to pin a location, e.g. LOC="London" or LOC="Berlin".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="$SCRIPT_DIR/../modules/_weather/_weather.sh"

LOC="${UK_TERMUX_WEATHER_LOC:-}"

if [[ ! -f "$TOOL" ]]; then
  echo "Weather tool not found at: $TOOL" >&2
  exit 1
fi

if [[ -n "$LOC" ]]; then
  out="$($TOOL "$LOC" --concise 2>&1)" || true
else
  out="$($TOOL --concise 2>&1)" || true
fi

if command -v less >/dev/null 2>&1; then
  printf '%s\n' "$out" | less -R -F -X
else
  printf '%s\n' "$out"
  echo
  echo "Tap the notification or press Enter to dismiss."
  read -r _ || true
fi
