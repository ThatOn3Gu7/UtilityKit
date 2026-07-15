#!/usr/bin/env bash
# plugins/pnpm.sh — pnpm store/cache plugin for cacheclean

pnpm_plugin_info() {
  printf 'pnpm|pnpm|🅿️\n'
}
pnpm_detect() {
  command -v pnpm >/dev/null
}
pnpm_get_cache_dirs() {
  printf '%s\n' "$HOME/.pnpm-store"
  if [ -n "${XDG_CACHE_HOME:-}" ]; then
    printf '%s\n' "$XDG_CACHE_HOME/pnpm"
  else
    printf '%s\n' "$HOME/.cache/pnpm"
  fi
}
pnpm_scan_cache() {
  local dir
  mapfile -t dir_list < <(pnpm_get_cache_dirs)
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
      cc_emit_orphan "$dir" "$f" "pnpm store cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done
}
pnpm_clean_orphans() {
  cc_clean_orphans_from_file "${1:-}"
}
