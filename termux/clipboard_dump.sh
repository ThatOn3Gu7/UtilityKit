#!/usr/bin/env bash
# Termux widget: capture the current clipboard and append it to a daily log.
# Version: 1.0.0
#
# Self-contained: depends only on termux-clipboard-get (Termux:API).
# No UtilityKit dependency, no TTY, no prompts.
set -euo pipefail

LOG="${HOME}/.cache/uk-clipboard.log"
mkdir -p "$(dirname "$LOG")"

if ! command -v termux-clipboard-get >/dev/null 2>&1; then
  echo "termux-clipboard-get not found (pkg install termux-api)"
  exit 1
fi

text="$(termux-clipboard-get 2>/dev/null)" || text=""
if [[ -z "$text" ]]; then
  echo "Clipboard empty"
  exit 0
fi

printf '%s\t%s\n' "$(date '+%F %T')" "$text" >> "$LOG"
echo "Saved $(wc -c <<<"$text") bytes to $LOG"
