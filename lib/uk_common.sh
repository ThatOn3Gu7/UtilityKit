#!/usr/bin/env bash
# Shared UtilityKit helpers

if [[ -n "${UK_COMMON_SH_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
readonly UK_COMMON_SH_LOADED=1
readonly UK_VERSION='2.0.2'

uk_setup_visuals() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    UK_C_RESET=$'\033[0m'
    UK_C_BOLD=$'\033[1m'
    UK_C_DIM=$'\033[2m'
    UK_C_RED=$'\033[31m'
    UK_C_GREEN=$'\033[32m'
    UK_C_YELLOW=$'\033[33m'
    UK_C_BLUE=$'\033[34m'
    UK_C_MAGENTA=$'\033[35m'
    UK_C_CYAN=$'\033[36m'
    UK_C_WHITE=$'\033[37m'
    UK_C_BRIGHT_BLUE=$'\033[94m'
    UK_C_BRIGHT_CYAN=$'\033[96m'
    UK_C_BRIGHT_MAGENTA=$'\033[95m'
  else
    UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN='' UK_C_YELLOW=''
    UK_C_BLUE='' UK_C_MAGENTA='' UK_C_CYAN='' UK_C_WHITE='' UK_C_BRIGHT_BLUE=''
    UK_C_BRIGHT_CYAN='' UK_C_BRIGHT_MAGENTA=''
  fi

  if [[ -t 1 && -z "${NO_UNICODE:-}" ]]; then
    UK_I_INFO='ℹ'
    UK_I_OK='✔'
    UK_I_WARN='⚠'
    UK_I_READY="●"
    UK_I_ERR='✖'
    UK_I_ARROW='❯'
    UK_I_SEP="╱"
    UK_I_WORK='⚙'
    UK_I_STAR='✦'
    UK_I_DOT='•'
  else
    UK_I_INFO='i'
    UK_I_OK='[OK]'
    UK_I_WARN='[!]'
    UK_I_READY="+"
    UK_I_ERR='[X]'
    UK_I_ARROW='>'
    UK_I_SEP="/"
    UK_I_WORK='*'
    UK_I_STAR='*'
    UK_I_DOT='-'
  fi
}

uk_setup_visuals

uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }
uk_is_interactive() { [[ -t 0 && -t 1 ]]; }
uk_platform() {
  if [[ -n "${TERMUX_VERSION:-}" ]]; then
    printf 'termux\n'
  elif [[ "$(uname -s 2>/dev/null || printf unknown)" == "Darwin" ]]; then
    printf 'macos\n'
  else
    printf 'linux\n'
  fi
}
uk_now() { date '+%Y-%m-%d %H:%M:%S'; }
uk_stamp() { date '+%Y%m%d_%H%M%S'; }
uk_abs_path() {
  if uk_has_cmd realpath; then
    realpath "${1:-}"
  elif uk_has_cmd python3; then
    python3 - "${1:-}" <<'PY'
import os,sys
print(os.path.abspath(sys.argv[1]))
PY
  else
    case "${1:-}" in
    /*) printf '%s\n' "${1:-}" ;;
    *) printf '%s/%s\n' "$PWD" "${1:-}" ;;
    esac
  fi
}
uk_data_dir() {
  local dir="${XDG_DATA_HOME:-$HOME/.local/share}/utilitykit"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}
uk_state_dir() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/utilitykit"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}
uk_note() { printf '%s%s%s %s\n' "$UK_C_BLUE" "$UK_I_INFO" "$UK_C_RESET" "$*"; }
uk_info() { printf '%s%s%s %s\n' "$UK_C_CYAN" "$UK_I_INFO" "$UK_C_RESET" "$*"; }
uk_success() { printf '%s%s%s %s\n' "$UK_C_GREEN" "$UK_I_OK" "$UK_C_RESET" "$*"; }
uk_warn() { printf '%s%s%s %s\n' "$UK_C_YELLOW" "$UK_I_WARN" "$UK_C_RESET" "$*" >&2; }
uk_error() { printf '%s%s%s %s\n' "$UK_C_RED" "$UK_I_ERR" "$UK_C_RESET" "$*" >&2; }
uk_die() {
  uk_error "$*"
  return 1
}
uk_confirm() {
  local prompt="${1:-}" default="${2:-N}" reply=''
  if ! uk_is_interactive; then
    [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1
  fi
  if [[ "$default" =~ ^[Yy]$ ]]; then
    printf ' %s %s [Y/n]: ' "$UK_I_ARROW" "$prompt" >&2
  else
    printf ' %s %s [y/N]: ' "$UK_I_ARROW" "$prompt" >&2
  fi
  if [[ -r /dev/tty ]]; then
    read -r reply </dev/tty
  else
    read -r reply
  fi
  if [[ -z "$reply" ]]; then
    if [[ "$default" =~ ^[Yy]$ ]]; then
      printf '\033[1A\r\033[K %s %s [Y/n]: %s\n' "$UK_I_ARROW" "$prompt" "$default" >&2
    else
      printf '\033[1A\r\033[K %s %s [y/N]: %s\n' "$UK_I_ARROW" "$prompt" "$default" >&2
    fi
  fi
  [[ -z "$reply" ]] && reply="$default"
  [[ "$reply" =~ ^[Yy] ]]
}
uk_prompt() {
  local label="${1:-}"
  local default="${2:-}"
  local example="${3:-}"
  local note="${4:-}"
  local reply=''

  printf ' %s %s' "$UK_I_ARROW" "$label" >&2
  [[ -n "$default" ]] && printf ' %s[default: %s]%s' "$UK_C_DIM" "$default" "$UK_C_RESET" >&2
  printf '\n' >&2
  [[ -n "$example" ]] && printf '   %sExample: %s%s\n' "$UK_C_DIM" "$example" "$UK_C_RESET" >&2
  [[ -n "$note" ]] && printf '   %s%s%s\n' "$UK_C_DIM" "$note" "$UK_C_RESET" >&2
  printf ' %s ' "$UK_I_ARROW" >&2
  if [[ -r /dev/tty ]]; then
    read -r reply </dev/tty
  else
    read -r reply
  fi
  if [[ -z "$reply" && -n "$default" ]]; then
    printf '\033[1A\r\033[K %s %s\n' "$UK_I_ARROW" "$default" >&2
  fi
  printf '%s\n' "${reply:-$default}"
}
uk_section_title() {
  local title="${1:-}"
  printf '\n%s%s%s\n' "$UK_C_BRIGHT_CYAN" "$title" "$UK_C_RESET"
}
uk_print_list_or_none() {
  local label="${1:-}"
  shift || true
  uk_note "$label"
  if [[ $# -eq 0 ]]; then
    printf '  %snone found%s\n' "$UK_C_DIM" "$UK_C_RESET"
    return 0
  fi
  local item
  for item in "$@"; do
    [[ -n "$item" ]] && printf '  - %s\n' "$item"
  done
}
uk_repeat() {
  local char="${1:-}" count="${2:-}"
  printf '%*s' "$count" '' | tr ' ' "$char"
}
uk_bar() {
  local value="${1:-}" total="${2:-}" width="${3:-24}"
  local fill=0 empty=0
  if [[ "$total" -le 0 ]]; then
    fill=0
  else
    fill=$((value * width / total))
  fi
  ((fill > width)) && fill=$width
  empty=$((width - fill))
  printf '%s%s%s%s%s' "$UK_C_GREEN" "$(printf '%*s' "$fill" '' | tr ' ' '#')" "$UK_C_DIM" "$(printf '%*s' "$empty" '' | tr ' ' '-')" "$UK_C_RESET"
}
uk_header() {
  local title="${1:-}" subtitle="${2:-}"
  printf '\n%s%s%s\n' "$UK_C_BRIGHT_CYAN$UK_C_BOLD" "$title" "$UK_C_RESET"
  [[ -n "$subtitle" ]] && printf '%s%s%s\n' "$UK_C_DIM" "$subtitle" "$UK_C_RESET"
  printf '%s\n' "$(printf '%*s' 72 '' | tr ' ' '-')"
}
uk_pick_clipboard_cmd() {
  local cmd=''
  for cmd in wl-copy xclip pbcopy termux-clipboard-set clip.exe; do
    if uk_has_cmd "$cmd"; then
      printf '%s\n' "$cmd"
      return 0
    fi
  done
  return 1
}
uk_copy_to_clipboard() {
  local text="${1:-}" cmd
  cmd="$(uk_pick_clipboard_cmd 2>/dev/null || true)"
  [[ -n "$cmd" ]] || return 1
  case "$cmd" in
  xclip) printf '%s' "$text" | xclip -selection clipboard ;;
  wl-copy | pbcopy | termux-clipboard-set | clip.exe) printf '%s' "$text" | "$cmd" ;;
  esac
}
uk_slugify() {
  printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | tr ' /' '--' | tr -cd 'a-z0-9._-'
}
uk_visible_len() {
  local s
  s="$(printf '%s' "${1:-}" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')"
  printf '%s' "${#s}"
}
uk_banner() {
  local name="${1:-}" tagline="${2:-}" icon="${3:-}"
  shift 3 2>/dev/null || true

  [[ -n "${UK_BANNER_PRINTED:-}" ]] && return 0
  [[ ! -t 1 ]] && return 0
  [[ -n "${NO_BANNER:-}" ]] && return 0
  local a
  for a in "$@"; do
    case "$a" in -q | --quiet) return 0 ;; esac
  done

  [[ -z "$icon" ]] && icon="$UK_I_WORK"

  local tl tr bl br h v
  if [[ -z "${NO_UNICODE:-}" ]]; then
    tl='╭' tr='╮' bl='╰' br='╯' h='─' v='│'
  else
    tl='+' tr='+' bl='+' br='+' h='-' v='|'
  fi

  local l1="  $icon utilitykit $UK_I_SEP $name  v$UK_VERSION  "
  local l2="  $tagline  "
  local l3="  linux $UK_I_DOT macos $UK_I_DOT termux  "

  local n1 n2 n3 term_width inner min_inner
  n1="$(uk_visible_len "$l1")"
  n2="$(uk_visible_len "$l2")"
  n3="$(uk_visible_len "$l3")"

  if uk_has_cmd tput; then
    term_width="$(tput cols 2>/dev/null)"
  fi
  if [[ -z "$term_width" ]] && uk_has_cmd stty; then
    term_width="$(stty size 2>/dev/null | cut -d' ' -f2)"
  fi
  if [[ -z "$term_width" ]]; then
    term_width="${COLUMNS:-80}"
  fi
  
  # Failsafe in case term_width is still somehow empty or not a number
  if ! [[ "$term_width" =~ ^[0-9]+$ ]]; then
    term_width=80
  fi

  inner=$((term_width - 2))

  min_inner=44
  ((n1 > min_inner)) && min_inner=$n1
  ((n2 > min_inner)) && min_inner=$n2
  ((n3 > min_inner)) && min_inner=$n3
  ((inner < min_inner)) && inner=$min_inner

  local hbar='' i
  for ((i = 0; i < inner; i++)); do hbar+="$h"; done

  printf '\n'
  printf '%s%s%s%s%s\n' "$UK_C_BRIGHT_CYAN" "$tl" "$hbar" "$tr" "$UK_C_RESET"
  
  local pad1=$(( (inner - n1) / 2 ))
  local pad1_r=$(( inner - n1 - pad1 ))
  printf '%s%s%s%*s%s%*s%s%s%s\n' \
    "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET" \
    "$pad1" '' \
    "$UK_C_BOLD$UK_C_BRIGHT_CYAN$l1$UK_C_RESET" \
    "$pad1_r" '' \
    "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET"
    
  if [[ -n "$tagline" ]]; then
    local pad2=$(( (inner - n2) / 2 ))
    local pad2_r=$(( inner - n2 - pad2 ))
    printf '%s%s%s%*s%s%*s%s%s%s\n' \
      "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET" \
      "$pad2" '' \
      "$UK_C_DIM$l2$UK_C_RESET" \
      "$pad2_r" '' \
      "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET"
  fi
  
  local pad3=$(( (inner - n3) / 2 ))
  local pad3_r=$(( inner - n3 - pad3 ))
  printf '%s%s%s%*s%s%*s%s%s%s\n' \
    "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET" \
    "$pad3" '' \
    "$UK_C_DIM$l3$UK_C_RESET" \
    "$pad3_r" '' \
    "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET"
    
  printf '%s%s%s%s%s\n' "$UK_C_BRIGHT_CYAN" "$bl" "$hbar" "$br" "$UK_C_RESET"
  printf '\n'

  UK_BANNER_PRINTED=1
}
