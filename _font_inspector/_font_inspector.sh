#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
fi_usage(){ echo 'Usage: _font_inspector.sh [--list] [--filter NAME] [--glyphs]'; }
fi_main(){ local list=0 filter='' glyphs=0; while [[ $# -gt 0 ]]; do case "$1" in --list) list=1;; --filter) shift; filter="${1:-}";; --glyphs) glyphs=1;; -h|--help) fi_usage; return 0;; esac; shift; done; (( glyphs==1 || list==0 )) && printf 'ASCII ABC 123\nBox ┌─┐ │ ╰─╯\nPowerline    \n'; if (( list==1 )); then if uk_has_cmd fc-list; then fc-list : family | sort -u | grep -i -- "$filter" | head || true; else uk_warn 'fc-list unavailable; cannot list fonts here.'; fi; fi; return 0; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" font
  else
    fi_main "$@"
  fi
fi
