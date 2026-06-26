#!/usr/bin/env bash
# plugins/dnf.sh — DNF/YUM RPM cache plugin for cacheclean

dnf_plugin_info() {
  printf 'dnf|dnf|🎩\n'
}
dnf_detect() {
  command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1
}
dnf_get_cache_dirs() {
  printf '%s\n' "/var/cache/dnf"
  printf '%s\n' "/var/cache/yum"
  if [ "$CC_OS" = "termux" ] && [ -n "${PREFIX:-}" ]; then
    printf '%s\n' "$PREFIX/var/cache/dnf"
    printf '%s\n' "$PREFIX/var/cache/yum"
  fi
}
dnf_scan_cache() {
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
      cc_emit_orphan "$dir" "$f" "rpm cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty download"
    done < <(cc_find_partial "$dir")
  done < <(dnf_get_cache_dirs)
}
dnf_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
