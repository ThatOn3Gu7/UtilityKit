#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"
# Usage
bs_usage() {
  local w
  w=$(uk_fh_cols); ((w > 80)) && w=80; ((w < 40)) && w=40
  printf '%sUsage:%s\n %sbash%s _backup_sync.sh %s--source DIR --dest DIR [--apply] [--delete] [--exclude PATTERN]...%s\n\n' \
          "${UK_C_YELLOW:-}${UK_C_BOLD:-}" "${UK_C_RESET:-}" "${UK_C_GREEN:-}${UK_C_BOLD:-}" "${UK_C_RESET:-}" \
          "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Options" --name-w 24 \
    "--source, -s DIR" "Source directory" \
    "--dest, -d DIR" "Destination directory" \
    "--apply" "Actually perform the copy; otherwise dry-run" \
    "--delete" "Delete files in destination not in source (rsync)" \
    "--exclude PATTERN" "Exclude files/dirs matching pattern" \
    "-h, --help" "Show this help"
}
bs_is_excluded() {
  local rel="${1:-}" pattern component
  local -a components=()
  shift
  for pattern in "$@"; do
    [[ -n "$pattern" ]] || continue
    [[ "$rel" == $pattern || "/$rel/" == *"/$pattern/"* ]] && return 0
    IFS='/' read -r -a components <<<"$rel"
    for component in "${components[@]}"; do [[ "$component" == $pattern ]] && return 0; done
  done
  return 1
}
# Main
bs_main() {
  uk_banner "backup-sync" "Dry-run-first backup wrapper around rsync" "" "$@"
  local src='' dst='' apply=0 delete=0
  local excludes=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --source | -s)
      shift
      src="${1:-}"
      ;;
    --dest | -d)
      shift
      dst="${1:-}"
      ;;
    --apply) apply=1 ;;
    --delete) delete=1 ;;
    --exclude)
      shift
      excludes+=("${1:-}")
      ;;
    -h | --help)
      bs_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  # Validate inputs
  if [[ -z "$src" || -z "$dst" ]]; then
    bs_usage
    return 1
  fi
  if [[ ! -d "$src" ]]; then
    uk_error "Source directory does not exist: $src"
    return 1
  fi

  local real_src real_dst
  real_src="$(cd "$src" && pwd -P)" || { uk_error "Unable to resolve source: $src"; return 1; }
  mkdir -p "$dst" || { uk_error "Unable to create destination: $dst"; return 1; }
  real_dst="$(cd "$dst" && pwd -P)" || { uk_error "Unable to resolve destination: $dst"; return 1; }
  [[ "$real_src" != "$real_dst" ]] || { uk_error 'Source and destination must differ.'; return 1; }
  [[ "$real_dst" != "$real_src"/* ]] || { uk_error 'Destination must not be inside source.'; return 1; }
  src="$real_src"
  dst="$real_dst"

  uk_section_title "$src → $dst"

  # Build exclusion patterns (always ignore .git and node_modules)
  local default_excludes=(".git" "node_modules")
  local all_excludes=("${default_excludes[@]}" "${excludes[@]}")

  # If rsync is available, use it (supports --delete and efficient sync)
  if uk_has_cmd rsync; then
    local args=(-a --itemize-changes --human-readable)
    ((delete == 1)) && args+=(--delete)
    ((apply == 0)) && args+=(--dry-run)

    for pattern in "${all_excludes[@]}"; do
      args+=(--exclude "$pattern")
    done

    rsync "${args[@]}" "$src"/ "$dst"/
    ((apply == 0)) && uk_note 'Dry-run only. Re-run with --apply to perform the sync.'
    return 0
  fi

  # Fallback: cp + checked find traversal (no --delete support)
  if ((delete == 1)); then
    uk_error 'rsync is required for --delete; refusing to silently ignore deletion semantics.'
    return 1
  fi

  local scan_file item rel target pattern copy_error=''
  local -a item_list=()
  scan_file="$(mktemp)" || { uk_error 'Unable to create backup scan file.'; return 1; }
  if ! find "$src" -mindepth 1 -print0 >"$scan_file"; then
    rm -f "$scan_file"
    uk_error 'Source traversal failed; refusing a partial backup.'
    return 1
  fi
  mapfile -d '' item_list <"$scan_file" || { rm -f "$scan_file"; return 1; }
  rm -f "$scan_file" || return 1

  if ((apply == 1)); then
    uk_note 'Copying files using cp (rsync not available)...'
    for item in "${item_list[@]}"; do
      rel="${item#"$src"/}"
      bs_is_excluded "$rel" "${all_excludes[@]}" && continue
      target="$dst/$rel"
      if [[ -d "$item" && ! -L "$item" ]]; then
        mkdir -p "$target" || return 1
      elif [[ -f "$item" || -L "$item" ]]; then
        mkdir -p "$(dirname "$target")" || return 1
        if ! copy_error="$(cp -a "$item" "$target" 2>&1)"; then
          uk_warn "cp -a failed; retrying with cp -p: $copy_error"
          cp -p "$item" "$target" || return 1
        fi
      fi
    done
    uk_success "Copy completed."
  else
    uk_note 'Dry-run: files that would be copied (excluding patterns):'
    for item in "${item_list[@]}"; do
      rel="${item#"$src"/}"
      bs_is_excluded "$rel" "${all_excludes[@]}" && continue
      printf '  would copy: %s\n' "$rel"
    done
    uk_note 'Dry-run only. Re-run with --apply to perform the copy (rsync not available).'
  fi

}
# Entry point
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  bs_main "$@"
fi
