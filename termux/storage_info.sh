#!/usr/bin/env bash
# Termux widget: print internal storage usage and Termux cache size.
# Version: 1.0.0
#
# Self-contained: uses only df and du (no UtilityKit dependency, no TTY).
set -euo pipefail

echo "Storage:"
df -h /data 2>/dev/null | awk 'NR==1 || /data/ {print "  "$0}'
df -h "/storage/emulated/0" 2>/dev/null | awk 'NR>1 {print "  "$0}'

if [[ -d "$HOME" ]]; then
  size="$(du -sh "$HOME" 2>/dev/null | cut -f1)"
  echo "Termux home ($HOME): $size"
fi
