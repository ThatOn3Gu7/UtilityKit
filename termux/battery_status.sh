#!/usr/bin/env bash
# Termux widget: show battery status and append a timestamped line to a log.
# Version: 1.0.0
#
# Fully self-contained: depends only on termux-battery-status (Termux:API).
# No UtilityKit tool dependency, no TTY, no prompts.
set -euo pipefail

LOG="${HOME}/.cache/uk-battery.log"
mkdir -p "$(dirname "$LOG")"

if command -v termux-battery-status >/dev/null 2>&1; then
  out="$(termux-battery-status 2>/dev/null)" || out="(unavailable)"
else
  out="termux-battery-status not found (pkg install termux-api)"
fi

printf '%s\n' "$out"
printf '%s  %s\n' "$(date '+%F %T')" "$(printf '%s' "$out" | tr '\n' ' ')" >> "$LOG"
