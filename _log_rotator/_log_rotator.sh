#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

lr_usage(){ echo 'Usage: _log_rotator.sh --path DIR --older-than DAYS --archive-dir DIR [--apply]'; }

lr_main(){
  local path='.' older=7 archive_dir='' apply=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path) shift; path="${1:-.}" ;;
      --older-than) shift; older="${1:-7}" ;;
      --archive-dir) shift; archive_dir="${1:-}" ;;
      --apply) apply=1 ;;
      -h|--help) lr_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done
  [[ -d "$path" ]] || { uk_error "Log path not found: $path"; return 1; }
  [[ "$older" =~ ^[0-9]+$ ]] || { uk_error '--older-than must be a non-negative integer.'; return 1; }
  archive_dir="${archive_dir:-$path/archives}"
  mkdir -p -- "$archive_dir"
  local archive="$archive_dir/logs_$(uk_stamp).tar.gz"
  local tmp
  tmp="$(mktemp)" || return 1
  trap 'rm -f "$tmp"' RETURN
  find "$path" -type f -name '*.log' -mtime +"$older" -print > "$tmp"
  if [[ ! -s "$tmp" ]]; then
    uk_note 'No old log files found.'
    return 0
  fi
  if (( apply == 1 )); then
    tar -czf "$archive" -T "$tmp"
    while IFS= read -r f; do rm -f -- "$f"; done < "$tmp"
    uk_success "Archived old logs to $archive"
  else
    uk_note 'Dry-run: matching logs:'
    cat "$tmp"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  lr_main "$@"
fi
