#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

PK_PID=''
PK_SIGNAL='TERM'

pk_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s %s_process_killer.sh [--pid PID] [--signal TERM|KILL]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Options" \
    "--pid PID" "Process ID to terminate" \
    "--signal" "Signal to send: TERM or KILL (default: TERM)" \
    "-h, --help" "Show this help"
}
pk_memory_summary() {
  printf '\n  %s%sMemory overview%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  if uk_has_cmd free; then
    local total used swap_total swap_used
    read -r _ total used _ < <(free -m | awk '/^Mem:/ {print $1, $2, $3, $4}')
    read -r _ swap_total swap_used _ < <(free -m | awk '/^Swap:/ {print $1, $2, $3, $4}')
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
  local output error=''
  if ! output="$(ps -eo pid,user,%cpu,%mem,comm --sort=-%mem 2>&1)"; then
    error="$output"
    output="$(ps -axo pid,user,%cpu,%mem,comm 2>&1)" || { uk_error "Unable to list processes: ${output:-$error}"; return 1; }
    output="$(printf '%s\n' "$output" | { IFS= read -r header; printf '%s\n' "$header"; sort -k4 -rn; })" || return 1
  fi
  printf '%s\n' "$output" | head -n 11 | awk 'NR==1 {
      printf "  \033[1m%-8s %-12s %-6s %-6s %s\033[0m\n", $1, $2, $3, $4, $5
      next
    }
    { printf "  %-8s %-12s %-6s %-6s %s\n", $1, $2, $3, $4, $5 }'
}

pk_validate_target() {
  [[ "$PK_PID" =~ ^[1-9][0-9]*$ ]] || { uk_error "PID must be a positive integer: $PK_PID"; return 1; }
  case "${PK_SIGNAL^^}" in TERM | KILL | INT | HUP | QUIT) PK_SIGNAL="${PK_SIGNAL^^}" ;;
  *) uk_error "Unsupported signal: $PK_SIGNAL"; return 1 ;;
  esac
}
pk_describe_pid() {
  ps -p "$PK_PID" -o pid=,user=,%cpu=,%mem=,comm=
}
pk_kill() {
  local before attempts=0
  pk_validate_target || return 1
  if ! before="$(pk_describe_pid)" || [[ -z "$before" ]]; then
    uk_warn "PID $PK_PID does not exist or is not visible to the current user."
    return 1
  fi
  uk_note "Target process: $before"
  kill -s "$PK_SIGNAL" -- "$PK_PID" || { uk_error "Failed to send SIG$PK_SIGNAL to PID $PK_PID."; return 1; }
  local state=''
  while state="$(ps -p "$PK_PID" -o stat= 2>&1)" && [[ -n "$state" && "$state" != Z* ]]; do
    ((attempts += 1))
    if ((attempts >= 10)); then
      uk_warn "Signal sent, but PID $PK_PID is still running."
      return 1
    fi
    sleep 0.1 || return 1
  done
  uk_success "Sent SIG$PK_SIGNAL to PID $PK_PID and the process exited."
}
pk_main() {
  uk_banner "process-killer" "RAM/swap overview, top consumers, optional signal send" "" "$@"
  PK_PID=''
  PK_SIGNAL='TERM'
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
