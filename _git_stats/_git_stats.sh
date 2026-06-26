#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
  source "$SCRIPT_DIR/../lib/uk_common.sh"
fi
# --- Fallback Functions if not defined in uk_common.sh ---
if ! declare -f uk_abs_path >/dev/null 2>&1; then
  uk_abs_path() {
    if command -v realpath >/dev/null; then
      realpath "${1:-.}"
    else
      local dir file
      dir="$(cd "$(dirname "${1:-.}")" && pwd -P)"
      file="$(basename "${1:-.}")"
      printf '%s/%s\n' "$dir" "$file"
    fi
  }
fi
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "Error: %s\n" "$*"; }; fi
if ! declare -f uk_header >/dev/null 2>&1; then uk_header() { printf "\n=== %s ===\n%s\n" "$1" "$2"; }; fi
if ! declare -f uk_section_title >/dev/null 2>&1; then uk_section_title() { printf "\n--- %s ---\n" "$*"; }; fi
gst_usage() {
  echo 'Usage: _git_stats.sh [--repo DIR] [--since DATE] [--until DATE] [--author PATTERN]'
}
gst_main() {
  local repo='.'
  local since=''
  local until=''
  local author=''
  local args=()

  # Safely parse arguments to prevent trailing shift and unbound variable errors
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --repo)
      if [[ $# -gt 1 ]]; then
        shift
        repo="${1:-.}"
        shift
      else
        uk_error "Option --repo requires an argument."
        gst_usage
        return 1
      fi
      ;;
    --since)
      if [[ $# -gt 1 ]]; then
        shift
        since="${1:-}"
        shift
      else
        uk_error "Option --since requires an argument."
        gst_usage
        return 1
      fi
      ;;
    --until)
      if [[ $# -gt 1 ]]; then
        shift
        until="${1:-}"
        shift
      else
        uk_error "Option --until requires an argument."
        gst_usage
        return 1
      fi
      ;;
    --author)
      if [[ $# -gt 1 ]]; then
        shift
        author="${1:-}"
        shift
      else
        uk_error "Option --author requires an argument."
        gst_usage
        return 1
      fi
      ;;
    -h | --help)
      gst_usage
      return 0
      ;;
    *)
      # Safely skip/shift unknown arguments
      shift
      ;;
    esac
  done
  # Validate that the target is a git repository
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    uk_error "Not a git repository: $repo"
    return 1
  }
  # Build the argument array dynamically
  [[ -n "$since" ]] && args+=(--since="$since")
  [[ -n "$until" ]] && args+=(--until="$until")
  [[ -n "$author" ]] && args+=(--author="$author")
  uk_header 'UtilityKit Git Stats' "repo: $(uk_abs_path "$repo")"
  # Commits by author
  uk_section_title 'Commits by author'
  # Safe array expansion ${args[@]+"${args[@]}"} prevents unbound errors on empty arrays in older bash versions
  git -C "$repo" shortlog -sn HEAD ${args[@]+"${args[@]}"} 2>/dev/null | sed 's/^/  /' || true
  # Most changed files
  uk_section_title 'Most changed files'
  git -C "$repo" log --name-only --pretty=format: ${args[@]+"${args[@]}"} 2>/dev/null | sed '/^$/d' | sort | uniq -c | sort -rn | head -n 15 | sed 's/^/  /' || true
  # Branches by activity (guarded with || true to prevent SIGPIPE crash on long branch lists under pipefail)
  uk_section_title 'Branches by activity'
  git -C "$repo" for-each-ref --sort=-committerdate --format='  %(committerdate:short) %(refname:short)' refs/heads refs/remotes 2>/dev/null | head -n 20 || true
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  gst_main "$@"
fi
