#!/usr/bin/env bash
# Termux widget: toggle the camera torch (flashlight) on/off.
# Version: 1.0.0
#
# Self-contained: depends only on termux-torch (Termux:API).
# No UtilityKit dependency, no TTY, no prompts. Tapping the widget flips state.
set -euo pipefail

if ! command -v termux-torch >/dev/null 2>&1; then
  echo "termux-torch not found (pkg install termux-api)"
  exit 1
fi

STATE_FILE="${HOME}/.cache/uk-torch.state"
prev="$(cat "$STATE_FILE" 2>/dev/null || true)"

if [[ "$prev" == "on" ]]; then
  termux-torch off
  echo "off" > "$STATE_FILE"
  echo "Torch OFF"
else
  termux-torch on
  echo "on" > "$STATE_FILE"
  echo "Torch ON"
fi
