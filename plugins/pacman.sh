#!/usr/bin/env bash
# plugins/pacman.sh — Pacman package cache plugin for cacheclean

pacman_plugin_info() {
  printf 'pacman|pacman|🐧\n'
}

pacman_detect() {
  command -v pacman >/dev/null 2>&1
}

pacman_get_cache_dirs() {
  if [ "$CC_OS" = "termux" ] && [ -n "${PREFIX:-}" ]; then
    printf '%s\n' "$PREFIX/var/cache/pacman/pkg"
  fi
  printf '%s\n' "/var/cache/pacman/pkg"
}

pacman_scan_cache() {
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
      cc_emit_orphan "$dir" "$f" "pacman package older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty download"
    done < <(cc_find_partial "$dir")
  done < <(pacman_get_cache_dirs)
}

pacman_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
