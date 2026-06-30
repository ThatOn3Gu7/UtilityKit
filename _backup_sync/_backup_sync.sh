#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
# Usage
bs_usage() {
  cat <<'USAGE'
Usage:
  _backup_sync.sh --source DIR --dest DIR [--apply] [--delete] [--exclude PATTERN]...

Options:
  --source, -s DIR      Source directory
  --dest, -d DIR        Destination directory
  --apply               Actually perform the copy; otherwise dry-run
  --delete              Delete files in destination that are not in source (requires rsync)
  --exclude PATTERN     Exclude files/dirs matching pattern (can be repeated)
  -h, --help            Show this help
USAGE
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

  mkdir -p "$dst"

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

  # Fallback: cp + find (no --delete support)
  if ((delete == 1)); then
    uk_warn 'rsync is not available; --delete will be ignored.'
  fi

  # Build find prune expression for all excludes
  local find_prune=()
  for pattern in "${all_excludes[@]}"; do
    # Simple pattern: we assume no wildcards or paths; just name-based pruning
    find_prune+=(-name "$pattern" -prune -o)
  done

  if ((apply == 1)); then
    uk_note 'Copying files using cp (rsync not available)...'

    mapfile -d '' item_list < <(find "$src" -mindepth 1 \( "${find_prune[@]}" \) -print0 2>/dev/null)
    for item in "${item_list[@]}"; do
      local rel="${item#"$src"/}"
      local target="$dst/$rel"
      if [[ -d "$item" && ! -L "$item" ]]; then
        mkdir -p "$target"
        # copy permissions if needed? but we will copy files later.
      elif [[ -f "$item" || -L "$item" ]]; then
        mkdir -p "$(dirname "$target")"
        cp -a "$item" "$target" 2>/dev/null || cp -p "$item" "$target"
      fi
    done
    uk_success "Copy completed."
  else
    uk_note 'Dry-run: files that would be copied (excluding patterns):'
    find "$src" -mindepth 1 \( "${find_prune[@]}" \) -print 2>/dev/null | while IFS= read -r item; do
      echo "  would copy: ${item#"$src"/}"
    done
    uk_note 'Dry-run only. Re-run with --apply to perform the copy (rsync not available).'
  fi
}
# Entry point
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  bs_main "$@"
fi
