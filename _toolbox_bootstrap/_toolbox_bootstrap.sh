#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
tb_usage() { echo 'Usage: _toolbox_bootstrap.sh'; }
tb_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in -h | --help)
      tb_usage
      return 0
      ;;
    esac
    shift
  done
  for c in fzf rg fd bat eza jq curl git tmux gh zoxide tldr; do uk_has_cmd "$c" && echo "[OK] $c" || echo "[MISSING] $c"; done
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  tb_main "$@"
fi
