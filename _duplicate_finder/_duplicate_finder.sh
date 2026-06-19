#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

DF_DIR='.'
DF_ACTION='report'
DF_APPLY=0

_df_hash() {
  if uk_has_cmd sha256sum; then
    sha256sum "$1" | awk '{print $1}'
  elif uk_has_cmd shasum; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    md5sum "$1" | awk '{print $1}'
  fi
}

df_usage() {
  cat <<'USAGE'
Usage:
  _duplicate_finder.sh [DIR] [--delete|--hardlink] [--apply]

Options:
  --delete      Delete duplicate copies, keeping the first file per hash.
  --hardlink    Replace duplicates with hardlinks to the first file.
  --apply       Execute the chosen action.
  -h, --help    Show this help.
USAGE
}

df_scan() {
  local sizes_file duplicates_file current_size='' file size
  sizes_file=$(mktemp)
  duplicates_file=$(mktemp)

  uk_header 'UtilityKit Duplicate Finder' "Directory: $(uk_abs_path "$DF_DIR")"
  uk_note 'Scanning files by size first, then hashing exact-size matches...'

  while IFS= read -r -d '' file; do
    size=$(wc -c < "$file")
    printf '%s\t%s\n' "$size" "$file" >> "$sizes_file"
  done < <(find "$DF_DIR" \( -path '*/.git/*' -o -path '*/.git' -o -path '*/.hg/*' -o -path '*/.hg' -o -path '*/.svn/*' -o -path '*/.svn' \) -prune -o -type f -print0)
  sort -n "$sizes_file" -o "$sizes_file"

  local -a group=()
  while IFS=$'\t' read -r size file; do
    if [[ "$size" != "$current_size" && ${#group[@]} -gt 0 ]]; then
      if (( ${#group[@]} > 1 )); then
        local candidate hash
        declare -A first_for_hash=()
        for candidate in "${group[@]}"; do
          hash=$(_df_hash "$candidate")
          if [[ -n "${first_for_hash[$hash]:-}" ]]; then
            printf '%s\t%s\n' "${first_for_hash[$hash]}" "$candidate" >> "$duplicates_file"
          else
            first_for_hash[$hash]="$candidate"
          fi
        done
      fi
      group=()
    fi
    current_size="$size"
    group+=("$file")
  done < "$sizes_file"

  if (( ${#group[@]} > 1 )); then
    local candidate hash
    declare -A first_for_hash=()
    for candidate in "${group[@]}"; do
      hash=$(_df_hash "$candidate")
      if [[ -n "${first_for_hash[$hash]:-}" ]]; then
        printf '%s\t%s\n' "${first_for_hash[$hash]}" "$candidate" >> "$duplicates_file"
      else
        first_for_hash[$hash]="$candidate"
      fi
    done
  fi

  if [[ ! -s "$duplicates_file" ]]; then
    uk_success 'No exact duplicates found.'
    rm -f "$sizes_file" "$duplicates_file"
    return 0
  fi

  awk -F '\t' '{printf "Canonical: %s\n  duplicate: %s\n", $1, $2}' "$duplicates_file"

  if [[ "$DF_ACTION" == 'report' ]]; then
    uk_note 'Preview only. Use --delete or --hardlink with --apply to modify files.'
    return 0
  fi

  local canonical duplicate changed=0
  while IFS=$'\t' read -r canonical duplicate; do
    if (( DF_APPLY == 1 )); then
      case "$DF_ACTION" in
        delete)
          rm -f "$duplicate"
          ;;
        hardlink)
          rm -f "$duplicate"
          ln "$canonical" "$duplicate"
          ;;
      esac
      changed=$((changed + 1))
    else
      uk_note "Would ${DF_ACTION} duplicate: $duplicate"
    fi
  done < "$duplicates_file"

  (( DF_APPLY == 1 )) && uk_success "Processed $changed duplicate file(s)."
  rm -f "$sizes_file" "$duplicates_file"
}

df_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --delete) DF_ACTION='delete' ;;
      --hardlink) DF_ACTION='hardlink' ;;
      --apply) DF_APPLY=1 ;;
      -h|--help) df_usage; return 0 ;;
      *) DF_DIR="$1" ;;
    esac
    shift
  done
  df_scan
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  df_main "$@"
fi
