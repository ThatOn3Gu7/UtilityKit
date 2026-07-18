#!/usr/bin/env bash
# Termux home-screen widget shortcut: QR Tool (scan / decode from camera)
# Version: 1.0.0
#
# Captures a photo with the camera (termux-camera-photo), then decodes any QR
# codes in it and prints the result(s) for mobile reading. Requires the
# Termux:API add-on (`pkg install termux-api`) and a camera permission grant.
#
# Install: copy this file into ~/.shortcuts/ (or symlink it).
#
# The captured image is written to a temp file and removed afterwards.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="$SCRIPT_DIR/../modules/_qr_tool/_qr_tool.sh"
TMP_IMG="$(mktemp -t uk-qr-XXXXXX.png)"

cleanup() { rm -f "$TMP_IMG" 2>/dev/null || true; }
trap cleanup EXIT

if [[ ! -f "$TOOL" ]]; then
  echo "QR Tool not found at: $TOOL" >&2
  exit 1
fi

if ! command -v termux-camera-photo >/dev/null 2>&1; then
  echo "termux-camera-photo not found. Install Termux:API: pkg install termux-api" >&2
  exit 1
fi

echo "Opening camera… tap the shutter to capture the QR code."
termux-camera-photo "$TMP_IMG" || { echo "Camera capture cancelled or failed." >&2; exit 1; }

out="$($TOOL decode --image "$TMP_IMG" 2>&1)" || true

if command -v less >/dev/null 2>&1; then
  printf '%s\n' "$out" | less -R -F -X
else
  printf '%s\n' "$out"
  echo
  echo "Tap the notification or press Enter to dismiss."
  read -r _ || true
fi
