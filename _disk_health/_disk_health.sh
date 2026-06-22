#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
dh_usage(){ echo 'Usage: _disk_health.sh [--list] [--device DEV] [--test-short]'; }
dh_main(){ local dev='' test=0; while [[ $# -gt 0 ]]; do case "$1" in --list) dev=LIST;; --device) shift; dev="${1:-}";; --test-short) test=1;; -h|--help) dh_usage; return 0;; *) dev="$1";; esac; shift; done; uk_header 'UtilityKit Disk Health' 'SMART'; uk_has_cmd smartctl || { uk_warn 'smartctl unavailable or not usable on minimal Termux.'; return 0; }; [[ "$dev" == LIST || -z "$dev" ]] && { smartctl --scan 2>/dev/null || true; [[ "$dev" == LIST ]] && return 0; }; [[ -n "$dev" ]] && { (( test==1 )) && smartctl -t short "$dev" || true; smartctl -H -A "$dev" || true; }; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" disk-health
  else
    dh_main "$@"
  fi
fi
