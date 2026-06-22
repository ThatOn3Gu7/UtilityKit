#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
cm_usage(){ echo "Usage: _cron_manager.sh --list | --add '*/5 * * * * cmd' [--apply] | --remove N [--apply]"; }
cm_have(){ uk_has_cmd crontab || { uk_error 'crontab unavailable. On Termux install cronie if you need cron.'; return 1; }; }
cm_main(){ local action=list line='' num='' apply=0; while [[ $# -gt 0 ]]; do case "$1" in --list) action=list;; --add) action=add; shift; line="${1:-}";; --remove) action=remove; shift; num="${1:-}";; --apply) apply=1;; -h|--help) cm_usage; return 0;; esac; shift; done; cm_have || return 1; local tmp; tmp=$(mktemp); crontab -l > "$tmp" 2>/dev/null || true; case "$action" in list) nl -ba "$tmp";; add) [[ "$line" =~ ^([^[:space:]]+[[:space:]]+){5}.+ ]] || { uk_error 'Expected five cron fields plus command.'; return 1; }; echo "$line" >> "$tmp"; (( apply==1 )) && { crontab "$tmp"; uk_success 'Crontab updated.'; } || { uk_note 'Dry-run crontab:'; cat "$tmp"; };; remove) awk -v n="$num" 'NR!=n' "$tmp" > "$tmp.new"; (( apply==1 )) && { crontab "$tmp.new"; uk_success 'Crontab updated.'; } || cat "$tmp.new";; esac; rm -f "$tmp" "$tmp.new"; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" cron
  else
    cm_main "$@"
  fi
fi
