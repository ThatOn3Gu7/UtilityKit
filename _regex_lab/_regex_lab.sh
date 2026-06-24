#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
rx_usage(){ echo 'Usage: _regex_lab.sh --pattern REGEX [--text TEXT|--file FILE]'; }
rx_main(){ local pat='' text='' file=''; while [[ $# -gt 0 ]]; do case "$1" in --pattern) shift; pat="${1:-}";; --text) shift; text="${1:-}";; --file) shift; file="${1:-}";; -h|--help) rx_usage; return 0;; esac; shift; done; [[ -n "$file" ]] && grep -En --color=always "$pat" "$file" || printf '%s\n' "$text" | grep -En --color=always "$pat" || true; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" regex
  else
    rx_main "$@"
  fi
fi
