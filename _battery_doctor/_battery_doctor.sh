#!/usr/bin/env bash
set -euo pipefail

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
  # Handle help
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    bd_usage
    return 0
  fi

  # Show a header (uses uk_header if available, else fallback)
  if declare -f uk_header >/dev/null 2>&1; then
    uk_header 'Battery Doctor' 'System power & process monitor'
  else
    printf '\n%sBattery Doctor%s\n' "${UK_C_BOLD:-}" "${UK_C_RESET:-}"
    printf '%s\n' "======================="
  fi

  # Battery info
  bd_show_battery || true   # continue even if no backend

  # Top processes (always show)
  bd_show_top_processes

  return 0
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" battery
  else
    bd_main "$@"
  fi
fi