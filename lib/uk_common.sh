#!/usr/bin/env bash
# Shared UtilityKit helpers

if [[ -n "${UK_COMMON_SH_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
readonly UK_COMMON_SH_LOADED=1
readonly UK_VERSION='2.1.0'

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
uk_note() { printf ' %s%s%s %s\n' "$UK_C_BLUE" "$UK_I_INFO" "$UK_C_RESET" "$*"; }
uk_info() { printf ' %s%s%s %s\n' "$UK_C_CYAN" "$UK_I_INFO" "$UK_C_RESET" "$*"; }
uk_success() { printf ' %s%s%s %s\n' "$UK_C_GREEN" "$UK_I_OK" "$UK_C_RESET" "$*"; }
uk_warn() { printf ' %s%s%s %s\n' "$UK_C_YELLOW" "$UK_I_WARN" "$UK_C_RESET" "$*" >&2; }
uk_error() { printf ' %s%s%s %s\n' "$UK_C_RED" "$UK_I_ERR" "$UK_C_RESET" "$*" >&2; }
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

  local l1="  $icon UtilityKit $UK_I_SEP $name  v$UK_VERSION  "
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

  local pad1=$(((inner - n1) / 2))
  local pad1_r=$((inner - n1 - pad1))
  printf '%s%s%s%*s%s%*s%s%s%s\n' \
    "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET" \
    "$pad1" '' \
    "$UK_C_BOLD$UK_C_BRIGHT_CYAN$l1$UK_C_RESET" \
    "$pad1_r" '' \
    "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET"

  if [[ -n "$tagline" ]]; then
    local pad2=$(((inner - n2) / 2))
    local pad2_r=$((inner - n2 - pad2))
    printf '%s%s%s%*s%s%*s%s%s%s\n' \
      "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET" \
      "$pad2" '' \
      "$UK_C_DIM$l2$UK_C_RESET" \
      "$pad2_r" '' \
      "$UK_C_BRIGHT_CYAN" "$v" "$UK_C_RESET"
  fi

  local pad3=$(((inner - n3) / 2))
  local pad3_r=$((inner - n3 - pad3))
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
# uk_term_size — write "$cols $rows" to stdout. Falls back through tput → stty
# → $COLUMNS/$LINES → 80x24, matching the pattern already used by uk_banner.
uk_term_size() {
  local cols='' rows=''
  if uk_has_cmd tput; then
    cols="$(tput cols 2>/dev/null || true)"
    rows="$(tput lines 2>/dev/null || true)"
  fi
  if [[ -z "$cols" || -z "$rows" ]] && uk_has_cmd stty; then
    local size
    size="$(stty size 2>/dev/null || true)"
    if [[ -n "$size" ]]; then
      rows="${size%% *}"
      cols="${size##* }"
    fi
  fi
  [[ "$cols" =~ ^[0-9]+$ ]] || cols="${COLUMNS:-80}"
  [[ "$rows" =~ ^[0-9]+$ ]] || rows="${LINES:-24}"
  printf '%s %s\n' "$cols" "$rows"
}

# uk_require_width — block until the terminal is exactly UK_REQUIRED_COLS wide
# (default 78). Renders a horizontally + vertically centred notice box asking
# the user to resize. Returns 0 when the width is correct, 130 if the user
# bails with q / Ctrl-C.
#
# No-ops when:
#   - stdout is not a TTY (piped, redirected, or under the smoke tests)
#   - UK_NO_WIDTH_GATE is set (escape hatch for CI / power users)
#   - the width is already exactly right
uk_require_width() {
  local required="${UK_REQUIRED_COLS:-78}"
  [[ -t 1 ]] || return 0
  [[ -n "${UK_NO_WIDTH_GATE:-}" ]] && return 0

  local cols rows size
  size="$(uk_term_size)"
  cols="${size%% *}"
  rows="${size##* }"
  [[ "$cols" == "$required" ]] && return 0

  # Box glyphs — respect NO_UNICODE just like uk_banner does.
  local tl tr bl br h v
  if [[ -z "${NO_UNICODE:-}" ]]; then
    tl='╭' tr='╮' bl='╰' br='╯' h='─' v='│'
  else
    tl='+' tr='+' bl='+' br='+' h='-' v='|'
  fi

  # Hide the cursor while the gate is drawing; always restore on the way out.
  # Note: interactive_menu_loop hides the cursor itself once we return, and
  # its EXIT trap ensures the cursor is restored on abnormal exit — so we
  # only need to be tidy about our own return paths here.
  tput civis 2>/dev/null || printf '\033[?25l'

  # Spinner frames — the ONLY thing that redraws every tick, so the rest of
  # the box stays perfectly still and readable. NO_UNICODE users get an ASCII
  # fallback so the frame widths stay equal (1 cell each).
  local spinner
  if [[ -z "${NO_UNICODE:-}" ]]; then
    spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  else
    spinner=('|' '/' '-' '\')
  fi
  local sp_len=${#spinner[@]}

  local key='' tick=0 prev_cols='' prev_rows=''
  # Geometry cache populated by _uk_render_width_notice_full (screen-absolute,
  # 1-indexed for \033[row;colH). Reused by _uk_render_width_notice_tick so
  # we only ever rewrite a single line per poll.
  _UK_WG_TOP=0 _UK_WG_LEFT=0 _UK_WG_INNER=0 _UK_WG_DYN_ROW=0

  while :; do
    size="$(uk_term_size)"
    cols="${size%% *}"
    rows="${size##* }"

    if [[ "$cols" == "$required" ]]; then
      tput cnorm 2>/dev/null || printf '\033[?25h'
      clear 2>/dev/null || printf '\n'
      return 0
    fi

    # Only do a full repaint when the terminal actually changed size (or on
    # the very first frame). Otherwise the box stays exactly where it was
    # and only the dynamic line ticks.
    if [[ "$cols" != "$prev_cols" || "$rows" != "$prev_rows" ]]; then
      _uk_render_width_notice_full "$cols" "$rows" "$required" \
        "$tl" "$tr" "$bl" "$br" "$h" "$v"
      prev_cols="$cols"
      prev_rows="$rows"
    fi

    _uk_render_width_notice_tick "$cols" "$required" "$v" \
      "${spinner[$((tick % sp_len))]}"
    tick=$((tick + 1))

    # Poll for input every 0.15 s — smooth spinner, still cheap. Any key
    # other than q/Q is ignored so accidental taps don't skip the check.
    key=''
    if IFS= read -rsn1 -t 0.15 key 2>/dev/null; then
      case "$key" in
      q | Q)
        tput cnorm 2>/dev/null || printf '\033[?25h'
        clear 2>/dev/null || printf '\n'
        return 130
        ;;
      esac
    fi
  done
}

# Internal — full one-shot paint of the centred resize notice. Called only
# when the terminal size changes (or on the very first frame). Caches the
# top-left corner + inner width + dynamic-line row into global geometry vars
# so _uk_render_width_notice_tick can rewrite a single line without touching
# the rest of the screen.
_uk_render_width_notice_full() {
  local cols="$1" rows="$2" required="$3"
  local tl="$4" tr="$5" bl="$6" br="$7" h="$8" v="$9"

  # Full-screen wipe — ONLY here, so the box no longer flickers between ticks.
  clear 2>/dev/null || printf '\033[2J\033[H'

  local diff verb
  diff=$((cols - required))
  if ((diff > 0)); then
    verb="Shrink the window (or zoom IN)"
  else
    verb="Widen the window (or zoom OUT)"
  fi

  local title="  ${UK_I_WARN} Terminal width mismatch  "
  local l1="UtilityKit renders best at exactly ${required} columns."
  # Static hint so the LIVE line is the only one that moves each tick.
  local l3="${verb} until \`tput cols\` reports ${required}."
  local l4="Then this notice will clear automatically."
  local hint="[ q ] skip check     resize live-checked below"

  # Reserve a width for the live line based on its widest possible layout:
  #   "  ⣾  Current: 9999   Target: 9999   Off by: 9999  "
  local live_template="  X  Current: 9999   Target: 9999   Off by: 9999  "

  # Compute box inner width from the widest static/reserved line.
  local inner=0 len line
  for line in "$title" "$l1" "$l3" "$l4" "$hint" "$live_template"; do
    len="$(uk_visible_len "$line")"
    ((len > inner)) && inner=$len
  done
  inner=$((inner + 4))

  # Terminal too narrow — one-line fallback (no live tick, no cursor moves).
  if ((cols < inner + 2)); then
    printf '\n%s%s%s Resize terminal to %s cols (current: %s). Press q to skip.%s\n' \
      "$UK_C_YELLOW" "$UK_I_WARN" "$UK_C_RESET" "$required" "$cols" ""
    _UK_WG_TOP=0 _UK_WG_LEFT=0 _UK_WG_INNER=0 _UK_WG_DYN_ROW=0
    return 0
  fi

  local hbar='' i
  for ((i = 0; i < inner; i++)); do hbar+="$h"; done

  # 10 rows total. Index 4 is the LIVE line — kept as an empty inner row here
  # so the tick can paint into it without disturbing anything else.
  local blank_row="${v}$(printf '%*s' "$inner" '')${v}"
  local rendered=()
  rendered+=("${tl}${hbar}${tr}")
  rendered+=("$(_uk_center_line "$title" "$inner" "$v" bold_cyan)")
  rendered+=("$blank_row")
  rendered+=("$(_uk_center_line "$l1" "$inner" "$v" bold)")
  rendered+=("$blank_row") # ← LIVE
  rendered+=("$(_uk_center_line "$l3" "$inner" "$v" plain)")
  rendered+=("$(_uk_center_line "$l4" "$inner" "$v" dim)")
  rendered+=("$blank_row")
  rendered+=("$(_uk_center_line "$hint" "$inner" "$v" arrow)")
  rendered+=("${bl}${hbar}${br}")
  local live_row_idx=4

  # Vertical centring (screen rows are 1-indexed for cursor addressing).
  local box_h=${#rendered[@]}
  local top=$(((rows - box_h) / 2 + 1))
  ((top < 1)) && top=1

  # Horizontal centring — column of the box's leftmost cell (1-indexed).
  local left=$(((cols - inner - 2) / 2 + 1))
  ((left < 1)) && left=1

  # Draw every row at an absolute (row,col) position — no reliance on the
  # cursor being anywhere in particular.
  local n
  for ((n = 0; n < box_h; n++)); do
    printf '\033[%d;%dH%s%s%s' \
      "$((top + n))" "$left" \
      "$UK_C_BRIGHT_CYAN" "${rendered[$n]}" "$UK_C_RESET"
  done

  # Cache geometry for the per-tick redraw.
  _UK_WG_TOP="$top"
  _UK_WG_LEFT="$left"
  _UK_WG_INNER="$inner"
  _UK_WG_DYN_ROW=$((top + live_row_idx))
}

# Internal — rewrites ONLY the live line (spinner + current cols + off-by).
# Absolute cursor addressing means the rest of the box is never touched, so
# there is no visible flicker even at high poll rates.
_uk_render_width_notice_tick() {
  local cols="$1" required="$2" v="$3" spin="$4"
  # Full-paint mode did the drawing already; nothing to update.
  ((_UK_WG_INNER > 0)) || return 0

  local diff abs_diff
  diff=$((cols - required))
  abs_diff=$diff
  ((abs_diff < 0)) && abs_diff=$((-abs_diff))

  local text
  text="$(printf '  %s  Current: %d   Target: %d   Off by: %d  ' \
    "$spin" "$cols" "$required" "$abs_diff")"

  local vis pad_l pad_r
  vis="$(uk_visible_len "$text")"
  ((vis > _UK_WG_INNER)) && vis=$_UK_WG_INNER
  pad_l=$(((_UK_WG_INNER - vis) / 2))
  pad_r=$((_UK_WG_INNER - vis - pad_l))

  # Jump to the reserved live row, redraw exactly one line's worth of cells.
  # Order: [left bar] [pad_l] [styled text] [pad_r] [right bar] [reset]
  printf '\033[%d;%dH%s%s%*s%s%*s%s%s' \
    "$_UK_WG_DYN_ROW" "$_UK_WG_LEFT" \
    "$UK_C_BRIGHT_CYAN" "$v" \
    "$pad_l" '' \
    "${UK_C_YELLOW}${text}${UK_C_RESET}${UK_C_BRIGHT_CYAN}" \
    "$pad_r" '' \
    "$v" \
    "$UK_C_RESET"

  # Park the cursor safely below the box so any accidental echo stays out
  # of the frame.
  printf '\033[%d;1H' "$((_UK_WG_TOP + 12))"
}

# Internal — pad `text` to `inner` visible columns and wrap it in the box's
# vertical bars, applying the requested colour style.
_uk_center_line() {
  local text="$1" inner="$2" v="$3" style="$4"
  local vis pad_l pad_r styled
  vis="$(uk_visible_len "$text")"
  ((vis > inner)) && vis=$inner
  pad_l=$(((inner - vis) / 2))
  pad_r=$((inner - vis - pad_l))

  case "$style" in
  bold_cyan) styled="${UK_C_BOLD}${UK_C_BRIGHT_CYAN}${text}${UK_C_RESET}${UK_C_BRIGHT_CYAN}" ;;
  bold) styled="${UK_C_BOLD}${text}${UK_C_RESET}${UK_C_BRIGHT_CYAN}" ;;
  dim) styled="${UK_C_DIM}${text}${UK_C_RESET}${UK_C_BRIGHT_CYAN}" ;;
  arrow) styled="${UK_C_YELLOW}${text}${UK_C_RESET}${UK_C_BRIGHT_CYAN}" ;;
  *) styled="${text}" ;;
  esac

  printf '%s%*s%s%*s%s' "$v" "$pad_l" '' "$styled" "$pad_r" '' "$v"
}
