#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"
rel_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf 'Usage: _release_helper.sh [--repo DIR] [--tag vX.Y.Z] [--apply]\n\n'
  uk_help_section "$w" "Options" \
    "--repo DIR" "Git repository directory (default: .)" \
    "--tag vX.Y.Z" "Tag name to create" \
    "--apply" "Actually create the tag (dry-run without this)" \
    "-h, --help" "Show this help"
}
rel_main() {
  uk_banner "release-helper" "Git status, recent log, optional tag creation" "" "$@"
  local repo='.' tag='' apply=0
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in --repo)
      shift
      repo="${1:-.}"
      ;;
    --tag)
      shift
      tag="${1:-}"
      ;;
    --apply) apply=1 ;; -h | --help)
      rel_usage
      return 0
      ;;
    esac
    shift
  done
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null || { uk_error "Not a Git repository: $repo"; return 1; }
  git -C "$repo" status --short || return 1
  git -C "$repo" log --oneline -5 || return 1
  if [[ -n "$tag" ]]; then
    git check-ref-format "refs/tags/$tag" || { uk_error "Invalid tag name: $tag"; return 1; }
    if ((apply == 1)); then
      git -C "$repo" tag "$tag" || return 1
    else
      uk_note "Would create tag $tag. Use --apply to create it."
    fi
  fi
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  rel_main "$@"
fi
