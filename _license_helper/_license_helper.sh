#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
lic_usage(){ echo 'Usage: _license_helper.sh --detect | --generate mit --name NAME'; }
lic_main(){ local gen='' name=''; while [[ $# -gt 0 ]]; do case "$1" in --detect) gen='';; --generate) shift; gen="${1:-mit}";; --name) shift; name="${1:-}";; -h|--help) lic_usage; return 0;; esac; shift; done; [[ -z "$gen" ]] && { ls LICENSE* COPYING 2>/dev/null || uk_warn 'No license found.'; return; }; echo "MIT License"; echo; echo "Copyright (c) $(date +%Y) $name"; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" license
  else
    lic_main "$@"
  fi
fi
