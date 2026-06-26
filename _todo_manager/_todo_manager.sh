#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
td_usage() { echo 'Usage: _todo_manager.sh --add TEXT [--tag TAG] | --list | --done ID | --search TERM'; }
td_file() { printf '%s/todos.tsv\n' "$(uk_data_dir)"; }
td_main() {
  local action=list text='' tag='' term='' id=''
  while [[ $# -gt 0 ]]; do
    case "$1" in --add)
      action=add
      shift
      text="${1:-}"
      ;;
    --tag)
      shift
      tag="${1:-}"
      ;;
    --list) action=list ;; --done)
      action=done
      shift
      id="${1:-}"
      ;;
    --search)
      action=search
      shift
      term="${1:-}"
      ;;
    -h | --help)
      td_usage
      return 0
      ;;
    esac
    shift
  done
  local f="$(td_file)"
  touch "$f"
  case "$action" in add) printf 'open\t%s\t%s\t%s\n' "$(uk_now)" "$tag" "$text" >>"$f" ;; list) nl -ba "$f" ;; done)
    [[ "$id" =~ ^[1-9][0-9]*$ ]] || {
      uk_error 'Todo ID must be a positive integer.'
      return 1
    }
    awk -v n="$id" 'BEGIN{FS=OFS="\t"} NR==n{$1="done"} {print}' "$f" >"$f.tmp" && mv "$f.tmp" "$f" || {
      rm -f "$f.tmp"
      return 1
    }
    ;;
  search) grep -in -- "$term" "$f" || true ;; esac
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  td_main "$@"
fi
