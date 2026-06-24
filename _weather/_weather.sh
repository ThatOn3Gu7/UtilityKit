#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
wt_usage(){ echo 'Usage: _weather.sh [LOCATION] [--units metric|imperial]'; }
wt_main(){ local loc='' units='metric'; while [[ $# -gt 0 ]]; do case "$1" in --units) shift; units="${1:-metric}";; -h|--help) wt_usage; return 0;; *) loc="$1";; esac; shift; done; local cache="$(uk_state_dir)/weather_last.txt" u=m encoded_loc; [[ "$units" == imperial ]] && u=u; uk_has_cmd curl || { uk_warn 'curl unavailable; cache only.'; [[ -f "$cache" ]] && cat "$cache"; return 0; }; encoded_loc="$(printf '%s' "$loc" | sed 's/ /+/g')"; curl -fsS --max-time 8 "https://wttr.in/${encoded_loc}?format=3&${u}" | tee "$cache" || { uk_warn 'Weather lookup failed.'; [[ -f "$cache" ]] && cat "$cache"; }; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" weather
  else
    wt_main "$@"
  fi
fi
