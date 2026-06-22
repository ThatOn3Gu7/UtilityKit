#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
ssn_usage(){ echo 'Usage: _system_snapshot.sh [--output FILE]'; }
ssn_main(){ local out=''; while [[ $# -gt 0 ]]; do case "$1" in --output) shift; out="${1:-}";; -h|--help) ssn_usage; return 0;; esac; shift; done; { echo "OS: $(uname -a)"; echo "Platform: $(uk_platform)"; df -h . 2>/dev/null || true; } | { [[ -n "$out" ]] && tee "$out" || cat; }; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" snapshot
  else
    ssn_main "$@"
  fi
fi
