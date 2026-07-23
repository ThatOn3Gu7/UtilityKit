#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

PI_PORT=''
PI_KILL=0

pi_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf 'Usage: _port_inspector.sh PORT [--kill]\n\n'
  uk_help_section "$w" "Options" \
    "PORT" "Local TCP port number to inspect" \
    "--kill" "Terminate the process holding the port" \
    "-h, --help" "Show this help"
}
pi_network_summary() {
  uk_section_title 'Network interfaces'
  if uk_has_cmd ip; then
    local output
    output="$(ip -brief addr 2>&1)" || { uk_error "Unable to inspect interfaces: $output"; return 1; }
    if [[ -n "$output" ]]; then
      printf '%s\n' "$output" | sed 's/^/  /'
    else
      printf '  %s(no interface data available)%s\n' "$UK_C_DIM" "$UK_C_RESET"
    fi
  elif uk_has_cmd ifconfig; then
    local output
    output="$(ifconfig 2>&1)" || { uk_error "Unable to inspect interfaces: $output"; return 1; }
    sed -n '1,20p' <<<"$output" | sed 's/^/  /'
  else
    printf '  %s(ip and ifconfig unavailable — skipping interface summary)%s\n' "$UK_C_DIM" "$UK_C_RESET"
  fi
}
pi_validate_port() {
  [[ "$PI_PORT" =~ ^[0-9]+$ ]] && ((PI_PORT >= 1 && PI_PORT <= 65535)) || {
    uk_error "Port must be an integer from 1 to 65535: $PI_PORT"
    return 1
  }
}
pi_inspect() {
  local output
  if uk_has_cmd lsof; then
    if ! output="$(lsof -nP -iTCP:"$PI_PORT" -sTCP:LISTEN 2>&1)"; then
      [[ -z "$output" ]] && return 3
      uk_error "lsof failed: $output"
      return 1
    fi
  elif uk_has_cmd ss; then
    output="$(ss -H -ltnp "sport = :$PI_PORT" 2>&1)" || { uk_error "ss failed: $output"; return 1; }
    [[ -n "$output" ]] || return 3
  else
    uk_error 'Neither lsof nor ss is available.'
    return 1
  fi
  printf '%s\n' "$output"
}
pi_extract_pid() {
  local output
  if uk_has_cmd lsof; then
    output="$(lsof -nP -iTCP:"$PI_PORT" -sTCP:LISTEN -t 2>&1)" || { [[ -z "$output" ]] && return 3; uk_error "lsof PID lookup failed: $output"; return 1; }
    awk 'NR==1 {print; exit}' <<<"$output"
  else
    output="$(ss -H -ltnp "sport = :$PI_PORT" 2>&1)" || { uk_error "ss PID lookup failed: $output"; return 1; }
    sed -n 's/.*pid=\([0-9]\+\).*/\1/p' <<<"$output" | awk 'NR==1 {print; exit}'
  fi
}
pi_main() {
  uk_banner "port-inspector" "Find which process owns a local TCP port" "" "$@"
  PI_PORT=''
  PI_KILL=0
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --kill) PI_KILL=1 ;;
    -h | --help)
      pi_usage
      return 0
      ;;
    *) PI_PORT="${1:-}" ;;
    esac
    shift
  done

  if [[ -z "$PI_PORT" && -t 0 ]]; then
    PI_PORT="$(uk_prompt \
      'Enter the local TCP port number to inspect' \
      '' \
      '3000   →  Node dev server | 8080  →  common HTTP alt | 5432  →  Postgres' \
      'The tool will find whichever process is currently listening on this port.')"
  fi
  [[ -n "$PI_PORT" ]] || {
    pi_usage
    return 1
  }

  pi_validate_port || return 1
  uk_section_title "Port: $PI_PORT"
  pi_network_summary || return 1
  printf '\nListening process details:\n'
  local inspect_status=0
  pi_inspect || inspect_status=$?
  if ((inspect_status == 3)); then
    uk_warn "No listening process found for port $PI_PORT"
    return 1
  elif ((inspect_status != 0)); then
    return "$inspect_status"
  fi

  local pid
  pid="$(pi_extract_pid)" || return $?
  if [[ -n "$pid" ]]; then
    [[ "$pid" =~ ^[1-9][0-9]*$ ]] || { uk_error "Invalid PID returned for port $PI_PORT: $pid"; return 1; }
    if ((PI_KILL == 1)) || uk_confirm "Terminate PID $pid holding port $PI_PORT?" 'N'; then
      kill -- "$pid" || { uk_error "Failed to signal PID $pid"; return 1; }
      sleep 0.2 || return 1
      if ps -p "$pid" >/dev/null; then
        uk_error "PID $pid is still running after SIGTERM."
        return 1
      fi
      uk_success "Sent SIGTERM to PID $pid and verified it exited."
    fi
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  pi_main "$@"
fi
