#!/usr/bin/env bash
# plugins/apt.sh — APT/DEB cache plugin for cacheclean

apt_plugin_info() {
  printf 'apt|apt|🐚\n'
}

apt_detect() {
  command -v apt >/dev/null 2>&1 || command -v apt-get >/dev/null 2>&1
}

apt_get_cache_dirs() {
  if [ "$CC_OS" = "termux" ] && [ -n "${PREFIX:-}" ]; then
    printf '%s\n' "$PREFIX/var/cache/apt/archives"
  fi
  printf '%s\n' "/var/cache/apt/archives"
}

apt_scan_cache() {
  local dir
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    if [ ! -d "$dir" ]; then
      cc_emit_err "$dir" "directory not found (may need root)"
      continue
    fi

    local total_kb
    total_kb=$(cc_du_kb "$dir")
    cc_emit_tot "$dir" "$total_kb"

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      case "$f" in
        */lock|*/lock-frontend|*/partial/*) continue ;;
      esac
      cc_emit_orphan "$dir" "$f" "apt package archive older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      case "$f" in
        */lock|*/lock-frontend|*/partial/*) continue ;;
      esac
      cc_emit_orphan "$dir" "$f" "partial or empty download"
    done < <(cc_find_partial "$dir")
  done < <(apt_get_cache_dirs)
}

apt_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
