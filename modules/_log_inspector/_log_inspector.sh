#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "Error: %s\n" "$*" >&2; }; fi

li_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s %s_log_inspector.sh FILE [OPTIONS]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Options" \
    "--pattern REGEX" "Grep pattern (default: error|warn|fail|exception)" \
    "-h, --help" "Show this help."
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

  # 1. Inspect patterns; distinguish no matches from an invalid regex/read error.
  printf "\n=== Pattern Matches: %s ===\n" "$pattern"
  local matches status=0 summary
  matches="$(grep -Ein -- "$pattern" "$file")" || status=$?
  if ((status == 0)); then
    awk 'NR<=50' <<<"$matches"
  elif ((status == 1)); then
    printf '(no matches)\n'
  else
    uk_error "Pattern search failed with status $status."
    return "$status"
  fi

  # 2. Summary counts (using sort -S for memory safety)
  printf "\n=== Frequency Summary (Top 10) ===\n"
  local probe_log
  probe_log="$(mktemp)" || { uk_error "Unable to create temporary file."; return 1; }
  if sort -S 50% </dev/null >/dev/null 2>"$probe_log"; then
    summary="$(sort -S 50% "$file" | uniq -c | sort -rn)" || { rm -f "$probe_log"; return 1; }
  else
    [[ -s "$probe_log" ]] && uk_note "GNU sort memory option unavailable; using portable sort."
    summary="$(sort "$file" | uniq -c | sort -rn)" || { rm -f "$probe_log"; return 1; }
  fi
  rm -f "$probe_log" || return 1
  awk 'NR<=10' <<<"$summary"
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  li_main "$@"
fi
