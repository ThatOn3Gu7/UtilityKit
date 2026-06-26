#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
psrch_usage() { echo 'Usage: _project_search.sh --text PATTERN|--name GLOB [DIR]'; }
psrch_main() {
  local text='' name='' dir='.'
  while [[ $# -gt 0 ]]; do
    case "$1" in --text)
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
    *) dir="$1" ;; esac
    shift
  done
  [[ -n "$text" ]] && {
    uk_has_cmd rg && rg "$text" "$dir" || grep -RIn "$text" "$dir" || true
    return
  }
  [[ -n "$name" ]] && find "$dir" -name "$name"
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  psrch_main "$@"
fi
