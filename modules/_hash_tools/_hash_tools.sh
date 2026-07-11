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
    sha256sum "$@"
  else
    shasum -a 256 "$@"
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

  for f in "$@"; do
    if [[ ! -e "$f" ]]; then
      uk_error "File or directory not found: $f"
      continue
    fi

    if [[ -d "$f" ]]; then
      # Use find with -print0 and xargs -0 to handle filenames with spaces correctly.
      # Guard the pipeline with '|| true' so non-zero exits don't trip set -e.
      find "$f" -type f -print0 | xargs -0 -r bash -c 'ht_run_hash "$@"' _ || true
    else
      ht_run_hash "$f"
    fi
  done
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  ht_main "$@"
fi
