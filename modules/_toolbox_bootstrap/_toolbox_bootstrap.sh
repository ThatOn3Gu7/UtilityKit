#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"
tb_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf 'Usage: _toolbox_bootstrap.sh\n\n'
  uk_help_section "$w" "Options" \
    "-h, --help" "Show this help."
}
tb_main() {
  uk_banner "toolbox-bootstrap" "Audit recommended CLI tools (fzf, rg, fd, bat, jq…)" "" "$@"
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in -h | --help)
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
