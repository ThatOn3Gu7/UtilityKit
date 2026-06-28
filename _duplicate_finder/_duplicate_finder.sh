#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source external library if available (will not break if missing due to fallbacks)
[[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]] && source "$SCRIPT_DIR/../lib/uk_common.sh"

DF_DIR='.'
DF_ACTION='report'
DF_APPLY=0

# Fallback functions if not defined in uk_common.sh
if ! declare -f uk_abs_path >/dev/null 2>&1; then
  uk_abs_path() {
    if command -v realpath >/dev/null; then
      realpath "$1"
    else
      local dir file
      dir="$(cd "$(dirname "$1")" && pwd -P)"
      file="$(basename "$1")"
      printf '%s/%s\n' "$dir" "$file"
    fi
  }
fi
if ! declare -f uk_confirm >/dev/null 2>&1; then
  uk_confirm() {
    local prompt="$1" default="$2"
    local answer
    printf '%s [%s/%s]: ' "$prompt" \
      "$([[ "$default" == "Y" ]] && echo "Y" || echo "y")" \
      "$([[ "$default" == "N" ]] && echo "N" || echo "n")" >&2
    read -r answer
    case "$answer" in
    Y | y) return 0 ;;
    N | n) return 1 ;;
    *) [[ "$default" == "Y" || "$default" == "y" ]] && return 0 || return 1 ;;
    esac
  }
fi
# Fallback for logging if not defined
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "Error: %s\n" "$*"; }; fi
if ! declare -f uk_note >/dev/null 2>&1; then uk_note() { printf "Note: %s\n" "$*"; }; fi
if ! declare -f uk_success >/dev/null 2>&1; then uk_success() { printf "Success: %s\n" "$*"; }; fi
if ! declare -f uk_header >/dev/null 2>&1; then uk_header() { printf "\n=== %s ===\n%s\n" "$1" "$2"; }; fi
_df_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q "$1" 2>/dev/null || md5 "$1" | awk '{print $NF}'
  else
    uk_error "No hash command found (sha256sum, shasum, md5sum, or md5)."
    return 1
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
  if ! command -v find >/dev/null; then
    uk_error "find command is required."
    return 1
  fi

  local current_size='' file size
  sizes_file=''
  duplicates_file=''

  trap 'rm -f -- "$sizes_file" "$duplicates_file"' EXIT

  sizes_file=$(mktemp)
  duplicates_file=$(mktemp)

  uk_section_title "Directory: $(uk_abs_path "$DF_DIR")"
  uk_note 'Scanning files by size first, then hashing exact-size matches...'

  while IFS= read -r -d '' file; do
    size=$(wc -c <"$file" 2>/dev/null || echo "0")
    printf '%s\t%s\n' "$size" "$file" >>"$sizes_file"
  done < <(find "$DF_DIR" \( -path '*/.git/*' -o -path '*/.git' -o -path '*/.hg/*' -o -path '*/.hg' -o -path '*/.svn/*' -o -path '*/.svn' \) -prune -o -type f -print0)

  sort -n "$sizes_file" -o "$sizes_file"

  local -a group=()
  current_size=''

  while IFS=$'\t' read -r size file; do
    if [[ "$size" != "$current_size" && ${#group[@]} -gt 0 ]]; then
      if ((${#group[@]} > 1)); then
        local candidate hash
        unset -v first_for_hash 2>/dev/null || true
        declare -A first_for_hash
        for candidate in "${group[@]}"; do
          hash=$(_df_hash "$candidate") || continue
          if [[ -n "${first_for_hash[$hash]:-}" ]]; then
            printf '%s\t%s\n' "${first_for_hash[$hash]}" "$candidate" >>"$duplicates_file"
          else
            first_for_hash[$hash]="$candidate"
          fi
        done
      fi
      group=()
    fi
    current_size="$size"
    group+=("$file")
  done <"$sizes_file"

  # Process last group
  if ((${#group[@]} > 1)); then
    local candidate hash
    unset -v first_for_hash 2>/dev/null || true
    declare -A first_for_hash
    for candidate in "${group[@]}"; do
      hash=$(_df_hash "$candidate") || continue
      if [[ -n "${first_for_hash[$hash]:-}" ]]; then
        printf '%s\t%s\n' "${first_for_hash[$hash]}" "$candidate" >>"$duplicates_file"
      else
        first_for_hash[$hash]="$candidate"
      fi
    done
  fi
  if [[ ! -s "$duplicates_file" ]]; then
    uk_success 'No exact duplicates found.'
    return 0
  fi
  local UK_C_BOLD=${UK_C_BOLD:-} UK_C_CYAN=${UK_C_CYAN:-} UK_C_RESET=${UK_C_RESET:-}
  local UK_C_GREEN=${UK_C_GREEN:-} UK_C_DIM=${UK_C_DIM:-} UK_I_ARROW=${UK_I_ARROW:-'>'}

  printf '\n  %s%sDuplicate groups found%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  while IFS=$'\t' read -r canon dup; do
    printf '\n  %sKeep:%s   %s%s%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_GREEN" "$canon" "$UK_C_RESET"
    printf '  %sDupe:%s   %s%s%s  %s(will be %s if applied)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$dup" "$UK_C_RESET" \
      "$UK_C_DIM" "${DF_ACTION:-removed}" "$UK_C_RESET"
  done <"$duplicates_file"
  printf '\n'

  if [[ "$DF_ACTION" == 'report' ]]; then
    uk_note 'Preview only. Use --delete or --hardlink with --apply to modify files.'
    return 0
  fi

  local changed=0
  while IFS=$'\t' read -r canonical duplicate; do
    if ((DF_APPLY == 1)); then
      case "$DF_ACTION" in
      delete)
        rm -f "$duplicate"
        ;;
      hardlink)
        rm -f "$duplicate"
        if ! ln "$canonical" "$duplicate"; then
          uk_error "Failed to create hardlink from $canonical to $duplicate (different filesystems?)"
          continue
        fi
        ;;
      esac
      changed=$((changed + 1))
    else
      uk_note "Would ${DF_ACTION} duplicate: $duplicate"
    fi
  done <"$duplicates_file"

  ((DF_APPLY == 1)) && uk_success "Processed $changed duplicate file(s)."
}
df_main() {
  uk_banner "duplicate-finder" "Size-first, hash-second duplicate detection" "" "$@"
  DF_DIR='.'
  DF_ACTION='report'
  DF_APPLY=0
  local seen_args=0
  while [[ $# -gt 0 ]]; do
    seen_args=1
    case "$1" in
    --delete) DF_ACTION='delete' ;;
    --hardlink) DF_ACTION='hardlink' ;;
    --apply) DF_APPLY=1 ;;
    -h | --help)
      df_usage
      return 0
      ;;
    *) DF_DIR="$1" ;;
    esac
    shift
  done
  if ((seen_args == 0)) && [[ -t 0 && -t 1 ]]; then

    if declare -f uk_prompt >/dev/null 2>&1; then
      DF_DIR="$(uk_prompt 'Enter directory to scan for duplicates' '.' '~/Downloads | ~/Pictures | ./assets' 'Matches sizes first, then hashes.')"
    else
      printf "Enter directory to scan for duplicates [default: .]: "
      read -r DF_DIR
      DF_DIR=${DF_DIR:-.}
    fi

    printf '\n'
    printf '  1) Report only          (show duplicates, make no changes)\n'
    printf '  2) Delete duplicates    (remove dupes, keep the first copy of each)\n'
    printf '  3) Replace with hardlinks (save space while keeping both paths intact)\n'
    printf '\n Choose an action [1-3]: '
    read -r mode </dev/tty

    case "$mode" in
    2)
      DF_ACTION='delete'
      if uk_confirm 'Apply deletion now? (duplicates will be permanently removed)' 'N'; then
        DF_APPLY=1
      fi
      ;;
    3)
      DF_ACTION='hardlink'
      if uk_confirm 'Apply hardlinking now? (duplicate files will be replaced with hardlinks)' 'N'; then
        DF_APPLY=1
      fi
      ;;
    *)
      DF_ACTION='report'
      ;;
    esac
  fi

  df_scan
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  df_main "$@"
fi
