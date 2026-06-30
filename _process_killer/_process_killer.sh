#!/usr/bin/env bash
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
  printf '\n  %s%sMemory overview%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  if uk_has_cmd free; then
    local total used swap_total swap_used
    read -r _ total used _ < <(free -m | awk '/^Mem:/ {print ${1:-}, ${2:-}, ${3:-}, ${4:-}}')
    read -r _ swap_total swap_used _ < <(free -m | awk '/^Swap:/ {print ${1:-}, ${2:-}, ${3:-}, ${4:-}}')
    printf '  %sRAM %s   %s%s MB%s / %s MB  %s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" \
      "$UK_C_GREEN" "$used" "$UK_C_RESET" "$total" \
      "$(uk_bar "$used" "$total" 28)"
    printf '  %sSwap%s  %s%s MB%s / %s MB  %s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" \
      "$UK_C_CYAN" "$swap_used" "$UK_C_RESET" "$swap_total" \
      "$(uk_bar "$swap_used" "$swap_total" 28)"
  else
    printf '  %s(free command not available — skipping memory chart)%s\n' \
      "$UK_C_DIM" "$UK_C_RESET"
  fi
}
pk_top() {
  printf '\n  %s%sTop processes by memory%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  ps -eo pid,user,%cpu,%mem,comm --sort=-%mem 2>/dev/null | head -n 11 |
    awk 'NR==1 {
      printf "  \033[1m%-8s %-12s %-6s %-6s %s\033[0m\n", ${1:-}, ${2:-}, ${3:-}, ${4:-}, ${5:-}
      next
    }
    { printf "  %-8s %-12s %-6s %-6s %s\n", ${1:-}, ${2:-}, ${3:-}, ${4:-}, ${5:-} }' ||
    ps -eo pid,user,%cpu,%mem,comm --sort=-%mem 2>/dev/null | head -n 11 | sed 's/^/  /'
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
  uk_banner "process-killer" "RAM/swap overview, top consumers, optional signal send" "" "$@"
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --pid)
      shift
      PK_PID="${1:-}"
      ;;
    --signal)
      shift
      PK_SIGNAL="${1:-TERM}"
      ;;
    -h | --help)
      pk_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  pk_memory_summary
  printf '\nTop processes:\n'
  pk_top

  if [[ -n "$PK_PID" ]]; then
    pk_kill
  elif uk_is_interactive; then
    printf '\n'
    PK_PID="$(uk_prompt \
      'Enter a PID to terminate (leave blank to only inspect and exit)' \
      '' \
      '1234  →  terminate that process  |  leave blank  →  view only, no action taken' \
      'Use the PID column from the process list above. Sending a signal cannot be undone.')"
    if [[ -n "$PK_PID" ]]; then
      PK_SIGNAL="$(uk_prompt \
        'Enter the signal to send' \
        'TERM' \
        'TERM  →  polite stop, process can clean up  |  KILL  →  forced immediate stop' \
        'Always try TERM first. Use KILL only if the process ignores TERM.')"
      pk_kill
    else
      printf '  %s(no PID entered — exiting without sending any signal)%s\n' \
        "$UK_C_DIM" "$UK_C_RESET"
    fi
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  pk_main "$@"
fi
