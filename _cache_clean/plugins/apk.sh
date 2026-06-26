#!/usr/bin/env bash
# plugins/apk.sh — Alpine APK cache plugin for cacheclean

apk_plugin_info() {
  printf 'apk|apk|🏔️\n'
}
apk_detect() {
  command -v apk >/dev/null 2>&1
}
apk_get_cache_dirs() {
  printf '%s\n' "/var/cache/apk"
}
apk_scan_cache() {
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
      cc_emit_orphan "$dir" "$f" "apk package older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty download"
    done < <(cc_find_partial "$dir")
  done < <(apk_get_cache_dirs)
}
apk_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
