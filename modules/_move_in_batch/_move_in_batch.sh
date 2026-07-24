#!/usr/bin/env bash
MIB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MIB_SCRIPT_DIR/../../lib/uk_common.sh"

IFS=$'\n\t'

#  0.  METADATA
MIB_SCRIPT_NAME="Batch File Mover"
MIB_SCRIPT_URL="https://github.com/Thaton3gu7/Utilitykit.git"

#  1.  TERMINAL CAPABILITY DETECTION
MIB_CAP_USE_COLOR=false
MIB_CAP_USE_UNICODE=false
MIB_CAP_IS_INTERACTIVE=false
MIB_TERM_WIDTH=80
MIB_METHOD="cp" # default: safe copy
MIB_FLATTEN_MODE=false

init_terminal_caps() {
  if [[ -n "${NO_COLOR:-}" ]]; then
    MIB_CAP_USE_COLOR=false
  elif [[ ! -t 1 ]]; then
    MIB_CAP_USE_COLOR=false
  else
    MIB_CAP_USE_COLOR=true
  fi

  local is_limited=false
  if [[ -n "${ANDROID_ROOT:-}" ]] || [[ "${TERM_PROGRAM:-}" == "Termux" ]] || [[ "${TERM:-}" == "dumb" ]]; then
    is_limited=true
  fi

  if [[ ! -t 1 ]] || [[ "$is_limited" == true ]]; then
    MIB_CAP_USE_UNICODE=false
  else
    MIB_CAP_USE_UNICODE=true
  fi

  if [[ -t 0 ]]; then
    MIB_CAP_IS_INTERACTIVE=true
  else
    MIB_CAP_IS_INTERACTIVE=false
  fi

  MIB_TERM_WIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}"
}

#  2.  ANSI ESCAPE CODES
MIB_C_RESET=""
MIB_C_BOLD=""
MIB_C_DIM=""
MIB_C_ITALIC=""
MIB_C_UNDERLINE=""
MIB_C_STRIKETHROUGH=""
MIB_C_OVERLINE=""
MIB_C_RED=""
MIB_C_GREEN=""
MIB_C_YELLOW=""
MIB_C_BLUE=""
MIB_C_MAGENTA=""
MIB_C_CYAN=""
MIB_C_WHITE=""
MIB_C_GRAY=""
MIB_C_RED_BRIGHT=""
MIB_C_GREEN_BRIGHT=""
MIB_C_YELLOW_BRIGHT=""
MIB_C_BLUE_BRIGHT=""
MIB_C_MAGENTA_BRIGHT=""
MIB_C_CYAN_BRIGHT=""
MIB_C_WHITE_BRIGHT=""
MIB_C_BG_RED=""
MIB_C_BG_GREEN=""
MIB_C_BG_YELLOW=""
MIB_C_BG_BLUE=""
MIB_C_BG_CYAN=""
MIB_C_BG_GRAY=""

init_colors() {
  if [[ "$MIB_CAP_USE_COLOR" == false ]]; then
    return
  fi
  MIB_C_RESET=$'\033[0m'
  MIB_C_BOLD=$'\033[1m'
  MIB_C_DIM=$'\033[2m'
  MIB_C_ITALIC=$'\033[3m'
  MIB_C_UNDERLINE=$'\033[4m'
  MIB_C_STRIKETHROUGH=$'\033[9m'
  MIB_C_OVERLINE=$'\033[53m'
  MIB_C_RED=$'\033[31m'
  MIB_C_GREEN=$'\033[32m'
  MIB_C_YELLOW=$'\033[33m'
  MIB_C_BLUE=$'\033[34m'
  MIB_C_MAGENTA=$'\033[35m'
  MIB_C_CYAN=$'\033[36m'
  MIB_C_WHITE=$'\033[37m'
  MIB_C_GRAY=$'\033[90m'
  MIB_C_RED_BRIGHT=$'\033[91m'
  MIB_C_GREEN_BRIGHT=$'\033[92m'
  MIB_C_YELLOW_BRIGHT=$'\033[93m'
  MIB_C_BLUE_BRIGHT=$'\033[94m'
  MIB_C_MAGENTA_BRIGHT=$'\033[95m'
  MIB_C_CYAN_BRIGHT=$'\033[96m'
  MIB_C_WHITE_BRIGHT=$'\033[97m'
  MIB_C_BG_RED=$'\033[41m'
  MIB_C_BG_GREEN=$'\033[42m'
  MIB_C_BG_YELLOW=$'\033[43m'
  MIB_C_BG_BLUE=$'\033[44m'
  MIB_C_BG_CYAN=$'\033[46m'
  MIB_C_BG_GRAY=$'\033[100m'
}

#  3.  ICON SET  (Unicode → ASCII fallback)
MIB_I_INFO=""
MIB_I_SUCCESS=""
MIB_I_ERROR=""
MIB_I_WARNING=""
MIB_I_WORKING=""
MIB_I_ARROW=""
MIB_I_STAR=""
MIB_I_BULLET=""
MIB_I_COLLAPSED=""
MIB_I_BOX_TL=""
MIB_I_BOX_TR=""
MIB_I_BOX_BL=""
MIB_I_BOX_BR=""
MIB_I_BOX_H=""
MIB_I_BOX_V=""
MIB_I_PROG_FILL=""
MIB_I_PROG_EMPTY=""
MIB_I_CHECK_OFF=""
MIB_I_CHECK_ON=""
MIB_I_LOZENGE=""
MIB_I_PLAY=""
MIB_I_TICK=""
MIB_I_CROSS=""
MIB_I_ELLIPSIS=""
MIB_I_SEPARATOR=""
MIB_I_GEAR=""
MIB_I_SEARCH=""
MIB_I_FOLDER=""
MIB_I_FILE=""
MIB_I_FLATTEN=""
MIB_I_PACKAGE=""

init_icons() {
  if [[ "$MIB_CAP_USE_UNICODE" == true ]]; then
    MIB_I_INFO="ℹ"
    MIB_I_SUCCESS="✔"
    MIB_I_ERROR="✖"
    MIB_I_WARNING="⚠"
    MIB_I_WORKING="⚙"
    MIB_I_ARROW="❯"
    MIB_I_STAR="★"
    MIB_I_BULLET="●"
    MIB_I_COLLAPSED="▸"
    MIB_I_BOX_TL="╭"
    MIB_I_BOX_TR="╮"
    MIB_I_BOX_BL="╰"
    MIB_I_BOX_BR="╯"
    MIB_I_BOX_H="─"
    MIB_I_BOX_V="│"
    MIB_I_PROG_FILL="█"
    MIB_I_PROG_EMPTY="░"
    MIB_I_CHECK_OFF="☐"
    MIB_I_CHECK_ON="☒"
    MIB_I_LOZENGE="◆"
    MIB_I_PLAY="▶"
    MIB_I_TICK="✔"
    MIB_I_CROSS="✖"
    MIB_I_ELLIPSIS="…"
    MIB_I_SEPARATOR="╱"
    MIB_I_GEAR="⚙"
    MIB_I_SEARCH="⌕"
    MIB_I_FOLDER="📁"
    MIB_I_FILE="📄"
    MIB_I_FLATTEN="↯"
    MIB_I_PACKAGE="📦"
  else
    MIB_I_INFO="i"
    MIB_I_SUCCESS="[OK]"
    MIB_I_ERROR="[ERR]"
    MIB_I_WARNING="[!]"
    MIB_I_WORKING="[*]"
    MIB_I_ARROW=">"
    MIB_I_STAR="*"
    MIB_I_BULLET="*"
    MIB_I_COLLAPSED=">"
    MIB_I_BOX_TL="+"
    MIB_I_BOX_TR="+"
    MIB_I_BOX_BL="+"
    MIB_I_BOX_BR="+"
    MIB_I_BOX_H="-"
    MIB_I_BOX_V="|"
    MIB_I_PROG_FILL="#"
    MIB_I_PROG_EMPTY="."
    MIB_I_CHECK_OFF="[ ]"
    MIB_I_CHECK_ON="[x]"
    MIB_I_LOZENGE="<>"
    MIB_I_PLAY=">"
    MIB_I_TICK="[OK]"
    MIB_I_CROSS="[ERR]"
    MIB_I_ELLIPSIS="..."
    MIB_I_SEPARATOR="|"
    MIB_I_GEAR="[*]"
    MIB_I_SEARCH="?"
    MIB_I_FOLDER="[D]"
    MIB_I_FILE="[F]"
    MIB_I_FLATTEN="|>"
    MIB_I_PACKAGE="[P]"
  fi
}

#  4.  HELPER FUNCTIONS
colorize() {
  local color="${1:-}"
  local text="${2:-}"
  if [[ "$MIB_CAP_USE_COLOR" == true ]]; then
    printf "%s%s%s" "$color" "$text" "$MIB_C_RESET"
  else
    printf "%s" "$text"
  fi
}

msg_info() { printf "  %s    %s\n" "$(colorize "$MIB_C_BLUE" "$MIB_I_INFO")" "$*"; }
msg_success() { printf "  %s %s\n" "$(colorize "$MIB_C_GREEN" "$MIB_I_SUCCESS")" "$*"; }
msg_error() { printf "  %s   %s\n" "$(colorize "$MIB_C_RED" "$MIB_I_ERROR")" "$*" >&2; }
msg_warning() { printf "  %s  %s\n" "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")" "$*"; }
msg_working() { printf "  %s %s\n" "$(colorize "$MIB_C_CYAN" "$MIB_I_WORKING")" "$*"; }
msg_arrow() { printf "  %s   %s\n" "$(colorize "$MIB_C_BLUE_BRIGHT" "$MIB_I_ARROW")" "$*"; }

format_size() {
  local size="${1:-}"
  if ((size >= 1073741824)); then
    awk "BEGIN { printf \"%.1f GB\", $size/1073741824 }"
  elif ((size >= 1048576)); then
    awk "BEGIN { printf \"%.1f MB\", $size/1048576 }"
  elif ((size >= 1024)); then
    awk "BEGIN { printf \"%.1f KB\", $size/1024 }"
  else
    printf "%s B" "$size"
  fi
}
format_duration() {
  local seconds=${1:-}
  local mins=$((seconds / 60))
  local secs=$((seconds % 60))
  if ((mins > 0)); then
    printf "%dm %02ds" "$mins" "$secs"
  else
    printf "%ds" "$secs"
  fi
}
#  5.  PROGRESS BAR
draw_progress() {
  local current="${1:-}"
  local total="${2:-}"
  local label="${3:-}"

  ((total == 0)) && return
  if [[ ! -t 1 ]]; then
    [[ "$label" == "Complete" ]] && printf "  %s Processed %d/%d file(s): %s\n" "$MIB_I_GEAR" "$current" "$total" "$label"
    return 0
  fi

  local term_width="$MIB_TERM_WIDTH"

  local bar_width=$((term_width / 4))
  ((bar_width > 30)) && bar_width=30
  ((bar_width < 10)) && bar_width=10

  local pct=$((current * 100 / total))
  local filled=$((current * bar_width / total))
  local empty=$((bar_width - filled))

  local bar=""
  local i
  for ((i = 0; i < filled; i++)); do bar+="$MIB_I_PROG_FILL"; done
  for ((i = 0; i < empty; i++)); do bar+="$MIB_I_PROG_EMPTY"; done

  local ui_reserved=$((14 + bar_width + 3 + ${#current} + ${#total}))
  local max_label_len=$((term_width - ui_reserved))

  local display_label="$label"
  if ((max_label_len < 5)); then
    display_label=""
  elif ((${#display_label} > max_label_len)); then
    display_label="${display_label:0:$((max_label_len - 3))}..."
  fi

  if [[ "$MIB_CAP_USE_COLOR" == true ]]; then
    local prog_color="$MIB_C_CYAN"
    if ((pct >= 100)); then
      prog_color="$MIB_C_GREEN"
    elif ((pct >= 66)); then
      prog_color="$MIB_C_GREEN_BRIGHT"
    elif ((pct >= 33)); then
      prog_color="$MIB_C_YELLOW"
    fi

    printf "%s" $'\033[2K\r'
    printf "  %s%s%s[%s]%s %s%3d%%%s  %s%d/%d%s  %s%s%s" \
      "$MIB_C_DIM" "$(colorize "$MIB_C_CYAN" "$MIB_I_GEAR")" "$MIB_C_DIM" \
      "$(colorize "$prog_color" "$bar")" \
      "$MIB_C_DIM" "$MIB_C_BOLD" "$pct" "$MIB_C_RESET" \
      "$MIB_C_DIM" "$current" "$total" "$MIB_C_RESET" \
      "$MIB_C_DIM" "$display_label" "$MIB_C_RESET"
  else
    printf "%s" $'\033[2K\r'
    printf "  %s [%s] %3d%%  %d/%d  %s" \
      "$MIB_I_GEAR" "$bar" "$pct" "$current" "$total" "$display_label"
  fi
}
#  6.  UTILITY:  tilde expansion
_expand_tilde() {
  local path="${1:-}"
  if [[ "$path" == "~" || "$path" == "~/"* ]]; then
    path="${HOME}${path:1}"
  fi
  printf '%s' "$path"
}

# =============================================================================
# Interactive directory picker (full-screen, banner-safe, with directory icons)
# =============================================================================

mib_ac_init_terminal() {
  MIB_AC_TERM_MODE="full"
  MIB_AC_TERM="${TERM:-dumb}"
  MIB_AC_HOME="${HOME:-/}"

  if [[ ! -t 0 || ! -t 2 || "$MIB_AC_TERM" == "dumb" || "$MIB_AC_TERM" == "unknown" ]]; then
    MIB_AC_TERM_MODE="plain"
  elif ! command -v tput >/dev/null 2>&1 || ! tput clear >/dev/null 2>&1 || ! tput cup 0 0 >/dev/null 2>&1; then
    MIB_AC_TERM_MODE="plain"
  fi

  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *UTF-8* | *utf8* | *UTF8*) MIB_AC_UNICODE=1 ;;
  *) MIB_AC_UNICODE=0 ;;
  esac
  [[ -n "${NO_UNICODE:-}" ]] && MIB_AC_UNICODE=0

  if ((MIB_AC_UNICODE)); then
    MIB_AC_TL='╭'
    MIB_AC_TR='╮'
    MIB_AC_BL='╰'
    MIB_AC_BR='╯'
    MIB_AC_H='─'
    MIB_AC_V='│'
    MIB_AC_ELL='…'
    MIB_AC_DIR='📁'
    MIB_AC_SYMLINK='🔗'
  else
    MIB_AC_TL='+'
    MIB_AC_TR='+'
    MIB_AC_BL='+'
    MIB_AC_BR='+'
    MIB_AC_H='-'
    MIB_AC_V='|'
    MIB_AC_ELL='...'
    MIB_AC_DIR='[D]'
    MIB_AC_SYMLINK='[L]'
  fi
  MIB_AC_ARR='>'
  MIB_AC_UP='^'
  MIB_AC_DOWN='v'
  MIB_AC_LINK='->'
  MIB_AC_LOCK='[!]'
  MIB_AC_SEL='*'
}

mib_ac_term_size() {
  local rows='' cols='' size=''
  if command -v tput >/dev/null 2>&1; then
    cols="$(tput cols 2>/dev/null || true)"
    rows="$(tput lines 2>/dev/null || true)"
  fi
  if [[ ! "$cols" =~ ^[0-9]+$ || ! "$rows" =~ ^[0-9]+$ ]]; then
    size="$(stty size </dev/tty 2>/dev/null || true)"
    rows="${size%% *}"
    cols="${size##* }"
  fi
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
  printf '%s %s\n' "$cols" "$rows"
}

mib_ac_hide_cursor() {
  [[ "${MIB_AC_TERM_MODE:-plain}" == full ]] || return 0
  tput civis 2>/dev/null || true
}
mib_ac_show_cursor() {
  [[ "${MIB_AC_TERM_MODE:-plain}" == full ]] || return 0
  tput cnorm 2>/dev/null || true
}
mib_ac_clear_screen() {
  [[ "${MIB_AC_TERM_MODE:-plain}" == full ]] || return 0
  tput clear >&2 2>/dev/null || printf '\033[H\033[2J' >&2
}

mib_ac_strip_ansi() {
  printf '%s' "${1:-}" | sed $'s/\033\[[0-9;]*[[:alpha:]]//g'
}
mib_ac_visible_len() {
  local plain
  plain="$(mib_ac_strip_ansi "${1:-}")"
  local len=${#plain}
  # Compensate for double-width emojis (2 display columns, 1 char count)
  local extra=0 tmp="$plain"
  while [[ "$tmp" == *"📁"* ]]; do
    extra=$((extra + 1))
    tmp="${tmp/"📁"/}"
  done
  tmp="$plain"
  while [[ "$tmp" == *"🔗"* ]]; do
    extra=$((extra + 1))
    tmp="${tmp/"🔗"/}"
  done
  len=$((len + extra))
  printf '%s' "$len"
}

mib_ac_truncate() {
  local text="${1:-}" max="${2:-80}" vis out='' i=0 len c code keep visible=0
  ((max > 0)) || return 0
  vis="$(mib_ac_visible_len "$text")"
  ((vis <= max)) && {
    printf '%s' "$text"
    return 0
  }
  keep=$((max - ${#MIB_AC_ELL}))
  ((keep < 0)) && keep=0
  len=${#text}
  while ((visible < keep && i < len)); do
    c="${text:i:1}"
    i=$((i + 1))
    if [[ "$c" == $'\033' ]]; then
      code="$c"
      while ((i < len)); do
        c="${text:i:1}"
        code+="$c"
        i=$((i + 1))
        [[ "$c" =~ [[:alpha:]] ]] && break
      done
      out+="$code"
    else
      out+="$c"
      visible=$((visible + 1))
    fi
  done
  printf '%s%s' "$out" "$MIB_AC_ELL"
}

mib_ac_box_row() {
  local text="${1:-}" sel="${2:-0}" dim="${3:-0}" width="${inner:-1}"
  local vis pad_r middle left_color='' body_color='' reset="${MIB_C_RESET:-}"
  ((width > 0)) || width=1
  vis="$(mib_ac_visible_len "$text")"
  if ((vis > width)); then
    text="$(mib_ac_truncate "$text" "$width")"
    vis="$(mib_ac_visible_len "$text")"
  fi
  pad_r=$((width - vis))
  ((pad_r < 0)) && pad_r=0
  printf -v middle '%s%*s' "$text" "$pad_r" ''
  left_color="${MIB_C_CYAN_BRIGHT:-}"
  if ((sel)); then
    body_color="${MIB_C_BOLD:-}${MIB_C_GREEN_BRIGHT:-}"
  elif ((dim)); then
    body_color="${MIB_C_DIM:-}"
  fi
  printf '%s%s%s%s%s%s%s\n' "$left_color" "$MIB_AC_V" "$reset" "$body_color" "$middle" "$reset$left_color$MIB_AC_V" "$reset" >&2
}
mib_ac_box_rule() {
  local left="${1:-+}" right="${2:-+}" hb=''
  printf -v hb '%*s' "${inner:-1}" ''
  hb="${hb// /$MIB_AC_H}"
  printf '%s%s%s%s%s%s\n' "${MIB_C_CYAN_BRIGHT:-}" "$left" "$hb" "$right" "${MIB_C_RESET:-}" '' >&2
}
mib_ac_box_top() { mib_ac_box_rule "$MIB_AC_TL" "$MIB_AC_TR"; }
mib_ac_box_bottom() { mib_ac_box_rule "$MIB_AC_BL" "$MIB_AC_BR"; }
mib_ac_box_title() {
  local t=" ${1:-}"
  mib_ac_box_row "$t" 0 0
}

mib_ac_draw_pointer() {
  local index="${1:-0}" window="${2:-0}" enabled="${3:-0}" prompt_row="${4:-0}"
  local row=$((3 + (window > 0 ? 1 : 0) + index - window))

  if [[ "${MIB_AC_MENU_SAVED:-0}" -eq 1 ]]; then
    tput rc >&2 2>/dev/null || return 1
    if ((row > 0)); then
      tput cud "$row" >&2 2>/dev/null || printf '\033[%dB' "$row" >&2
    fi
    tput cuf 1 >&2 2>/dev/null || printf '\033[1C' >&2
  else
    tput cup "$row" 1 >&2 2>/dev/null || return 1
  fi

  if ((enabled)); then
    printf '%s %s %s' "${MIB_C_BOLD:-}${MIB_C_GREEN_BRIGHT:-}" "$MIB_AC_ARR" "${MIB_C_RESET:-}" >&2
  else
    printf '   ' >&2
  fi

  if [[ "${MIB_AC_MENU_SAVED:-0}" -eq 1 ]]; then
    tput rc >&2 2>/dev/null || true
    if ((prompt_row > 0)); then
      tput cud "$prompt_row" >&2 2>/dev/null || printf '\033[%dB' "$prompt_row" >&2
    fi
    tput cr >&2 2>/dev/null || printf '\r' >&2
  else
    tput cup "$prompt_row" 0 >&2 2>/dev/null || true
  fi
}

mib_ac_read_key() {
  local key='' seq=''
  IFS= read -rsn1 key </dev/tty || {
    printf 'EOF'
    return
  }
  [[ -z "$key" ]] && {
    printf 'ENTER'
    return
  }
  if [[ "$key" == $'\033' ]]; then
    IFS= read -rsn1 -t 0.08 seq </dev/tty 2>/dev/null || {
      printf 'ESC'
      return
    }
    if [[ "$seq" == '[' || "$seq" == 'O' ]]; then
      local tail=''
      IFS= read -rsn1 -t 0.08 tail </dev/tty 2>/dev/null || true
      # Consume any remaining parameter bytes until the final letter.
      # Some terminals send longer sequences like \033[1;2A (Shift+Arrow)
      # or \033[5~ (Page Up). Without this, leftover bytes leak to screen.
      while [[ -n "$tail" && ! "$tail" =~ [A-Za-z~] ]]; do
        IFS= read -rsn1 -t 0.01 tail </dev/tty 2>/dev/null || { tail=''; break; }
      done
      case "$tail" in A) printf 'UP' ;; B) printf 'DOWN' ;; C) printf 'RIGHT' ;; D) printf 'LEFT' ;; H) printf 'HOME' ;; F) printf 'END' ;; *) printf 'ESC' ;; esac
    else
      printf 'ESC'
    fi
    return
  fi
  [[ "$key" == $'\177' || "$key" == $'\010' ]] && {
    printf 'BACKSPACE'
    return
  }
  printf '%s' "$key"
}

mib_ac_read_filter() {
  local q='' ch
  printf '\r\033[K  > Filter: ' >&2
  while :; do
    ch="$(mib_ac_read_key)"
    case "$ch" in
    ENTER) break ;;
    ESC)
      q=''
      break
      ;;
    BACKSPACE) q="${q%?}" ;;
    EOF)
      q=''
      break
      ;;
    *) [[ ${#ch} -eq 1 ]] && q+="$ch" ;;
    esac
    printf '\r\033[K  > Filter: %s' "$q" >&2
  done
  printf '\n' >&2
  printf '%s' "$q"
}

mib_ac_list_dirs() {
  local dir="${1:-}" hidden="${2:-0}" p
  local -a out=()
  if ((hidden)); then
    while IFS= read -r -d '' p; do [[ -d "$p" || -L "$p" ]] && out+=("$p"); done \
      < <(find "$dir" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) -print0 2>/dev/null)
  else
    while IFS= read -r -d '' p; do [[ -d "$p" || -L "$p" ]] && out+=("$p"); done \
      < <(find "$dir" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) ! -name '.*' -print0 2>/dev/null)
  fi
  ((${#out[@]})) && printf '%s\0' "${out[@]}"
}

mib_ac_abs_path() {
  if command -v realpath >/dev/null 2>&1; then
    realpath "${1:-}"
  else
    (cd "$(dirname "${1:-}")" && printf '%s/%s\n' "$(pwd -P)" "$(basename "${1:-}")")
  fi
}

_mib_ac_descend() {
  local p="${1:-}" rp='' v
  [[ -d "$p" ]] || {
    msg_warning "Not a directory."
    return 1
  }
  rp="$(mib_ac_abs_path "$p")" || return 1
  for v in ${visited[@]+"${visited[@]}"}; do
    [[ "$v" == "$rp" ]] && {
      msg_warning "Loop prevented: already visited."
      return 1
    }
  done
  visited+=("$rp")
  cur_dir="$rp"
  SELECTED_INDEX=0
  filter=''
}

mib_ac_prompt_path() {
  local default="${1:-/}" answer=''
  printf 'Enter directory path [%s]: ' "$default" >&2
  IFS= read -r answer </dev/tty || return 1
  printf '%s' "${answer:-$default}"
}

_mib_ac_act() {
  local kind="${1:-}" path="${2:-}" cp=''
  case "$kind" in
  select)
    chosen="$path"
    return 0
    ;;
  up)
    cur_dir="$(dirname "$cur_dir")"
    SELECTED_INDEX=0
    filter=''
    return 1
    ;;
  custom)
    cp="$(mib_ac_prompt_path "$cur_dir")" || return 1
    if [[ -d "$cp" ]]; then
      chosen="$(mib_ac_abs_path "$cp")"
      return 0
    fi
    msg_warning "Not a directory: $cp"
    return 1
    ;;
  dir | symlink)
    _mib_ac_descend "$path"
    return 1
    ;;
  *) return 1 ;;
  esac
}

mib_ac_pick_dir_plain() {
  local label="${1:-Select directory}" cur_dir="${2:-${HOME:-/}}" answer='' p base i
  local -a entries=()
  while :; do
    entries=()
    while IFS= read -r -d '' p; do entries+=("$p"); done < <(mib_ac_list_dirs "$cur_dir" 0)
    printf '\n%s\nCurrent: %s\n  0) select this folder\n  u) up  c) custom path  q) cancel\n' "$label" "$cur_dir" >&2
    for i in ${entries[@]+"${!entries[@]}"}; do
      base="$(basename "${entries[$i]}")"
      p="${entries[$i]}"
      if [[ -L "$p" ]]; then
        printf '  %d) %s %s\n' "$((i + 1))" "$MIB_AC_SYMLINK" "$base" >&2
      else
        printf '  %d) %s %s\n' "$((i + 1))" "$MIB_AC_DIR" "$base" >&2
      fi
    done
    printf 'Choice: ' >&2
    IFS= read -r answer </dev/tty || return 1
    case "$answer" in
    0)
      printf '%s\n' "$cur_dir"
      return 0
      ;;
    u | U) [[ "$cur_dir" != / ]] && cur_dir="$(dirname "$cur_dir")" ;;
    c | C)
      p="$(mib_ac_prompt_path "$cur_dir")" || continue
      [[ -d "$p" ]] && cur_dir="$(mib_ac_abs_path "$p")" || msg_warning "Not a directory: $p"
      ;;
    q | Q) return 1 ;;
    *)
      if [[ "$answer" =~ ^[0-9]+$ ]] && ((answer >= 1 && answer <= ${#entries[@]})); then cur_dir="$(mib_ac_abs_path "${entries[$((answer - 1))]}")"; else msg_warning "Invalid choice."; fi
      ;;
    esac
  done
}

mib_ac_pick_dir() {
  [[ -t 0 && -t 2 ]] || return 1
  mib_ac_init_terminal
  mib_ac_hide_cursor
  local label="${1:-Select directory}" start="${2:-${HOME:-/}}"
  # Save terminal settings and disable echoing so held-key escape fragments
  # never appear on screen between read calls.
  local _ac_old_stty=''
  _ac_old_stty=$(stty -g </dev/tty 2>/dev/null) || _ac_old_stty=''
  stty -echo </dev/tty 2>/dev/null || true
  if [[ "$MIB_AC_TERM_MODE" != full ]]; then
    [[ -n "${_ac_old_stty:-}" ]] && stty "$_ac_old_stty" </dev/tty 2>/dev/null || true
    mib_ac_show_cursor
    mib_ac_pick_dir_plain "$label" "$start"
    return $?
  fi

  local cur_dir="$start" filter='' show_hidden=0 SELECTED_INDEX=0 chosen=''
  local -a visited=() disp=() paths=() kinds=() entries=() fdisp=() fpaths=() fkinds=()
  local dims AC_COLS=0 AC_ROWS=0 inner=1 total=0 vis=1 win=0 i p base kind lab lock prefix key
  local selected_kind selected_path footer shown=0 above=0 below=0 menu_prompt_row=0
  local needs_redraw=1 rendered_cols=0 rendered_rows=0 old_index new_index new_win

  MIB_AC_MENU_SAVED=0
  if [[ "$MIB_AC_TERM_MODE" == full ]]; then
    tput sc >&2 2>/dev/null && MIB_AC_MENU_SAVED=1
  fi

  # Query cursor row so vis accounts for banners/messages already printed
  # above us, without clearing the screen.
  local _ac_start_row=1
  printf '\033[6n' >/dev/tty 2>/dev/null
  local _dsr=''
  IFS= read -rs -d 'R' -t 0.1 _dsr </dev/tty 2>/dev/null || true
  _ac_start_row="${_dsr#*\[}"
  _ac_start_row="${_ac_start_row%%;*}"
  [[ "$_ac_start_row" =~ ^[0-9]+$ ]] || _ac_start_row=1

  while :; do
    dims="$(mib_ac_term_size)"
    AC_COLS="${dims%% *}"
    AC_ROWS="${dims##* }"

    if ((AC_COLS != rendered_cols || AC_ROWS != rendered_rows)); then needs_redraw=1; fi

    if ((AC_COLS < 24 || AC_ROWS < 10)); then
      MIB_AC_MENU_SAVED=0
      [[ -n "${_ac_old_stty:-}" ]] && stty "$_ac_old_stty" </dev/tty 2>/dev/null || true
      mib_ac_show_cursor
      mib_ac_pick_dir_plain "$label" "$cur_dir"
      return $?
    fi

    if ((needs_redraw)); then
      inner=$((AC_COLS - 3))
      disp=("$MIB_AC_SEL Select this folder: $cur_dir")
      paths=("$cur_dir")
      kinds=("select")
      if [[ "$cur_dir" != / ]]; then
        disp+=(".. (up one level)")
        paths+=("__UP__")
        kinds+=("up")
      fi

      entries=()
      while IFS= read -r -d '' p; do entries+=("$p"); done < <(mib_ac_list_dirs "$cur_dir" "$show_hidden")
      for p in ${entries[@]+"${entries[@]}"}; do
        base="$(basename "$p")"
        kind='dir'
        [[ -L "$p" ]] && kind='symlink'
        lock=0
        [[ ! -r "$p" || ! -x "$p" ]] && lock=1
        if [[ "$kind" == symlink ]]; then
          lab="$MIB_AC_SYMLINK $base"
          lab+=" $MIB_AC_LINK $(readlink "$p" 2>/dev/null || true)"
        else
          lab="$MIB_AC_DIR $base"
        fi
        ((lock)) && lab+=" $MIB_AC_LOCK"
        disp+=("$lab")
        paths+=("$p")
        kinds+=("$kind")
      done
      disp+=("[ Type a custom path$MIB_AC_ELL ]")
      paths+=("__CUSTOM__")
      kinds+=("custom")

      fdisp=()
      fpaths=()
      fkinds=()
      for i in ${disp[@]+"${!disp[@]}"}; do
        kind="${kinds[$i]}"
        if [[ -z "$filter" || "$kind" == select || "$kind" == up || "$kind" == custom || "${disp[$i],,}" == *"${filter,,}"* ]]; then
          fdisp+=("${disp[$i]}")
          fpaths+=("${paths[$i]}")
          fkinds+=("$kind")
        fi
      done
      total=${#fdisp[@]}
      if ((total == 0)); then
        filter=''
        continue
      fi
      ((SELECTED_INDEX < 0)) && SELECTED_INDEX=0
      ((SELECTED_INDEX >= total)) && SELECTED_INDEX=$((total - 1))

      vis=$((AC_ROWS - _ac_start_row - 7))
      ((vis < 1)) && vis=1
      win=$((SELECTED_INDEX / vis * vis))
      above=0
      below=0
      ((win > 0)) && above=1
      ((win + vis < total)) && below=1
      shown=$((total - win))
      ((shown > vis)) && shown=$vis
      menu_prompt_row=$((3 + above + shown + below + 2))

      if [[ "$MIB_AC_TERM_MODE" == full ]]; then
        if [[ "${MIB_AC_MENU_SAVED:-0}" -eq 1 ]]; then
          tput rc >&2 2>/dev/null || true
          tput ed >&2 2>/dev/null || printf '\033[J' >&2
        else
          mib_ac_clear_screen
        fi
      fi

      mib_ac_box_top
      mib_ac_box_title "$label"
      mib_ac_box_row "  $cur_dir" 0 1
      ((above)) && mib_ac_box_row "  $MIB_AC_UP more above" 0 1
      for ((i = win; i < win + shown; i++)); do
        prefix='   '
        ((i == SELECTED_INDEX)) && prefix=" $MIB_AC_ARR "
        mib_ac_box_row "$prefix${fdisp[$i]}" 0 0
      done
      ((below)) && mib_ac_box_row "  $MIB_AC_DOWN more below" 0 1
      mib_ac_box_bottom
      footer='Up/Dn move  Enter open  s select  Left up  / filter  h hidden  ~ home  q quit'
      printf ' %s\n' "$(mib_ac_truncate "$footer" "$((AC_COLS - 2))")" >&2

      rendered_cols=$AC_COLS
      rendered_rows=$AC_ROWS
      needs_redraw=0
    fi

    key="$(mib_ac_read_key)"
    case "$key" in
    UP | k | K)
      old_index=$SELECTED_INDEX
      new_index=$((SELECTED_INDEX - 1))
      ((new_index < 0)) && new_index=0
      if ((new_index != old_index)); then
        new_win=$((new_index / vis * vis))
        SELECTED_INDEX=$new_index
        if ((new_win == win)); then
          mib_ac_draw_pointer "$old_index" "$win" 0 "$menu_prompt_row"
          mib_ac_draw_pointer "$new_index" "$win" 1 "$menu_prompt_row"
        else
          needs_redraw=1
        fi
      fi
      ;;
    DOWN | j | J)
      old_index=$SELECTED_INDEX
      new_index=$((SELECTED_INDEX + 1))
      ((new_index >= total)) && new_index=$((total - 1))
      if ((new_index != old_index)); then
        new_win=$((new_index / vis * vis))
        SELECTED_INDEX=$new_index
        if ((new_win == win)); then
          mib_ac_draw_pointer "$old_index" "$win" 0 "$menu_prompt_row"
          mib_ac_draw_pointer "$new_index" "$win" 1 "$menu_prompt_row"
        else
          needs_redraw=1
        fi
      fi
      ;;

    ENTER | RIGHT)
      selected_kind="${fkinds[$SELECTED_INDEX]:-}"
      selected_path="${fpaths[$SELECTED_INDEX]:-}"
      if [[ "$selected_kind" == dir || "$selected_kind" == symlink ]]; then
        _mib_ac_descend "$selected_path" || true
      else
        _mib_ac_act "$selected_kind" "$selected_path" && break
      fi
      needs_redraw=1
      ;;
    LEFT | BACKSPACE)
      if [[ -n "$filter" ]]; then
        filter=''
        needs_redraw=1
      elif [[ "$cur_dir" != / ]]; then
        cur_dir="$(dirname "$cur_dir")"
        SELECTED_INDEX=0
        needs_redraw=1
      fi
      ;;
    s | S | ' ')
      selected_kind="${fkinds[$SELECTED_INDEX]:-}"
      selected_path="${fpaths[$SELECTED_INDEX]:-}"
      if [[ "$selected_kind" == dir || "$selected_kind" == symlink ]]; then
        if [[ -d "$selected_path" ]]; then
          chosen="$(mib_ac_abs_path "$selected_path")"
          break
        else
          msg_warning "Not a directory."
        fi
      else
        _mib_ac_act "$selected_kind" "$selected_path" && break
      fi
      needs_redraw=1
      ;;
    / | f | F)
      filter="$(mib_ac_read_filter)"
      SELECTED_INDEX=0
      needs_redraw=1
      ;;
    h | H)
      show_hidden=$((1 - show_hidden))
      SELECTED_INDEX=0
      needs_redraw=1
      ;;
    '~')
      cur_dir="${HOME:-/}"
      SELECTED_INDEX=0
      filter=''
      needs_redraw=1
      ;;
    q | Q | EOF)
      MIB_AC_MENU_SAVED=0
      [[ -n "${_ac_old_stty:-}" ]] && stty "$_ac_old_stty" </dev/tty 2>/dev/null || true
      mib_ac_show_cursor
      return 1
      ;;
    ESC) : ;;
    *) : ;;
    esac
  done
  MIB_AC_MENU_SAVED=0
  [[ -n "${_ac_old_stty:-}" ]] && stty "$_ac_old_stty" </dev/tty 2>/dev/null || true
  mib_ac_show_cursor
  [[ -n "$chosen" ]] && printf '%s\n' "$chosen"
}

#  7.  HELP & VERSION
show_help() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  uk_help_section "$w" "USAGE" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} _move_in_batch.sh ${UK_C_YELLOW:-}-t <target>${UK_C_RESET:-} ${UK_C_GREEN:-}-o <output>${UK_C_RESET:-} ${UK_C_DIM:-}[flags]${UK_C_RESET:-}" "" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} _move_in_batch.sh ${UK_C_DIM:-}-i  (launch interactive picker)${UK_C_RESET:-}" ""
  uk_help_section "$w" "Flags" \
    "-t, --target DIR" "Source directory (required)" \
    "-o, --output DIR" "Destination directory (required)" \
    "-e, --exclude" "Extensions/patterns to skip" \
    "-f, --flatten" "Strip subdirectory structure" \
    "-m, --method" "Transfer method: cp (default) or mv" \
    "-i, --interactive" "Launch interactive directory picker" \
    "-h, --help" "Show this help"
  printf '\n'
  uk_help_section "$w" "Examples" \
    "${UK_C_GREEN:-}bash _move_in_batch.sh${UK_C_RESET:-} ${UK_C_YELLOW:-}-t ~/src -o ~/out${UK_C_RESET:-} ${UK_C_DIM:-}-e .md .git${UK_C_RESET:-}" "Copy files, excluding .md & .git, preserve structure" \
    "${UK_C_GREEN:-}bash _move_in_batch.sh${UK_C_RESET:-} ${UK_C_YELLOW:-}-t ~/src -o ~/out${UK_C_RESET:-} ${UK_C_DIM:-}-f -m=mv${UK_C_RESET:-}" "Move files, flatten subdirectories" \
    "${UK_C_GREEN:-}bash _move_in_batch.sh${UK_C_RESET:-} ${UK_C_DIM:-}--target ~/src --output ~/out --flatten --method=mv --exclude .git .md${UK_C_RESET:-}" "Same but using long flags" \
    "${UK_C_GREEN:-}bash _move_in_batch.sh${UK_C_RESET:-} ${UK_C_DIM:-}-i${UK_C_RESET:-}" "Launch interactive directory picker"
  printf '\n'
  uk_help_section "$w" "Notes" \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}⚠${UK_C_RESET:-} ${UK_C_BOLD:-}Default method is cp (copy) for safety.${UK_C_RESET:-}" "" \
    "${UK_C_YELLOW:-}⚠${UK_C_RESET:-} ${UK_C_DIM:-}Use -m=mv only if you intend to move/delete originals.${UK_C_RESET:-}" ""
}
show_version() {
  printf "%s %s\n" \
    "$(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$MIB_SCRIPT_NAME")" \
    "$(colorize "$MIB_C_GREEN" "v${UK_VERSION}")"
  printf "%s\n" "$(colorize "$MIB_C_DIM" "$MIB_SCRIPT_URL")"
  printf "\n"
  printf "  Bash:          %s\n" "${BASH_VERSION}"
  printf "  Unicode:       %s\n" "$([[ "$MIB_CAP_USE_UNICODE" == true ]] && echo "enabled" || echo "disabled")"
  printf "  Color:         %s\n" "$([[ "$MIB_CAP_USE_COLOR" == true ]] && echo "enabled" || echo "disabled")"
  printf "  Interactive:   %s\n" "$([[ "$MIB_CAP_IS_INTERACTIVE" == true ]] && echo "yes" || echo "no")"
}
#  8.  EXCLUSION CHECK & GROUPING
_exclusion_group() {
  local filepath="${1:-}"
  local basename
  basename="${filepath##*/}"
  shift
  local exts=("$@")
  for ext in "${exts[@]}"; do
    local clean_ext="${ext#.}"
    # Path-component match first (e.g. ".git" matches ".git/config" or
    # "sub/.git/objects/…")
    if [[ "/${filepath}" == *"/${clean_ext}/"* || "/${filepath}" == *"/${ext}"* ]]; then
      printf '%s' "${ext}"
      return 0
    fi
    # Basename match (e.g. ".md" matches "readme.md")
    if [[ "$basename" == *"$ext" ]]; then
      printf '%s' "${basename}"
      return 0
    fi
  done
  return 1
}
_is_excluded() {
  local filepath="${1:-}"
  local basename
  basename="${filepath##*/}"
  shift
  local exts=("$@")
  for ext in "${exts[@]}"; do
    if [[ "$basename" == *"$ext" ]]; then
      return 0
    fi
    if [[ "/${filepath}" == *"/${ext#.}/"* || "/${filepath}" == *"/${ext}"* ]]; then
      return 0
    fi
  done
  return 1
}
#  9. MAIN  —  move_in_batch
move_in_batch() {
  init_terminal_caps
  init_colors
  init_icons
  local target=""
  local output=""
  local exclude=()
  MIB_FLATTEN_MODE=false
  MIB_METHOD="cp"

  # ---- rollback tracking ----
  declare -ga ROLLBACK_SRC=()
  declare -ga ROLLBACK_DST=()

  # ---- parse flags ----
  local INTERACTIVE_MODE=false
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    -i | --interactive)
      INTERACTIVE_MODE=true
      shift
      ;;
    -t | --target)
      target="$(_expand_tilde "${2:-}")"
      shift 2
      ;;
    -o | --output)
      output="$(_expand_tilde "${2:-}")"
      shift 2
      ;;
    -e | --exclude)
      shift
      while [[ $# -gt 0 && ! "${1:-}" =~ ^- ]]; do
        exclude+=("${1:-}")
        shift
      done
      ;;
    -f | --flatten)
      MIB_FLATTEN_MODE=true
      shift
      ;;
    -m=* | --method=*)
      MIB_METHOD="${1#*=}"
      shift
      ;;
    -m | --method)
      MIB_METHOD="${2:-}"
      shift 2
      ;;
    -h | --help)
      show_help
      return 0
      ;;
    -v | --version)
      show_version
      return 0
      ;;
    *)
      msg_error "Unknown option: ${1:-}"
      msg_info "Use -h or --help for usage."
      return 1
      ;;
    esac
  done

  # ---- Interactive Wizard if no target/output provided ----
  if [[ -z "$target" && -z "$output" ]] || [[ "$INTERACTIVE_MODE" == true ]]; then
    if [[ "$MIB_CAP_IS_INTERACTIVE" == false ]]; then
      msg_error "Non-interactive environment detected and no parameters supplied."
      msg_info "Usage: $0 -t <target_dir> -o <output_dir> [flags]"
      return 1
    fi

    uk_section_title "Interactive Configuration"

    msg_info "Step 1 of 2 — choose the SOURCE directory (files to move/copy)."
    target="$(mib_ac_pick_dir "Select SOURCE directory" "${HOME:-/}")" || {
      mib_ac_show_cursor
      msg_warning "Selection cancelled."
      return 1
    }
    [[ -n "$target" ]] || {
      mib_ac_show_cursor
      return 1
    }

    msg_info "Step 2 of 2 — choose the DESTINATION directory."
    output="$(mib_ac_pick_dir "Select DESTINATION directory" "${HOME:-/}")" || {
      mib_ac_show_cursor
      msg_warning "Selection cancelled."
      return 1
    }
    [[ -n "$output" ]] || {
      mib_ac_show_cursor
      return 1
    }

    # Optional: ask for method
    printf "\n  %s  Transfer method: cp (copy) or mv (move)? [cp] \n  %s " \
      "$(colorize "$MIB_C_BLUE_BRIGHT" "$MIB_I_ARROW")" "$(colorize "$MIB_C_DIM" "> ")"
    local method_choice=''
    read -r method_choice
    if [[ "$method_choice" == "mv" || "$method_choice" == "move" ]]; then
      MIB_METHOD="mv"
    fi

    # Optional: ask for flatten
    printf "  %s  Flatten subdirectory structure? [y/N] \n  %s " \
      "$(colorize "$MIB_C_BLUE_BRIGHT" "$MIB_I_ARROW")" "$(colorize "$MIB_C_DIM" "> ")"
    local flatten_choice=''
    read -r flatten_choice
    if [[ "$flatten_choice" == "y" || "$flatten_choice" == "Y" ]]; then
      MIB_FLATTEN_MODE=true
    fi
  fi

  # ---- validate flags ----
  if [[ -z "$target" ]]; then
    msg_error "Target directory (-t) is required."
    return 1
  fi
  if [[ -z "$output" ]]; then
    msg_error "Output directory (-o) is required."
    return 1
  fi
  if [[ ! -d "$target" ]]; then
    msg_error "Target directory does not exist: $target"
    return 1
  fi

  # ---- validate method ----
  if [[ "$MIB_METHOD" != "cp" && "$MIB_METHOD" != "mv" ]]; then
    msg_warning "Unknown method '$MIB_METHOD' — falling back to 'cp' (copy)."
    MIB_METHOD="cp"
  fi

  local method_verb="Copying"
  local method_label="copy (cp)"
  if [[ "$MIB_METHOD" == "mv" ]]; then
    method_verb="Moving"
    method_label="move  (mv)"
  fi

  mkdir -p "$output" || { msg_error "Unable to create output directory: $output"; return 1; }

  # Resolve once, reuse for both checks.
  local real_target real_output
  real_target="$(realpath "$target" 2>&1)" || { msg_error "Unable to resolve source directory: $real_target"; return 1; }
  real_output="$(realpath "$output" 2>&1)" || { msg_error "Unable to resolve output directory: $real_output"; return 1; }

  # ---- same-directory guard ----
  if [[ "$real_target" == "$real_output" ]]; then
    msg_error "Target and output directories are the same. Refusing to transfer."
    return 1
  fi

  # Refuse destination nesting inside the source tree; otherwise a re-run can
  # recursively copy/move the previous output back into itself.
  if [[ "$real_output" == "$real_target"/* ]]; then
    msg_error "Output directory must not be inside the source directory: $output"
    return 1
  fi

  # ---- scan files ----
  msg_working "Scanning for files in $(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$target") ..."

  local files=()
  local total_size=0
  # Prefer GNU find's -printf for size+path in one syscall pass.
  # Use NUL-delimited field pairs and a checked scan file so traversal errors propagate.
  local scan_file probe_file probe_error='' filepath file_size
  scan_file="$(mktemp)" || { msg_error "Unable to create transfer scan file."; return 1; }
  probe_file="$(mktemp)" || { rm -f "$scan_file"; msg_error "Unable to create find probe log."; return 1; }
  if find "$target" -maxdepth 0 -printf '' >/dev/null 2>"$probe_file"; then
    rm -f "$probe_file" || { rm -f "$scan_file"; return 1; }
    if ! find "$target" -type f -printf '%s\0%p\0' >"$scan_file"; then
      rm -f "$scan_file"
      msg_error "Source traversal failed; refusing a partial transfer list."
      return 1
    fi
  else
    probe_error="$(cat "$probe_file")" || probe_error='unable to read find probe error'
    rm -f "$probe_file" || { rm -f "$scan_file"; return 1; }
    [[ -n "$probe_error" ]] && msg_warning "GNU find -printf unavailable; using portable stat scan: $probe_error"
    local path_file
    path_file="$(mktemp)" || { rm -f "$scan_file"; return 1; }
    if ! find "$target" -type f -print0 >"$path_file"; then
      rm -f "$scan_file" "$path_file"
      msg_error "Source traversal failed; refusing a partial transfer list."
      return 1
    fi
    while IFS= read -r -d '' filepath; do
      if file_size="$(stat -c '%s' "$filepath" 2>&1)"; then
        :
      elif file_size="$(stat -f '%z' "$filepath" 2>&1)"; then
        :
      else
        rm -f "$scan_file" "$path_file"
        msg_error "Unable to read file size: $filepath ($file_size)"
        return 1
      fi
      printf '%s\0%s\0' "$file_size" "$filepath" >>"$scan_file" || return 1
    done <"$path_file"
    rm -f "$path_file" || { rm -f "$scan_file"; return 1; }
  fi
  while IFS= read -r -d '' file_size && IFS= read -r -d '' filepath; do
    [[ "$file_size" =~ ^[0-9]+$ ]] || { rm -f "$scan_file"; msg_error "Invalid file size for: $filepath"; return 1; }
    files+=("$filepath")
    total_size=$((total_size + file_size))
  done <"$scan_file"
  rm -f "$scan_file" || { msg_error "Unable to remove transfer scan file."; return 1; }

  local total_files=${#files[@]}

  if ((total_files == 0)); then
    msg_warning "No files found in $(colorize "$MIB_C_BOLD" "$target")"
    uk_section_title "Operation Summary — Nothing to process"
    printf "  %s  0 files processed\n" "$(colorize "$MIB_C_GREEN" "$MIB_I_TICK")"
    return 0
  fi

  # ---- classify files (with in-memory destination tracking for collisions) ----
  local dests=()
  local skipped_excluded=0
  local collision_count=0
  declare -A _seen_dests=()      # track assigned destinations to avoid collisions
  declare -A _excluded_groups=() # group_label → count, for compact display

  for file in "${files[@]}"; do
    local basename
    basename="${file##*/}"
    local rel_path
    rel_path="${file#"$target"}"
    rel_path="${rel_path#/}"

    local group_label
    if group_label="$(_exclusion_group "$rel_path" "${exclude[@]}")"; then
      dests+=("__SKIP__:${group_label}")
      _excluded_groups["$group_label"]=$((${_excluded_groups["$group_label"]:-0} + 1))
      skipped_excluded=$((skipped_excluded + 1))
      continue
    fi

    local dest
    if $MIB_FLATTEN_MODE; then
      local candidate="${output}/${basename}"
      if [[ -e "$candidate" ]] || [[ -n "${_seen_dests[$candidate]:-}" ]]; then
        local name="${basename%.*}"
        local ext="${basename##*.}"
        if [[ "$name" == "$ext" ]]; then ext=""; else ext=".${ext}"; fi
        local c=1
        while true; do
          candidate="${output}/${name}_${c}${ext}"
          if [[ ! -e "$candidate" ]] && [[ -z "${_seen_dests[$candidate]:-}" ]]; then
            break
          fi
          c=$((c + 1))
        done
        collision_count=$((collision_count + 1))
      fi
      dest="$candidate"
    else
      local parent_dir="${rel_path%/*}"
      if [[ "$parent_dir" == "$rel_path" ]]; then
        parent_dir=""
      fi
      local dest_dir="$output"
      [[ -n "$parent_dir" ]] && dest_dir="${output}/${parent_dir}"
      mkdir -p "$dest_dir" || { msg_error "Unable to create destination directory: $dest_dir"; return 1; }

      local candidate="${dest_dir}/${basename}"
      if [[ -e "$candidate" ]] || [[ -n "${_seen_dests[$candidate]:-}" ]]; then
        local name="${basename%.*}"
        local ext="${basename##*.}"
        if [[ "$name" == "$ext" ]]; then ext=""; else ext=".${ext}"; fi
        local c=1
        while true; do
          candidate="${dest_dir}/${name}_${c}${ext}"
          if [[ ! -e "$candidate" ]] && [[ -z "${_seen_dests[$candidate]:-}" ]]; then
            break
          fi
          c=$((c + 1))
        done
        collision_count=$((collision_count + 1))
      fi
      dest="$candidate"
    fi
    _seen_dests["$dest"]=1
    dests+=("$dest")
  done
  unset _seen_dests

  local active_count=$((total_files - skipped_excluded))

  # ---- BANNER & PREVIEW ----
  local mode_tags=""
  if $MIB_FLATTEN_MODE; then
    mode_tags+="$(colorize "$MIB_C_MAGENTA" " [flatten]")"
  fi

  uk_section_title "Batch Move Operation"

  msg_info "Source:      $(colorize "$MIB_C_BOLD" "$target")"
  msg_info "Output:      $(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$output")"
  msg_info "Method:      $(colorize "$MIB_C_BLUE" "$method_label")$mode_tags"
  msg_info "Files found: $(colorize "${MIB_C_BOLD}${MIB_C_WHITE}" "$total_files")"
  msg_info "Total size:  $(colorize "$MIB_C_DIM" "$(format_size "$total_size")")"

  if ((skipped_excluded > 0)); then
    msg_info "Excluded:    $(colorize "$MIB_C_DIM" "$skipped_excluded") file(s)"
  fi
  if ((collision_count > 0)); then
    msg_warning "Collisions:  $(colorize "$MIB_C_YELLOW_BRIGHT" "$collision_count") file(s) will be auto-renamed (_1, _2, …)"
  fi

  if ((active_count == 0)); then
    printf "\n"
    msg_warning "All files were excluded — nothing to do."
    return 0
  fi

  # ---- file preview ----
  printf "\n"
  printf "  %s  %s %s\n" \
    "$(colorize "$MIB_C_BLUE_BRIGHT" "$MIB_I_COLLAPSED")" \
    "$(colorize "$MIB_C_BOLD" "Preview")" \
    "$(colorize "$MIB_C_DIM" "(showing up to 10 files):")"

  local preview_max_transfers=7
  local preview_max_groups=3
  local shown=0

  # (A) Show transfer previews first
  local idx=0
  while ((idx < total_files && shown < preview_max_transfers)); do
    local d="${dests[$idx]}"
    if [[ "$d" != __SKIP__:* ]]; then
      local fn
      fn="${files[$idx]##*/}"
      local dn
      dn="${d##*/}"
      printf "    %s %s %s %s\n" \
        "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
        "$(colorize "$MIB_C_GRAY" "$fn")" \
        "$(colorize "$MIB_C_CYAN" " ──→ ")" \
        "$(colorize "$MIB_C_GREEN_BRIGHT" "$dn")"
      shown=$((shown + 1))
    fi
    idx=$((idx + 1))
  done

  # Count unshown transfers
  local unshown_transfers=0
  while ((idx < total_files)); do
    local d="${dests[$idx]}"
    [[ "$d" != __SKIP__:* ]] && unshown_transfers=$((unshown_transfers + 1))
    idx=$((idx + 1))
  done

  # (B) Show excluded groups (compact)
  local group_shown=0
  for grp in "${!_excluded_groups[@]}"; do
    ((group_shown >= preview_max_groups)) && break
    local cnt="${_excluded_groups[$grp]}"
    if ((cnt == 1)); then
      printf "    %s %s %s\n" \
        "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
        "$(colorize "$MIB_C_GRAY" "$grp")" \
        "$(colorize "$MIB_C_YELLOW" "(excluded)")"
    else
      printf "    %s %s %s\n" \
        "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
        "$(colorize "$MIB_C_GRAY" "$grp")" \
        "$(colorize "$MIB_C_YELLOW" "(${cnt} files excluded)")"
    fi
    group_shown=$((group_shown + 1))
  done

  # Count unshown groups for the "and more" line
  local total_groups=${#_excluded_groups[@]}
  local total_remaining=$((unshown_transfers + (total_groups > preview_max_groups ? total_groups - preview_max_groups : 0)))
  if ((total_remaining > 0)); then
    printf "    %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ELLIPSIS} and ${total_remaining} more")"
  fi

  printf "\n"

  # ---- interactive confirmation ----
  if [[ "$MIB_CAP_IS_INTERACTIVE" == true ]]; then
    local proceed=""
    printf "  %s  Proceed with %s? %s %s" \
      "$(colorize "${MIB_C_BOLD}${MIB_C_YELLOW}" "$MIB_I_PLAY")" \
      "$(colorize "$MIB_C_BOLD" "$method_verb $active_count file(s)")" \
      "$(colorize "$MIB_C_GREEN" "[Y/n]")" \
      "$(colorize "$MIB_C_DIM" "> ")"
    read -r proceed
    case "${proceed,,}" in
    n | no)
      printf "\n"
      msg_warning "Operation cancelled by user."
      return 0
      ;;
    esac
    printf "\n"
  fi

  # ---- processing ----
  local success_count=0
  local failed_count=0
  local skipped_conflict=0
  local processed_files=()
  local failed_files=()
  local skipped_list=()

  local start_time
  start_time=$(date +%s)

  # ---- Ctrl+C handler with rollback ----
  handle_interrupt() {
    trap - SIGINT
    printf "\n\n"
    msg_warning "Process interrupted by user (Ctrl+C)!"

    local count=${#ROLLBACK_SRC[@]}
    if ((count == 0)); then
      msg_info "No files were transferred yet. Exiting safely."
      exit 130
    fi

    printf "  %s  %d file(s) have already been transferred.\n" \
      "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")" "$count"

    if [[ "$MIB_CAP_IS_INTERACTIVE" == true ]]; then
      local rb_choice=""
      printf "  %s  Roll back these changes? %s %s" \
        "$(colorize "${MIB_C_BOLD}${MIB_C_YELLOW}" "$MIB_I_SEARCH")" \
        "$(colorize "$MIB_C_GREEN" "[Y/n]")" \
        "$(colorize "$MIB_C_DIM" "> ")"
      read -r rb_choice
      case "${rb_choice,,}" in
      y | yes | "")
        msg_working "Rolling back changes..."
        local rb_fails=0
        for ((i = ${#ROLLBACK_SRC[@]} - 1; i >= 0; i--)); do
          local r_src="${ROLLBACK_SRC[$i]}"
          local r_dst="${ROLLBACK_DST[$i]}"
          if [[ -e "$r_dst" ]]; then
            if [[ "$MIB_METHOD" == "mv" ]]; then
              mv -- "$r_dst" "$r_src" || rb_fails=$((rb_fails + 1))
            else
              rm -f "$r_dst" || rb_fails=$((rb_fails + 1))
            fi
          fi
        done
        if ((rb_fails > 0)); then
          msg_error "Rollback completed with $rb_fails error(s)."
        else
          msg_success "Rollback successful. Output directory restored."
        fi
        ;;
      *)
        msg_info "Keeping transferred files. Exiting."
        ;;
      esac
    fi
    exit 130
  }

  msg_working "Processing $(colorize "$MIB_C_BOLD" "$active_count") file(s)..."
  printf "\n"

  local progress_current=0

  trap 'handle_interrupt' SIGINT

  for ((idx = 0; idx < total_files; idx++)); do
    local src="${files[$idx]}"
    local dst="${dests[$idx]}"
    local src_name
    src_name="${src##*/}"

    # Skip excluded files (already counted in _excluded_groups)
    if [[ "$dst" == __SKIP__:* ]]; then
      continue
    fi

    progress_current=$((progress_current + 1))
    draw_progress "$progress_current" "$active_count" "$src_name"

    # If destination already exists (e.g. from a previous partial run), skip
    if [[ -e "$dst" && "$dst" != "$src" ]]; then
      skipped_conflict=$((skipped_conflict + 1))
      skipped_list+=("$src_name (destination exists)")
      continue
    fi

    # Ensure parent directories exist
    local dst_dir
    if [[ "$dst" == */* ]]; then
      dst_dir="${dst%/*}"
    else
      dst_dir="."
    fi
    if ! mkdir -p "$dst_dir"; then
      failed_count=$((failed_count + 1))
      failed_files+=("$src_name (cannot create destination directory)")
      msg_error "Unable to create destination directory: $dst_dir"
      continue
    fi

    local op_status=0
    if [[ "$MIB_METHOD" == "cp" ]]; then
      cp -- "$src" "$dst" || op_status=$?
    else
      mv -- "$src" "$dst" || op_status=$?
    fi

    if ((op_status == 0)); then
      success_count=$((success_count + 1))
      processed_files+=("${dst##*/}")
      ROLLBACK_SRC+=("$src")
      ROLLBACK_DST+=("$dst")
    else
      failed_count=$((failed_count + 1))
      failed_files+=("$src_name (exit: ${op_status})")
      printf "%s" $'\033[2K\r'
      msg_error "Failed: $(colorize "$MIB_C_BOLD" "$src") → $(colorize "$MIB_C_BOLD" "$dst") (exit: ${op_status})"
    fi
  done

  # Final 100% draw
  draw_progress "$active_count" "$active_count" "Complete"
  printf "\n\n"

  trap - SIGINT

  # ---- summary ----
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  uk_section_title "Operation Complete — processed in $(format_duration "$duration")"

  printf "  %s  %s\n" "$(colorize "$MIB_C_GREEN" "$MIB_I_TICK")" "$(colorize "$MIB_C_BOLD" "Summary")"
  printf "\n"
  printf "    %s  Success:  %s\n" \
    "$(colorize "$MIB_C_GREEN" "$MIB_I_SUCCESS")" \
    "$(colorize "${MIB_C_BOLD}${MIB_C_GREEN}" "$success_count")"
  printf "    %s   Skipped:  %s\n" \
    "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")" \
    "$(colorize "${MIB_C_BOLD}${MIB_C_YELLOW}" "$((skipped_excluded + skipped_conflict))")"

  if ((failed_count > 0)); then
    printf "    %s  Failed:   %s\n" \
      "$(colorize "$MIB_C_RED" "$MIB_I_ERROR")" \
      "$(colorize "${MIB_C_BOLD}${MIB_C_RED}" "$failed_count")"
  fi

  if ((total_files > 0)); then
    local success_rate=$(((success_count * 100) / active_count))
    printf "    %s\n" "$(colorize "$MIB_C_DIM" "───────")"
    printf "    %s  Total:    %s  %s\n" \
      "$(colorize "$MIB_C_CYAN" "$MIB_I_LOZENGE")" \
      "$(colorize "$MIB_C_BOLD" "$active_count")" \
      "$(colorize "$MIB_C_DIM" "(${success_rate}% success)")"
  fi
  printf "\n"

  # ---- transferred list ----
  if ((${#processed_files[@]} > 0)); then
    printf "  %s  Transferred files:\n" "$(colorize "$MIB_C_GREEN" "$MIB_I_TICK")"
    local shown=0
    for f in "${processed_files[@]}"; do
      ((shown >= 10)) && break
      printf "    %s  %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" "$(colorize "$MIB_C_GREEN_BRIGHT" "$f")"
      shown=$((shown + 1))
    done
    if ((${#processed_files[@]} > 10)); then
      printf "    %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ELLIPSIS} and $((${#processed_files[@]} - 10)) more")"
    fi
    printf "\n"
  fi

  # ---- skipped list (grouped exclusions + conflict skips) ----
  if ((${#_excluded_groups[@]} > 0)) || ((${#skipped_list[@]} > 0)); then
    printf "  %s Skipped:\n" "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")"
    local shown=0

    # Excluded groups first
    for grp in "${!_excluded_groups[@]}"; do
      ((shown >= 10)) && break
      local cnt="${_excluded_groups[$grp]}"
      if ((cnt == 1)); then
        printf "    %s  %s\n" \
          "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
          "$(colorize "$MIB_C_YELLOW" "$grp (excluded)")"
      else
        printf "    %s  %s\n" \
          "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
          "$(colorize "$MIB_C_YELLOW" "$grp (${cnt} files excluded)")"
      fi
      shown=$((shown + 1))
    done

    # Conflict / already-exists skips
    for f in "${skipped_list[@]}"; do
      ((shown >= 10)) && break
      printf "    %s  %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" "$(colorize "$MIB_C_YELLOW" "$f")"
      shown=$((shown + 1))
    done

    local total_skip_entries=$((${#_excluded_groups[@]} + ${#skipped_list[@]}))
    if ((total_skip_entries > 10)); then
      printf "    %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ELLIPSIS} and $((total_skip_entries - 10)) more")"
    fi
    printf "\n"
  fi
  # ---- failed list ----
  if ((${#failed_files[@]} > 0)); then
    printf "  %s  Failed:\n" "$(colorize "$MIB_C_RED" "$MIB_I_ERROR")"
    for f in "${failed_files[@]}"; do
      printf "    %s  %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" "$(colorize "$MIB_C_RED" "$f")"
    done
    printf "\n"
  fi

  if [[ "$MIB_METHOD" == "cp" ]]; then
    msg_info "Originals preserved in: $(colorize "$MIB_C_DIM" "$target")"
    msg_info "Copies now reside in:  $(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$output")"
  else
    msg_info "Files moved from:  $(colorize "$MIB_C_DIM" "$target")"
    msg_info "Files now reside in:  $(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$output")"
  fi
  printf "\n"

  if ((failed_count > 0 && success_count > 0)); then
    return 2
  elif ((failed_count > 0)); then
    return 1
  fi
}
mib_main() {
  init_terminal_caps
  init_colors
  init_icons
  uk_banner "move-in-batch" "Bulk copy or move files with exclusions and collision-safe renaming" "" "$@"
  move_in_batch "$@"
}
#  11. ENTRY POINT
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  mib_main "$@"
fi
