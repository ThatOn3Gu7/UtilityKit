#!/usr/bin/env bash
# plugins/gem.sh — RubyGems cache plugin for cacheclean

gem_plugin_info() {
  printf 'gem|gem|💎\n'
}
gem_detect() {
  command -v gem >/dev/null 2>&1
}
gem_get_cache_dirs() {
  if [ "$CC_OS" = "macos" ]; then
    printf '%s\n' "$HOME/Library/Caches/gem"
  fi
  printf '%s\n' "$HOME/.gem/caches"
  if [ -n "${XDG_CACHE_HOME:-}" ]; then
    printf '%s\n' "$XDG_CACHE_HOME/gem"
  else
    printf '%s\n' "$HOME/.cache/gem"
  fi
}
gem_scan_cache() {
  local dir
  while IFS= read -r dir; do
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
      cc_emit_orphan "$dir" "$f" "gem cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done < <(gem_get_cache_dirs)
}
gem_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
