#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

SD_APPLY=0
SD_PASSES=3
declare -a SD_FILES=()

sd_usage() {
  cat <<'USAGE'
Usage:
  _shredder.sh [--passes N] [--apply] FILE...
USAGE
}

sd_secure_delete() {
  local file="$1" size pass
  [[ -f "$file" ]] || { uk_warn "Skipping missing file: $file"; return 0; }
  if uk_has_cmd shred; then
    shred -n "$SD_PASSES" -z -u "$file"
    return 0
  fi
  size=$(wc -c < "$file")
  for ((pass=1; pass<=SD_PASSES; pass++)); do
    head -c "$size" /dev/urandom > "$file"
  done
  : > "$file"
  rm -f "$file"
}

sd_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --passes) shift; SD_PASSES="${1:-3}" ;;
      --apply) SD_APPLY=1 ;;
      -h|--help) sd_usage; return 0 ;;
      *) SD_FILES+=("$1") ;;
    esac
    shift
  done
  (( ${#SD_FILES[@]} > 0 )) || { sd_usage; return 1; }
  uk_header 'UtilityKit Shredder' "Passes: $SD_PASSES"
  local f
  for f in "${SD_FILES[@]}"; do
    if (( SD_APPLY == 1 )); then
      sd_secure_delete "$f"
      uk_success "Securely removed $f"
    else
      uk_note "Would securely erase $f"
    fi
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  sd_main "$@"
fi
