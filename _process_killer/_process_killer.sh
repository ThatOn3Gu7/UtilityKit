#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

PK_PID=''
PK_SIGNAL='TERM'

pk_usage() {
  cat <<'USAGE'
Usage:
  _process_killer.sh [--pid PID] [--signal TERM|KILL]
USAGE
}

pk_memory_summary() {
  if uk_has_cmd free; then
    local total used swap_total swap_used
    read -r _ total used _ < <(free -m | awk '/^Mem:/ {print $1, $2, $3, $4}')
    read -r _ swap_total swap_used _ < <(free -m | awk '/^Swap:/ {print $1, $2, $3, $4}')
    printf 'RAM  : %s MB / %s MB %s\n' "$used" "$total" "$(uk_bar "$used" "$total" 28)"
    printf 'Swap : %s MB / %s MB %s\n' "$swap_used" "$swap_total" "$(uk_bar "$swap_used" "$swap_total" 28)"
  else
    uk_warn 'free command not available; skipping RAM chart.'
  fi
}

pk_top() {
  ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 11
}

pk_describe_pid() {
  ps -p "$PK_PID" -o pid=,user=,%cpu=,%mem=,comm= 2>/dev/null || true
}

pk_kill() {
  local before
  before="$(pk_describe_pid)"
  if [[ -z "$before" ]]; then
    uk_warn "PID $PK_PID does not exist or is not visible to the current user."
    return 1
  fi
  uk_note "Target process: $before"
  kill -s "$PK_SIGNAL" "$PK_PID"
  sleep 0.2
  if ps -p "$PK_PID" >/dev/null 2>&1; then
    uk_warn "Signal sent, but PID $PK_PID is still running."
  else
    uk_success "Sent SIG$PK_SIGNAL to PID $PK_PID and the process exited."
  fi
}

pk_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pid) shift; PK_PID="${1:-}" ;;
      --signal) shift; PK_SIGNAL="${1:-TERM}" ;;
      -h|--help) pk_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done

  uk_header 'UtilityKit Process Killer' 'RAM/swap overview and top memory consumers'
  pk_memory_summary
  printf '\nTop processes:\n'
  pk_top

  if [[ -n "$PK_PID" ]]; then
    pk_kill
  elif uk_is_interactive; then
    PK_PID="$(uk_prompt 'Enter a PID to terminate (leave blank to only inspect)' '' '12345' 'If you leave this blank, the tool will return after the process overview.')"
    if [[ -n "$PK_PID" ]]; then
      PK_SIGNAL="$(uk_prompt 'Enter signal type (TERM or KILL)' 'TERM' 'KILL' 'TERM is safer; KILL is stronger for stubborn processes.')"
      pk_kill
    fi
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  pk_main "$@"
fi
