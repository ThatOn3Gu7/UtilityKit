#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

dh_usage() {
  cat <<'USAGE'
Usage: _disk_health.sh [OPTIONS]

SMART disk health utility (requires smartctl, usually needs sudo).

Options:
  --list               List all available disks (smartctl --scan)
  --device DEV         Specify device (e.g., /dev/sda) to inspect
  --test-short         Start a short self‑test on the device (non‑destructive)
  -h, --help           Show this help

Without options, shows health and attributes for the first detected disk.
USAGE
}
dh_require_smartctl() {
  if ! uk_has_cmd smartctl; then
    uk_error 'smartctl is not installed. Please install smartmontools (pkg install smartmontools on Termux, but may not work).'
    return 1
  fi
  # Check if smartctl works (maybe permissions)
  if ! smartctl --version >/dev/null 2>&1; then
    uk_warn 'smartctl is installed but cannot be executed. Try running with sudo.'
    return 1
  fi
  return 0
}
dh_main() {
  uk_banner "disk-health" "SMART health and attribute report via smartctl" "" "$@"
  local dev='' action='show' test_short=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --list)
      action='list'
      dev='LIST'
      ;;
    --device)
      shift
      dev="${1:-}"
      ;;
    --test-short) test_short=1 ;;
    -h | --help)
      dh_usage
      return 0
      ;;
    --*)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    *) dev="${1:-}" ;;
    esac
    shift
  done

  # If no device and not list, try to auto‑detect
  if [[ -z "$dev" && "$action" != 'list' ]]; then
    # Try to get first non‑removable disk
    local detected
    detected=$(smartctl --scan 2>/dev/null | head -1 | awk '{print ${1:-}}')
    if [[ -n "$detected" ]]; then
      dev="$detected"
      uk_note "Auto‑detected device: $dev"
    else
      uk_error 'No devices found. Run with --list to see available devices.'
      return 1
    fi
  fi

  # Ensure smartctl is available
  dh_require_smartctl || return 1

  # Action: list
  if [[ "$action" == 'list' ]]; then
    uk_section_title 'Available devices'
    smartctl --scan 2>/dev/null || true
    return 0
  fi

  # Validate device
  if [[ -z "$dev" ]]; then
    uk_error 'No device specified. Use --device DEV or let auto‑detection work.'
    return 1
  fi
  if [[ ! -e "$dev" ]]; then
    uk_error "Device '$dev' does not exist."
    return 1
  fi

  # Run short test if requested
  if ((test_short == 1)); then
    uk_note "Starting short self‑test on $dev (may take several minutes)..."
    if smartctl -t short "$dev" >/dev/null 2>&1; then
      uk_success "Test started. Check results later with: smartctl -l selftest $dev"
      # Optionally, wait a few seconds and show test status
      sleep 2
      smartctl -l selftest "$dev" | tail -5 || true
    else
      uk_error "Failed to start test on $dev. Check permissions or device status."
      return 1
    fi
  fi

  # Show health and attributes
  uk_section_title "SMART health for $dev"
  if ! smartctl -H "$dev" 2>/dev/null; then
    uk_warn "Could not get health status (permissions or unsupported device)."
  fi
  echo
  uk_section_title "SMART attributes"
  if ! smartctl -A "$dev" 2>/dev/null; then
    uk_warn "Could not get attributes."
  fi
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  dh_main "$@"
fi

