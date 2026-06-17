#!/usr/bin/env bash
# plugins/pip.sh — pip/pip3 cache cleaning plugin for cacheclean

pip_plugin_info() {
  printf 'pip|pip|🐍\n'
}

pip_detect() {
  command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1
}

pip_get_cache_dirs() {
  local dirs=""
  if [ -n "${XDG_CACHE_HOME:-}" ]; then
    dirs="$XDG_CACHE_HOME/pip"
  else
    dirs="$HOME/.cache/pip"
  fi
  # macOS default (appdirs / platformdirs) when XDG_CACHE_HOME is not set.
  if [ "$CC_OS" = "macos" ]; then
    dirs="$dirs"$'\n'"$HOME/Library/Caches/pip"
  fi
  printf '%s\n' "$dirs"
}

pip_scan_cache() {
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

    # Old built wheels (most of pip's on-disk cache size).
    if [ -d "$dir/wheels" ]; then
      while IFS= read -r f; do
        [ -z "$f" ] && continue
        cc_emit_orphan "$dir" "$f" "old pip wheel cache"
      done < <(cc_find_old "$dir/wheels" "$CC_OLDER_THAN")
    fi

    # Old HTTP cache metadata / responses.
    if [ -d "$dir/http" ]; then
      while IFS= read -r f; do
        [ -z "$f" ] && continue
        cc_emit_orphan "$dir" "$f" "stale pip HTTP cache entry"
      done < <(cc_find_old "$dir/http" "$CC_OLDER_THAN")
    fi

    # Partial / empty / temporary files anywhere in the cache tree.
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "partial or empty file"
    done < <(cc_find_partial "$dir")

  done < <(pip_get_cache_dirs)
}

pip_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
