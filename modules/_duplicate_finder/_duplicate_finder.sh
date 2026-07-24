#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source external library if available (will not break if missing due to fallbacks)
[[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]] && source "$SCRIPT_DIR/../../lib/uk_common.sh"

DF_DIR='.'
DF_ACTION='report'
DF_APPLY=0

# Fallback functions if not defined in uk_common.sh
if ! declare -f uk_abs_path >/dev/null 2>&1; then
  uk_abs_path() {
    if command -v realpath >/dev/null; then
      realpath "${1:-}"
    else
      local dir file
      dir="$(cd "$(dirname "${1:-}")" && pwd -P)"
      file="$(basename "${1:-}")"
      printf '%s/%s\n' "$dir" "$file"
    fi
  }
fi
if ! declare -f uk_confirm >/dev/null 2>&1; then
  uk_confirm() {
    local prompt="${1:-}" default="${2:-}"
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
if ! declare -f uk_header >/dev/null 2>&1; then uk_header() { printf "\n=== %s ===\n%s\n" "${1:-}" "${2:-}"; }; fi
_df_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "${1:-}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -- "${1:-}" | awk '{print $1}'
  elif command -v md5sum >/dev/null 2>&1; then
    md5sum -- "${1:-}" | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q "${1:-}"
  else
    uk_error "No hash command found (sha256sum, shasum, md5sum, or md5)."
    return 1
  fi
}
df_usage() {
  local w
  w=$(uk_fh_cols); ((w > 80)) && w=80; ((w < 40)) && w=40
  printf '%sUsage: %sbash%s %s_duplicate_finder.sh [DIR] [--delete|--hardlink] [--apply]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Options" --name-w 22 \
    "--delete" "Delete duplicate copies, keeping the first file per hash" \
    "--hardlink" "Replace duplicates with hardlinks to the first file" \
    "--apply" "Execute the chosen action" \
    "-h, --help" "Show this help"
  uk_help_section "$w" "Examples" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_duplicate_finder.sh${UK_C_RESET:-} ${UK_C_DIM:-}~/Downloads${UK_C_RESET:-}" "Scan a directory for duplicates" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_duplicate_finder.sh${UK_C_RESET:-} ${UK_C_DIM:-}--delete --apply${UK_C_RESET:-}" "Delete duplicates in current dir" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_duplicate_finder.sh${UK_C_RESET:-} ${UK_C_DIM:-}--hardlink /path/to/dir${UK_C_RESET:-}" "Replace duplicates with hardlinks"
}
df_scan() {
  command -v find >/dev/null || {
    uk_error "find command is required."
    return 1
  }
  [[ -d "$DF_DIR" ]] || { uk_error "Directory not found: $DF_DIR"; return 1; }

  local scan_file file size hash candidate canonical duplicate link_tmp
  local -a files=() sizes=() canonicals=() duplicates=()
  scan_file="$(mktemp)" || { uk_error "Unable to create duplicate-scan temporary file."; return 1; }
  if ! find "$DF_DIR" \( -path '*/.git/*' -o -path '*/.git' -o -path '*/.hg/*' -o -path '*/.hg' -o -path '*/.svn/*' -o -path '*/.svn' \) -prune -o -type f -print0 >"$scan_file"; then
    rm -f "$scan_file" || uk_warn "Unable to remove failed scan file: $scan_file"
    uk_error "Directory traversal failed; refusing a partial duplicate report."
    return 1
  fi

  local abs_dir
  abs_dir="$(uk_abs_path "$DF_DIR")" || { rm -f "$scan_file"; return 1; }
  uk_section_title "Directory: $abs_dir"
  uk_note 'Scanning files by size first, then hashing exact-size matches...'

  while IFS= read -r -d '' file; do
    size="$(wc -c <"$file")" || {
      rm -f "$scan_file" || uk_warn "Unable to remove failed scan file: $scan_file"
      uk_error "Unable to read file size: $file"
      return 1
    }
    [[ "$size" =~ ^[0-9]+$ ]] || { uk_error "Invalid file size for: $file"; rm -f "$scan_file"; return 1; }
    files+=("$file")
    sizes+=("$size")
  done <"$scan_file"
  rm -f "$scan_file" || { uk_error "Unable to remove duplicate-scan temporary file."; return 1; }

  local i idx members group_key
  declare -A size_groups=() first_for_hash=()
  for ((i=0; i<${#files[@]}; i++)); do
    size_groups[${sizes[$i]}]+=" $i"
  done
  for group_key in "${!size_groups[@]}"; do
    members=()
    for idx in ${size_groups[$group_key]}; do
      members+=("${files[$idx]}")
    done
    ((${#members[@]} > 1)) || continue
    first_for_hash=()
    for candidate in "${members[@]}"; do
      hash="$(_df_hash "$candidate")" || { uk_error "Hashing failed: $candidate"; return 1; }
      [[ -n "$hash" ]] || { uk_error "Hash command returned no digest: $candidate"; return 1; }
      if [[ -n "${first_for_hash[$hash]:-}" ]]; then
        canonicals+=("${first_for_hash[$hash]}")
        duplicates+=("$candidate")
      else
        first_for_hash[$hash]="$candidate"
      fi
    done
  done

  if ((${#duplicates[@]} == 0)); then
    uk_success 'No exact duplicates found.'
    return 0
  fi
  local UK_C_BOLD=${UK_C_BOLD:-} UK_C_CYAN=${UK_C_CYAN:-} UK_C_RESET=${UK_C_RESET:-}
  local UK_C_GREEN=${UK_C_GREEN:-} UK_C_DIM=${UK_C_DIM:-} UK_I_ARROW=${UK_I_ARROW:-'>'}

  printf '\n  %s%sDuplicate groups found%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  for i in "${!duplicates[@]}"; do
    canonical="${canonicals[$i]}"
    duplicate="${duplicates[$i]}"
    printf '\n  %sKeep:%s   %s%s%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_GREEN" "$canonical" "$UK_C_RESET"
    printf '  %sDupe:%s   %s%s%s  %s(will be %s if applied)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$duplicate" "$UK_C_RESET" \
      "$UK_C_DIM" "${DF_ACTION:-removed}" "$UK_C_RESET"
  done
  printf '\n'

  if [[ "$DF_ACTION" == 'report' ]]; then
    uk_note 'Preview only. Use --delete or --hardlink with --apply to modify files.'
    return 0
  fi

  local changed=0
  for i in "${!duplicates[@]}"; do
    canonical="${canonicals[$i]}"
    duplicate="${duplicates[$i]}"
    if ((DF_APPLY == 1)); then
      case "$DF_ACTION" in
      delete)
        rm -f -- "$duplicate" || { uk_error "Failed to delete duplicate: $duplicate"; return 1; }
        ;;
      hardlink)
        link_tmp="${duplicate}.utilitykit-link.$$.$i"
        [[ ! -e "$link_tmp" && ! -L "$link_tmp" ]] || { uk_error "Temporary hardlink path already exists: $link_tmp"; return 1; }
        if ! ln -- "$canonical" "$link_tmp"; then
          uk_error "Failed to prepare hardlink for $duplicate (different filesystems?)"
          return 1
        fi
        if ! mv -f -- "$link_tmp" "$duplicate"; then
          rm -f -- "$link_tmp" || uk_warn "Unable to remove failed hardlink temporary file: $link_tmp"
          uk_error "Failed to atomically replace duplicate: $duplicate"
          return 1
        fi
        [[ "$canonical" -ef "$duplicate" ]] || { uk_error "Hardlink verification failed: $duplicate"; return 1; }
        ;;
      esac
      changed=$((changed + 1))
    else
      uk_note "Would ${DF_ACTION} duplicate: $duplicate"
    fi
  done

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
    case "${1:-}" in
    --delete) DF_ACTION='delete' ;;
    --hardlink) DF_ACTION='hardlink' ;;
    --apply) DF_APPLY=1 ;;
    -h | --help)
      df_usage
      return 0
      ;;
    *) DF_DIR="${1:-}" ;;
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
    if uk_menu --prompt "Choose an action" \
      "Report only|show duplicates, make no changes" \
      "Delete duplicates|remove dupes, keep the first copy" \
      "Replace with hardlinks|save space while keeping both paths"; then
      case "$UK_MENU_SELECTED" in
      1)
        DF_ACTION='delete'
        if uk_confirm 'Apply deletion now? (duplicates will be permanently removed)' 'N'; then
          DF_APPLY=1
        fi
        ;;
      2)
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
  fi

  df_scan
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  df_main "$@"
fi
