#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"
psrch_usage() { echo 'Usage: _project_search.sh --text PATTERN|--name GLOB [DIR]'; }
psrch_main() {
  uk_banner "project-search" "Text or filename search with rg → grep → find fallback" "" "$@"
  local text='' name='' dir='.'
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in --text)
      shift
      text="${1:-}"
      ;;
    --name)
      shift
      name="${1:-}"
      ;;
    -h | --help)
      psrch_usage
      return 0
      ;;
    *) dir="${1:-}" ;; esac
    shift
  done
  if [[ -n "$text" ]]; then
    if uk_has_cmd rg; then
      rg -- "$text" "$dir"
      return $?
    fi
    grep -RIn -- "$text" "$dir"
    return $?
  fi
  if [[ -n "$name" ]]; then
    find "$dir" -name "$name"
    return $?
  fi
  uk_error 'Specify --text or --name.'
  return 1
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  psrch_main "$@"
fi
