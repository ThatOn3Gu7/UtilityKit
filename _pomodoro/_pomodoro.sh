#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

PO_WORK=25
PO_BREAK=5
PO_CYCLES=4
PO_UNIT='minutes'
PO_NO_BELL=0

po_usage() {
  cat <<'USAGE'
Usage:
  _pomodoro.sh [--work N] [--break N] [--cycles N] [--unit minutes|seconds] [--no-bell]
USAGE
}
po_seconds() {
  if [[ "$PO_UNIT" == 'seconds' ]]; then
    printf '%s\n' "${1:-}"
  else
    printf '%s\n' $((${1:-} * 60))
  fi
}
po_timer() {
  local label="${1:-}" total="${2:-}" remaining="${2:-}" icon='*' title='Session'
  case "$label" in
  work)
    icon='*'
    [[ -z "${NO_UNICODE:-}" ]] && icon='◆'
    title='Work focus'
    ;;
  break)
    icon='*'
    [[ -z "${NO_UNICODE:-}" ]] && icon='☕'
    title='Break time'
    ;;
  esac
  local color="$UK_C_GREEN"
  [[ "$label" == 'break' ]] && color="$UK_C_CYAN"

  while ((remaining > 0)); do
    printf '\r%s%s%s %-12s %s%4ss%s %s' \
      "$color" "$icon" "$UK_C_RESET" \
      "$title" \
      "$UK_C_BOLD" "$remaining" "$UK_C_RESET" \
      "$(uk_bar $((total - remaining)) "$total" 28)"
    sleep 1
    remaining=$((remaining - 1))
  done
  printf '\r%s%s%s %-12s %s%4ss%s %s\n' \
    "$color" "$icon" "$UK_C_RESET" \
    "$title" \
    "$UK_C_BOLD" "0" "$UK_C_RESET" \
    "$(uk_bar "$total" "$total" 28)"
  ((PO_NO_BELL == 0)) && printf '\a'
  if uk_has_cmd termux-vibrate; then termux-vibrate -d 200 >/dev/null 2>&1 || true; fi
}
po_interactive() {

  PO_WORK="$(uk_prompt \
    'Work duration per cycle' \
    '25' \
    '25  →  standard Pomodoro | 50  →  long focus block | 90  →  ultradian rhythm' \
    'How long you want to focus before each break.')"

  PO_BREAK="$(uk_prompt \
    'Break duration per cycle' \
    '5' \
    '5  →  short rest | 10  →  medium rest | 15  →  long rest' \
    'How long your rest period lasts after each work block.')"

  PO_CYCLES="$(uk_prompt \
    'Number of cycles to run' \
    '4' \
    '4  →  classic set | 2  →  quick session | 8  →  full day block' \
    'The timer will alternate work and break for this many cycles.')"

  PO_UNIT="$(uk_prompt \
    'Time unit to use' \
    'minutes' \
    'minutes  →  normal use | seconds  →  testing/demo only' \
    'Use seconds only when testing — a 25-second work block is not a real session.')"

  local bell_choice
  bell_choice="$(uk_prompt \
    'Disable bell and vibration at end of each block?' \
    'n' \
    'y  →  silent mode | n  →  play bell and vibrate on Termux' \
    'The bell fires once at the end of each work or break block.')"
  if [[ "$bell_choice" =~ ^[Yy]$ ]]; then
    PO_NO_BELL=1
  fi

}
po_main() {
  uk_banner "pomodoro" "Work/break cycle timer with progress bar and session log" "" "$@"
  PO_WORK=25
  PO_BREAK=5
  PO_CYCLES=4
  PO_UNIT='minutes'
  PO_NO_BELL=0
  local seen_args=0
  while [[ $# -gt 0 ]]; do
    seen_args=1
    case "${1:-}" in
    --work)
      shift
      PO_WORK="${1:-25}"
      ;;
    --break)
      shift
      PO_BREAK="${1:-5}"
      ;;
    --cycles)
      shift
      PO_CYCLES="${1:-4}"
      ;;
    --unit)
      shift
      PO_UNIT="${1:-minutes}"
      ;;
    --no-bell) PO_NO_BELL=1 ;;
    -h | --help)
      po_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  if ((seen_args == 0)) && [[ -t 0 && -t 1 ]]; then
    po_interactive
  fi

  PO_WORK=${PO_WORK:-25}
  PO_BREAK=${PO_BREAK:-5}
  PO_CYCLES=${PO_CYCLES:-4}
  PO_UNIT=${PO_UNIT:-minutes}

  uk_section_title "$PO_CYCLES cycle(s) | $PO_WORK work | $PO_BREAK break | unit=$PO_UNIT"
  local cycle work_s break_s logf
  work_s=$(po_seconds "$PO_WORK")
  break_s=$(po_seconds "$PO_BREAK")
  logf="$(uk_state_dir)/pomodoro.log"
  for ((cycle = 1; cycle <= PO_CYCLES; cycle++)); do
    printf 'Cycle %d/%d\n' "$cycle" "$PO_CYCLES"
    po_timer 'work' "$work_s"
    printf '%s | completed work cycle %d\n' "$(uk_now)" "$cycle" >>"$logf"
    if ((cycle < PO_CYCLES)); then
      po_timer 'break' "$break_s"
    fi
  done
  uk_success "Pomodoro complete. Log: $logf"
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  po_main "$@"
fi
