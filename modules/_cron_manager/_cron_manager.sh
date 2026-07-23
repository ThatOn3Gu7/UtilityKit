#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

cm_usage() {
  local w
  w=$(uk_fh_cols); ((w > 80)) && w=80; ((w < 40)) && w=40
  printf 'Usage: _cron_manager.sh --list | --add '"'"'*/5 * * * * cmd'"'"' [--apply] | --remove N [--apply]\n\n'
  uk_help_section "$w" "Options" --name-w 24 \
    "--list" "Show current crontab with line numbers" \
    "--add '...'" "Add a new cron entry (dry-run unless --apply)" \
    "--remove N" "Remove line number N (dry-run unless --apply)" \
    "--apply" "Apply changes (otherwise dry-run)" \
    "-h, --help" "Show this help"
}
cm_have() {
  uk_has_cmd crontab || {
    uk_error 'crontab unavailable. On Termux install cronie if you need cron.'
    return 1
  }
}
cm_cleanup() {
  trap - RETURN
  rm -f -- "${tmp:-}" "${tmp:-}.new" "${tmp:-}.err" || uk_warn 'Unable to remove cron temporary files.'
}
cm_main() {
  uk_banner "cron-manager" "List, add, and remove crontab entries with format validation" "" "$@"
  local action='list' line='' num='' apply=0
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --list) action='list' ;;
    --add)
      action='add'
      shift
      line="${1:-}"
      ;;
    --remove)
      action='remove'
      shift
      num="${1:-}"
      ;;
    --apply) apply=1 ;;
    -h | --help)
      cm_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  cm_have || return 1

  local tmp list_error='' list_status=0
  tmp=$(mktemp) || { uk_error 'Unable to create crontab temporary file.'; return 1; }
  trap 'cm_cleanup' RETURN

  crontab -l >"$tmp" 2>"${tmp}.err" || list_status=$?
  if ((list_status != 0)); then
    list_error="$(cat "${tmp}.err")" || return 1
    if [[ -z "$list_error" || "$list_error" == *'no crontab for'* || "$list_error" == *'no crontab'* ]]; then
      # No crontab yet (or a silent empty read) — safe to start from scratch.
      : >"$tmp" || return 1
    else
      uk_error "Unable to read existing crontab: $list_error"
      return 1
    fi
  fi
  rm -f "${tmp}.err" || return 1

  case "$action" in
  list)
    if [[ -s "$tmp" ]]; then
      cat -n "$tmp"
    else
      uk_note "No crontab entries found."
    fi
    ;;
  add)
    if [[ "$line" == *$'\n'* || "$line" == *$'\r'* || ! "$line" =~ ^([^[:space:]]+[[:space:]]+){5}[^[:space:]].*$ ]]; then
      uk_error 'Expected five cron fields plus command (e.g., "*/5 * * * * /path/to/script")'
      return 1
    fi
    echo "$line" >>"$tmp"
    if ((apply == 1)); then
      crontab "$tmp"
      uk_success 'Crontab updated.'
    else
      uk_note 'Dry-run: new crontab would be:'
      cat -n "$tmp"
    fi
    ;;
  remove)
    if [[ ! "$num" =~ ^[0-9]+$ ]] || ((num < 1)); then
      uk_error 'Line number must be a positive integer.'
      return 1
    fi
    local total
    total=$(wc -l <"$tmp") || return 1
    ((num <= total)) || { uk_error "Line number out of range: $num (have $total)."; return 1; }
    awk -v n="$num" 'NR!=n' "$tmp" >"$tmp.new" || return 1
    if ((apply == 1)); then
      crontab "$tmp.new"
      uk_success 'Crontab updated.'
    else
      uk_note "Dry-run: line $num would be removed. New crontab would be:"
      cat -n "$tmp.new"
    fi
    ;;
  esac
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  cm_main "$@"
fi

