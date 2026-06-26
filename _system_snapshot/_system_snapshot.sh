#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
ssn_usage() { echo 'Usage: _system_snapshot.sh [--output FILE]'; }
ssn_main() {
  local out=''
  while [[ $# -gt 0 ]]; do
    case "$1" in --output)
      shift
      out="${1:-}"
      ;;
    -h | --help)
      ssn_usage
      return 0
      ;;
    esac
    shift
  done
  {
    echo "OS: $(uname -a)"
    echo "Platform: $(uk_platform)"
    df -h . 2>/dev/null || true
  } | { [[ -n "$out" ]] && tee "$out" || cat; }
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  ssn_main "$@"
fi
