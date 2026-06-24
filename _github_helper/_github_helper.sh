#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
  source "$SCRIPT_DIR/../lib/uk_common.sh"
fi

# --- Fallback Functions if not defined in uk_common.sh ---
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "Error: %s\n" "$*"; }; fi
if ! declare -f uk_has_cmd >/dev/null 2>&1; then uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }; fi

ghh_usage() {
  cat <<USAGE
Usage:
  _github_helper.sh [ACTION]

Actions:
  --status    Check GitHub auth status.
  --prs       List pull requests.
  --issues    List issues.
  --runs      List workflow runs.
  -h, --help  Show this help.
USAGE
}

ghh_main() {
  local action='status'

  # Argument Parsing
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --status) action='status' ;;
    --prs) action='prs' ;;
    --issues) action='issues' ;;
    --runs) action='runs' ;;
    -h | --help)
      ghh_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: $1"
      ghh_usage
      return 1
      ;;
    esac
    shift
  done

  # Dependency Validation
  if ! uk_has_cmd gh; then
    uk_error 'The GitHub CLI (gh) is required but not found.'
    return 1
  fi

  # Action Dispatcher
  case "$action" in
  status) gh auth status ;;
  prs) gh pr list ;;
  issues) gh issue list ;;
  runs) gh run list ;;
  *)
    uk_error "Internal error: invalid action '$action'"
    return 1
    ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  # Integration with main entry point if it exists
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" github
  else
    ghh_main "$@"
  fi
fi
