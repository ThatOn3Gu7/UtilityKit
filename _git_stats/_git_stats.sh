#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
gst_usage(){ echo 'Usage: _git_stats.sh [--repo DIR] [--since DATE] [--until DATE] [--author PATTERN]'; }
gst_main(){ local repo='.' since='' until='' author='' args=(); while [[ $# -gt 0 ]]; do case "$1" in --repo) shift; repo="${1:-.}";; --since) shift; since="${1:-}";; --until) shift; until="${1:-}";; --author) shift; author="${1:-}";; -h|--help) gst_usage; return 0;; esac; shift; done; git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { uk_error "Not a git repository: $repo"; return 1; }; [[ -n "$since" ]] && args+=(--since="$since"); [[ -n "$until" ]] && args+=(--until="$until"); [[ -n "$author" ]] && args+=(--author="$author"); uk_header 'UtilityKit Git Stats' "repo: $(uk_abs_path "$repo")"; uk_section_title 'Commits by author'; git -C "$repo" shortlog -sn HEAD "${args[@]}" 2>/dev/null | sed 's/^/  /' || true; uk_section_title 'Most changed files'; git -C "$repo" log --name-only --pretty=format: "${args[@]}" | sed '/^$/d' | sort | uniq -c | sort -rn | head -15 | sed 's/^/  /' || true; uk_section_title 'Branches by activity'; git -C "$repo" for-each-ref --sort=-committerdate --format='  %(committerdate:short) %(refname:short)' refs/heads refs/remotes | head -20; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" git-stats
  else
    gst_main "$@"
  fi
fi
