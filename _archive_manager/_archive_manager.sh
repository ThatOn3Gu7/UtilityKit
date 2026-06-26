#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
am_usage() {
  cat <<'USAGE'
Usage:
  _archive_manager.sh --list ARCHIVE
  _archive_manager.sh --extract ARCHIVE --dest DIR
  _archive_manager.sh --create OUT.tar.gz PATH...
  _archive_manager.sh --create OUT.zip PATH...
USAGE
}
am_check_archive_paths() {
  local archive="$1" entries
  case "$archive" in
  *.zip) entries="$(unzip -Z1 "$archive" 2>/dev/null || unzip -l "$archive" 2>/dev/null | awk 'NR>3{print $4}')" ;;
  *) entries="$(tar -tf "$archive")" ;;
  esac
  printf '%s\n' "$entries" | awk 'length($0) && ($0 ~ /^\// || $0 ~ /^\.\.\// || $0 ~ /\.\.\//) {print; bad=1} END{exit bad?1:0}'
}
am_main() {
  local action='' archive='' dest='.' out='' paths=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --list)
      action=list
      shift
      archive="${1:-}"
      ;;
    --extract)
      action=extract
      shift
      archive="${1:-}"
      ;;
    --dest)
      shift
      dest="${1:-.}"
      ;;
    --create)
      action=create
      shift
      out="${1:-}"
      ;;
    -h | --help)
      am_usage
      return 0
      ;;
    *) paths+=("$1") ;;
    esac
    shift
  done

  case "$action" in
  list)
    [[ -f "$archive" ]] || {
      uk_error "Archive not found: $archive"
      return 1
    }
    case "$archive" in
    *.zip)
      uk_has_cmd unzip || {
        uk_error 'unzip is required for zip archives.'
        return 1
      }
      unzip -l "$archive"
      ;;
    *) tar -tf "$archive" ;;
    esac
    ;;
  extract)
    [[ -f "$archive" ]] || {
      uk_error "Archive not found: $archive"
      return 1
    }
    uk_note 'Previewing archive paths for unsafe absolute/parent traversal entries...'
    if [[ "$archive" == *.zip ]]; then
      uk_has_cmd unzip || {
        uk_error 'unzip is required for zip archives.'
        return 1
      }
    fi
    if bad_paths="$(am_check_archive_paths "$archive")" && [[ -z "$bad_paths" ]]; then
      mkdir -p "$dest"
      case "$archive" in
      *.zip)
        uk_has_cmd unzip || {
          uk_error 'unzip is required for zip archives.'
          return 1
        }
        unzip "$archive" -d "$dest"
        ;;
      *) tar -xvf "$archive" -C "$dest" ;;
      esac
    else
      uk_error "Archive contains unsafe paths; refusing extraction:"
      printf '%s\n' "$bad_paths" >&2
      return 1
    fi
    ;;
  create)
    [[ -n "$out" && ${#paths[@]} -gt 0 ]] || {
      am_usage
      return 1
    }
    case "$out" in
    *.zip)
      uk_has_cmd zip || {
        uk_error 'zip is required to create zip archives.'
        return 1
      }
      zip -r "$out" "${paths[@]}"
      ;;
    *) tar -czf "$out" "${paths[@]}" ;;
    esac
    uk_success "Created $out"
    ;;
  *)
    am_usage
    return 1
    ;;
  esac
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  am_main "$@"
fi
