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

  if [[ ${#LR_PATHS[@]} -eq 0 && -t 0 && -t 1 ]]; then
    uk_header 'UtilityKit Log Rotator' 'Archive old logs and purge stale archives'
    local input_path
    input_path="$(uk_prompt \
      'Enter a log directory to scan' \
      './logs' \
      '/var/log  |  ~/.pm2/logs  |  ~/project/logs' \
      'The tool will find files older than your threshold and archive them.')"
    LR_PATHS+=("$input_path")

    LR_ARCHIVE_AFTER="$(uk_prompt \
      'Archive logs older than how many days?' \
      '7' \
      '7  →  weekly cleanup  |  30  →  monthly  |  1  →  aggressive' \
      'Files older than this threshold get packaged into a tar.gz archive.')"

    LR_PURGE_AFTER="$(uk_prompt \
      'Purge old archive files after how many days?' \
      '30' \
      '30  →  keep one month  |  90  →  keep a quarter  |  7  →  aggressive' \
      'Archive files older than this threshold are permanently deleted.')"

    LR_ARCHIVE_DIR="$(uk_prompt \
      'Enter output directory for archive files (leave blank for default)' \
      '' \
      '~/log-archives  |  /tmp/archives  |  leave blank for UtilityKit state dir' \
      'Compressed archives will be written here. The directory is created if needed.')"

    if uk_confirm 'Apply archiving and purging now? (dry-run if you say no)' 'N'; then
      LR_APPLY=1
    fi
  elif [[ ${#LR_PATHS[@]} -eq 0 ]]; then
    uk_error 'No log directories found. Use --path.'
    return 1
  fi

  LR_ARCHIVE_DIR=${LR_ARCHIVE_DIR:-"$(uk_state_dir)/log_archives"}
  mkdir -p "$LR_ARCHIVE_DIR"

  uk_header 'UtilityKit Log Rotator' "Archive dir: $LR_ARCHIVE_DIR"
  local path list_file archive archived=0 removed=0
  list_file=$(mktemp)
  trap "rm -f '$list_file'" RETURN

  for path in "${LR_PATHS[@]}"; do
    : > "$list_file"
    lr_collect_logs "$path" "$list_file"

    printf '\n  %s%s%s\n' "$UK_C_BOLD" "$path" "$UK_C_RESET"
    printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"

    if [[ -s "$list_file" ]]; then
      archive="$(lr_archive_path "$path")"
      printf '  %sFiles older than %d day(s) — will be archived:%s\n' \
        "$UK_C_DIM" "$LR_ARCHIVE_AFTER" "$UK_C_RESET"
      sed "s#^#  $UK_C_CYAN•$UK_C_RESET $path/#" "$list_file"
      printf '  %sTarget archive:%s %s\n' "$UK_C_DIM" "$UK_C_RESET" "$archive"
      if (( LR_APPLY == 1 )); then
        tar -czf "$archive" -C "$path" -T "$list_file"
        while IFS= read -r old_log; do rm -f "$path/$old_log"; done < "$list_file"
        archived=$((archived + 1))
        uk_success "Created $archive"
      fi
    else
      printf '  %s(no logs older than %d day(s) found — nothing to archive)%s\n' \
        "$UK_C_DIM" "$LR_ARCHIVE_AFTER" "$UK_C_RESET"
    fi
  done

  printf '\n  %s%sPurge check%s — archives older than %d day(s):\n' \
    "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET" "$LR_PURGE_AFTER"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  local stale_list
  stale_list="$(find "$LR_ARCHIVE_DIR" -type f -name '*.tar.gz' -mtime +"$LR_PURGE_AFTER" -print 2>/dev/null || true)"
  if [[ -n "$stale_list" ]]; then
    printf '%s\n' "$stale_list" | sed "s/^/  $UK_C_DIM- /" | sed "s/$/$UK_C_RESET/"
  else
    printf '  %s(no stale archives found)%s\n' "$UK_C_DIM" "$UK_C_RESET"
  fi
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
