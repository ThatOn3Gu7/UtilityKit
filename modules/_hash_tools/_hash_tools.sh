#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_has_cmd >/dev/null 2>&1; then
  uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }
fi

if ! declare -f uk_error >/dev/null 2>&1; then
  uk_error() { printf "Error: %s\n" "$*" >&2; }
fi
# --------------------------

# Wrapper function to handle command differences correctly
ht_run_hash() {
  if uk_has_cmd sha256sum; then
    sha256sum -- "$@"
  elif uk_has_cmd shasum; then
    shasum -a 256 -- "$@"
  else
    uk_error 'sha256sum or shasum is required.'
    return 1
  fi
}
ht_usage() {
  echo 'Usage: _hash_tools.sh FILE|DIR...'
}
ht_main() {
  uk_banner "hash-tools" "sha256/md5 hashing over files and directory trees" "" "$@"
  if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    ht_usage
    return 0
  fi

  if [[ $# -eq 0 ]]; then
    ht_usage
    return 1
  fi

  local failed=0 scan_file path
  for f in "$@"; do
    if [[ ! -e "$f" ]]; then
      uk_error "File or directory not found: $f"
      failed=1
      continue
    fi

    if [[ -d "$f" ]]; then
      scan_file="$(mktemp)" || return 1
      if ! find "$f" -type f -print0 >"$scan_file"; then
        rm -f "$scan_file"
        uk_error "Directory traversal failed: $f"
        return 1
      fi
      while IFS= read -r -d '' path; do
        ht_run_hash "$path" || { rm -f "$scan_file"; return 1; }
      done <"$scan_file"
      rm -f "$scan_file" || return 1
    else
      ht_run_hash "$f" || return 1
    fi
  done
  return "$failed"
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  ht_main "$@"
fi
