#!/usr/bin/env bash
# plugins/composer.sh — PHP Composer cache plugin for cacheclean

composer_plugin_info() {
  printf 'composer|composer|🎼\n'
}
composer_detect() {
  command -v composer >/dev/null 2>&1
}
composer_get_cache_dirs() {
  if [ "$CC_OS" = "macos" ]; then
    printf '%s\n' "$HOME/Library/Caches/composer"
  fi
  printf '%s\n' "$HOME/.composer/cache"
  if [ -n "${XDG_CACHE_HOME:-}" ]; then
    printf '%s\n' "$XDG_CACHE_HOME/composer"
  else
    printf '%s\n' "$HOME/.cache/composer"
  fi
}
composer_scan_cache() {
  local dir
  mapfile -t dir_list < <(composer_get_cache_dirs)
  for dir in "${dir_list[@]}"; do
    [ -z "$dir" ] && continue
    if [ ! -d "$dir" ]; then
      cc_emit_err "$dir" "directory not found"
      continue
    fi

    local total_kb
    total_kb=$(cc_du_kb "$dir")
    cc_emit_tot "$dir" "$total_kb"

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "composer cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done
}
composer_clean_orphans() {
  cc_clean_orphans_from_file "${1:-}"
}
