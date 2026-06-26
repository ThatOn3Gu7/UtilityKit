#!/usr/bin/env bash
# plugins/conan.sh — Conan C/C++ package cache plugin for cacheclean

conan_plugin_info() {
  printf 'conan|conan|🐕\n'
}
conan_detect() {
  command -v conan >/dev/null 2>&1
}
conan_get_cache_dirs() {
  printf '%s\n' "$HOME/.conan/data"
  printf '%s\n' "$HOME/.conan2/p"
}
conan_scan_cache() {
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
      cc_emit_orphan "$dir" "$f" "conan cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done < <(conan_get_cache_dirs)
}
conan_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
