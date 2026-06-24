#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
  source "$SCRIPT_DIR/../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_warn >/dev/null 2>&1; then uk_warn() { printf "Warning: %s\n" "$*" >&2; }; fi
# --------------------------

lic_usage() {
  cat <<USAGE
Usage:
  _license_helper.sh --detect
  _license_helper.sh --generate TYPE --name NAME

Types: mit, apache
USAGE
}

lic_main() {
  local gen='' name=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --detect) gen='' ;;
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
    -h | --help)
      lic_usage
      return 0
      ;;
    *)
      uk_warn "Unknown option: $1"
      return 1
      ;;
    esac
    shift
  done

  # Detection logic
  if [[ -z "$gen" ]]; then
    if ! find . -maxdepth 1 \( -name 'LICENSE*' -o -name 'COPYING*' \) -print -quit | grep -q .; then
      uk_warn 'No license file (LICENSE* or COPYING*) found in current directory.'
    fi
    return 0
  fi

  # Generation logic
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
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" license
  else
    lic_main "$@"
  fi
fi
