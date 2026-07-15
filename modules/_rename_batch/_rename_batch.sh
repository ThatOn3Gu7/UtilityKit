#!/usr/bin/env bash
RB_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RB_SCRIPT_DIR/../../lib/uk_common.sh"

IFS=$'\n\t'

#  0.  METADATA
readonly SCRIPT_NAME="Batch File Renamer"
readonly SCRIPT_URL="https://github.com/Thaton3gu7/Utilitykit.git"

#  1.  TERMINAL CAPABILITY DETECTION
RB_CAP_USE_COLOR=false
RB_CAP_USE_UNICODE=false
RB_CAP_IS_INTERACTIVE=false
RB_TERM_WIDTH=80
OPT_ALLOW_EXCLUDED=false # Global switch for exclusion overrides

init_terminal_caps() {
  if [[ -n "${NO_COLOR:-}" ]]; then
    RB_CAP_USE_COLOR=false
  elif [[ ! -t 1 ]]; then
    RB_CAP_USE_COLOR=false
  else
    RB_CAP_USE_COLOR=true
  fi

  local is_limited=false
  if [[ -n "${ANDROID_ROOT:-}" ]] || [[ "${TERM_PROGRAM:-}" == "Termux" ]] || [[ "${TERM:-}" == "dumb" ]]; then
    is_limited=true
  fi

  if [[ ! -t 1 ]] || [[ "$is_limited" == true ]]; then
    RB_CAP_USE_UNICODE=false
  else
    RB_CAP_USE_UNICODE=true
  fi

  if [[ -t 0 ]]; then
    RB_CAP_IS_INTERACTIVE=true
  else
    RB_CAP_IS_INTERACTIVE=false
  fi

  RB_TERM_WIDTH="${COLUMNS:-$(tput cols || echo 80)}"
}
#  2.  ANSI ESCAPE CODES
RB_C_RESET=""
RB_C_BOLD=""
RB_C_DIM=""
RB_C_ITALIC=""
RB_C_UNDERLINE=""
RB_C_STRIKETHROUGH=""
RB_C_OVERLINE=""
RB_C_RED=""
RB_C_GREEN=""
RB_C_YELLOW=""
RB_C_BLUE=""
RB_C_MAGENTA=""
RB_C_CYAN=""
RB_C_WHITE=""
RB_C_GRAY=""
RB_C_RED_BRIGHT=""
RB_C_GREEN_BRIGHT=""
RB_C_YELLOW_BRIGHT=""
RB_C_BLUE_BRIGHT=""
RB_C_MAGENTA_BRIGHT=""
RB_C_CYAN_BRIGHT=""
RB_C_WHITE_BRIGHT=""
RB_C_BG_RED=""
RB_C_BG_GREEN=""
RB_C_BG_YELLOW=""
RB_C_BG_BLUE=""
RB_C_BG_CYAN=""
RB_C_BG_GRAY=""

init_colors() {
  if [[ "$RB_CAP_USE_COLOR" == false ]]; then
    RB_C_RESET=""
    RB_C_BOLD=""
    RB_C_DIM=""
    RB_C_ITALIC=""
    RB_C_UNDERLINE=""
    RB_C_STRIKETHROUGH=""
    RB_C_OVERLINE=""
    RB_C_RED=""
    RB_C_GREEN=""
    RB_C_YELLOW=""
    RB_C_BLUE=""
    RB_C_MAGENTA=""
    RB_C_CYAN=""
    RB_C_WHITE=""
    RB_C_GRAY=""
    RB_C_RED_BRIGHT=""
    RB_C_GREEN_BRIGHT=""
    RB_C_YELLOW_BRIGHT=""
    RB_C_BLUE_BRIGHT=""
    RB_C_MAGENTA_BRIGHT=""
    RB_C_CYAN_BRIGHT=""
    RB_C_WHITE_BRIGHT=""
    RB_C_BG_RED=""
    RB_C_BG_GREEN=""
    RB_C_BG_YELLOW=""
    RB_C_BG_BLUE=""
    RB_C_BG_CYAN=""
    RB_C_BG_GRAY=""
  else
    RB_C_RESET=$'\033[0m'
    RB_C_BOLD=$'\033[1m'
    RB_C_DIM=$'\033[2m'
    RB_C_ITALIC=$'\033[3m'
    RB_C_UNDERLINE=$'\033[4m'
    RB_C_STRIKETHROUGH=$'\033[9m'
    RB_C_OVERLINE=$'\033[53m'

    RB_C_RED=$'\033[31m'
    RB_C_GREEN=$'\033[32m'
    RB_C_YELLOW=$'\033[33m'
    RB_C_BLUE=$'\033[34m'
    RB_C_MAGENTA=$'\033[35m'
    RB_C_CYAN=$'\033[36m'
    RB_C_WHITE=$'\033[37m'
    RB_C_GRAY=$'\033[90m'
    RB_C_RED_BRIGHT=$'\033[91m'
    RB_C_GREEN_BRIGHT=$'\033[92m'
    RB_C_YELLOW_BRIGHT=$'\033[93m'
    RB_C_BLUE_BRIGHT=$'\033[94m'
    RB_C_MAGENTA_BRIGHT=$'\033[95m'
    RB_C_CYAN_BRIGHT=$'\033[96m'
    RB_C_WHITE_BRIGHT=$'\033[97m'

    RB_C_BG_RED=$'\033[41m'
    RB_C_BG_GREEN=$'\033[42m'
    RB_C_BG_YELLOW=$'\033[43m'
    RB_C_BG_BLUE=$'\033[44m'
    RB_C_BG_CYAN=$'\033[46m'
    RB_C_BG_GRAY=$'\033[100m'
  fi
}
#  3.  ICON SET  (Unicode → ASCII fallback)
RB_I_INFO=""
RB_I_SUCCESS=""
RB_I_ERROR=""
RB_I_WARNING=""
RB_I_WORKING=""
RB_I_ARROW=""
RB_I_STAR=""
RB_I_BULLET=""
RB_I_COLLAPSED=""
RB_I_BOX_TL=""
RB_I_BOX_TR=""
RB_I_BOX_BL=""
RB_I_BOX_BR=""
RB_I_BOX_H=""
RB_I_BOX_V=""
RB_I_PROG_FILL=""
RB_I_PROG_EMPTY=""
RB_I_CHECK_OFF=""
RB_I_CHECK_ON=""
RB_I_LOZENGE=""
RB_I_PLAY=""
RB_I_TICK=""
RB_I_CROSS=""
RB_I_ELLIPSIS=""
RB_I_SEPARATOR=""
RB_I_GEAR=""
RB_I_SEARCH=""

init_icons() {
  if [[ "$RB_CAP_USE_UNICODE" == true ]]; then
    RB_I_INFO="ℹ"
    RB_I_SUCCESS="✔"
    RB_I_ERROR="✖"
    RB_I_WARNING="⚠"
    RB_I_WORKING="⚙"
    RB_I_ARROW="❯"
    RB_I_STAR="★"
    RB_I_BULLET="●"
    RB_I_COLLAPSED="▸"
    RB_I_BOX_TL="╭"
    RB_I_BOX_TR="╮"
    RB_I_BOX_BL="╰"
    RB_I_BOX_BR="╯"
    RB_I_BOX_H="─"
    RB_I_BOX_V="│"
    RB_I_PROG_FILL="█"
    RB_I_PROG_EMPTY="░"
    RB_I_CHECK_OFF="☐"
    RB_I_CHECK_ON="☒"
    RB_I_LOZENGE="◆"
    RB_I_PLAY="▶"
    RB_I_TICK="✔"
    RB_I_CROSS="✖"
    RB_I_ELLIPSIS="…"
    RB_I_SEPARATOR="╱"
    RB_I_GEAR="⚙"
    RB_I_SEARCH="⌕"
  else
    RB_I_INFO="i"
    RB_I_SUCCESS="[OK]"
    RB_I_ERROR="[ERR]"
    RB_I_WARNING="[ℹ]"
    RB_I_WORKING="[*]"
    RB_I_ARROW=">"
    RB_I_STAR="*"
    RB_I_BULLET="*"
    RB_I_COLLAPSED=">"
    RB_I_BOX_TL="+"
    RB_I_BOX_TR="+"
    RB_I_BOX_BL="+"
    RB_I_BOX_BR="+"
    RB_I_BOX_H="-"
    RB_I_BOX_V="|"
    RB_I_PROG_FILL="#"
    RB_I_PROG_EMPTY="."
    RB_I_CHECK_OFF="[ ]"
    RB_I_CHECK_ON="[x]"
    RB_I_LOZENGE="<>"
    RB_I_PLAY=">"
    RB_I_TICK="[OK]"
    RB_I_CROSS="[ERR]"
    RB_I_ELLIPSIS="..."
    RB_I_SEPARATOR="|"
    RB_I_GEAR="[*]"
    RB_I_SEARCH="?"
  fi
}
#  4.  HELPER FUNCTIONS
colorize() {
  local color="${1:-}"
  local text="${2:-}"
  if [[ "$RB_CAP_USE_COLOR" == true ]]; then
    printf "%s%s%s" "$color" "$text" "$RB_C_RESET"
  else
    printf "%s" "$text"
  fi
}
msg_info() { printf "  %s    %s\n" "$(colorize "$RB_C_BLUE" "$RB_I_INFO")" "$*"; }
msg_success() { printf "  %s %s\n" "$(colorize "$RB_C_GREEN" "$RB_I_SUCCESS")" "$*"; }
msg_error() { printf "  %s   %s\n" "$(colorize "$RB_C_RED" "$RB_I_ERROR")" "$*" >&2; }
msg_warning() { printf "  %s  %s\n" "$(colorize "$RB_C_YELLOW" "$RB_I_WARNING")" "$*"; }
msg_working() { printf "  %s %s\n" "$(colorize "$RB_C_CYAN" "$RB_I_WORKING")" "$*"; }
msg_arrow() { printf "  %s   %s\n" "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_ARROW")" "$*"; }
box_line() {
  local content="${1:-}"
  local width="${2:-}"
  printf "  %s %-*s %s\n" "$RB_I_BOX_V" "$width" "$content" "$RB_I_BOX_V"
}
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
#  5.  PROGRESS BAR  (single-line, in-place, no cursor tricks)
draw_progress() {
  local current="${1:-}"
  local total="${2:-}"
  local label="${3:-}"

  ((total == 0)) && return

  # 1. Terminal width cached once at startup (init_terminal_caps) — no per-tick fork
  local term_width="$RB_TERM_WIDTH"

  # 2. Scale the progress bar based on screen size, keeping it within sensible limits
  local bar_width=$((term_width / 4))
  ((bar_width > 30)) && bar_width=30
  ((bar_width < 10)) && bar_width=10

  local pct=$((current * 100 / total))
  local filled=$((current * bar_width / total))
  local empty=$((bar_width - filled))

  local bar=""
  local i
  for ((i = 0; i < filled; i++)); do bar+="$RB_I_PROG_FILL"; done
  for ((i = 0; i < empty; i++)); do bar+="$RB_I_PROG_EMPTY"; done

  # 3. Calculate exactly how many characters the static UI elements take up
  # Padding(2) + Gear(1) + Brackets(2) + Spaces(8) + % + Fractions
  local ui_reserved=$((14 + bar_width + 3 + ${#current} + ${#total}))

  # 4. Calculate available space for the filename label
  local max_label_len=$((term_width - ui_reserved))

  local display_label="$label"
  if ((max_label_len < 5)); then
    display_label="" # Screen is extremely narrow, hide the text to save the UI
  elif ((${#display_label} > max_label_len)); then
    display_label="${display_label:0:$((max_label_len - 3))}..."
  fi

  # 5. Print out the bar exactly as before
  if [[ "$RB_CAP_USE_COLOR" == true ]]; then
    local prog_color="$RB_C_CYAN"
    if ((pct >= 100)); then
      prog_color="$RB_C_GREEN"
    elif ((pct >= 66)); then
      prog_color="$RB_C_GREEN_BRIGHT"
    elif ((pct >= 33)); then
      prog_color="$RB_C_YELLOW"
    fi

    local gear_colored="$(colorize "$RB_C_CYAN" "$RB_I_GEAR")"
    local bar_colored="$(colorize "$prog_color" "$bar")"

    printf "%s" $'\033[2K\r'
    printf "  %s%s%s[%s]%s %s%3d%%%s  %s%d/%d%s  %s%s%s" \
      "$RB_C_DIM" "$gear_colored" "$RB_C_DIM" \
      "$bar_colored" \
      "$RB_C_DIM" "$RB_C_BOLD" "$pct" "$RB_C_RESET" \
      "$RB_C_DIM" "$current" "$total" "$RB_C_RESET" \
      "$RB_C_DIM" "$display_label" "$RB_C_RESET"
  else
    printf "%s" $'\033[2K\r'
    printf "  %s [%s] %3d%%  %d/%d  %s" \
      "$RB_I_GEAR" "$bar" "$pct" "$current" "$total" "$display_label"
  fi
}
#  6.  FILENAME COMPUTATION & EXTENSION NORMALISATION
normalize_extension() {
  local ext="${1:-}"
  ext="${ext#.}"
  printf "%s" "$ext"
}
validate_extension() {
  local ext="${1:-}"
  [[ "$ext" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]{0,31}$ ]] || return 1
  [[ "$ext" != *..* ]]
}
is_excluded_file() {
  # If the user forced the operation, nothing is excluded
  [[ "$OPT_ALLOW_EXCLUDED" == true ]] && return 1

  local filepath="${1:-}"
  local base_name
  base_name="${filepath##*/}"

  # 1. Check exact filenames (lowercased for safety)
  local lower_base="${base_name,,}"
  case "$lower_base" in
  license | licence | copying | notice | readme | changelog | contributing | makefile | dockerfile | containerfile)
    return 0 # In Bash, 0 means "Success/True"
    ;;
  package-lock.json | yarn.lock | cargo.lock | pnpm-lock.yaml | composer.lock)
    return 0
    ;;
  esac

  # 2. Check by file extensions
  if [[ "$base_name" == *.* ]]; then
    local ext="${base_name##*.}"
    case "${ext,,}" in
    md | json | yaml | yml | toml | xml | ini | conf | html | log | lock)
      return 0
      ;;
    esac
  fi

  return 1 # 1 means "False/No Match"
}
compute_new_name() {
  local filepath="${1:-}"
  local new_ext="${2:-}"
  local output_dir="${3:-}"
  local basename
  basename="${filepath##*/}"

  local name_part

  if [[ "$basename" != *.* ]]; then
    name_part="$basename"
  else
    if [[ "$basename" =~ ^\.[^.]+$ ]]; then
      name_part="$basename"
    else
      name_part="${basename%.*}"
      if [[ -z "$name_part" ]]; then
        name_part="$basename"
      fi
    fi
  fi

  local new_name="${name_part}.${new_ext}"
  local dest="${output_dir}/${new_name}"

  local counter=1
  while [[ -e "$dest" ]]; do
    new_name="${name_part}_${counter}.${new_ext}"
    dest="${output_dir}/${new_name}"
    counter=$((counter + 1))
  done

  printf "%s\n" "$dest"
}
compute_copy_destination() {
  local filepath="${1:-}"
  local new_ext="${2:-}"
  local source_dir="${3:-}"
  local output_dir="${4:-}"
  local rel_path rel_dir target_dir

  rel_path="${filepath#"$source_dir"/}"
  if [[ "$rel_path" == */* ]]; then
    rel_dir="${rel_path%/*}"
    target_dir="$output_dir/$rel_dir"
  else
    target_dir="$output_dir"
  fi

  compute_new_name "$filepath" "$new_ext" "$target_dir"
}
already_has_extension() {
  local filepath="${1:-}"
  local new_ext="${2:-}"
  local basename
  basename="${filepath##*/}"

  [[ "$basename" != *.* ]] && return 1

  local current_ext="${basename##*.}"
  [[ "$current_ext" == "$new_ext" ]]
}

# =============================================================================
# Interactive directory picker (full-screen, banner-safe, with directory icons)
# =============================================================================

rb_ac_init_terminal() {
  RB_AC_TERM_MODE="full"
  RB_AC_TERM="${TERM:-dumb}"
  RB_AC_HOME="${HOME:-/}"

  if [[ ! -t 0 || ! -t 2 || "$RB_AC_TERM" == "dumb" || "$RB_AC_TERM" == "unknown" ]]; then
    RB_AC_TERM_MODE="plain"
  elif ! command -v tput >/dev/null || ! tput clear >/dev/null || ! tput cup 0 0 >/dev/null; then
    RB_AC_TERM_MODE="plain"
  fi

  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *UTF-8* | *utf8* | *UTF8*) RB_AC_UNICODE=1 ;;
  *) RB_AC_UNICODE=0 ;;
  esac
  [[ -n "${NO_UNICODE:-}" ]] && RB_AC_UNICODE=0

  if ((RB_AC_UNICODE)); then
    RB_AC_TL='╭'
    RB_AC_TR='╮'
    RB_AC_BL='╰'
    RB_AC_BR='╯'
    RB_AC_H='─'
    RB_AC_V='│'
    RB_AC_ELL='…'
    RB_AC_DIR='📁'
    RB_AC_SYMLINK='🔗'
  else
    RB_AC_TL='+'
    RB_AC_TR='+'
    RB_AC_BL='+'
    RB_AC_BR='+'
    RB_AC_H='-'
    RB_AC_V='|'
    RB_AC_ELL='...'
    RB_AC_DIR='[D]'
    RB_AC_SYMLINK='[L]'
  fi
  RB_AC_ARR='>'
  RB_AC_UP='^'
  RB_AC_DOWN='v'
  RB_AC_LINK='->'
  RB_AC_LOCK='[!]'
  RB_AC_SEL='*'
}

rb_ac_term_size() {
  local rows='' cols='' size=''
  if command -v tput >/dev/null; then
    cols="$(tput cols || true)"
    rows="$(tput lines || true)"
  fi
  if [[ ! "$cols" =~ ^[0-9]+$ || ! "$rows" =~ ^[0-9]+$ ]]; then
    size="$(stty size </dev/tty || true)"
    rows="${size%% *}"
    cols="${size##* }"
  fi
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
  printf '%s %s\n' "$cols" "$rows"
}

rb_ac_hide_cursor() {
  [[ "${RB_AC_TERM_MODE:-plain}" == full ]] || return 0
  tput civis || true
}
rb_ac_show_cursor() {
  [[ "${RB_AC_TERM_MODE:-plain}" == full ]] || return 0
  tput cnorm || true
}
rb_ac_clear_screen() {
  [[ "${RB_AC_TERM_MODE:-plain}" == full ]] || return 0
  tput clear >&2 || printf '\033[H\033[2J' >&2
}

rb_ac_strip_ansi() {
  printf '%s' "${1:-}" | sed $'s/\033\[[0-9;]*[[:alpha:]]//g'
}
rb_ac_visible_len() {
  local plain
  plain="$(rb_ac_strip_ansi "${1:-}")"
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

rb_ac_truncate() {
  local text="${1:-}" max="${2:-80}" vis out='' i=0 len c code keep visible=0
  ((max > 0)) || return 0
  vis="$(rb_ac_visible_len "$text")"
  ((vis <= max)) && {
    printf '%s' "$text"
    return 0
  }
  keep=$((max - ${#RB_AC_ELL}))
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
  printf '%s%s' "$out" "$RB_AC_ELL"
}

rb_ac_box_row() {
  local text="${1:-}" sel="${2:-0}" dim="${3:-0}" width="${inner:-1}"
  local vis pad_r middle left_color='' body_color='' reset="${RB_C_RESET:-}"
  ((width > 0)) || width=1
  vis="$(rb_ac_visible_len "$text")"
  if ((vis > width)); then
    text="$(rb_ac_truncate "$text" "$width")"
    vis="$(rb_ac_visible_len "$text")"
  fi
  pad_r=$((width - vis))
  ((pad_r < 0)) && pad_r=0
  printf -v middle '%s%*s' "$text" "$pad_r" ''
  left_color="${RB_C_CYAN_BRIGHT:-}"
  if ((sel)); then
    body_color="${RB_C_BOLD:-}${RB_C_GREEN_BRIGHT:-}"
  elif ((dim)); then
    body_color="${RB_C_DIM:-}"
  fi
  printf '%s%s%s%s%s%s%s\n' "$left_color" "$RB_AC_V" "$reset" "$body_color" "$middle" "$reset$left_color$RB_AC_V" "$reset" >&2
}
rb_ac_box_rule() {
  local left="${1:-+}" right="${2:-+}" hb=''
  printf -v hb '%*s' "${inner:-1}" ''
  hb="${hb// /$RB_AC_H}"
  printf '%s%s%s%s%s%s\n' "${RB_C_CYAN_BRIGHT:-}" "$left" "$hb" "$right" "${RB_C_RESET:-}" '' >&2
}
rb_ac_box_top() { rb_ac_box_rule "$RB_AC_TL" "$RB_AC_TR"; }
rb_ac_box_bottom() { rb_ac_box_rule "$RB_AC_BL" "$RB_AC_BR"; }
rb_ac_box_title() {
  local t=" ${1:-}"
  rb_ac_box_row "$t" 0 0
}

rb_ac_draw_pointer() {
  local index="${1:-0}" window="${2:-0}" enabled="${3:-0}" prompt_row="${4:-0}"
  local row=$((3 + (window > 0 ? 1 : 0) + index - window))

  if [[ "${RB_AC_MENU_SAVED:-0}" -eq 1 ]]; then
    tput rc >&2 || return 1
    if ((row > 0)); then
      tput cud "$row" >&2 || printf '\033[%dB' "$row" >&2
    fi
    tput cuf 1 >&2 || printf '\033[1C' >&2
  else
    tput cup "$row" 1 >&2 || return 1
  fi

  if ((enabled)); then
    printf '%s %s %s' "${RB_C_BOLD:-}${RB_C_GREEN_BRIGHT:-}" "$RB_AC_ARR" "${RB_C_RESET:-}" >&2
  else
    printf '   ' >&2
  fi

  if [[ "${RB_AC_MENU_SAVED:-0}" -eq 1 ]]; then
    tput rc >&2 || true
    if ((prompt_row > 0)); then
      tput cud "$prompt_row" >&2 || printf '\033[%dB' "$prompt_row" >&2
    fi
    tput cr >&2 || printf '\r' >&2
  else
    tput cup "$prompt_row" 0 >&2 || true
  fi
}

rb_ac_read_key() {
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
    IFS= read -rsn1 -t 0.08 seq </dev/tty || {
      printf 'ESC'
      return
    }
    if [[ "$seq" == '[' || "$seq" == 'O' ]]; then
      local tail=''
      IFS= read -rsn1 -t 0.08 tail </dev/tty || true
      # Consume any remaining parameter bytes until the final letter.
      # Some terminals send longer sequences like \033[1;2A (Shift+Arrow)
      # or \033[5~ (Page Up). Without this, leftover bytes leak to screen.
      while [[ -n "$tail" && ! "$tail" =~ [A-Za-z~] ]]; do
        IFS= read -rsn1 -t 0.01 tail </dev/tty || { tail=''; break; }
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

rb_ac_read_filter() {
  local q='' ch
  printf '\r\033[K  > Filter: ' >&2
  while :; do
    ch="$(rb_ac_read_key)"
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

rb_ac_list_dirs() {
  local dir="${1:-}" hidden="${2:-0}" p
  local -a out=()
  if ((hidden)); then
    while IFS= read -r -d '' p; do [[ -d "$p" || -L "$p" ]] && out+=("$p"); done \
      < <(find "$dir" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) -print0)
  else
    while IFS= read -r -d '' p; do [[ -d "$p" || -L "$p" ]] && out+=("$p"); done \
      < <(find "$dir" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) ! -name '.*' -print0)
  fi
  ((${#out[@]})) && printf '%s\0' "${out[@]}"
}

rb_ac_abs_path() {
  if command -v realpath >/dev/null; then
    realpath "${1:-}"
  else
    (cd "$(dirname "${1:-}")" && printf '%s/%s\n' "$(pwd -P)" "$(basename "${1:-}")")
  fi
}

_rb_ac_descend() {
  local p="${1:-}" rp='' v
  [[ -d "$p" ]] || {
    msg_warning "Not a directory."
    return 1
  }
  rp="$(rb_ac_abs_path "$p")" || return 1
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

rb_ac_prompt_path() {
  local default="${1:-/}" answer=''
  printf 'Enter directory path [%s]: ' "$default" >&2
  IFS= read -r answer </dev/tty || return 1
  printf '%s' "${answer:-$default}"
}

_rb_ac_act() {
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
    cp="$(rb_ac_prompt_path "$cur_dir")" || return 1
    if [[ -d "$cp" ]]; then
      chosen="$(rb_ac_abs_path "$cp")"
      return 0
    fi
    msg_warning "Not a directory: $cp"
    return 1
    ;;
  dir | symlink)
    _rb_ac_descend "$path"
    return 1
    ;;
  *) return 1 ;;
  esac
}

rb_ac_pick_dir_plain() {
  local label="${1:-Select directory}" cur_dir="${2:-${HOME:-/}}" answer='' p base i
  local -a entries=()
  while :; do
    entries=()
    while IFS= read -r -d '' p; do entries+=("$p"); done < <(rb_ac_list_dirs "$cur_dir" 0)
    printf '\n%s\nCurrent: %s\n  0) select this folder\n  u) up  c) custom path  q) cancel\n' "$label" "$cur_dir" >&2
    for i in ${entries[@]+"${!entries[@]}"}; do
      base="$(basename "${entries[$i]}")"
      p="${entries[$i]}"
      if [[ -L "$p" ]]; then
        printf '  %d) %s %s\n' "$((i + 1))" "$RB_AC_SYMLINK" "$base" >&2
      else
        printf '  %d) %s %s\n' "$((i + 1))" "$RB_AC_DIR" "$base" >&2
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
      p="$(rb_ac_prompt_path "$cur_dir")" || continue
      [[ -d "$p" ]] && cur_dir="$(rb_ac_abs_path "$p")" || msg_warning "Not a directory: $p"
      ;;
    q | Q) return 1 ;;
    *)
      if [[ "$answer" =~ ^[0-9]+$ ]] && ((answer >= 1 && answer <= ${#entries[@]})); then cur_dir="$(rb_ac_abs_path "${entries[$((answer - 1))]}")"; else msg_warning "Invalid choice."; fi
      ;;
    esac
  done
}

rb_ac_pick_dir() {
  [[ -t 0 && -t 2 ]] || return 1
  rb_ac_init_terminal
  rb_ac_hide_cursor
  local label="${1:-Select directory}" start="${2:-${HOME:-/}}"
  # Save terminal settings and disable echoing so held-key escape fragments
  # never appear on screen between read calls.
  local _ac_old_stty=''
  _ac_old_stty=$(stty -g </dev/tty) || _ac_old_stty=''
  stty -echo </dev/tty || true
  if [[ "$RB_AC_TERM_MODE" != full ]]; then
    [[ -n "${_ac_old_stty:-}" ]] && stty "$_ac_old_stty" </dev/tty || true
    rb_ac_show_cursor
    rb_ac_pick_dir_plain "$label" "$start"
    return $?
  fi

  local cur_dir="$start" filter='' show_hidden=0 SELECTED_INDEX=0 chosen=''
  local -a visited=() disp=() paths=() kinds=() entries=() fdisp=() fpaths=() fkinds=()
  local dims AC_COLS=0 AC_ROWS=0 inner=1 total=0 vis=1 win=0 i p base kind lab lock prefix key
  local selected_kind selected_path footer shown=0 above=0 below=0 menu_prompt_row=0
  local needs_redraw=1 rendered_cols=0 rendered_rows=0 old_index new_index new_win

  RB_AC_MENU_SAVED=0
  if [[ "$RB_AC_TERM_MODE" == full ]]; then
    tput sc >&2 && RB_AC_MENU_SAVED=1
  fi

  # Query cursor row so vis accounts for banners/messages already printed
  # above us, without clearing the screen.
  local _ac_start_row=1
  printf '\033[6n' >/dev/tty
  local _dsr=''
  IFS= read -rs -d 'R' -t 0.1 _dsr </dev/tty || true
  _ac_start_row="${_dsr#*\[}"
  _ac_start_row="${_ac_start_row%%;*}"
  [[ "$_ac_start_row" =~ ^[0-9]+$ ]] || _ac_start_row=1

  while :; do
    dims="$(rb_ac_term_size)"
    AC_COLS="${dims%% *}"
    AC_ROWS="${dims##* }"

    if ((AC_COLS != rendered_cols || AC_ROWS != rendered_rows)); then needs_redraw=1; fi

    if ((AC_COLS < 24 || AC_ROWS < 10)); then
      RB_AC_MENU_SAVED=0
      [[ -n "${_ac_old_stty:-}" ]] && stty "$_ac_old_stty" </dev/tty || true
      rb_ac_show_cursor
      rb_ac_pick_dir_plain "$label" "$cur_dir"
      return $?
    fi

    if ((needs_redraw)); then
      inner=$((AC_COLS - 3))
      disp=("$RB_AC_SEL Select this folder: $cur_dir")
      paths=("$cur_dir")
      kinds=("select")
      if [[ "$cur_dir" != / ]]; then
        disp+=(".. (up one level)")
        paths+=("__UP__")
        kinds+=("up")
      fi

      entries=()
      while IFS= read -r -d '' p; do entries+=("$p"); done < <(rb_ac_list_dirs "$cur_dir" "$show_hidden")
      for p in ${entries[@]+"${entries[@]}"}; do
        base="$(basename "$p")"
        kind='dir'
        [[ -L "$p" ]] && kind='symlink'
        lock=0
        [[ ! -r "$p" || ! -x "$p" ]] && lock=1
        if [[ "$kind" == symlink ]]; then
          lab="$RB_AC_SYMLINK $base"
          lab+=" $RB_AC_LINK $(readlink "$p" || true)"
        else
          lab="$RB_AC_DIR $base"
        fi
        ((lock)) && lab+=" $RB_AC_LOCK"
        disp+=("$lab")
        paths+=("$p")
        kinds+=("$kind")
      done
      disp+=("[ Type a custom path$RB_AC_ELL ]")
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

      if [[ "$RB_AC_TERM_MODE" == full ]]; then
        if [[ "${RB_AC_MENU_SAVED:-0}" -eq 1 ]]; then
          tput rc >&2 || true
          tput ed >&2 || printf '\033[J' >&2
        else
          rb_ac_clear_screen
        fi
      fi

      rb_ac_box_top
      rb_ac_box_title "$label"
      rb_ac_box_row "  $cur_dir" 0 1
      ((above)) && rb_ac_box_row "  $RB_AC_UP more above" 0 1
      for ((i = win; i < win + shown; i++)); do
        prefix='   '
        ((i == SELECTED_INDEX)) && prefix=" $RB_AC_ARR "
        rb_ac_box_row "$prefix${fdisp[$i]}" 0 0
      done
      ((below)) && rb_ac_box_row "  $RB_AC_DOWN more below" 0 1
      rb_ac_box_bottom
      footer='Up/Dn move  Enter open  s select  Left up  / filter  h hidden  ~ home  q quit'
      printf ' %s\n' "$(rb_ac_truncate "$footer" "$((AC_COLS - 2))")" >&2

      rendered_cols=$AC_COLS
      rendered_rows=$AC_ROWS
      needs_redraw=0
    fi

    key="$(rb_ac_read_key)"
    case "$key" in
    UP | k | K)
      old_index=$SELECTED_INDEX
      new_index=$((SELECTED_INDEX - 1))
      ((new_index < 0)) && new_index=0
      if ((new_index != old_index)); then
        new_win=$((new_index / vis * vis))
        SELECTED_INDEX=$new_index
        if ((new_win == win)); then
          rb_ac_draw_pointer "$old_index" "$win" 0 "$menu_prompt_row"
          rb_ac_draw_pointer "$new_index" "$win" 1 "$menu_prompt_row"
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
          rb_ac_draw_pointer "$old_index" "$win" 0 "$menu_prompt_row"
          rb_ac_draw_pointer "$new_index" "$win" 1 "$menu_prompt_row"
        else
          needs_redraw=1
        fi
      fi
      ;;
    ENTER | RIGHT)
      selected_kind="${fkinds[$SELECTED_INDEX]:-}"
      selected_path="${fpaths[$SELECTED_INDEX]:-}"
      if [[ "$selected_kind" == dir || "$selected_kind" == symlink ]]; then
        _rb_ac_descend "$selected_path" || true
      else
        _rb_ac_act "$selected_kind" "$selected_path" && break
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
          chosen="$(rb_ac_abs_path "$selected_path")"
          break
        else
          msg_warning "Not a directory."
        fi
      else
        _rb_ac_act "$selected_kind" "$selected_path" && break
      fi
      needs_redraw=1
      ;;
    / | f | F)
      filter="$(rb_ac_read_filter)"
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
      RB_AC_MENU_SAVED=0
      [[ -n "${_ac_old_stty:-}" ]] && stty "$_ac_old_stty" </dev/tty || true
      rb_ac_show_cursor
      return 1
      ;;
    ESC) : ;;
    *) : ;;
    esac
  done
  RB_AC_MENU_SAVED=0
  [[ -n "${_ac_old_stty:-}" ]] && stty "$_ac_old_stty" </dev/tty || true
  rb_ac_show_cursor
  [[ -n "$chosen" ]] && printf '%s\n' "$chosen"
}

#  7.  HELP & VERSION
show_help() {

  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "USAGE")"
  printf "\n"
  printf "    %s %s %s %s %s\n" "$(colorize "$RB_C_CYAN" "  $0")" "$(colorize "$RB_C_GREEN" "<source_dir>")" "$(colorize "$RB_C_YELLOW" "<new_extension>")" "$(colorize "$RB_C_GRAY" "[output_dir]")" "$(colorize "$RB_C_CYAN" "[flags]")"
  printf "    %s %s\n" "$(colorize "$RB_C_CYAN" "  $0")" "$(colorize "$RB_C_DIM" "(runs Interactive Wizard if executed without arguments)")"
  printf "    %s %s\n" "$(colorize "$RB_C_CYAN" "  $0")" "$(colorize "$RB_C_DIM" "-i  (launch interactive picker even with args)")"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "DESCRIPTION")"
  printf "\n"
  printf "    Recursively rename all non-hidden files in <source_dir> (and all\n"
  printf "    subdirectories) to a new file extension.\n"
  printf "\n"
  printf "    In-place mode (2 args):  Files are renamed where they sit.\n"
  printf "    Copy mode    (3 args):  Files are COPIED to output_dir with new names.\n"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "ARGUMENTS")"
  printf "\n"
  printf "    %-18s %s\n" "$(colorize "$RB_C_GREEN" "source_dir")" "Directory to scan"
  printf "    %-18s %s\n" "$(colorize "$RB_C_YELLOW" "new_extension")" "Target extension (e.g. txt, md, py)"
  printf "    %-18s %s\n" "$(colorize "$RB_C_GRAY" "output_dir")" "(Optional) destination directory"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "OPTIONS / FLAGS")"
  printf "\n"
  printf "    %-18s %s\n" "$(colorize "$RB_C_CYAN" "-f, --force, --all")" "Force process protected files (README, LICENSE, etc.)"
  printf "    %-18s %s\n" "$(colorize "$RB_C_CYAN" "-h, --help")" "Show this message"
  printf "    %-18s %s\n" "$(colorize "$RB_C_CYAN" "-v, --version")" "Show version info"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "EXAMPLES")"
  printf "\n"
  printf "    %s\n" "$(colorize "$RB_C_DIM" "# Rename everything in ./ProjectR to .txt")"
  printf "    %s\n" "$(colorize "$RB_C_GREEN" "  $0 ./ProjectR txt")"
  printf "\n"
  printf "    %s\n" "$(colorize "$RB_C_DIM" "# Copy+rename to ./renamed-files")"
  printf "    %s\n" "$(colorize "$RB_C_GREEN" "  $0 ./ProjectR md ./renamed-files")"
  printf "\n"
  printf "    %s\n" "$(colorize "$RB_C_DIM" "# Force change extensions on every file, including Markdown files")"
  printf "    %s\n" "$(colorize "$RB_C_GREEN" "  $0 . bak --force")"
  printf "\n"
  printf "    %s\n" "$(colorize "$RB_C_DIM" "# Launch interactive directory picker")"
  printf "    %s\n" "$(colorize "$RB_C_GREEN" "  $0 -i")"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "EXIT CODES")"
  printf "\n"
  printf "    %s   %s\n" "$(colorize "$RB_C_GREEN" "0")" "All good (or all skipped)"
  printf "    %s   %s\n" "$(colorize "$RB_C_RED" "1")" "Fatal error (bad args, missing dir, ...)"
  printf "    %s   %s\n" "$(colorize "$RB_C_YELLOW" "2")" "Partial failure (some files failed)"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "ENVIRONMENT")"
  printf "\n"
  printf "    %s   %s\n" "$(colorize "$RB_C_CYAN" "NO_COLOR")" "Set to any value to disable ANSI"
  printf "\n"
}

show_version() {
  printf "%s %s\n" "$(colorize "${RB_C_BOLD}${RB_C_CYAN}" "$SCRIPT_NAME")" "$(colorize "$RB_C_GREEN" "v${UK_VERSION}")"
  printf "%s\n" "$(colorize "$RB_C_DIM" "$SCRIPT_URL")"
  printf "\n"
  printf "  Bash:          %s\n" "${BASH_VERSION}"
  printf "  Unicode:       %s\n" "$([[ "$RB_CAP_USE_UNICODE" == true ]] && echo "enabled" || echo "disabled")"
  printf "  Color:         %s\n" "$([[ "$RB_CAP_USE_COLOR" == true ]] && echo "enabled" || echo "disabled")"
  printf "  Interactive:   %s\n" "$([[ "$RB_CAP_IS_INTERACTIVE" == true ]] && echo "yes" || echo "no")"
}
#  8.  MAIN
rb_file_size() {
  local path="${1:-}" size='' stat_error=''
  if size="$(stat -c '%s' -- "$path" 2>&1)"; then
    printf '%s\n' "$size"
    return 0
  fi
  stat_error="$size"
  if size="$(stat -f '%z' -- "$path" 2>&1)"; then
    [[ -n "$stat_error" ]] && msg_info "GNU stat unavailable for '$path'; used BSD stat."
    printf '%s\n' "$size"
    return 0
  fi
  msg_warning "stat failed for '$path' (${size:-$stat_error}); using wc -c."
  wc -c <"$path"
}

rb_scan_files() {
  local source_dir="${1:-}" filepath file_size probe_error='' probe_file
  probe_file="$(mktemp)" || {
    msg_error "Unable to create temporary file for find capability probe."
    return 1
  }
  if find "$source_dir" -maxdepth 0 -printf '' >/dev/null 2>"$probe_file"; then
    rm -f "$probe_file" || { msg_error "Unable to remove find probe log: $probe_file"; return 1; }
    find "$source_dir" -type f ! -path '*/\.*' -printf '%s\0%p\0'
  else
    probe_error="$(cat "$probe_file")" || probe_error='unable to read find probe error'
    rm -f "$probe_file" || { msg_error "Unable to remove find probe log: $probe_file"; return 1; }
    [[ -n "$probe_error" ]] && printf '  [INFO] GNU find -printf unavailable; using portable scan: %s\n' "$probe_error" >&2
    local scan_file
    scan_file="$(mktemp)" || {
      msg_error "Unable to create temporary file for source scan."
      return 1
    }
    if ! find "$source_dir" -type f ! -path '*/\.*' -print0 >"$scan_file"; then
      rm -f "$scan_file" || msg_warning "Unable to remove failed scan file: $scan_file"
      return 1
    fi
    while IFS= read -r -d '' filepath; do
      file_size="$(rb_file_size "$filepath")" || {
        rm -f "$scan_file" || msg_warning "Unable to remove failed scan file: $scan_file"
        return 1
      }
      printf '%s\0%s\0' "$file_size" "$filepath"
    done <"$scan_file"
    rm -f "$scan_file" || {
      msg_error "Unable to remove source scan file: $scan_file"
      return 1
    }
  fi
}
rb_main() {
  init_terminal_caps
  init_colors
  init_icons
  uk_banner "rename-batch" "Recursively rename or copy files to a new extension" "" "$@"
  # 1. Parse incoming script flags and parameters
  local positional_args=()
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    -h | --help)
      show_help
      return 0
      ;;
    -v | --version)
      show_version
      return 0
      ;;
    -f | --force | --all)
      OPT_ALLOW_EXCLUDED=true
      shift
      ;;
    *)
      positional_args+=("${1:-}")
      shift
      ;;
    esac
  done

  # Structural tracking initializations
  local excluded_skipped=0
  declare -a ROLLBACK_SRC=()
  declare -a ROLLBACK_DST=()

  local source_dir=""
  local new_ext_raw=""
  local output_dir=""
  local mode="in-place"

  # 2. Interactive Wizard if executed without target args
  if [[ ${#positional_args[@]} -eq 0 ]]; then
    if [[ "$RB_CAP_IS_INTERACTIVE" == false ]]; then
      msg_error "Non-interactive environment detected and no parameters supplied."
      msg_info "Usage: $0 <source_dir> <new_extension> [output_dir]"
      return 1
    fi

    uk_section_title "Interactive Configuration"

    msg_info "Step 1 of 3 — choose the SOURCE directory (contains files to rename)."
    source_dir="$(rb_ac_pick_dir "Select SOURCE directory" "${HOME:-/}")" || {
      rb_ac_show_cursor
      msg_warning "Selection cancelled."
      return 1
    }
    [[ -n "$source_dir" ]] || {
      rb_ac_show_cursor
      return 1
    }

    msg_info "Step 2 of 3 — enter the new file extension."
    printf "  %s  Enter target new extension format (e.g. sh, py, txt) \n  %s " "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_ARROW")" "$(colorize "$RB_C_DIM" "> ")"
    read -r new_ext_raw
    while [[ -z "$new_ext_raw" ]]; do
      msg_warning "Target configuration format extension cannot be blank."
      printf "  %s " "$(colorize "$RB_C_DIM" "> ")"
      read -r new_ext_raw
    done

    msg_info "Step 3 of 3 — choose the OUTPUT directory (leave blank for in-place)."
    printf "  %s  Press Enter to use in-place mode, or pick an output directory. \n  %s " "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_ARROW")" "$(colorize "$RB_C_DIM" "> ")"
    read -r output_dir
    if [[ -n "$output_dir" ]]; then
      output_dir="$(rb_ac_pick_dir "Select OUTPUT directory" "${HOME:-/}")" || {
        rb_ac_show_cursor
        msg_warning "Selection cancelled."
        return 1
      }
    fi
  else
    # Fallback to normal CLI processing if parameters are present
    if [[ ${#positional_args[@]} -lt 2 ]]; then
      msg_error "Missing required parameters. Expected: <source_dir> <new_extension> [output_dir]"
      msg_info "Try '$0 --help' for syntax options."
      return 1
    fi
    source_dir="${positional_args[0]}"
    new_ext_raw="${positional_args[1]}"
    output_dir="${positional_args[2]:-}"
  fi

  # 3. Path & Normalization Logic Continues ...
  [[ -d "$source_dir" ]] || {
    msg_error "Source directory does not exist: $source_dir"
    return 1
  }
  local new_ext
  new_ext="$(normalize_extension "$new_ext_raw")" || {
    msg_error "Unable to normalize target extension."
    return 1
  }
  validate_extension "$new_ext" || {
    msg_error "Unsafe target extension '$new_ext_raw'. Use 1-32 letters, numbers, dot, underscore, plus, or dash; slashes and '..' are not allowed."
    return 1
  }

  if [[ -z "$output_dir" ]]; then
    mode="in-place"
  elif [[ "$source_dir" == "$output_dir" ]]; then
    msg_warning "Source and output directories are identical — switching to in-place mode."
    mode="in-place"
    output_dir=""
  else
    mode="copy"
  fi

  msg_working "Scanning for files in $(colorize "${RB_C_BOLD}${RB_C_CYAN}" "$source_dir") ..."

  local file_old_names=()
  local total_size=0
  local file_count=0

  # High-Performance Scan: NUL-delimited size/path pairs preserve every valid filename.
  local scan_file
  scan_file="$(mktemp)" || {
    msg_error "Unable to create temporary file for rename scan."
    return 1
  }
  if ! rb_scan_files "$source_dir" >"$scan_file"; then
    rm -f "$scan_file" || msg_warning "Unable to remove failed scan file: $scan_file"
    msg_error "Source scan failed; refusing to continue with a partial file list."
    return 1
  fi
  while IFS= read -r -d '' file_size && IFS= read -r -d '' filepath; do
    local base="${filepath##*/}"

    [[ "$base" == .* ]] && continue
    [[ ! -f "$filepath" ]] && continue
    [[ "$file_size" =~ ^[0-9]+$ ]] || {
      rm -f "$scan_file" || msg_warning "Unable to remove failed scan file: $scan_file"
      msg_error "Invalid file size returned for: $filepath"
      return 1
    }

    file_old_names+=("$filepath")
    total_size=$((total_size + file_size))
    file_count=$((file_count + 1))
  done <"$scan_file"
  rm -f "$scan_file" || {
    msg_error "Unable to remove rename scan file: $scan_file"
    return 1
  }

  if ((file_count == 0)); then
    msg_warning "No files found in $(colorize "$RB_C_BOLD" "$source_dir")"
    uk_section_title "Operation Summary — Nothing to process"
    printf "  %s  0 files processed\n" "$(colorize "$RB_C_GREEN" "$RB_I_TICK")"
    return 0
  fi

  local dest_names=()
  local conflicts=0
  local already_skipped=0

  for filepath in "${file_old_names[@]}"; do
    if already_has_extension "$filepath" "$new_ext"; then
      dest_names+=("$filepath")
      already_skipped=$((already_skipped + 1))
      continue
    fi

    if is_excluded_file "$filepath"; then
      dest_names+=("$filepath")
      excluded_skipped=$((excluded_skipped + 1))
      continue
    fi

    local dest
    if [[ "$mode" == "copy" ]]; then
      dest="$(compute_copy_destination "$filepath" "$new_ext" "$source_dir" "$output_dir")"
    else
      local dir
      if [[ "$filepath" == */* ]]; then
        dir="${filepath%/*}"
      else
        dir="."
      fi
      dest="$(compute_new_name "$filepath" "$new_ext" "$dir")"
    fi
    dest_names+=("$dest")

    local base_dest
    base_dest="${dest##*/}"
    local base_orig
    base_orig="${filepath##*/}"
    local expected="${base_orig%.*}.${new_ext}"
    if [[ "$base_dest" != "$expected" ]] && [[ "$base_dest" != "$base_orig" ]]; then
      conflicts=$((conflicts + 1))
    fi
  done

  local total_files=${#file_old_names[@]}
  local active_count=$((total_files - already_skipped - excluded_skipped))

  local mode_label="In-place rename"
  [[ "$mode" == "copy" ]] && mode_label="Copy + rename → $(colorize "$RB_C_CYAN" "$output_dir")"

  uk_section_title "Batch Rename Operation"

  msg_info "Source:      $(colorize "$RB_C_BOLD" "$source_dir")"
  msg_info "Extension:   $(colorize "${RB_C_BOLD}${RB_C_YELLOW}" ".${new_ext}")"
  msg_info "Mode:        ${mode_label}"
  msg_info "Files found: $(colorize "${RB_C_BOLD}${RB_C_WHITE}" "$total_files")"
  msg_info "Total size:  $(colorize "$RB_C_DIM" "$(format_size "$total_size")")"

  if ((already_skipped > 0)); then
    msg_info "Already .${new_ext}: $(colorize "$RB_C_DIM" "$already_skipped") (will be skipped)"
  fi

  if ((active_count == 0)); then
    printf "\n"
    msg_warning "All files already have the .${new_ext} extension — nothing to do."
    return 0
  fi

  if ((conflicts > 0)); then
    msg_warning "Conflicts to resolve: $(colorize "$RB_C_YELLOW_BRIGHT" "$conflicts") file(s) will be auto-renamed (_1, _2, …)"
  fi

  printf "\n"

  # 1. Initialize budget tracking counters
  local idx=0
  local total_printed=0
  local exclusions_printed=0
  local actionable_printed=0

  # 2. Set quotas (adjust these numbers to change your preview balance)
  local max_exclusions=4
  local max_actionable=6

  printf "  %s  %s %s\n" "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_COLLAPSED")" "$(colorize "$RB_C_BOLD" "Preview")" "$(colorize "$RB_C_DIM" "(balanced summary of discovered files):")"

  # 3. Dynamic search loop
  while ((idx < total_files)); do
    # Break early if we have completely satisfied both quotas
    if ((exclusions_printed >= max_exclusions && actionable_printed >= max_actionable)); then
      break
    fi

    local src_name="${file_old_names[$idx]##*/}"
    local dst_name="${dest_names[$idx]##*/}"
    local src_rel="${file_old_names[$idx]#"$source_dir"/}"
    [[ "$src_rel" == "${file_old_names[$idx]}" ]] && src_rel="$src_name"
    local dst_rel="$dst_name"
    if [[ "$mode" == "copy" && -n "$output_dir" ]]; then
      dst_rel="${dest_names[$idx]#"$output_dir"/}"
    elif [[ "$mode" == "in-place" ]]; then
      dst_rel="${dest_names[$idx]#"$source_dir"/}"
      [[ "$dst_rel" == "${dest_names[$idx]}" ]] && dst_rel="$dst_name"
    fi

    # Determine file status
    local is_ex=false
    if is_excluded_file "${file_old_names[$idx]}"; then
      is_ex=true
    fi

    # 4. Quota Filtering Logic
    local should_print=false
    if [[ "$is_ex" == true ]]; then
      if ((exclusions_printed < max_exclusions)); then
        should_print=true
      fi
    else
      if ((actionable_printed < max_actionable)); then
        should_print=true
      fi
    fi

    # 5. Render lines matching the allowed budget
    if [[ "$should_print" == true ]]; then
      total_printed=$((total_printed + 1))

      if [[ "$is_ex" == true ]]; then
        exclusions_printed=$((exclusions_printed + 1))
        printf "    %s %s %s\n" \
          "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" \
          "$(colorize "$RB_C_GRAY" "$src_rel")" \
          "$(colorize "$RB_C_YELLOW" "(excluded)")"
      else
        actionable_printed=$((actionable_printed + 1))
        printf "    %s %s %s %s\n" \
          "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" \
          "$(colorize "$RB_C_GRAY" "$src_rel")" \
          "$(colorize "$RB_C_CYAN" " ──→ ")" \
          "$(colorize "$RB_C_GREEN_BRIGHT" "$dst_rel")"
      fi
    fi

    idx=$((idx + 1))
  done

  # 6. Correctly calculate the unprinted remainder
  local remaining=$((total_files - total_printed))
  if ((remaining > 0)); then
    printf "    %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ELLIPSIS} and ${remaining} more file(s)")"
  fi

  printf "\n"

  if [[ "$RB_CAP_IS_INTERACTIVE" == true ]]; then
    local proceed=""
    printf "  %s  Proceed with %s? %s %s" \
      "$(colorize "${RB_C_BOLD}${RB_C_YELLOW}" "$RB_I_PLAY")" \
      "$(colorize "$RB_C_BOLD" "$mode_label")" \
      "$(colorize "$RB_C_GREEN" "[Y/n]")" \
      "$(colorize "$RB_C_DIM" "> ")"
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

  local success_count=0
  local failed_count=0
  local skipped_count=0
  local renamed_files=()
  local failed_files=()
  local skipped_list=()

  local start_time
  start_time=$(date +%s)

  handle_interrupt() {
    # Immediately disable the trap so a second Ctrl+C actually kills the script
    trap - SIGINT

    printf "\n\n"
    msg_warning "Process interrupted by user (Ctrl+C)!"

    local count=${#ROLLBACK_SRC[@]}
    if ((count == 0)); then
      msg_info "No files were modified yet. Exiting safely."
      exit 130
    fi

    printf "  %s  %d file(s) have already been processed.\n" "$(colorize "$RB_C_YELLOW" "$RB_I_WARNING")" "$count"

    if [[ "$RB_CAP_IS_INTERACTIVE" == true ]]; then
      local proceed=""
      printf "  %s  Do you want to roll back these changes? %s %s" \
        "$(colorize "${RB_C_BOLD}${RB_C_YELLOW}" "$RB_I_SEARCH")" \
        "$(colorize "$RB_C_GREEN" "[Y/n]")" \
        "$(colorize "$RB_C_DIM" "> ")"
      read -r proceed
      case "${proceed,,}" in
      y | yes | "")
        msg_working "Rolling back changes..."
        local fails=0

        # Loop backward through our history
        for ((i = ${#ROLLBACK_SRC[@]} - 1; i >= 0; i--)); do
          local r_src="${ROLLBACK_SRC[$i]}"
          local r_dst="${ROLLBACK_DST[$i]}"

          if [[ "$mode" == "copy" ]]; then
            # Reversing a copy means deleting the new file
            rm -f "$r_dst" || fails=$((fails + 1))
          else
            # Reversing a rename means moving it back
            mv -- "$r_dst" "$r_src" || fails=$((fails + 1))
          fi
        done

        if ((fails > 0)); then
          msg_error "Rollback completed with $fails error(s)."
        else
          msg_success "Rollback successful. Original state restored."
        fi
        ;;
      *)
        msg_info "Keeping changes. Exiting."
        ;;
      esac
    fi
    exit 130
  }

  msg_working "Processing $(colorize "$RB_C_BOLD" "$active_count") file(s)..."
  printf "\n"

  local progress_current=0

  # Activate the trap right before the loop starts
  trap 'handle_interrupt' SIGINT

  for ((idx = 0; idx < total_files; idx++)); do
    local src="${file_old_names[$idx]}"
    local dst="${dest_names[$idx]}"
    local src_name
    src_name="${src##*/}"
    local dst_name
    dst_name="${dst##*/}"

    if [[ "$src" == "$dst" ]]; then
      skipped_count=$((skipped_count + 1))

      # Use your helper function to tag the reason accurately in the summary
      if is_excluded_file "$src"; then
        skipped_list+=("$src_name (excluded)")
      else
        skipped_list+=("$src_name (already .${new_ext})")
      fi
      continue
    fi

    progress_current=$((progress_current + 1))
    draw_progress "$progress_current" "$active_count" "$src_name"

    if [[ -e "$dst" ]]; then
      skipped_count=$((skipped_count + 1))
      skipped_list+=("$src_name (destination exists)")
      continue
    fi

    local op_status=0
    local dst_dir
    if [[ "$dst" == */* ]]; then
      dst_dir="${dst%/*}"
    else
      dst_dir="."
    fi
    if ! mkdir -p "$dst_dir"; then
      failed_count=$((failed_count + 1))
      failed_files+=("$src_name (cannot create destination directory)")
      msg_error "Failed to create destination directory: $dst_dir"
      continue
    fi
    if [[ "$mode" == "copy" ]]; then
      if cp -- "$src" "$dst"; then
        : # success
      else
        op_status=$?
      fi
    else
      if mv -- "$src" "$dst"; then
        : # success
      else
        op_status=$?
      fi
    fi

    if ((op_status == 0)); then
      success_count=$((success_count + 1))
      renamed_files+=("$dst_name")
      # Track the exact paths for a potential rollback
      ROLLBACK_SRC+=("$src")
      ROLLBACK_DST+=("$dst")
    else
      failed_count=$((failed_count + 1))
      failed_files+=("$src_name (exit: ${op_status})")
      # Clear the progress line before printing the error
      printf "%s" $'\033[2K\r'
      msg_error "Failed: $(colorize "$RB_C_BOLD" "$src") → $(colorize "$RB_C_BOLD" "$dst") (exit: ${op_status})"
    fi
  done

  # Final draw at 100%, then move to a new line
  draw_progress "$active_count" "$active_count" "Complete"
  printf "\n\n"

  # Deactivate the trap
  trap - SIGINT

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  uk_section_title "Operation Complete — processed in $(format_duration "$duration")"

  printf "  %s  %s\n" "$(colorize "$RB_C_GREEN" "$RB_I_TICK")" "$(colorize "$RB_C_BOLD" "Summary")"
  printf "\n"
  printf "    %s  Success:  %s\n" "$(colorize "$RB_C_GREEN" "$RB_I_SUCCESS")" "$(colorize "${RB_C_BOLD}${RB_C_GREEN}" "$success_count")"
  printf "    %s   Skipped:  %s\n" "$(colorize "$RB_C_YELLOW" "$RB_I_WARNING")" "$(colorize "${RB_C_BOLD}${RB_C_YELLOW}" "$skipped_count")"
  printf "    %s  Failed:   %s\n" "$(colorize "$RB_C_RED" "$RB_I_ERROR")" "$(colorize "${RB_C_BOLD}${RB_C_RED}" "$failed_count")"
  if ((total_files > 0)); then
    local success_rate=$(((success_count * 100) / total_files))
    printf "    %s\n" "$(colorize "$RB_C_DIM" "───────")"
    printf "    %s  Total:    %s  %s\n" "$(colorize "$RB_C_CYAN" "$RB_I_LOZENGE")" "$(colorize "$RB_C_BOLD" "$total_files")" "$(colorize "$RB_C_DIM" "(${success_rate}% success)")"
  fi
  printf "\n"

  if ((${#renamed_files[@]} > 0)); then
    printf "  %s  Renamed files:\n" "$(colorize "$RB_C_GREEN" "$RB_I_TICK")"
    local shown=0
    for f in "${renamed_files[@]}"; do
      ((shown >= 10)) && break
      printf "    %s  %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" "$(colorize "$RB_C_GREEN_BRIGHT" "$f")"
      shown=$((shown + 1))
    done
    if ((${#renamed_files[@]} > 10)); then
      printf "    %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ELLIPSIS} and $((${#renamed_files[@]} - 10)) more")"
    fi
    printf "\n"
  fi

  if ((${#skipped_list[@]} > 0)); then
    printf "  %s Skipped:\n" "$(colorize "$RB_C_YELLOW" "$RB_I_WARNING")"
    local shown=0
    for f in "${skipped_list[@]}"; do
      ((shown >= 10)) && break
      printf "    %s  %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" "$(colorize "$RB_C_YELLOW" "$f")"
      shown=$((shown + 1))
    done
    if ((${#skipped_list[@]} > 10)); then
      printf "    %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ELLIPSIS} and $((${#skipped_list[@]} - 10)) more")"
    fi
    printf "\n"
  fi

  if ((${#failed_files[@]} > 0)); then
    printf "  %s  Failed:\n" "$(colorize "$RB_C_RED" "$RB_I_ERROR")"
    for f in "${failed_files[@]}"; do
      printf "    %s  %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" "$(colorize "$RB_C_RED" "$f")"
    done
    printf "\n"
  fi

  if [[ "$mode" == "copy" ]]; then
    msg_info "Originals preserved in: $(colorize "$RB_C_DIM" "$source_dir")"
    msg_info "Renamed copies in:    $(colorize "${RB_C_BOLD}${RB_C_CYAN}" "$output_dir")"
  else
    msg_info "Files renamed in-place at: $(colorize "$RB_C_DIM" "$source_dir")"
  fi
  printf "\n"

  if ((failed_count > 0 && success_count > 0)); then
    return 2
  elif ((failed_count > 0)); then
    return 1
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  rb_main "$@"
fi
