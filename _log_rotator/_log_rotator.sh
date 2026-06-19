#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

LR_ARCHIVE_AFTER=7
LR_PURGE_AFTER=30
LR_APPLY=0
LR_ARCHIVE_DIR=''
declare -a LR_PATHS=()

lr_usage() {
  cat <<'USAGE'
Usage:
  _log_rotator.sh [--path DIR]... [--older-than DAYS] [--purge-older-than DAYS] [--archive-dir DIR] [--apply]
USAGE
}

lr_default_paths() {
  local path
  for path in /var/log "$HOME/.pm2/logs" ./logs; do
    [[ -d "$path" ]] && LR_PATHS+=("$path")
  done
}

lr_collect_logs() {
  local base="$1" list_file="$2"
  (cd "$base" && find . -type f -mtime +"$LR_ARCHIVE_AFTER" -print | sed 's#^\./##') >> "$list_file" 2>/dev/null || true
}

lr_archive_path() {
  local path="$1"
  local name
  name="$(basename "$path")_$(uk_stamp).tar.gz"
  printf '%s/%s\n' "$LR_ARCHIVE_DIR" "$name"
}

lr_main() {
  LR_ARCHIVE_AFTER=7
  LR_PURGE_AFTER=30
  LR_APPLY=0
  LR_ARCHIVE_DIR=''
  LR_PATHS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path) shift; LR_PATHS+=("${1:-}") ;;
      --older-than) shift; LR_ARCHIVE_AFTER="${1:-7}" ;;
      --purge-older-than) shift; LR_PURGE_AFTER="${1:-30}" ;;
      --archive-dir) shift; LR_ARCHIVE_DIR="${1:-}" ;;
      --apply) LR_APPLY=1 ;;
      -h|--help) lr_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done

  [[ ${#LR_PATHS[@]} -gt 0 ]] || lr_default_paths
  [[ ${#LR_PATHS[@]} -gt 0 ]] || { uk_error 'No log directories found. Use --path.'; return 1; }
  LR_ARCHIVE_DIR=${LR_ARCHIVE_DIR:-"$(uk_state_dir)/log_archives"}
  mkdir -p "$LR_ARCHIVE_DIR"

  uk_header 'UtilityKit Log Rotator' "Archive dir: $LR_ARCHIVE_DIR"
  local path list_file archive archived=0 removed=0
  list_file=$(mktemp)
  trap "rm -f '$list_file'" RETURN

  for path in "${LR_PATHS[@]}"; do
    : > "$list_file"
    lr_collect_logs "$path" "$list_file"
    if [[ -s "$list_file" ]]; then
      archive="$(lr_archive_path "$path")"
      uk_note "Archive candidate from $path -> $archive"
      sed "s#^#  - $path/#" "$list_file"
      if (( LR_APPLY == 1 )); then
        tar -czf "$archive" -C "$path" -T "$list_file"
        while IFS= read -r old_log; do rm -f "$path/$old_log"; done < "$list_file"
        archived=$((archived + 1))
        uk_success "Created $archive"
      fi
    else
      uk_note "No logs older than $LR_ARCHIVE_AFTER day(s) in $path"
    fi
  done

  uk_note "Purge preview for archives older than $LR_PURGE_AFTER day(s):"
  find "$LR_ARCHIVE_DIR" -type f -name '*.tar.gz' -mtime +"$LR_PURGE_AFTER" -print 2>/dev/null | sed 's/^/  - /' || true
  if (( LR_APPLY == 1 )); then
    while IFS= read -r stale; do
      [[ -n "$stale" ]] || continue
      rm -f "$stale"
      removed=$((removed + 1))
    done < <(find "$LR_ARCHIVE_DIR" -type f -name '*.tar.gz' -mtime +"$LR_PURGE_AFTER" -print 2>/dev/null)
    uk_success "Archived $archived set(s), purged $removed stale archive(s)."
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  lr_main "$@"
fi
