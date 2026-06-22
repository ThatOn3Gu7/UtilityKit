#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
of_usage(){ echo 'Usage: _open_files.sh --path PATH | --port PORT'; }
of_main(){ local path='' port=''; while [[ $# -gt 0 ]]; do case "$1" in --path) shift; path="${1:-}";; --port) shift; port="${1:-}";; -h|--help) of_usage; return 0;; esac; shift; done; [[ -n "$path" ]] && { uk_has_cmd lsof && lsof -- "$path" || uk_error 'lsof unavailable'; return; }; [[ -n "$port" ]] && { uk_has_cmd lsof && lsof -i ":$port" || uk_error 'lsof unavailable'; return; }; of_usage; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" open-files
  else
    of_main "$@"
  fi
fi
