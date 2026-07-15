#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"
of_usage() { echo 'Usage: _open_files.sh --path PATH | --port PORT'; }
of_main() {
  uk_banner "open-files" "Find processes using a path or port via lsof" "" "$@"
  local path='' port=''
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in --path)
      shift
      path="${1:-}"
      ;;
    --port)
      shift
      port="${1:-}"
      ;;
    -h | --help)
      of_usage
      return 0
      ;;
    esac
    shift
  done
  uk_has_cmd lsof || { uk_error 'lsof unavailable'; return 1; }
  if [[ -n "$path" ]]; then
    local output status=0
    output="$(lsof -- "$path" 2>&1)" || status=$?
    if ((status != 0)); then
      [[ -n "$output" ]] && uk_error "lsof path lookup failed: $output" || uk_note "No process is using: $path"
      return "$status"
    fi
    printf '%s\n' "$output"
    return 0
  fi
  if [[ -n "$port" ]]; then
    [[ "$port" =~ ^[0-9]+$ ]] && ((port >= 1 && port <= 65535)) || { uk_error "Invalid port: $port"; return 1; }
    local output status=0
    output="$(lsof -i ":$port" 2>&1)" || status=$?
    if ((status != 0)); then
      [[ -n "$output" ]] && uk_error "lsof port lookup failed: $output" || uk_note "No process is using port: $port"
      return "$status"
    fi
    printf '%s\n' "$output"
    return 0
  fi
  of_usage
  return 1
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  of_main "$@"
fi
