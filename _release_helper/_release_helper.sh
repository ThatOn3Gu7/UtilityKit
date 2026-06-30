#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
rel_usage() { echo 'Usage: _release_helper.sh [--repo DIR] [--tag vX.Y.Z] [--apply]'; }
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
  git -C "$repo" status --short
  git -C "$repo" log --oneline -5
  if [[ -n "$tag" ]]; then if ((apply == 1)); then git -C "$repo" tag "$tag"; else uk_note "Would create tag $tag. Use --apply to create it."; fi; fi
  return 0
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  rel_main "$@"
fi
