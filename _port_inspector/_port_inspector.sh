#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

PI_PORT=''
PI_KILL=0

pi_usage() {
  cat <<'USAGE'
Usage:
  _port_inspector.sh PORT [--kill]
USAGE
}
pi_network_summary() {
  uk_section_title 'Network interfaces'
  if uk_has_cmd ip; then
    local output
    output=$(ip -brief addr 2>/dev/null || true)
    if [[ -n "$output" ]]; then
      printf '%s\n' "$output" | sed 's/^/  /'
    else
      printf '  %s(no interface data available)%s\n' "$UK_C_DIM" "$UK_C_RESET"
    fi
  elif uk_has_cmd ifconfig; then
    ifconfig 2>/dev/null | sed -n '1,20p' | sed 's/^/  /' || true
  else
    printf '  %s(ip and ifconfig unavailable — skipping interface summary)%s\n' "$UK_C_DIM" "$UK_C_RESET"
  fi
}
pi_inspect() {
  if uk_has_cmd lsof; then
    lsof -nP -iTCP:"$PI_PORT" -sTCP:LISTEN
  elif uk_has_cmd ss; then
    ss -ltnp "sport = :$PI_PORT"
  else
    uk_error 'Neither lsof nor ss is available.'
    return 1
  fi
}
pi_extract_pid() {
  if uk_has_cmd lsof; then
    lsof -nP -iTCP:"$PI_PORT" -sTCP:LISTEN -t 2>/dev/null | head -n 1
  else
    ss -ltnp "sport = :$PI_PORT" 2>/dev/null | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -n 1
  fi
}
pi_main() {
  uk_banner "port-inspector" "Find which process owns a local TCP port" "" "$@"
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --kill) PI_KILL=1 ;;
    -h | --help)
      pi_usage
      return 0
      ;;
    *) PI_PORT="$1" ;;
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

  uk_section_title "Port: $PI_PORT"
  pi_network_summary
  printf '\nListening process details:\n'
  if ! pi_inspect; then
    uk_warn "No listening process found for port $PI_PORT"
    return 0
  fi

  local pid
  pid=$(pi_extract_pid || true)
  if [[ -n "$pid" ]]; then
    if ((PI_KILL == 1)) || uk_confirm "Terminate PID $pid holding port $PI_PORT?" 'N'; then
      kill "$pid"
      uk_success "Sent SIGTERM to PID $pid"
    fi
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  pi_main "$@"
fi
