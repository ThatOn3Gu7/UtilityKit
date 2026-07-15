#!/usr/bin/env bash
# plugins/dotnet.sh — .NET NuGet cache plugin for cacheclean

dotnet_plugin_info() {
  printf 'dotnet|dotnet|🔷\n'
}
dotnet_detect() {
  command -v dotnet >/dev/null
}
dotnet_get_cache_dirs() {
  printf '%s\n' "$HOME/.nuget/packages"
  printf '%s\n' "$HOME/.local/share/NuGet/http-cache"
  printf '%s\n' "$HOME/.local/share/NuGet/cache"
  # macOS NuGet cache path
  if [ "$CC_OS" = "macos" ]; then
    printf '%s\n' "$HOME/Library/Application Support/NuGet/http-cache"
  fi
}
dotnet_scan_cache() {
  local dir
  mapfile -t dir_list < <(dotnet_get_cache_dirs)
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
      cc_emit_orphan "$dir" "$f" "nuget cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")
  done
}
dotnet_clean_orphans() {
  cc_clean_orphans_from_file "${1:-}"
}
