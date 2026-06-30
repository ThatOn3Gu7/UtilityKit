#!/usr/bin/env bash
# plugins/cargo.sh — Cargo (Rust) cache cleaning plugin for cacheclean

cargo_plugin_info() {
  printf 'cargo|cargo|🦀\n'
}
cargo_detect() {
  command -v cargo >/dev/null 2>&1
}
cargo_get_cache_dirs() {
  local cargo_home="${CARGO_HOME:-$HOME/.cargo}"
  printf '%s\n' "$cargo_home/registry/cache"
}
cargo_scan_cache() {
  local dir
  mapfile -t dir_list < <(cargo_get_cache_dirs)
  for dir in "${dir_list[@]}"; do
    [ -z "$dir" ] && continue
    if [ ! -d "$dir" ]; then
      cc_emit_err "$dir" "directory not found"
      continue
    fi

    local total_kb
    total_kb=$(cc_du_kb "$dir")
    cc_emit_tot "$dir" "$total_kb"

    # Old .crate tarballs. Cargo re-downloads them from crates.io as needed.
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "stale .crate older than ${CC_OLDER_THAN} days"
    done < <(find "$dir" -type f -name '*.crate' -mtime +"$CC_OLDER_THAN" 2>/dev/null)

    # Partial / empty / temporary files.
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")

  done
}
cargo_clean_orphans() {
  cc_clean_orphans_from_file "${1:-}"
}
