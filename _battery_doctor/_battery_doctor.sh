#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
# Usage
bd_usage() {
  cat <<'USAGE'
Usage: _battery_doctor.sh [OPTIONS]

Display battery status (if available) and top CPU/memory‑consuming processes.

Options:
  -h, --help    Show this help message and exit.

Backends tried (in order):
  - termux-battery-status (Termux/Android)
  - pmset -g batt          (macOS)
  - acpi -V                (Linux with ACPI)
USAGE
}
# Show battery information using the first available backend
bd_show_battery() {
  if uk_has_cmd termux-battery-status; then
    termux-battery-status
    return 0
  elif uk_has_cmd pmset; then
    pmset -g batt
    return 0
  elif uk_has_cmd acpi; then
    acpi -V
    return 0
  else
    uk_warn 'No battery backend found (termux-battery-status, pmset, or acpi).'
    return 1
  fi
}
# Show top CPU/memory processes (with a fallback if ps fails)
bd_show_top_processes() {
  local ps_cmd
  # Try different ps syntaxes – we keep it simple for Linux/macOS
  if ps -eo pid,comm,%cpu,%mem 2>/dev/null | head -1 >/dev/null; then
    ps_cmd="ps -eo pid,comm,%cpu,%mem"
  elif ps -eo pid,command,%cpu,%mem 2>/dev/null | head -1 >/dev/null; then
    ps_cmd="ps -eo pid,command,%cpu,%mem"
  else
    uk_warn 'Cannot retrieve process list with ps.'
    return 1
  fi

  printf '\n%sTop CPU & Memory Processes%s\n' "${UK_C_BOLD:-}" "${UK_C_RESET:-}"
  printf '%s\n' "----------------------------------------"
  $ps_cmd 2>/dev/null | sort -k3 -rn | head -10 || true
}
# Main
bd_main() {
  uk_banner "battery-doctor" "Battery status and top CPU/memory processes" "" "$@"
  # Handle help
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    bd_usage
    return 0
  fi
  # Battery info
  if ! bd_show_battery; then
    uk_warn 'Battery status unavailable; continuing with process summary.'
  fi
  # Top processes (always show)
  bd_show_top_processes

  return 0
}
# Entry point
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  bd_main "$@"
fi

