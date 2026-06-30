#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
td_usage() { echo 'Usage: _todo_manager.sh --add TEXT [--tag TAG] | --list | --done ID | --search TERM'; }
td_file() { printf '%s/todos.tsv\n' "$(uk_data_dir)"; }
td_main() {
  uk_banner "todo-manager" "Plain-text TSV task tracker with tags and search" "" "$@"
  local action=list text='' tag='' term='' id=''
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --add)
      action=add
      shift
      text="${1:-}"
      ;;
    --tag)
      shift
      tag="${1:-}"
      ;;
    --list) action=list ;;
    --done)
      action=done
      if [[ $# -gt 1 && "${2:-}" != --* ]]; then
        shift
        id="${1:-}"
      fi
      ;;
    --search)
      action=search
      shift
      term="${1:-}"
      ;;
    -h|--help)
      td_usage
      return 0
      ;;
    esac
    shift
  done

  local f
  f="$(td_file)"
  touch "$f"

  case "$action" in
  add)
    printf 'open\t%s\t%s\t%s\n' "$(uk_now)" "$tag" "$text" >>"$f"
    uk_success "Added: $text"
    ;;
  list)
    nl -ba "$f"
    ;;
  done)
    if [[ -z "$id" || ! "$id" =~ ^[1-9][0-9]*$ ]]; then
      uk_error 'Todo ID must be a positive integer.'
      return 1
    fi
    awk -v n="$id" 'BEGIN{FS=OFS="\t"} NR==n{${1:-}="done"} {print}' "$f" >"$f.tmp" \
      && mv "$f.tmp" "$f" || { rm -f "$f.tmp"; return 1; }
    uk_success "Marked item $id as done."
    ;;
  search)
    grep -in -- "$term" "$f" || true
    ;;
  esac
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  td_main "$@"
fi
