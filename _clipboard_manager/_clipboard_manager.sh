#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

cb_usage(){ echo 'Usage: _clipboard_manager.sh --copy TEXT | --paste'; }
cb_main(){
  local action='' text=''
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --copy) action=copy; shift; text="${1:-}" ;;
      --paste) action=paste ;;
      -h|--help) cb_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done
  case "$action" in
    copy) uk_copy_to_clipboard "$text" || { uk_warn 'No supported clipboard command found.'; return 1; } ;;
    paste)
      if uk_has_cmd pbpaste; then pbpaste
      elif uk_has_cmd xclip; then xclip -selection clipboard -o
      elif uk_has_cmd wl-paste; then wl-paste
      elif uk_has_cmd termux-clipboard-get; then termux-clipboard-get
      else uk_warn 'No supported clipboard paste command found.'; return 1; fi ;;
    *) cb_usage; return 0 ;;
  esac
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  cb_main "$@"
fi
