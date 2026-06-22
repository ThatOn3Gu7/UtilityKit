#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
bd_usage(){ echo 'Usage: _battery_doctor.sh'; }
bd_main(){ [[ ${1:-} == -h || ${1:-} == --help ]] && { bd_usage; return 0; }; uk_has_cmd termux-battery-status && termux-battery-status || uk_has_cmd pmset && pmset -g batt || uk_has_cmd acpi && acpi -V || uk_warn 'No battery backend available.'; ps -eo pid,comm,%cpu,%mem 2>/dev/null | sort -k3 -rn | head || true; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" battery
  else
    bd_main "$@"
  fi
fi
