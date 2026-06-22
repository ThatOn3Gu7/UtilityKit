#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
cbm_usage(){ echo 'Usage: _clipboard_manager.sh --add TEXT|--list|--search TERM|--copy ID|--clear'; }
cbm_file(){ printf '%s/clipboard_history.txt\n' "$(uk_state_dir)"; }
cbm_main(){ local action=list arg=''; while [[ $# -gt 0 ]]; do case "$1" in --add) action=add; shift; arg="${1:-}";; --list) action=list;; --search) action=search; shift; arg="${1:-}";; --copy) action=copy; shift; arg="${1:-}";; --clear) action=clear;; -h|--help) cbm_usage; return 0;; esac; shift; done; local f; f="$(cbm_file)"; touch "$f"; case "$action" in add) printf '%s\t%s\n' "$(uk_now)" "$arg" >> "$f";; list) nl -ba "$f";; search) grep -in -- "$arg" "$f" || true;; copy) text=$(sed -n "${arg}p" "$f" | cut -f2-); uk_copy_to_clipboard "$text" || uk_error 'No clipboard setter available.';; clear) : > "$f";; esac; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" clipboard
  else
    cbm_main "$@"
  fi
fi
