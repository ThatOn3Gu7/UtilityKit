#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
li_usage(){ echo 'Usage: _log_inspector.sh FILE [--pattern REGEX]'; }
li_main(){ local file='' pattern='error|warn|fail|exception'; while [[ $# -gt 0 ]]; do case "$1" in --pattern) shift; pattern="${1:-$pattern}";; -h|--help) li_usage; return 0;; *) file="$1";; esac; shift; done; [[ -f "$file" ]] || { li_usage; return 1; }; grep -Ein "$pattern" "$file" | head -50 || true; echo; sort "$file" | uniq -c | sort -rn | head; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" log-inspect
  else
    li_main "$@"
  fi
fi
