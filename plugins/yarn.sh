#!/usr/bin/env bash
# plugins/yarn.sh — Yarn cache plugin for cacheclean

yarn_plugin_info() {
  printf 'yarn|yarn|🧶\n'
}

yarn_detect() {
  command -v yarn >/dev/null 2>&1
}

yarn_get_cache_dirs() {
  local cache_dir
  if [ -n "${YARN_CACHE_FOLDER:-}" ]; then
    cache_dir="$YARN_CACHE_FOLDER"
  else
    cache_dir="$HOME/.yarn/cache"
  fi
  printf '%s\n' "$cache_dir"
}

yarn_scan_cache() {
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
      cc_emit_orphan "$dir" "$f" "yarn cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done < <(yarn_get_cache_dirs)
}

yarn_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
