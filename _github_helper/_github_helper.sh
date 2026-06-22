#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
ghh_usage(){ echo 'Usage: _github_helper.sh --status|--prs|--issues|--runs'; }
ghh_main(){ local action=status; while [[ $# -gt 0 ]]; do case "$1" in --status) action=status;; --prs) action=prs;; --issues) action=issues;; --runs) action=runs;; -h|--help) ghh_usage; return 0;; esac; shift; done; uk_has_cmd gh || { uk_error 'gh is required.'; return 1; }; case "$action" in status) gh auth status;; prs) gh pr list;; issues) gh issue list;; runs) gh run list;; esac; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" github
  else
    ghh_main "$@"
  fi
fi
