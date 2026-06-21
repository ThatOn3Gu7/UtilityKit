#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

ZM_MODE='waves'
ZM_DURATION=10

zm_usage() {
  cat <<'USAGE'
Usage:
  _zen_mode.sh [--mode matrix|life|waves] [--duration SECONDS]
USAGE
}

zm_matrix() {
  local end cols rows line c chars='01<>/*+-'
  end=$((SECONDS + ZM_DURATION))
  cols=$(tput cols 2>/dev/null || echo 80)
  rows=$(tput lines 2>/dev/null || echo 24)
  while (( SECONDS < end )); do
    clear 2>/dev/null || printf '\n'
    for ((r=0; r<rows; r++)); do
      line=''
      for ((c=0; c<cols; c++)); do
        line+="${chars:RANDOM%${#chars}:1}"
      done
      printf '%s%s%s\n' "$UK_C_GREEN" "$line" "$UK_C_RESET"
    done
    sleep 0.12
  done
}

zm_life() {
  python3 - <<'PY2' "$ZM_DURATION"
import os,sys,time,random
end=time.time()+int(sys.argv[1])
rows,cols=18,48
board=[[random.randint(0,1) for _ in range(cols)] for _ in range(rows)]
while time.time()<end:
    os.system('clear >/dev/null 2>&1')
    for r in range(rows):
        print(''.join('█' if cell else ' ' for cell in board[r]))
    nxt=[[0]*cols for _ in range(rows)]
    for r in range(rows):
        for c in range(cols):
            n=sum(board[(r+dr)%rows][(c+dc)%cols] for dr in (-1,0,1) for dc in (-1,0,1) if dr or dc)
            nxt[r][c]=1 if (board[r][c] and n in (2,3)) or (not board[r][c] and n==3) else 0
    board=nxt
    time.sleep(0.15)
PY2
}

zm_waves() {
  local end t x cols line y
  end=$((SECONDS + ZM_DURATION))
  cols=$(tput cols 2>/dev/null || echo 80)
  t=0
  while (( SECONDS < end )); do
    clear 2>/dev/null || printf '\n'
    for y in $(seq 1 16); do
      line=''
      for ((x=0; x<cols; x++)); do
        if (( ((x + t + y) % 11) == 0 )); then line+='*'; else line+=' '; fi
      done
      printf '%s%s%s\n' "$UK_C_BRIGHT_MAGENTA" "$line" "$UK_C_RESET"
    done
    sleep 0.12
    t=$((t+1))
  done
}

zm_interactive() {
  uk_header 'UtilityKit Zen Mode' 'Terminal screensaver — press Ctrl+C to exit early'

  ZM_MODE="$(uk_prompt \
    'Choose a screensaver mode' \
    'waves' \
    'waves  →  flowing ASCII wave pattern  |  matrix  →  falling binary rain  |  life  →  Conway Game of Life' \
    'Each mode runs as a full-screen animation until the duration expires.')"

  ZM_DURATION="$(uk_prompt \
    'Enter duration in seconds' \
    '10' \
    '10  →  quick preview  |  60  →  one minute  |  300  →  five minutes' \
    'The screensaver exits automatically after this many seconds, or press Ctrl+C to stop early.')"

  ZM_MODE=${ZM_MODE:-waves}
  ZM_DURATION=${ZM_DURATION:-10}
}

zm_main() {
  local seen_args=0
  while [[ $# -gt 0 ]]; do
    seen_args=1
    case "$1" in
      --mode) shift; ZM_MODE="${1:-waves}" ;;
      --duration) shift; ZM_DURATION="${1:-10}" ;;
      -h|--help) zm_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done

  if (( seen_args == 0 )) && [[ -t 0 && -t 1 ]]; then
    zm_interactive
  fi

  printf '\n  %s%sStarting %s mode%s  %s(%s seconds — press Ctrl+C to exit early)%s\n\n' \
    "$UK_C_BOLD" "$UK_C_CYAN" "$ZM_MODE" "$UK_C_RESET" \
    "$UK_C_DIM" "$ZM_DURATION" "$UK_C_RESET"
  sleep 1

  case "$ZM_MODE" in
    matrix) zm_matrix ;;
    life) zm_life ;;
    waves) zm_waves ;;
    *) uk_error "Unknown mode: $ZM_MODE"; return 1 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  zm_main "$@"
fi
