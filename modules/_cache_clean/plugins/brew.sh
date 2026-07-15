#!/usr/bin/env bash
# plugins/brew.sh — Homebrew cache plugin for cacheclean

brew_plugin_info() {
  printf 'brew|brew|🍺\n'
}
brew_detect() {
  command -v brew >/dev/null
}
brew_get_cache_dirs() {
  if [ "$CC_OS" = "macos" ]; then
    printf '%s\n' "$HOME/Library/Caches/Homebrew"
    printf '%s\n' "$HOME/Library/Caches/Homebrew/downloads"
  else
    printf '%s\n' "$HOME/.cache/Homebrew"
    printf '%s\n' "/home/linuxbrew/.cache/Homebrew"
  fi
}
brew_scan_cache() {
  local dir
  mapfile -t dir_list < <(brew_get_cache_dirs)
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
      cc_emit_orphan "$dir" "$f" "homebrew cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty download"
    done < <(cc_find_partial "$dir")
  done
}
brew_clean_orphans() {
  cc_clean_orphans_from_file "${1:-}"
}
