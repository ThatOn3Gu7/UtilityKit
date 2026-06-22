#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
tms_usage(){ echo 'Usage: _tmux_session.sh --list|--new NAME|--attach NAME|--kill NAME'; }
tms_main(){ local action=list name=''; while [[ $# -gt 0 ]]; do case "$1" in --list) action=list;; --new) action=new; shift; name="${1:-}";; --attach) action=attach; shift; name="${1:-}";; --kill) action=kill; shift; name="${1:-}";; -h|--help) tms_usage; return 0;; esac; shift; done; uk_has_cmd tmux || { uk_error 'tmux not installed; on Termux: pkg install tmux'; return 1; }; case "$action" in list) tmux list-sessions 2>/dev/null || uk_note 'No sessions.';; new) tmux new-session -d -s "$name";; attach) exec tmux attach -t "$name";; kill) tmux kill-session -t "$name";; esac; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" tmux
  else
    tms_main "$@"
  fi
fi
