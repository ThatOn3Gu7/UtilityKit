#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_warn >/dev/null 2>&1; then uk_warn() { printf "Warning: %s\n" "$*" >&2; }; fi
# --------------------------

lic_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf 'Usage:\n  _license_helper.sh --detect\n  _license_helper.sh --generate TYPE --name NAME\n\n'
  uk_help_section "$w" "Options" \
    "--detect" "Detect existing license in current directory." \
    "--generate TYPE" "Generate license (mit, apache)." \
    "--name NAME" "Name for the license." \
    "-h, --help" "Show this help."
}
lic_main() {
  uk_banner "license-helper" "Detect existing license and generate MIT or Apache 2.0" "" "$@"
  local gen='' name='' detect=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --detect) detect=1 ;;
    --generate)
      if [[ $# -gt 1 ]]; then
        shift
        gen="${1:-mit}"
      else
        uk_warn "Option --generate requires a type (e.g., mit)."
        return 1
      fi
      ;;
    --name)
      if [[ $# -gt 1 ]]; then
        shift
        name="${1:-}"
      else
        uk_warn "Option --name requires a name."
        return 1
      fi
      ;;
    -h|--help) lic_usage; return 0 ;;
    *) uk_warn "Unknown option: ${1:-}"; return 1 ;;
    esac
    shift
  done

  # Detection logic
  if ((detect == 1)); then
    local found
    found=$(find . -maxdepth 1 -type f \( -name 'LICENSE*' -o -name 'COPYING*' \) 2>/dev/null | head -1)
    if [[ -z "$found" ]]; then
      uk_warn 'No license file (LICENSE* or COPYING*) found in current directory.'
    else
      uk_success "Found: $found"
    fi
    return 0
  fi

  # Generation logic
  [[ -n "$gen" ]] || { lic_usage; return 1; }

  case "$gen" in
  mit)
    printf "MIT License\n\nCopyright (c) %s %s\n\nPermission is hereby granted..." "$(date +%Y)" "$name"
    ;;
  apache)
    printf "Apache License 2.0\n\nCopyright %s %s\n\nLicensed under the Apache License..." "$(date +%Y)" "$name"
    ;;
  *)
    uk_warn "Unsupported license type: $gen"
    return 1
    ;;
  esac
  printf '\n'
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  lic_main "$@"
fi
