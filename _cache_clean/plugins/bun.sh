#!/usr/bin/env bash
# plugins/bun.sh — Bun install cache plugin for cacheclean

bun_plugin_info() {
  printf 'bun|bun|🥯\n'
}
bun_detect() {
  command -v bun >/dev/null 2>&1
}
bun_get_cache_dirs() {
  printf '%s\n' "$HOME/.bun/install/cache"
}
bun_scan_cache() {
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
      cc_emit_orphan "$dir" "$f" "bun cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done < <(bun_get_cache_dirs)
}
bun_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
