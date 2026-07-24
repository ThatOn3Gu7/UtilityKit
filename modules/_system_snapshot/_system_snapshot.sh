#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"
ssn_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s %s_system_snapshot.sh [OPTIONS]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Options" \
    "--output FILE" "Write snapshot to FILE instead of stdout" \
    "-h, --help" "Show this help"
  uk_help_section "$w" "Examples" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_system_snapshot.sh${UK_C_RESET:-} ${UK_C_DIM:-}--output /tmp/sys.txt${UK_C_RESET:-}" "Save snapshot to file"
}
ssn_main() {
  uk_banner "system-snapshot" "Compact diagnostic summary of OS, platform, disk" "" "$@"
  local out=''
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in --output)
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
