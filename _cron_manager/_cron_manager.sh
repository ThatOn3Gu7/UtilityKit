#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

cm_usage() {
  cat <<'USAGE'
Usage: _cron_manager.sh --list | --add '*/5 * * * * cmd' [--apply] | --remove N [--apply]
Options:
  --list              Show current crontab with line numbers
  --add '...'         Add a new cron entry (dry-run unless --apply)
  --remove N          Remove line number N (dry-run unless --apply)
  --apply             Apply changes (otherwise dry-run)
  -h, --help          Show this help
USAGE
}

cm_have() {
  uk_has_cmd crontab || {
    uk_error 'crontab unavailable. On Termux install cronie if you need cron.'
    return 1
  }
}

cm_main() {
  local action='list' line='' num='' apply=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list)   action='list' ;;
      --add)    action='add'; shift; line="${1:-}" ;;
      --remove) action='remove'; shift; num="${1:-}" ;;
      --apply)  apply=1 ;;
      -h|--help) cm_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done

  cm_have || return 1

  local tmp
  tmp=$(mktemp)
  trap 'rm -f "$tmp" "$tmp.new"' EXIT

  crontab -l > "$tmp" 2>/dev/null || true

  case "$action" in
    list)
      if [[ -s "$tmp" ]]; then
        cat -n "$tmp"
      else
        uk_note "No crontab entries found."
      fi
      ;;
    add)
      if [[ ! "$line" =~ ^([^[:space:]]+[[:space:]]+){5}[^[:space:]] ]]; then
        uk_error 'Expected five cron fields plus command (e.g., "*/5 * * * * /path/to/script")'
        return 1
      fi
      echo "$line" >> "$tmp"
      if (( apply == 1 )); then
        crontab "$tmp"
        uk_success 'Crontab updated.'
      else
        uk_note 'Dry-run: new crontab would be:'
        cat -n "$tmp"
      fi
      ;;
    remove)
      if [[ ! "$num" =~ ^[0-9]+$ ]] || (( num < 1 )); then
        uk_error 'Line number must be a positive integer.'
        return 1
      fi
      awk -v n="$num" 'NR!=n' "$tmp" > "$tmp.new"
      if (( apply == 1 )); then
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
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" cron
  else
    cm_main "$@"
  fi
fi