#!/usr/bin/env bash
# Shared UtilityKit helpers

if [[ -n "${UK_COMMON_SH_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
readonly UK_COMMON_SH_LOADED=1
readonly UK_VERSION='5.10.6'

# uk_load_config — apply ${XDG_CONFIG_HOME:-~/.config}/utilitykit/config
# (path overridable via UK_CONFIG_FILE) so suite-wide defaults like
# DEFAULT_CACHE_OLDER_THAN=30 can be set once instead of retyped as flags.
# The file is parsed, never sourced: only `[export] KEY=VALUE` lines are
# accepted, so a stray command cannot execute and a typo cannot abort every
# tool under `set -eu`. Values may be bare or single/double quoted; blank
# lines and `# comments` (full-line or after an unquoted value) are ignored;
# anything else is skipped with a warning on stderr.
# Precedence: flag > environment > config file > built-in default — a key
# already set in the environment (even to empty) is never overwritten.
uk_load_config() {
  local file="${UK_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/utilitykit/config}"
  [[ -f "$file" && -r "$file" ]] || return 0

  local re_kv='^([A-Za-z_][A-Za-z0-9_]*)=(.*)$'
  local re_dq='^"([^"]*)"[[:space:]]*(#.*)?$'
  local re_sq="^'([^']*)'[[:space:]]*(#.*)?\$"
  local line key value lineno=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" =~ ^export[[:space:]]+ ]]; then
      line="${line#export}"
      line="${line#"${line%%[![:space:]]*}"}"
    fi

    if [[ ! "$line" =~ $re_kv ]]; then
      printf 'utilitykit: %s:%d skipped (expected KEY=VALUE): %s\n' "$file" "$lineno" "$line" >&2
      continue
    fi
    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"

    case "$value" in
    \"*)
      if [[ "$value" =~ $re_dq ]]; then
        value="${BASH_REMATCH[1]}"
      else
        printf 'utilitykit: %s:%d skipped (unterminated quote): %s\n' "$file" "$lineno" "$line" >&2
        continue
      fi
      ;;
    \'*)
      if [[ "$value" =~ $re_sq ]]; then
        value="${BASH_REMATCH[1]}"
      else
        printf 'utilitykit: %s:%d skipped (unterminated quote): %s\n' "$file" "$lineno" "$line" >&2
        continue
      fi
      ;;
    *)
      value="${value%%[[:space:]]\#*}"
      value="${value%"${value##*[![:space:]]}"}"
      ;;
    esac

    [[ -n "${!key+x}" ]] && continue
    # The key regex keeps printf -v safe (no array-subscript injection);
    # `|| true` shields readonly collisions from set -e.
    printf -v "$key" '%s' "$value" 2>/dev/null || true
  done <"$file"
  return 0
}

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
    UK_C_BRIGHT_GREEN=$'\033[92m'
    UK_C_BRIGHT_RED=$'\033[91m'
    UK_C_BRIGHT_YELLOW=$'\033[93m'
  else
    UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN='' UK_C_YELLOW=''
    UK_C_BLUE='' UK_C_MAGENTA='' UK_C_CYAN='' UK_C_WHITE='' UK_C_BRIGHT_BLUE=''
    UK_C_BRIGHT_CYAN='' UK_C_BRIGHT_MAGENTA='' UK_C_BRIGHT_GREEN='' UK_C_BRIGHT_RED='' UK_C_BRIGHT_YELLOW=''
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
    UK_I_CLAUDE='✽'
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
    UK_I_CLAUDE='∅'
    UK_I_DOT='-'
  fi
}

uk_load_config
uk_setup_visuals

uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }
uk_is_interactive() { [[ -t 0 && -t 1 ]]; }
uk_platform() {
  if [[ -n "${TERMUX_VERSION:-}" ]]; then
    printf 'termux\n'
    return 0
  fi
  local system
  if ! system="$(uname -s 2>/dev/null)"; then
    uk_error 'Unable to determine the current platform.'
    return 1
  fi
  if [[ "$system" == "Darwin" ]]; then
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
  if ! mkdir -p "$dir"; then
    uk_error "Unable to create data directory: $dir"
    return 1
  fi
  printf '%s\n' "$dir"
}
uk_state_dir() {
  local dir="${XDG_STATE_HOME:-$HOME/.local/state}/utilitykit"
  if ! mkdir -p "$dir"; then
    uk_error "Unable to create state directory: $dir"
    return 1
  fi
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
    if ! read -r reply </dev/tty; then
      uk_error 'Unable to read confirmation input.'
      return 2
    fi
  else
    if ! read -r reply; then
      uk_error 'Unable to read confirmation input.'
      return 2
    fi
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
    if ! read -r reply </dev/tty; then
      uk_error 'Unable to read prompt input.'
      return 1
    fi
  else
    if ! read -r reply; then
      uk_error 'Unable to read prompt input.'
      return 1
    fi
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
# Populates UK_SPINNER_FRAMES with the canonical animation frames, honoring
# NO_UNICODE at call time (not source time) so tools that flip modes late
# still get the right glyph set. Every frame is exactly 1 cell wide.
uk_spinner_frames() {
  if [[ -z "${NO_UNICODE:-}" ]]; then
    UK_SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  else
    UK_SPINNER_FRAMES=('|' '/' '-' '\')
  fi
}

# uk_spinner [--prefix STR] [--label-file FILE] [--elapsed] [--interval S] <pid> <label>
# Canonical wait-on-a-background-job spinner. Animates frames next to the
# label until <pid> exits, then erases its own line and returns the job's
# exit status. Honors NO_UNICODE (ASCII frames) and NO_COLOR at call time.
# Non-TTY stdout prints "<label>... " once with no animation.
#   --prefix STR      static text drawn between the frame and the label
#   --label-file FILE re-read FILE every tick for a live label (falls back
#                     to <label> while FILE is empty or missing)
#   --elapsed         append a running "Ns" seconds counter
#   --interval S      frame delay in seconds (default 0.08)
uk_spinner() {
  local prefix='' label_file='' show_elapsed=0 interval=0.08
  while [[ "${1:-}" == --* ]]; do
    case "${1:-}" in
    --prefix)
      shift
      prefix="${1:-}"
      ;;
    --label-file)
      shift
      label_file="${1:-}"
      ;;
    --elapsed) show_elapsed=1 ;;
    --interval)
      shift
      interval="${1:-0.08}"
      ;;
    *) break ;;
    esac
    shift
  done
  local pid="${1:-}" label="${2:-}" rc=0
  [[ -n "$pid" ]] || return 1

  if [[ ! -t 1 ]]; then
    printf '%s... ' "${prefix:+$prefix }$label"
    wait "$pid" || rc=$?
    return "$rc"
  fi

  uk_spinner_frames
  local c_frame="$UK_C_CYAN" c_reset="$UK_C_RESET" ell='…'
  [[ -n "${NO_COLOR:-}" ]] && c_frame='' c_reset=''
  [[ -n "${NO_UNICODE:-}" ]] && ell='.'

  local n=${#UK_SPINNER_FRAMES[@]} i=0 start now cols budget line
  start="$(date +%s)"

  while kill -0 "$pid" 2>/dev/null; do
    if [[ -n "$label_file" && -s "$label_file" ]]; then
      label="$(<"$label_file")"
    fi
    line="${prefix:+$prefix }$label"
    if ((show_elapsed == 1)); then
      now="$(date +%s)"
      line="$line $((now - start))s"
    fi

    # Never print wider than the terminal: a wrapped line breaks the \r
    # redraw and the spinner "walks" down the screen.
    cols="${COLUMNS:-0}"
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=0
    if ((cols <= 0)); then
      cols="$(tput cols 2>/dev/null || printf '80')"
      [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
    fi
    budget=$((cols - 4))
    ((budget < 8)) && budget=8
    ((${#line} > budget)) && line="${line:0:budget-1}$ell"

    printf '\r\033[K %s%s%s %s' "$c_frame" "${UK_SPINNER_FRAMES[i % n]}" "$c_reset" "$line"
    i=$((i + 1))
    sleep "$interval"
  done

  wait "$pid" || rc=$?
  printf '\r\033[K'
  return "$rc"
}

# uk_fake_progress <pid> <label> [done_label]
# Indeterminate percent bar for a background job of unknown duration: the
# percentage accelerates toward 99% and holds until <pid> exits, then a full
# green 100% bar (or a red failure line with the exit code) is printed.
# Returns the job's exit status. Non-TTY stdout waits with no output.
uk_fake_progress() {
  local pid="${1:-}" label="${2:-working...}" done_label="${3:-done.}"
  local rc=0 width=28 pct=0 fill empty bar_fill bar_empty
  [[ -n "$pid" ]] || return 1

  if [[ ! -t 1 ]]; then
    wait "$pid" || rc=$?
    return "$rc"
  fi

  local ch_fill ch_empty
  if [[ -z "${NO_UNICODE:-}" ]]; then
    ch_fill='█' ch_empty='░'
  else
    ch_fill='#' ch_empty='-'
  fi
  local c_bar="$UK_C_CYAN" c_done="$UK_C_GREEN" c_fail="$UK_C_RED"
  local c_dim="$UK_C_DIM" c_bold="$UK_C_BOLD" c_reset="$UK_C_RESET"
  [[ -n "${NO_COLOR:-}" ]] && c_bar='' c_done='' c_fail='' c_dim='' c_bold='' c_reset=''

  printf '\n'
  while kill -0 "$pid" 2>/dev/null; do
    if ((pct < 50)); then
      pct=$((pct + 4))
    elif ((pct < 99)); then
      pct=$((pct + 1))
    fi
    ((pct > 99)) && pct=99

    fill=$((pct * width / 100))
    empty=$((width - fill))
    printf -v bar_fill '%*s' "$fill" ''
    printf -v bar_empty '%*s' "$empty" ''
    bar_fill="${bar_fill// /$ch_fill}"
    bar_empty="${bar_empty// /$ch_empty}"

    printf '\r  %s%s%s [%s%s%s%s%s] %s%3d%%%s  %s' \
      "$c_bar" "$UK_I_WORK" "$c_reset" \
      "$c_bar" "$bar_fill" "$c_dim" "$bar_empty" "$c_reset" \
      "$c_bold" "$pct" "$c_reset" "$label"

    # Re-check before sleeping so we exit promptly when the job finishes
    # instead of burning a long final tick.
    kill -0 "$pid" 2>/dev/null || break
    if ((pct < 50)); then
      sleep 0.06
    elif ((pct < 85)); then
      sleep 0.25
    else
      sleep 0.80
    fi
  done

  wait "$pid" || rc=$?

  printf -v bar_fill '%*s' "$width" ''
  bar_fill="${bar_fill// /$ch_fill}"
  if ((rc == 0)); then
    printf '\r\033[K  %s%s%s [%s%s%s] %s100%%%s  %s\n' \
      "$c_done" "$UK_I_OK" "$c_reset" \
      "$c_done" "$bar_fill" "$c_reset" \
      "$c_bold" "$c_reset" "$done_label"
  else
    printf '\r\033[K  %s%s%s [%s%s%s] %s%s failed (exit %d)%s\n' \
      "$c_fail" "$UK_I_ERR" "$c_reset" \
      "$c_fail" "$bar_fill" "$c_reset" \
      "$c_bold" "$label" "$rc" "$c_reset" >&2
  fi
  return "$rc"
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
    term_width="$(tput cols 2>/dev/null || true)"
  fi
  if [[ -z "$term_width" ]] && uk_has_cmd stty; then
    term_width="$(stty size 2>/dev/null | cut -d' ' -f2 || true)"
  fi
  if [[ -z "$term_width" ]]; then
    term_width="${COLUMNS:-80}"
  fi

  # Failsafe in case term_width is still somehow invalid or unreasonable.
  if ! _uk_valid_term_dimension "$term_width"; then
    term_width=80
  else
    term_width=$((10#$term_width))
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
_uk_valid_term_dimension() {
  local value="${1:-}"
  [[ "$value" =~ ^[0-9]{1,5}$ ]] || return 1
  ((10#$value >= 1 && 10#$value <= 10000))
}
# uk_term_size — write "$cols $rows" to stdout. Falls back through tput → stty
# → $COLUMNS/$LINES → 80x24, matching the pattern already used by uk_banner.
uk_term_size() {
  local cols='' rows=''
  if uk_has_cmd tput; then
    cols="$(tput cols 2>/dev/null || true)"
    rows="$(tput lines 2>/dev/null || true)"
  fi
  if { ! _uk_valid_term_dimension "$cols" || ! _uk_valid_term_dimension "$rows"; } && uk_has_cmd stty; then
    local size
    size="$(stty size 2>/dev/null || true)"
    if [[ -n "$size" ]]; then
      rows="${size%% *}"
      cols="${size##* }"
    fi
  fi
  _uk_valid_term_dimension "$cols" || cols="${COLUMNS:-}"
  _uk_valid_term_dimension "$rows" || rows="${LINES:-}"
  _uk_valid_term_dimension "$cols" || cols=80
  _uk_valid_term_dimension "$rows" || rows=24
  cols=$((10#$cols))
  rows=$((10#$rows))
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
  if ! _uk_valid_term_dimension "$required"; then
    uk_error "UK_REQUIRED_COLS must be an integer from 1 to 10000: $required"
    return 2
  fi
  required=$((10#$required))
  [[ -t 1 ]] || return 0
  [[ -n "${UK_NO_WIDTH_GATE:-}" ]] && return 0

  local cols rows size
  if ! size="$(uk_term_size)"; then
    uk_error 'Unable to determine terminal size.'
    return 1
  fi
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
  # the box stays perfectly still and readable. Shared canonical frame set;
  # NO_UNICODE users get the ASCII fallback (1 cell each either way).
  uk_spinner_frames
  local sp_len=${#UK_SPINNER_FRAMES[@]}

  local key='' tick=0 prev_cols='' prev_rows=''
  # Geometry cache populated by _uk_render_width_notice_full (screen-absolute,
  # 1-indexed for \033[row;colH). Reused by _uk_render_width_notice_tick so
  # we only ever rewrite a single line per poll.
  _UK_WG_TOP=0 _UK_WG_LEFT=0 _UK_WG_INNER=0 _UK_WG_DYN_ROW=0

  while :; do
    if ! size="$(uk_term_size)"; then
      tput cnorm 2>/dev/null || printf '\033[?25h'
      uk_error 'Unable to refresh terminal size.'
      return 1
    fi
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
      "${UK_SPINNER_FRAMES[$((tick % sp_len))]}"
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
# =============================================================================
# uk_output_format — shared table / JSON / CSV rendering for tools.
#
# Problem this solves: many tools hand-roll `python3 -c 'import json…'` string
# escaping (or a brittle sed fallback) every time they add a `--json` flag.
# New tools should get rendering for free by accumulating rows with the helpers
# below and calling a single render routine.
#
# Three layers:
#
#   1. Escaping helpers (safe to use standalone):
#        uk_json_escape <string>      -> emit a quoted, escaped JSON string
#        uk_json_str <key> <string>   -> emit `"key":<escaped>`
#        uk_json_lit <key> <json>     -> emit `"key":<json>` (value is RAW JSON)
#        uk_json_obj <fragments...>    -> emit `{…}` from `"k":v` fragments
#        uk_json_arr <items...>       -> emit `[…]` from already-built items
#
#   2. Row accumulator (the table/CSV/JSON multiplexer):
#        uk_table_init <h1> <h2> …        -> reset + declare column headers
#        uk_table_row  <c1> <c2> …       -> append one row
#        uk_table_count                    -> echo number of accumulated rows
#        uk_table_render [--format X]      -> emit rows in the chosen format
#
#      Format resolution (lowest -> highest precedence):
#        UK_FMT env var  ->  --format/--json/--csv flag  ->  TTY? table : json
#      so a tool that just calls `uk_table_render` does the right thing in a
#      pipe (JSON) vs. a terminal (table) without any flags.
#
#   3. Flag parsing helper:
#        uk_out_format_from_args "$@"  -> set UK_FMT and return (via $?) the
#        number of args consumed; caller does `shift $?`. Recognises
#        --json, --csv, and `--format <fmt>`.
#
# All functions are safe under `set -euo pipefail` and never clobber the
# UK_C_* colour variables. They degrade gracefully when python3 is absent.
# =============================================================================

# uk_json_escape <string> — write a JSON-escaped, double-quoted string.
uk_json_escape() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

# uk_json_str <key> <string> — emit `"key":<escaped string>`.
uk_json_str() {
  printf '"%s":%s' "$1" "$(uk_json_escape "${2:-}")"
}

# uk_json_lit <key> <json-value> — emit `"key":<raw json>` (no escaping).
uk_json_lit() {
  printf '"%s":%s' "$1" "${2:-}"
}

# uk_json_arr <item> [item …] — emit `[item,item,…]` of pre-built JSON.
uk_json_arr() {
  local first=1
  printf '['
  for item in "$@"; do
    (( first )) || printf ','
    printf '%s' "$item"
    first=0
  done
  printf ']'
}

# uk_json_obj <fragment> [fragment …] — emit `{"k":v,"k":v,…}`.
# Each argument is a ready-made `"key":value` fragment produced by
# uk_json_str / uk_json_lit or written by hand. Fragments are joined with
# commas, so callers never need to track the "first" comma themselves.
uk_json_obj() {
  local first=1
  printf '{'
  for frag in "$@"; do
    (( first )) || printf ','
    printf '%s' "$frag"
    first=0
  done
  printf '}'
}

# ---- Row accumulator -------------------------------------------------------

# uk_table_init <h1> <h2> … — reset the accumulator and declare headers.
uk_table_init() {
  UK_T_HEADERS=("$@")
  UK_T_ROWS=()
}

# uk_table_row <c1> <c2> … — append a row; cell count must equal header count.
uk_table_row() {
  UK_T_ROWS+=("$#|$(printf '%s ' "$@")")
}

# uk_table_count — echo number of accumulated rows (handy for "0 results").
uk_table_count() {
  printf '%s\n' "${#UK_T_ROWS[@]}"
}

# _uk_table_resolve_fmt <explicit> — echo final format respecting env + TTY.
_uk_table_resolve_fmt() {
  local explicit="${1:-}"
  if [[ -n "$explicit" ]]; then
    printf '%s\n' "$explicit"
  elif [[ -n "${UK_FMT:-}" ]]; then
    printf '%s\n' "$UK_FMT"
  elif [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    printf 'table\n'
  else
    printf 'json\n'
  fi
}

# _uk_table_split <rowvar> — split a stored row into `ncells` + `cells` names.
# Stored rows look like `N|cell0 cell1 …`; cells are space-joined.
_uk_table_split() {
  local row="$1"
  UK_T_NCELLS="${row%%|*}"
  UK_T_CELLS="${row#*|}"
  # shellcheck disable=SC2162
  IFS=' ' read -ra UK_T_PARSED <<<"$UK_T_CELLS"
}

# uk_table_render [--format table|json|csv] — emit the accumulated rows.
uk_table_render() {
  local fmt=''
  while [[ "${1:-}" == --* ]]; do
    case "${1:-}" in
      --format) shift; fmt="${1:-}" ;;
      *) break ;;
    esac
    shift || true
  done
  fmt="$(_uk_table_resolve_fmt "$fmt")"

  local -a H=("${UK_T_HEADERS[@]}")
  local ncol=${#H[@]} i row

  if [[ "$fmt" == "csv" ]]; then
    local cell
    for ((i = 0; i < ncol; i++)); do
      (( i )) && printf ','
      cell="${H[i]}"
      if [[ "$cell" == *[,\"$'\n']* ]]; then
        cell="\"${cell//\"/\"\"}\""
      fi
      printf '%s' "$cell"
    done
    printf '\n'
    for row in "${UK_T_ROWS[@]}"; do
      _uk_table_split "$row"
      for ((i = 0; i < ncol; i++)); do
        (( i )) && printf ','
        cell="${UK_T_PARSED[i]:-}"
        if [[ "$cell" == *[,\"$'\n']* ]]; then
          cell="\"${cell//\"/\"\"}\""
        fi
        printf '%s' "$cell"
      done
      printf '\n'
    done
    return 0
  fi

  if [[ "$fmt" == "json" ]]; then
    local first=1 obj
    printf '['
    for row in "${UK_T_ROWS[@]}"; do
      _uk_table_split "$row"
      obj=''
      for ((i = 0; i < ncol; i++)); do
        [[ -n "$obj" ]] && obj+=' '
        obj+="$(uk_json_str "${H[i]}" "${UK_T_PARSED[i]:-}")"
      done
      (( first )) || printf ','
      # shellcheck disable=SC2086
      uk_json_obj $obj
      first=0
    done
    printf ']\n'
    return 0
  fi

  # table format — compute column widths on visible (colour-stripped) length.
  local -a widths=()
  for ((i = 0; i < ncol; i++)); do widths[i]=$(uk_visible_len "${H[i]}"); done
  for row in "${UK_T_ROWS[@]}"; do
    _uk_table_split "$row"
    for ((i = 0; i < ncol; i++)); do
      local len; len=$(uk_visible_len "${UK_T_PARSED[i]:-}")
      (( len > widths[i] )) && widths[i]=$len
    done
  done

  local sep='' line='' c
  for ((i = 0; i < ncol; i++)); do
    sep+="+$(printf '%*s' $((widths[i] + 2)) '' | tr ' ' '-')"
  done
  sep+='+'

  printf '%s\n' "$sep"
  line=''
  for ((i = 0; i < ncol; i++)); do
    printf -v c '| %-*s ' "${widths[i]}" "${H[i]}"
    line+="$c"
  done
  printf '%s|\n' "$line"
  printf '%s\n' "$sep"
  for row in "${UK_T_ROWS[@]}"; do
    _uk_table_split "$row"
    line=''
    for ((i = 0; i < ncol; i++)); do
      printf -v c '| %-*s ' "${widths[i]}" "${UK_T_PARSED[i]:-}"
      line+="$c"
    done
    printf '%s|\n' "$line"
  done
  printf '%s\n' "$sep"
}

# uk_out_format_from_args <args…> — parse a `--format/--json/--csv` token out
# of the given args, set UK_FMT accordingly, and return (via `$?`) how many
# positional args it consumed so the caller can `shift $?`. Echoes nothing.
# Usage inside a flag loop:
#   --json) UK_FMT=json; shift ;;
#   *)      uk_out_format_from_args "$@"; shift $? ;;
uk_out_format_from_args() {
  local a="${1:-}"
  case "$a" in
    --json) UK_FMT=json; return 1 ;;
    --csv)  UK_FMT=csv;   return 1 ;;
    --format)
      UK_FMT="${2:-table}"
      return 2
      ;;
  esac
  return 0
}

# =============================================================================
# uk_read_key — single keypress reader for interactive menus.
#
# Reads one keypress and echoes a normalized name:
#   UP, DOWN, ENTER, ESC, or the literal character typed.
# Supports arrow keys (with and without numeric-keypad prefix),
# Enter (empty read), Escape, and regular characters.
# =============================================================================
uk_read_key() {
  local key
  IFS= read -rsn1 key 2>/dev/null || true
  if [[ "$key" == $'\x1b' ]]; then
    read -rsn2 -t 0.1 key 2>/dev/null || true
    case "$key" in
    '[A' | 'OA') echo "UP" ;;
    '[B' | 'OB') echo "DOWN" ;;
    *) echo "ESC" ;;
    esac
  elif [[ "$key" == "" ]]; then
    echo "ENTER"
  else
    echo "$key"
  fi
}

# =============================================================================
# uk_menu — interactive arrow-key navigable list selector.
#
# Renders a scrollable, arrow-key navigable list with optional descriptions
# and icons. Automatically falls back to a numbered prompt on non-TTY output.
#
# Usage:
#   uk_menu [--prompt STR] [--default N] [--] item1 item2 ...
#
# Each item can be a simple label:
#     "Option A"
#   or a pipe-delimited enriched record:
#     "Display Name|short description|icon-glyph"
#
# Output:
#   UK_MENU_SELECTED  — 0-based index of the chosen item
# Return:
#   0 on selection, 1 if the user quit / cancelled
#
# Navigation:
#   ↑/↓ or k/j  — move selection
#   Enter        — confirm selection
#   q / Q        — quit / cancel
#
# Non-TTY fallback:
#   Prints a numbered list and waits for a numeric answer on stdin.
# =============================================================================
uk_menu() {
  local prompt="" default=0
  local -a items=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt) shift; prompt="${1:-}"; shift ;;
      --default) shift; default="${1:-0}"; shift ;;
      --) shift; break ;;
      *) break ;;
    esac
  done
  items=("$@")
  local n=${#items[@]}
  [[ "$n" -eq 0 ]] && return 1

  # Parse pipe-delimited items -> labels, descs, icons
  local -a labels=() descs=() icons=()
  local item rest label desc icon
  for item in "${items[@]}"; do
    label="${item%%|*}"
    rest="${item#*|}"
    labels+=("$label")
    if [[ "$rest" == "$item" ]]; then
      descs+=(""); icons+=("")
    else
      desc="${rest%%|*}"
      rest="${rest#*|}"
      descs+=("$desc")
      if [[ "$rest" == "$desc" ]]; then
        icons+=("")
      else
        icons+=("$rest")
      fi
    fi
  done

  # ---- Non-TTY fallback: numbered prompt --------------------------------
  if ! uk_is_interactive; then
    local i
    for ((i = 0; i < n; i++)); do
      printf '  %d) %s' "$((i+1))" "${labels[i]}"
      [[ -n "${descs[i]:-}" ]] && printf '  (%s)' "${descs[i]}"
      printf '\n'
    done
    printf ' %s Choose [1-%d] (0 to cancel): ' "$UK_I_ARROW" "$n" >&2
    local reply
    read -r reply
    if [[ "$reply" == "0" || -z "$reply" ]]; then
      return 1
    fi
    if [[ "$reply" =~ ^[0-9]+$ ]] && ((reply >= 1 && reply <= n)); then
      UK_MENU_SELECTED=$((reply - 1))
      return 0
    fi
    return 1
  fi

  # ---- Interactive arrow-key menu --------------------------------------
  local selected_index="$default"
  local viewport_start=0
  local viewport_count=8

  # Cursor management: hide on entry, restore on exit
  trap 'tput cnorm 2>/dev/null || printf "\033[?25h"; trap - EXIT INT TERM HUP; return 1' EXIT INT TERM HUP
  tput civis 2>/dev/null || printf '\033[?25l'

  while true; do
    # Boundary wrapping
    if ((selected_index < 0)); then
      selected_index=$((n - 1))
    elif ((selected_index >= n)); then
      selected_index=0
    fi

    # Viewport sliding window
    if ((selected_index < viewport_start)); then
      viewport_start=$selected_index
    elif ((selected_index >= viewport_start + viewport_count)); then
      viewport_start=$((selected_index - viewport_count + 1))
    fi

    # Clear and render
    printf '\033[H\033[J'

    if [[ -n "$prompt" ]]; then
      printf '  %s%s%s\n\n' "$UK_C_BOLD$UK_C_GREEN" "$prompt" "$UK_C_RESET"
    fi

    # Upwards scroll indicator
    if ((viewport_start > 0)); then
      printf '     %s▲%s\n' "$UK_C_DIM" "$UK_C_RESET"
    else
      printf '\n'
    fi

    local i ic cl lb ds
    for ((i = viewport_start; i < viewport_start + viewport_count && i < n; i++)); do
      ic="${icons[i]:-}"
      cl="${UK_C_WHITE}"
      lb="${labels[i]}"
      ds="${descs[i]:-}"

      if ((i == selected_index)); then
        if [[ -n "$ic" ]]; then
          printf '  %s➔%s  %s%s %s%s  %s(%s)%s\n' \
            "$UK_C_BRIGHT_CYAN" "$UK_C_RESET" \
            "$UK_C_BOLD$cl" "$ic" "$lb" "$UK_C_RESET" \
            "$UK_C_BOLD" "$ds" "$UK_C_RESET"
        else
          printf '  %s➔%s  %s%s%s  %s(%s)%s\n' \
            "$UK_C_BRIGHT_CYAN" "$UK_C_RESET" \
            "$UK_C_BOLD$cl" "$lb" "$UK_C_RESET" \
            "$UK_C_BOLD" "$ds" "$UK_C_RESET"
        fi
      else
        if [[ -n "$ic" ]]; then
          printf '     %s%s %s%s  %s(%s)%s\n' \
            "$cl" "$ic" "$UK_C_RESET" \
            "$UK_C_BOLD" "$lb" "$UK_C_RESET" \
            "$UK_C_DIM" "$ds" "$UK_C_RESET"
        else
          printf '     %s%s  %s(%s)%s\n' \
            "$UK_C_BOLD" "$lb" "$UK_C_RESET" \
            "$UK_C_DIM" "$ds" "$UK_C_RESET"
        fi
      fi
    done

    # Downwards scroll indicator
    if ((viewport_start + viewport_count < n)); then
      printf '     %s▼%s\n' "$UK_C_DIM" "$UK_C_RESET"
    else
      printf '\n'
    fi

    # Footer
    printf '\n  %s↑/↓ or k/j navigate     Enter select     q quit%s\n' \
      "$UK_C_DIM" "$UK_C_RESET"

    # Read key
    local key
    key=$(uk_read_key)
    case "$key" in
      UP|k|K) ((selected_index--)) ;;
      DOWN|j|J) ((selected_index++)) ;;
      ENTER)
        tput cnorm 2>/dev/null || printf '\033[?25h'
        trap - EXIT INT TERM HUP
        UK_MENU_SELECTED="$selected_index"
        return 0
        ;;
      q|Q)
        tput cnorm 2>/dev/null || printf '\033[?25h'
        trap - EXIT INT TERM HUP
        return 1
        ;;
    esac
  done
}
