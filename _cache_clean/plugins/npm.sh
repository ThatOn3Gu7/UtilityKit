#!/usr/bin/env bash
# plugins/npm.sh — npm cache cleaning plugin for cacheclean

npm_plugin_info() {
  printf 'npm|npm|🟩\n'
}
npm_detect() {
  command -v npm >/dev/null 2>&1
}
npm_get_cache_dirs() {
  local cache_dir
  if [ -n "${npm_config_cache:-}" ]; then
    cache_dir="$npm_config_cache"
  else
    cache_dir="$HOME/.npm"
  fi
  printf '%s\n' "$cache_dir"
}
npm_scan_cache() {
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

    # Old npm debug logs (npm i 2>&1 logs, etc.)
    if [ -d "$dir/_logs" ]; then
      while IFS= read -r f; do
        [ -z "$f" ] && continue
        cc_emit_orphan "$dir" "$f" "npm log older than ${CC_OLDER_THAN} days"
      done < <(cc_find_old "$dir/_logs" "$CC_OLDER_THAN")
    fi

    # Stale cacache entries. npm can rebuild these from the registry if needed.
    if [ -d "$dir/_cacache" ]; then
      while IFS= read -r f; do
        [ -z "$f" ] && continue
        cc_emit_orphan "$dir" "$f" "stale npm cacache entry"
      done < <(cc_find_old "$dir/_cacache" "$CC_OLDER_THAN")
    fi

    # Incomplete / temporary / zero-byte downloads.
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")

  done < <(npm_get_cache_dirs)
}
npm_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
