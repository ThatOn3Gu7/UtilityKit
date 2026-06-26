#!/usr/bin/env bash
# plugins/go.sh — Go module cache plugin for cacheclean

go_plugin_info() {
  printf 'go|go|🐹\n'
}
go_detect() {
  command -v go >/dev/null 2>&1
}
go_get_cache_dirs() {
  local gopath
  gopath="${GOPATH:-$HOME/go}"
  # GOPATH can be a list; take the first entry.
  gopath="${gopath%%:*}"
  printf '%s\n' "$gopath/pkg/mod/cache"
  if [ -n "${GOCACHE:-}" ]; then
    printf '%s\n' "$GOCACHE"
  fi
}
go_scan_cache() {
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
      cc_emit_orphan "$dir" "$f" "go module cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done < <(go_get_cache_dirs)
}
go_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
