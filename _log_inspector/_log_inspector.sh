#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
  source "$SCRIPT_DIR/../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "Error: %s\n" "$*" >&2; }; fi

li_usage() {
  cat <<USAGE
Usage:
  _log_inspector.sh FILE [OPTIONS]

Options:
  --pattern REGEX  Grep pattern (default: error|warn|fail|exception)
  -h, --help       Show this help.
USAGE
}
li_main() {
  uk_banner "log-inspector" "Grep error/warn/fail patterns and surface frequent lines" "" "$@"
  local file='' pattern='error|warn|fail|exception'

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --pattern)
      if [[ $# -gt 1 ]]; then
        shift
        pattern="${1:-}"
      else
        uk_error "Option --pattern requires a regex."
        return 1
      fi
      ;;
    -h | --help)
      li_usage
      return 0
      ;;
    -*)
      uk_error "Unknown option: ${1:-}"
      li_usage
      return 1
      ;;
    *) file="${1:-}" ;;
    esac
    shift
  done

  if [[ -z "$file" ]]; then
    uk_error "No log file specified."
    li_usage
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    uk_error "Log file not found: $file"
    return 1
  fi

  # 1. Inspect patterns (guarded against pipefail)
  printf "\n=== Pattern Matches: %s ===\n" "$pattern"
  grep -Ein "$pattern" "$file" | head -n 50 || true

  # 2. Summary counts (using sort -S for memory safety)
  printf "\n=== Frequency Summary (Top 10) ===\n"
  # Use GNU sort -S when available, with a BSD/macOS fallback.
  if sort -S 50% </dev/null >/dev/null 2>&1; then
    sort -S 50% "$file" | uniq -c | sort -rn | head -n 10 || true
  else
    sort "$file" | uniq -c | sort -rn | head -n 10 || true
  fi
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  li_main "$@"
fi
