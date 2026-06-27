#!/usr/bin/env bash
# plugins/vcpkg.sh — vcpkg download cache plugin for cacheclean

vcpkg_plugin_info() {
  printf 'vcpkg|vcpkg|🎒\n'
}
vcpkg_detect() {
  command -v vcpkg >/dev/null 2>&1
}
vcpkg_get_cache_dirs() {
  if [ -n "${VCPKG_ROOT:-}" ]; then
    printf '%s\n' "$VCPKG_ROOT/downloads"
  fi
  # Common user clone location
  printf '%s\n' "$HOME/.vcpkg/downloads"
}
vcpkg_scan_cache() {
  local dir
  mapfile -t dir_list < <(vcpkg_get_cache_dirs)
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
      cc_emit_orphan "$dir" "$f" "vcpkg download older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done
}
vcpkg_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
