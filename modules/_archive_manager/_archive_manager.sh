#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"
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
  local archive="${1:-}"
  uk_has_cmd python3 || { uk_error 'python3 is required for safe archive validation.'; return 1; }
  python3 - "$archive" <<'PY'
import os, stat, sys, tarfile, zipfile
from pathlib import PurePosixPath

archive = sys.argv[1]
unsafe = []
def bad_name(name):
    p = PurePosixPath(name.replace('\\', '/'))
    return p.is_absolute() or '..' in p.parts or '\x00' in name
try:
    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as z:
            for info in z.infolist():
                if bad_name(info.filename):
                    unsafe.append(info.filename)
                mode = (info.external_attr >> 16) & 0o170000
                if mode and mode not in (stat.S_IFREG, stat.S_IFDIR):
                    unsafe.append(f'{info.filename} (special/link entry)')
    else:
        with tarfile.open(archive) as t:
            for member in t.getmembers():
                if bad_name(member.name):
                    unsafe.append(member.name)
                if member.issym() or member.islnk() or member.isdev() or member.isfifo():
                    unsafe.append(f'{member.name} (special/link entry)')
except Exception as e:
    print(f'archive validation failed: {e}')
    sys.exit(1)
if unsafe:
    print('\n'.join(dict.fromkeys(unsafe)))
    sys.exit(1)
PY
}
am_extract_safe() {
  local archive="${1:-}" dest="${2:-}"
  python3 - "$archive" "$dest" <<'PY'
import os, sys, tarfile, zipfile
archive, dest = sys.argv[1], sys.argv[2]
os.makedirs(dest, exist_ok=True)
if zipfile.is_zipfile(archive):
    with zipfile.ZipFile(archive) as z:
        z.extractall(dest)
else:
    with tarfile.open(archive) as t:
        try:
            t.extractall(dest, filter='data')
        except TypeError:
            t.extractall(dest)
PY
}
am_main() {
  uk_banner "archive-manager" "List, extract, and create tar.gz / zip archives safely" "" "$@"
  local action='' archive='' dest='.' out='' paths=()
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
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
    *) paths+=("${1:-}") ;;
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
    if bad_paths="$(am_check_archive_paths "$archive")" && [[ -z "$bad_paths" ]]; then
      mkdir -p "$dest" || return 1
      am_extract_safe "$archive" "$dest" || { uk_error 'Archive extraction failed.'; return 1; }
    else
      # Only fabricate an "unsafe paths" message when the validator actually
      # reported member names; a dependency/exception failure prints its own
      # error and leaves bad_paths empty.
      if [[ -n "$bad_paths" ]]; then
        uk_error "Archive contains unsafe paths; refusing extraction:"
        printf '%s\n' "$bad_paths" >&2
      fi
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
