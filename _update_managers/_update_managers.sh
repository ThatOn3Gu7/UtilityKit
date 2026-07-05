#!/usr/bin/env bash
# universal-package-updater.sh
# A beautiful, robust, and universal updater for system, app, and language package managers.
# Portable Bash 3+; designed for Linux, macOS, BSD, Windows Bash/MSYS/WSL, and Termux.

# Strict mode: fail on unset variables, catch pipe failures.
# Intentionally avoiding `set -e` so one failed manager doesn't crash the whole script.
set -uo pipefail
IFS=$' \t\n'

VERSION="2.1.0"
SCRIPT_NAME="${0##*/}"

# ----------------------------- Defaults & State -----------------------------
INTERACTIVE="auto"
ASSUME_YES=0
DRY_RUN=0
LIST_ONLY=0
COLOR_MODE="auto"
UNICODE_MODE="auto"
VERBOSE=0
SHOW_LOG_ON_FAILURE=1
ONLY_LIST=""
SKIP_LIST=""
LOG_FILE=""
NO_CLEAR=0

# Global tracking for clean exits
CURRENT_SPIN_PID=""
TEMP_DIR=""

# UI State
USE_COLOR=0
USE_UNICODE=0
: "${C_RESET:=}" "${C_BOLD:=}" "${C_DIM:=}" "${C_RED:=}" "${C_GREEN:=}" "${C_YELLOW:=}" "${C_BLUE:=}" "${C_MAGENTA:=}" "${C_CYAN:=}" "${C_GRAY:=}"
SYM_OK="OK" SYM_FAIL="!!" SYM_WARN="!!" SYM_INFO="ii" SYM_RUN=">>" SYM_SKIP="--" SYM_PKG="[]" SYM_SPIN='|/-\\'

# ----------------------------- Storage Arrays -------------------------------
# Bash 3 compatible parallel arrays (avoiding associative arrays for high portability)
M_ID=()
M_CAT=()
M_DETECT=()
M_UPDATE=()
M_SUMMARY=()
M_NOTES=()

# Detected-manager positions (values are indices into the M_* registry).
D_IDX=()

# Result arrays. IMPORTANT: these are keyed by the *registry index* (idx), NOT by
# append order. That guarantees the summary maps status -> manager correctly even
# if selections are sparse or the menu is run more than once.
R_STATUS=()
R_SECONDS=()
R_LOG=()
R_SUMMARY=()
R_KEYMSG=()

# ----------------------------- Robustness & Traps ---------------------------

# Reset per-run result state. Called before every batch so a second run through
# the interactive menu doesn't inherit stale results.
reset_results() {
  R_STATUS=()
  R_SECONDS=()
  R_LOG=()
  R_SUMMARY=()
  R_KEYMSG=()
}

# Graceful cleanup on interrupt (Ctrl+C).
# NOTE: does not depend on color() being initialized (we may be interrupted early).
cleanup() {
  if [ "${USE_COLOR:-0}" -eq 1 ]; then
    printf '\n%s!! Interrupted by user. Cleaning up...%s\n' "$C_RED" "$C_RESET" >&2
  else
    printf '\n!! Interrupted by user. Cleaning up...\n' >&2
  fi
  if [ -n "$CURRENT_SPIN_PID" ]; then
    kill -9 "$CURRENT_SPIN_PID" 2>/dev/null || true
  fi
  exit 130
}
trap cleanup INT TERM

# Ensure critical base utilities exist
check_deps() {
  local deps="awk sed grep tr"
  for cmd in $deps; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      printf "Critical Error: Required command '%s' is missing on this system.\n" "$cmd" >&2
      exit 1
    fi
  done
}

# Resolve a safe temporary directory, inherently supporting Termux environments
resolve_tmp() {
  if [ -n "${PREFIX:-}" ] && [ -d "$PREFIX/tmp" ]; then
    TEMP_DIR="$PREFIX/tmp"
  elif [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ] && [ -w "$TMPDIR" ]; then
    TEMP_DIR="$TMPDIR"
  elif [ -d "/tmp" ] && [ -w "/tmp" ]; then
    TEMP_DIR="/tmp"
  else
    TEMP_DIR="$(pwd)" # Absolute fallback to current directory
  fi
}

# Connectivity check.
# FIX: previously an `elif` chain meant that if `ping` existed but was blocked
# (common in containers / corporate nets), we reported "no internet" and never
# tried curl/wget. Now each method is attempted in turn until one succeeds, and
# curl/wget use real URLs instead of a bare IP.
check_internet() {
  say "$(color "$C_DIM" "Checking internet connection...")"
  local connected=0

  if command -v ping >/dev/null 2>&1; then
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
      connected=1
    fi
  fi

  if [ "$connected" -eq 0 ] && command -v curl >/dev/null 2>&1; then
    if curl -fsS --connect-timeout 5 -o /dev/null "https://1.1.1.1" 2>/dev/null ||
      curl -fsS --connect-timeout 5 -o /dev/null "https://8.8.8.8" 2>/dev/null; then
      connected=1
    fi
  fi

  if [ "$connected" -eq 0 ] && command -v wget >/dev/null 2>&1; then
    if wget -q --spider --timeout=5 "https://1.1.1.1" 2>/dev/null ||
      wget -q --spider --timeout=5 "https://8.8.8.8" 2>/dev/null; then
      connected=1
    fi
  fi

  if [ "$connected" -eq 0 ]; then
    say "$(color "$C_YELLOW" "${SYM_WARN} Warning: No reliable internet connection detected. Network-based updates may fail.")"
    sleep 2
  fi
}

# ----------------------------- Helpers & UI ---------------------------------
usage() {
  cat <<EOF
${SCRIPT_NAME} v${VERSION}

Detect and securely update all package managers found on this machine.

Usage:
  ${SCRIPT_NAME} [options]

Modes:
  -i, --interactive       Force interactive menu
  -y, --yes, --all        Non-interactive: auto-update all detected managers
      --list              Detect and list managers beautifully, then exit
      --dry-run           Simulate operations; show commands without changing anything

Filtering:
      --only a,b,c        Run only matching manager ids, e.g., apt,brew,npm
      --skip a,b,c        Skip matching manager ids

Output:
      --no-color          Disable ANSI colors
      --color             Force ANSI colors
      --ascii             Disable Unicode icons/spinners
      --unicode           Force Unicode icons/spinners
      --no-clear          Do not clear the screen before the banner
      --log-file FILE     Write full combined execution logs to FILE
  -v, --verbose           Print command output directly (disables spinner)
  -h, --help              Show this help menu
EOF
}

is_tty() { [ -t 1 ]; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }
trim() { printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

contains_csv() {
  [ -n "$1" ] || return 1
  local csv=",$(lower "$1"),"
  local wanted="$(lower "$2")"
  case "$csv" in *",$wanted,"*) return 0 ;; *) return 1 ;; esac
}

init_ui() {
  if [ "$COLOR_MODE" = "always" ] || { [ "$COLOR_MODE" = "auto" ] && is_tty && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; }; then
    USE_COLOR=1
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_MAGENTA=$'\033[35m'
    C_CYAN=$'\033[36m'
    C_GRAY=$'\033[90m'
  fi

  local loc="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
  if [ "$UNICODE_MODE" = "always" ] || { [ "$UNICODE_MODE" = "auto" ] && is_tty && printf '%s' "$loc" | grep -Eiq 'utf-?8'; }; then
    USE_UNICODE=1
    SYM_OK="✓"
    SYM_FAIL="✗"
    SYM_WARN="!"
    SYM_INFO="ℹ"
    SYM_RUN="▶"
    SYM_SKIP="○"
    SYM_PKG="📦"
    SYM_SPIN='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  fi
}

color() {
  if [ "$USE_COLOR" -eq 1 ]; then printf '%s%s%s' "$1" "$2" "$C_RESET"; else printf '%s' "$2"; fi
}

say() { printf '%s\n' "$*"; }

banner() {
  [ "$NO_CLEAR" -eq 0 ] && clear
  local os arch kern bashv
  os="$(uname -s 2>/dev/null || echo 'Unknown OS')"
  arch="$(uname -m 2>/dev/null || echo 'Unknown Arch')"
  kern="$(uname -r 2>/dev/null || echo 'Unknown Kernel')"
  bashv="${BASH_VERSION%%[^0-9.]*}"

  if [ "$USE_UNICODE" -eq 1 ] && [ "$USE_COLOR" -eq 1 ]; then
    cat <<EOF
${C_CYAN}    __  __      _                            __ 
   / / / /___  (_)   _____  ______________ _/ / 
  / / / / __ \\/ / | / / _ \\/ ___/ ___/ __ \`/ /  
 / /_/ / / / / /| |/ /  __/ /  (__  ) /_/ / /   
 \\____/_/ /_/_/ |___/\\___/_/  /____/\\__,_/_/    ${C_RESET}
                                                
 ${C_BOLD}${C_MAGENTA}Universal Package Updater${C_RESET} ${C_DIM}v${VERSION}${C_RESET}
 ${C_GRAY}──────────────────────────────────────────────────${C_RESET}
 ${C_BLUE}▪ OS:${C_RESET} $os 
 ${C_BLUE}▪ Arch:${C_RESET} $arch 
 ${C_BLUE}▪ Kernel:${C_RESET} $kern
 ${C_BLUE}▪ Shell:${C_RESET} Bash v$bashv
 ${C_GRAY}──────────────────────────────────────────────────${C_RESET}
EOF
  else
    cat <<EOF
+--------------------------------------------------+
| Universal Package Updater               v${VERSION} |
+--------------------------------------------------+
| OS: $os | Arch: $arch | Bash: $bashv
+--------------------------------------------------+
EOF
  fi
}

hr() {
  if [ "$USE_UNICODE" -eq 1 ]; then
    say "$(color "$C_GRAY" "──────────────────────────────────────────────────────────────")"
  else say "$(color "$C_GRAY" "--------------------------------------------------------------")"; fi
}

progress_bar() {
  local cur=$1 total=$2 width=28 pct filled empty bar="" i=0
  [ "$total" -le 0 ] && total=1
  pct=$((cur * 100 / total))
  filled=$((cur * width / total))
  empty=$((width - filled))
  while [ $i -lt $filled ]; do
    bar="${bar}█"
    i=$((i + 1))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}░"
    i=$((i + 1))
  done
  if [ "$USE_UNICODE" -ne 1 ]; then bar=$(echo "$bar" | tr '█░' '#-'); fi
  printf '[%s] %3d%%' "$bar" "$pct"
}

make_tmp_log() {
  local base="$TEMP_DIR/univ_pkg_upd_$$.$1.log"
  if has_cmd mktemp; then base=$(mktemp "$TEMP_DIR/univ_pkg_upd_$1.XXXXXX.log" 2>/dev/null || echo "$base"); fi
  : >"$base" 2>/dev/null || base="./univ_pkg_upd_$$.$1.log"
  printf '%s' "$base"
}

append_master_log() {
  [ -n "$LOG_FILE" ] || return 0
  {
    printf '\n===== %s | %s | %s =====\n' "$1" "$2" "$(date '+%Y-%m-%d %H:%M:%S')"
    cat "$3" 2>/dev/null || true
  } >>"$LOG_FILE" 2>/dev/null || true
}

print_tail() {
  local file=$1 lines=${2:-25}
  [ -s "$file" ] || return 0
  tail -n "$lines" "$file" 2>/dev/null || true
}

# ------------------------- Smart log "grep-ping" ----------------------------
# Extract the single most important line from a manager's log.
#
# On FAILURE (rc != 0) we hunt for the actual error reason: lines matching common
# error/failure keywords, taking the LAST such line (errors near the end are
# usually the root cause / final verdict). On SUCCESS we surface a meaningful
# progress line (counts of upgraded/installed packages, "up to date", etc.).
#
# All matching is done with grep -E (ERE) so this stays portable. Output is a
# single trimmed line, truncated so it fits nicely under the spinner.
extract_key_message() {
  local log=$1 rc=$2 msg="" maxlen=180
  [ -s "$log" ] || {
    printf '%s' ""
    return 0
  }

  if [ "$rc" -ne 0 ]; then
    # Prefer explicit, high-signal error lines; take the LAST match (final cause).
    msg=$(grep -Ei \
      'error|fail(ed|ure)?|fatal|cannot|could not|unable to|not found|permission denied|no space|held (back|broken)|unmet dependenc|conflict|denied|E:|abort|traceback' \
      "$log" 2>/dev/null | grep -Ev '^\s*$' | tail -n 1)

    # Fallback: last non-empty line of output.
    if [ -z "$msg" ]; then
      msg=$(grep -Ev '^\s*$' "$log" 2>/dev/null | tail -n 1)
    fi
  else
    # Success: try to find a line that quantifies what changed.
    msg=$(grep -Ei \
      '([0-9]+) *(packages?|to upgrade|newly installed|upgraded|installed|removed|updated)|up to date|already up.to.date|nothing to do|no updates|successfully' \
      "$log" 2>/dev/null | grep -Ev '^\s*$' | tail -n 1)

    # Fallback: last non-empty line (still informative, e.g. "done").
    if [ -z "$msg" ]; then
      msg=$(grep -Ev '^\s*$' "$log" 2>/dev/null | tail -n 1)
    fi
  fi

  # Normalize: strip carriage returns, ANSI escapes, and surrounding whitespace.
  msg=$(printf '%s' "$msg" | tr -d '\r' | sed 's/\x1b\[[0-9;]*[A-Za-z]//g; s/^[[:space:]]*//; s/[[:space:]]*$//')

  # Truncate very long lines so the UI stays tidy.
  if [ "${#msg}" -gt "$maxlen" ]; then
    msg="${msg:0:$maxlen}…"
  fi

  printf '%s' "$msg"
}

confirm() {
  local prompt=$1 def=${2:-0} ans
  [ "$ASSUME_YES" -eq 1 ] && return 0
  if ! is_tty; then return 1; fi
  if [ "$def" -eq 1 ]; then prompt="$prompt [Y/n] "; else prompt="$prompt [y/N] "; fi
  printf '%s' "$prompt"
  read -r ans || return 1
  ans="$(lower "$(trim "$ans")")"
  if [ -z "$ans" ]; then
    [ "$def" -eq 1 ]
    return $?
  fi
  case "$ans" in y | yes) return 0 ;; *) return 1 ;; esac
}

run_as_root() {
  if [ "$(id -u 2>/dev/null || echo 1)" = "0" ] || [ -n "${PREFIX:-}" ]; then
    "$@"
  elif has_cmd sudo; then
    sudo "$@"
  elif has_cmd doas; then
    doas "$@"
  else
    echo "Need root privileges for: $*" >&2
    return 127
  fi
}

prepare_privileges() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  [ "$(id -u 2>/dev/null || echo 1)" = "0" ] && return 0
  # Do not ask on Termux Android
  [ -n "${PREFIX:-}" ] && return 0
  if has_cmd sudo && is_tty; then
    say "$(color "$C_DIM" "Pre-authenticating for sudo commands...")"
    sudo -v >/dev/null 2>&1 || true
  fi
}

# ------------------- Live sub-command display helpers -----------------------
# The spinner can show the *exact* sub-command currently executing (e.g. it flips
# 'apt-get update' -> 'apt-get upgrade -y' -> 'apt-get autoremove -y' live). To do
# that safely we only step through commands that are plain chains joined by
# && / || / ; . Anything with shell constructs (if/for/while/case, functions,
# subshell groups, pipes to complex logic, etc.) is treated as "complex" and run
# whole, unchanged, so we never alter execution semantics for those.

# Return 0 (true) if the command is too complex to safely split into steps.
is_complex_cmd() {
  case " $1 " in
  *' if '* | *' then '* | *' fi '* | *' for '* | *' while '* | *' do '* | *' done '* | *' case '* | *' esac '* | *' function '*)
    return 0
    ;;
  esac
  # Subshell group, brace group, command substitution -> treat as complex.
  case "$1" in
  *'('* | *'{'* | *'`'* | *'$('*) return 0 ;;
  esac
  # A real pipe '|' makes it complex, but '||' (logical OR) is fine. Temporarily
  # blank out '||' occurrences, then check for a remaining single '|'.
  local nolor
  nolor=$(printf '%s' "$1" | sed 's/||/\x1e/g')
  case "$nolor" in
  *'|'*) return 0 ;;
  esac
  # A single "word" that resolves to a shell function (our extension funcs).
  if printf '%s' "$1" | grep -Eq '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*$'; then
    return 0
  fi
  return 1
}

# Prettify a single sub-command for on-screen display (does NOT affect what runs).
clean_display_cmd() {
  printf '%s' "$1" | sed -E '
    s/run_as_root //g;
    s/env [A-Za-z_][A-Za-z0-9_]*=[^ ]* //g;
    s/[[:space:]]*1?>[^ ]*//g;
    s/[[:space:]]*2>&1//g;
    s/[[:space:]]*2>[^ ]*//g;
    s/^[[:space:]]*//; s/[[:space:]]*$//;
  '
}

# Draw one spinner frame. Args: frame_char, id, label, elapsed_seconds.
#
# IMPORTANT: we must never print more characters than the terminal is wide, and
# we must clear the line with the terminal's "erase to end of line" capability
# rather than padding with a fixed number of spaces. Padding with e.g. 100 spaces
# wraps onto a second physical line on narrower terminals; after that wrap, the
# leading '\r' only returns to the start of the *current* (wrapped) line, so the
# spinner "walks" downward and prints a new line every refresh. Using \r + ESC[K
# (or a width-bounded fallback) keeps everything on a single line at any width.
draw_spinner_line() {
  local frame=$1 id=$2 label=$3 elapsed=$4
  local cols budget plain

  # Determine terminal width (fall back to 80 if unknown).
  cols=${COLUMNS:-0}
  if [ "$cols" -le 0 ]; then
    cols=$(tput cols 2>/dev/null || echo 80)
  fi
  [ "$cols" -le 0 ] && cols=80

  # Reserve room for the fixed parts: "<frame> <id> » " + " <elapsed>s".
  # +6 is slack for spaces and the 's' suffix so we never hit the last column
  # (writing the final column can trigger an auto-wrap on some terminals).
  budget=$((cols - ${#frame} - ${#id} - ${#elapsed} - 6))
  [ "$budget" -lt 8 ] && budget=8

  if [ "${#label}" -gt "$budget" ]; then
    label="${label:0:$((budget - 1))}…"
  fi

  if [ "$USE_COLOR" -eq 1 ]; then
    # \r  -> return to column 0
    # \033[K -> erase from cursor to end of line (no wrapping, width-independent)
    printf '\r\033[K%s %s %s %s %ss' \
      "$(color "$C_CYAN" "$frame")" \
      "$(color "$C_BOLD" "$id")" \
      "$(color "$C_DIM" "»")" \
      "$(color "$C_GRAY" "$label")" \
      "$elapsed"
  else
    # No-color fallback: still use \r + ESC[K; if a terminal ignores ESC[K it is
    # virtually always also color-capable, so this path is safe in practice.
    printf '\r\033[K%s %s %s %s %ss' "$frame" "$id" "»" "$label" "$elapsed"
  fi
}

# Execute a simple && / || / ; chain step-by-step, writing the current
# sub-command to $stepfile before each step so the spinner can display it, and
# honoring short-circuit semantics so the overall exit code matches `eval "$cmd"`.
#   $1 = full command string, $2 = log path, $3 = stepfile path
# Returns the exit code of the last executed command in the chain.
run_chain_stepwise() {
  local cmd=$1 log=$2 stepfile=$3
  local rc=0 first=1 last_op="" seg display
  # Tokenize into "OP\tSEGMENT" records. We translate the operators to unique
  # markers, then read them back. Using awk keeps this portable.
  local records
  records=$(printf '%s' "$cmd" | awk '
    {
      s=$0; out="";
      # Emit a record boundary before each top-level && || ;
      n=length(s); i=1; buf="";
      while (i<=n) {
        c=substr(s,i,1); c2=substr(s,i,2);
        if (c2=="&&") { out=out buf "\x01AND\x01"; buf=""; i+=2; continue }
        if (c2=="||") { out=out buf "\x01OR\x01";  buf=""; i+=2; continue }
        if (c==";")   { out=out buf "\x01SEMI\x01"; buf=""; i+=1; continue }
        buf=buf c; i++;
      }
      out=out buf;
      print out;
    }')

  # Split on our marker and walk each (op, segment).
  local oldifs="$IFS"
  # Replace markers with newlines but keep the op label attached to the FOLLOWING segment.
  # Format after this: first segment has no leading op; subsequent segments are
  # prefixed with AND\x01 / OR\x01 / SEMI\x01.
  records=$(printf '%s' "$records" | sed 's/\x01AND\x01/\n\x02AND\x02/g; s/\x01OR\x01/\n\x02OR\x02/g; s/\x01SEMI\x01/\n\x02SEMI\x02/g')

  IFS=$'\n'
  local line op
  for line in $records; do
    [ -z "$line" ] && continue
    op="SEMI"
    case "$line" in
    $'\x02AND\x02'*)
      op="AND"
      line=${line#$'\x02AND\x02'}
      ;;
    $'\x02OR\x02'*)
      op="OR"
      line=${line#$'\x02OR\x02'}
      ;;
    $'\x02SEMI\x02'*)
      op="SEMI"
      line=${line#$'\x02SEMI\x02'}
      ;;
    esac
    seg=$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -z "$seg" ] && continue

    # Short-circuit logic (skip for the very first segment).
    if [ "$first" -eq 0 ]; then
      if [ "$op" = "AND" ] && [ "$rc" -ne 0 ]; then continue; fi
      if [ "$op" = "OR" ] && [ "$rc" -eq 0 ]; then continue; fi
    fi
    first=0

    # Publish the current sub-command for the spinner to pick up.
    display=$(clean_display_cmd "$seg")
    printf '%s' "$display" >"$stepfile" 2>/dev/null || true

    # Run this single segment, appending to the shared log.
    eval "$seg" >>"$log" 2>&1
    rc=$?
  done
  IFS="$oldifs"
  return "$rc"
}

run_shell_with_spinner() {
  local id=$1 cmd=$2 log=$3 spin_len frame frame_idx=0 start now elapsed rc
  local stepfile label
  if [ "$DRY_RUN" -eq 1 ]; then
    say "$(color "$C_YELLOW" "${SYM_INFO} dry-run") $id: $cmd"
    return 0
  fi

  start=$(date +%s)
  if [ "$VERBOSE" -eq 1 ]; then
    # Verbose: show output live, no spinner
    (eval "$cmd") 2>&1 | tee "$log"
    rc=${PIPESTATUS[0]}
  else
    if is_tty; then
      spin_len=${#SYM_SPIN}
      if is_complex_cmd "$cmd"; then
        # ---- Complex command: run whole (unchanged semantics), static label ----
        label="running..."
        (eval "$cmd") >"$log" 2>&1 &
        CURRENT_SPIN_PID=$!
        while kill -0 "$CURRENT_SPIN_PID" >/dev/null 2>&1; do
          frame="${SYM_SPIN:$((frame_idx % spin_len)):1}"
          now=$(date +%s)
          elapsed=$((now - start))
          draw_spinner_line "$frame" "$id" "$label" "$elapsed"
          frame_idx=$((frame_idx + 1))
          sleep 0.1
        done
        wait "$CURRENT_SPIN_PID"
        rc=$?
        CURRENT_SPIN_PID=""
      else
        # ---- Simple chain: step through it, showing each live sub-command ----
        stepfile="${log}.step"
        : >"$stepfile" 2>/dev/null || stepfile=""
        run_chain_stepwise "$cmd" "$log" "$stepfile" &
        CURRENT_SPIN_PID=$!
        while kill -0 "$CURRENT_SPIN_PID" >/dev/null 2>&1; do
          frame="${SYM_SPIN:$((frame_idx % spin_len)):1}"
          now=$(date +%s)
          elapsed=$((now - start))
          # Read the sub-command the executor is currently on.
          if [ -n "$stepfile" ] && [ -s "$stepfile" ]; then
            label=$(cat "$stepfile" 2>/dev/null)
          else
            label="starting..."
          fi
          draw_spinner_line "$frame" "$id" "$label" "$elapsed"
          frame_idx=$((frame_idx + 1))
          sleep 0.1
        done
        wait "$CURRENT_SPIN_PID"
        rc=$?
        CURRENT_SPIN_PID=""
        [ -n "$stepfile" ] && rm -f "$stepfile" 2>/dev/null || true
      fi
      # Final clear of the spinner line: return + erase-to-end-of-line (width-safe).
      printf '\r\033[K'
    else
      (eval "$cmd") >"$log" 2>&1
      rc=$?
    fi
  fi
  return "$rc"
}

# ---------- Ecosystem Extension Functions ----------
update_pip_packages() {
  local pipcmd parser outdated
  if has_cmd python3 && python3 -m pip --version >/dev/null 2>&1; then
    pipcmd="python3 -m pip"
    parser="python3"
  elif has_cmd python && python -m pip --version >/dev/null 2>&1; then
    pipcmd="python -m pip"
    parser="python"
  elif has_cmd pip3; then
    pipcmd="pip3"
    parser="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
  elif has_cmd pip; then
    pipcmd="pip"
    parser="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
  else
    return 127
  fi

  eval "$pipcmd install --upgrade pip setuptools wheel" >/dev/null 2>&1 || true
  if [ -z "$parser" ]; then return 0; fi
  outdated=$(eval "$pipcmd list --outdated --format=json" 2>/dev/null | "$parser" -c 'import sys,json; data=json.load(sys.stdin); print(" ".join(p["name"] for p in data))' 2>/dev/null || true)
  if [ -n "$outdated" ]; then
    eval "$pipcmd install --upgrade $outdated"
  fi
}

summary_pip_packages() {
  local pipcmd parser
  if has_cmd python3 && python3 -m pip --version >/dev/null 2>&1; then
    pipcmd="python3 -m pip"
    parser="python3"
  elif has_cmd python && python -m pip --version >/dev/null 2>&1; then
    pipcmd="python -m pip"
    parser="python"
  elif has_cmd pip3; then
    pipcmd="pip3"
    parser="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
  elif has_cmd pip; then
    pipcmd="pip"
    parser="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
  else
    return 1
  fi

  if [ -z "$parser" ]; then return 0; fi
  eval "$pipcmd list --outdated --format=json" 2>/dev/null | "$parser" -c 'import sys,json
data=json.load(sys.stdin)
print("\n".join("{} {} -> {}".format(p["name"], p["version"], p["latest_version"]) for p in data))' 2>/dev/null | sed -n '1,12p'
}

# -------------------------- Manager Registry -------------------------
register_manager() {
  M_ID[${#M_ID[@]}]="$1"
  M_CAT[${#M_CAT[@]}]="$2"
  M_DETECT[${#M_DETECT[@]}]="$3"
  M_UPDATE[${#M_UPDATE[@]}]="$4"
  M_SUMMARY[${#M_SUMMARY[@]}]="$5"
  M_NOTES[${#M_NOTES[@]}]="$6"
}

register_managers() {
  # --- SYSTEM PACKAGE MANAGERS ---
  register_manager "apt" "system" "has_cmd apt-get && [ -z \"\${PREFIX:-}\" ]" "run_as_root apt-get update && run_as_root env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && run_as_root env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y" "apt list --upgradable 2>/dev/null | sed -n '2,8p'" "Debian/Ubuntu/WSL via apt"
  register_manager "pkg-termux" "system" "has_cmd pkg && [ -n \"\${PREFIX:-}\" ] && printf '%s' \"\${PREFIX:-}\" | grep -q 'com.termux'" "pkg update -y && pkg upgrade -y" "apt list --upgradable 2>/dev/null | sed -n '2,8p'" "Termux wrapper"
  register_manager "dnf" "system" "has_cmd dnf" "run_as_root dnf upgrade --refresh -y" "dnf check-update 2>/dev/null | sed -n '1,8p'" "Fedora/RHEL family"
  register_manager "yum" "system" "has_cmd yum && ! has_cmd dnf" "run_as_root yum update -y" "yum check-update 2>/dev/null | sed -n '1,8p'" "Legacy RHEL/CentOS"
  register_manager "zypper" "system" "has_cmd zypper" "run_as_root zypper --non-interactive refresh && run_as_root zypper --non-interactive update" "zypper list-updates 2>/dev/null | sed -n '1,8p'" "openSUSE/SLES"
  register_manager "pacman" "system" "has_cmd pacman" "run_as_root pacman -Syu --noconfirm" "pacman -Qu 2>/dev/null | sed -n '1,8p'" "Arch Linux"
  register_manager "yay" "system" "has_cmd yay" "yay -Syu --noconfirm" "yay -Qu 2>/dev/null | sed -n '1,8p'" "Arch AUR helper"
  register_manager "paru" "system" "has_cmd paru" "paru -Syu --noconfirm" "paru -Qu 2>/dev/null | sed -n '1,8p'" "Arch AUR helper"
  register_manager "pacstall" "system" "has_cmd pacstall" "pacstall -U && pacstall -Up" "pacstall -L 2>/dev/null" "Ubuntu AUR equivalent"
  register_manager "apk" "system" "has_cmd apk" "run_as_root apk update && run_as_root apk upgrade" "apk version -l '<' 2>/dev/null | sed -n '1,8p'" "Alpine Linux"
  register_manager "xbps" "system" "has_cmd xbps-install" "run_as_root xbps-install -Syu" "xbps-install -un 2>/dev/null | sed -n '1,8p'" "Void Linux"
  register_manager "eopkg" "system" "has_cmd eopkg" "run_as_root eopkg upgrade -y" "eopkg list-upgrades 2>/dev/null | sed -n '1,8p'" "Solus"
  register_manager "emerge" "system" "has_cmd emerge" "run_as_root emerge --sync && run_as_root emerge -uDN --with-bdeps=y @world" "emerge -uDNpv @world 2>/dev/null | sed -n '1,12p'" "Gentoo (Can take hours)"
  register_manager "slpkg" "system" "has_cmd slpkg" "run_as_root slpkg update && run_as_root slpkg upgrade" "slpkg list 2>/dev/null" "Slackware wrapper"
  register_manager "slackpkg" "system" "has_cmd slackpkg" "run_as_root slackpkg update && run_as_root slackpkg upgrade-all -y" "slackpkg check-updates 2>/dev/null" "Slackware native"
  register_manager "pkg-freebsd" "system" "has_cmd pkg && uname -s 2>/dev/null | grep -Eq 'FreeBSD|DragonFly'" "run_as_root pkg update && run_as_root pkg upgrade -y" "pkg version -vIL= 2>/dev/null | sed -n '1,8p'" "FreeBSD/DragonFly"
  register_manager "pkgin" "system" "has_cmd pkgin" "run_as_root pkgin update && run_as_root pkgin full-upgrade -y" "pkgin avail 2>/dev/null | sed -n '1,8p'" "pkgsrc manager"
  register_manager "brew" "system" "has_cmd brew" "brew update && brew upgrade && brew cleanup" "brew outdated 2>/dev/null | sed -n '1,12p'" "Homebrew (Mac/Linux)"
  register_manager "macports" "system" "has_cmd port" "run_as_root port selfupdate && run_as_root port upgrade outdated" "port outdated 2>/dev/null | sed -n '1,12p'" "MacPorts"
  register_manager "nix" "system" "has_cmd nix-env || has_cmd nix" "(has_cmd nix-channel && nix-channel --update || true); (has_cmd nix-env && nix-env -u '*' || true); (has_cmd nix && nix profile upgrade '.*' || true)" "(has_cmd nix-env && nix-env -q --outdated 2>/dev/null || true) | sed -n '1,8p'" "Nix pkgs/profiles"
  register_manager "guix" "system" "has_cmd guix" "guix pull && guix package -u" "guix package --list-generations 2>/dev/null | tail -n 8" "GNU Guix"
  register_manager "swupd" "system" "has_cmd swupd" "run_as_root swupd update" "swupd check-update 2>/dev/null | sed -n '1,8p'" "Clear Linux"
  register_manager "rpm-ostree" "system" "has_cmd rpm-ostree" "run_as_root rpm-ostree upgrade" "rpm-ostree status 2>/dev/null | sed -n '1,12p'" "OSTree variants"

  # --- APP STORES & BINARIES ---
  register_manager "snap" "apps" "has_cmd snap" "run_as_root snap refresh" "snap refresh --list 2>/dev/null | sed -n '1,12p'" "Canonical Snap"
  register_manager "flatpak" "apps" "has_cmd flatpak" "flatpak update -y" "flatpak remote-ls --updates 2>/dev/null | sed -n '1,12p'" "Flatpak"
  register_manager "mas" "apps" "has_cmd mas" "mas upgrade" "mas outdated 2>/dev/null | sed -n '1,12p'" "Mac App Store CLI"
  register_manager "winget" "apps" "has_cmd winget" "winget source update; winget upgrade --all --silent --accept-package-agreements --accept-source-agreements" "winget upgrade 2>/dev/null | sed -n '1,12p'" "Windows Pkg Mgr"
  register_manager "choco" "apps" "has_cmd choco" "choco upgrade all -y" "choco outdated 2>/dev/null | sed -n '1,12p'" "Chocolatey"
  register_manager "scoop" "apps" "has_cmd scoop" "scoop update; scoop update '*'; scoop cleanup '*'" "scoop status 2>/dev/null | sed -n '1,12p'" "Scoop Windows"

  # --- LANGUAGES & ECOSYSTEMS ---
  register_manager "pipx" "language" "has_cmd pipx" "pipx upgrade-all" "pipx list --short 2>/dev/null | sed -n '1,12p'" "Python isolated apps"
  register_manager "pip" "language" "has_cmd python3 && python3 -m pip --version >/dev/null 2>&1 || has_cmd pip" "update_pip_packages" "summary_pip_packages" "Python global pip"
  register_manager "uv" "language" "has_cmd uv" "uv self update || true; uv tool upgrade --all || true" "uv tool list 2>/dev/null | sed -n '1,12p'" "Astral uv tools"
  register_manager "conda" "language" "has_cmd conda" "conda update -n base conda -y || true; conda update --all -y" "conda update --all --dry-run 2>/dev/null | sed -n '1,18p'" "Conda base"
  register_manager "npm" "language" "has_cmd npm" "npm update -g && npm install -g npm@latest" "npm outdated -g --depth=0 2>/dev/null | sed -n '1,12p'" "Node npm globals"
  # FIX: previous updater ran `ncu -g -u && npm install -g` (no package -> no-op).
  # npm-check-updates in -g mode only PRINTS the commands to run; run them explicitly.
  register_manager "ncu" "language" "has_cmd ncu" "ncu -g -u 2>/dev/null; npm update -g" "ncu -g 2>/dev/null" "NPM Check Updates"
  register_manager "pnpm" "language" "has_cmd pnpm" "pnpm self-update || true; pnpm update -g --latest || pnpm update -g" "pnpm outdated -g 2>/dev/null | sed -n '1,12p'" "pnpm global pkgs"
  register_manager "yarn" "language" "has_cmd yarn" "yarn global upgrade || yarn set version stable || true" "yarn global outdated 2>/dev/null | sed -n '1,12p'" "Yarn global pkgs"
  register_manager "bun" "language" "has_cmd bun" "bun upgrade" "bun --version 2>/dev/null" "Bun runtime/tooling"
  register_manager "deno" "language" "has_cmd deno" "deno upgrade" "deno --version 2>/dev/null" "Deno runtime/tooling"
  register_manager "gem" "language" "has_cmd gem" "run_as_root gem update --system || true; run_as_root gem update" "gem outdated 2>/dev/null | sed -n '1,12p'" "RubyGems"
  register_manager "rustup" "language" "has_cmd rustup" "rustup update" "rustup show 2>/dev/null | sed -n '1,14p'" "Rust toolchains"
  register_manager "cargo" "language" "has_cmd cargo" "if has_cmd cargo-install-update; then cargo install-update -a; else has_cmd rustup && rustup update || true; fi" "(has_cmd cargo-install-update && cargo install-update -l 2>/dev/null || cargo install --list 2>/dev/null) | sed -n '1,16p'" "Cargo binaries"
  register_manager "cargo-update" "language" "has_cmd cargo-install-update" "cargo install-update -a" "cargo install-update -l 2>/dev/null | sed -n '1,16p'" "Cargo update (cargo-install-update)"
  register_manager "go" "language" "has_cmd go-global-update" "go-global-update" "go version 2>/dev/null" "Go binaries"
  register_manager "composer" "language" "has_cmd composer" "composer self-update || true; composer global update" "composer global outdated 2>/dev/null | sed -n '1,12p'" "PHP Composer global"
  register_manager "pecl" "language" "has_cmd pecl" "run_as_root pecl update-channels && run_as_root pecl upgrade" "pecl list-upgrades 2>/dev/null" "PHP PECL extensions"
  register_manager "dotnet" "language" "has_cmd dotnet" "dotnet tool update -g --all" "dotnet tool list -g 2>/dev/null | sed -n '1,12p'" ".NET global tools"
  register_manager "poetry" "language" "has_cmd poetry" "poetry self update" "poetry --version 2>/dev/null" "Poetry self-update"
  register_manager "rye" "language" "has_cmd rye" "rye self update" "rye --version 2>/dev/null" "Rye self-update"
  register_manager "luarocks" "language" "has_cmd luarocks" "run_as_root luarocks install luarocks" "luarocks --version" "Lua Rocks"
  register_manager "cpanm" "language" "has_cmd cpanm" "run_as_root cpanm --self-upgrade" "cpanm --version" "Perl CPAN Minus"
  register_manager "opam" "language" "has_cmd opam" "opam update && opam upgrade -y" "opam list --outdated 2>/dev/null | sed -n '1,12p'" "OCaml opam"
  register_manager "julia" "language" "has_cmd julia" "julia -e 'import Pkg; Pkg.update()'" "julia -e 'import Pkg; Pkg.status()' 2>/dev/null | sed -n '1,16p'" "Julia env"
  register_manager "mix" "language" "has_cmd mix" "mix local.hex --force && mix local.rebar --force" "mix hex.info 2>/dev/null | sed -n '1,12p'" "Elixir Hex/Rebar"
  register_manager "cabal" "language" "has_cmd cabal" "cabal update && cabal install cabal-install" "cabal outdated 2>/dev/null | sed -n '1,12p'" "Haskell Cabal"

  # --- TOOLS & PLUGINS ---
  register_manager "sdkman" "tools" "[ -s \"\${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh\" ]" ". \"\${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh\" && sdk selfupdate force || true; . \"\${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh\" && sdk update" ". \"\${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh\" && sdk current 2>/dev/null" "SDKMAN! Candidates"
  register_manager "asdf" "tools" "has_cmd asdf" "asdf plugin update --all; asdf reshim" "asdf plugin list 2>/dev/null | sed -n '1,18p'" "asdf plugins"
  register_manager "mise" "tools" "has_cmd mise" "mise self-update -y || true; mise upgrade -y" "mise outdated 2>/dev/null | sed -n '1,18p'" "mise toolchains"
  register_manager "fvm" "tools" "has_cmd fvm" "fvm flutter upgrade" "fvm list" "Flutter Version Management"
  register_manager "flutter" "tools" "has_cmd flutter && ! has_cmd fvm" "flutter upgrade" "flutter --version 2>/dev/null | sed -n '1,8p'" "Flutter SDK"
  register_manager "gcloud" "tools" "has_cmd gcloud" "gcloud components update --quiet" "gcloud components list --only-local-state 2>/dev/null" "Google Cloud SDK"
  register_manager "tldr" "tools" "has_cmd tldr" "tldr --update" "tldr --version" "TLDR pages cache"
  register_manager "gh" "tools" "has_cmd gh" "gh extension upgrade --all" "gh extension list 2>/dev/null | sed -n '1,12p'" "GitHub CLI extensions"
  register_manager "krew" "tools" "has_cmd kubectl && kubectl krew version >/dev/null 2>&1" "kubectl krew update && kubectl krew upgrade" "kubectl krew list 2>/dev/null | sed -n '1,12p'" "kubectl krew plugins"
  register_manager "vagrant" "tools" "has_cmd vagrant" "vagrant plugin update" "vagrant plugin list" "Vagrant Plugins"
  register_manager "doom" "tools" "[ -d \"$HOME/.config/emacs/bin\" ] && has_cmd doom" "doom upgrade" "doom version" "Doom Emacs"
  register_manager "tlmgr" "tools" "has_cmd tlmgr" "tlmgr update --self --all" "tlmgr update --list 2>/dev/null | sed -n '1,12p'" "TeX Live Manager"
}

# ----------------------------- Core Logic -----------------------------
should_include_id() {
  local id=$1
  if [ -n "$ONLY_LIST" ] && ! contains_csv "$ONLY_LIST" "$id"; then return 1; fi
  if [ -n "$SKIP_LIST" ] && contains_csv "$SKIP_LIST" "$id"; then return 1; fi
  return 0
}

detect_managers() {
  D_IDX=()
  local i=0 id detect
  while [ $i -lt ${#M_ID[@]} ]; do
    id=${M_ID[$i]}
    detect=${M_DETECT[$i]}
    if should_include_id "$id" && eval "$detect" >/dev/null 2>&1; then
      D_IDX[${#D_IDX[@]}]=$i
    fi
    i=$((i + 1))
  done
}

print_detected() {
  if [ ${#D_IDX[@]} -eq 0 ]; then
    say "$(color "$C_YELLOW" "${SYM_WARN} No matching package managers detected.")"
    return 0
  fi
  say "$(color "$C_BOLD" "Detected Package Managers:")"

  local cat_list="system apps language tools"
  local c i idx found n
  for c in $cat_list; do
    found=0
    i=0
    while [ $i -lt ${#D_IDX[@]} ]; do
      if [ "${M_CAT[${D_IDX[$i]}]}" = "$c" ]; then
        found=1
        break
      fi
      i=$((i + 1))
    done

    if [ "${found:-0}" -eq 1 ]; then
      local cap_cat
      if [ -n "$c" ]; then
        local first="${c:0:1}"
        cap_cat="$(tr '[:lower:]' '[:upper:]' <<<"$first")${c:1}"
      else
        cap_cat=""
      fi
      say $'\n'"  $(color "$C_BLUE" "●") $(color "$C_BOLD" "$cap_cat")"

      i=0
      n=1
      while [ $i -lt ${#D_IDX[@]} ]; do
        idx=${D_IDX[$i]}
        if [ -n "$idx" ] && [ "${M_CAT[$idx]}" = "$c" ]; then
          printf '    %2d. %s %-18s %s\n' \
            "$n" \
            "$(color "$C_GREEN" "$SYM_OK")" \
            "${M_ID[$idx]}" \
            "$(color "$C_DIM" "${M_NOTES[$idx]}")"
          n=$((n + 1))
        fi
        i=$((i + 1))
      done
    fi
  done
  echo
}

# ---------------------------- Interactive ----------------------------
parse_selection_to_indices() {
  local sel=$1 result="" token start end i idx id found OLDIFS
  sel=$(printf '%s' "$sel" | tr ' ' ',')
  [ -z "$sel" ] && return 1
  [ "$(lower "$sel")" = "all" ] && {
    i=0
    while [ $i -lt ${#D_IDX[@]} ]; do
      result="$result $i"
      i=$((i + 1))
    done
    printf '%s' "$result"
    return 0
  }

  OLDIFS=$IFS
  IFS=','
  set -- $sel
  IFS=$OLDIFS
  for token in "$@"; do
    token=$(trim "$token")
    [ -z "$token" ] && continue
    case "$token" in
    *-*)
      start=${token%-*}
      end=${token#*-}
      # FIX: guard malformed / open-ended / reversed ranges. Both sides must be
      # non-empty integers, and we swap if the user typed them backwards.
      if printf '%s' "$start" | grep -Eq '^[0-9]+$' && printf '%s' "$end" | grep -Eq '^[0-9]+$'; then
        if [ "$start" -gt "$end" ]; then
          local tmp=$start
          start=$end
          end=$tmp
        fi
        i=$start
        while [ $i -le $end ]; do
          if [ "$i" -ge 1 ] && [ "$i" -le ${#D_IDX[@]} ]; then result="$result $((i - 1))"; fi
          i=$((i + 1))
        done
      else
        say "$(color "$C_YELLOW" "${SYM_WARN} Invalid range: $token")" >&2
      fi
      ;;
    *)
      if printf '%s' "$token" | grep -Eq '^[0-9]+$'; then
        if [ "$token" -ge 1 ] && [ "$token" -le ${#D_IDX[@]} ]; then result="$result $((token - 1))"; fi
      else
        found=0
        i=0
        while [ $i -lt ${#D_IDX[@]} ]; do
          idx=${D_IDX[$i]}
          id=${M_ID[$idx]}
          if [ "$(lower "$id")" = "$(lower "$token")" ]; then
            result="$result $i"
            found=1
            break
          fi
          i=$((i + 1))
        done
        [ "$found" -eq 0 ] && say "$(color "$C_YELLOW" "${SYM_WARN} Unknown selection: $token")" >&2
      fi
      ;;
    esac
  done
  printf '%s\n' $result 2>/dev/null | awk '!seen[$0]++' | tr '\n' ' '
}

interactive_menu() {
  local choice sel parsed
  while true; do
    hr
    say "$(color "$C_BOLD" "Menu")"
    say "  1) Update all detected managers"
    say "  2) Choose managers to update"
    say "  3) Toggle dry-run ($([ "$DRY_RUN" -eq 1 ] && echo "$(color "$C_YELLOW" "ON")" || echo "$(color "$C_DIM" "OFF")"))"
    say "  4) Quit"
    printf '\nChoose [1-4]: '
    read -r choice || return 1
    case "$(trim "$choice")" in
    1)
      confirm "Run updates for all detected managers?" 0 || continue
      SELECTED_POSITIONS="all"
      return 0
      ;;
    2)
      print_detected
      say "Enter numbers, ranges, ids, or 'all' (e.g. 1,3-5,npm):"
      printf '> '
      read -r sel || continue
      parsed=$(parse_selection_to_indices "$sel")
      if [ -z "$(trim "$parsed")" ]; then
        say "No valid selections."
        continue
      fi
      SELECTED_POSITIONS="$parsed"
      return 0
      ;;
    3) if [ "$DRY_RUN" -eq 1 ]; then DRY_RUN=0; else DRY_RUN=1; fi ;;
    4 | q | quit | exit) return 1 ;;
    *) say "Invalid choice." ;;
    esac
  done
}

# ----------------------------- Execution -----------------------------
# NOTE: result arrays are keyed by registry index (idx). run_manager writes
# R_STATUS[$idx], R_SECONDS[$idx], etc. so mapping is always correct.
run_manager() {
  local idx=$1 id=${M_ID[$idx]} cmd=${M_UPDATE[$idx]} summary_cmd=${M_SUMMARY[$idx]}
  local log=$(make_tmp_log "$id") start end rc summary="" keymsg=""

  start=$(date +%s)
  say "$(color "$C_CYAN" "$SYM_RUN") $(color "$C_BOLD" "$id") $(color "$C_DIM" "${M_NOTES[$idx]}")"
  run_shell_with_spinner "$id" "$cmd" "$log"
  rc=$?
  end=$(date +%s)
  append_master_log "$id" "exit=$rc" "$log"

  # "grep-ping" the log for the single most important line (skip in dry-run).
  if [ "$DRY_RUN" -eq 0 ]; then
    keymsg=$(extract_key_message "$log" "$rc")
  fi

  if [ "$DRY_RUN" -eq 0 ] && [ -n "$summary_cmd" ]; then
    summary=$(eval "$summary_cmd" 2>/dev/null | sed -n '1,10p' || true)
  fi

  R_STATUS[$idx]="$rc"
  R_SECONDS[$idx]="$((end - start))"
  R_LOG[$idx]="$log"
  R_SUMMARY[$idx]="$summary"
  R_KEYMSG[$idx]="$keymsg"

  if [ "$rc" -eq 0 ]; then
    say "$(color "$C_GREEN" "$SYM_OK") $id completed in $((end - start))s"
    # Show the extracted success line right under the animation, if we found one.
    if [ -n "$keymsg" ]; then
      say "$(color "$C_DIM" "  ${SYM_INFO} ")$(color "$C_GRAY" "$keymsg")"
    fi
  else
    say "$(color "$C_RED" "$SYM_FAIL") $id failed with exit code $rc after $((end - start))s"
    # Show the extracted failure reason prominently right under the animation.
    if [ -n "$keymsg" ]; then
      say "$(color "$C_RED" "  ${SYM_WARN} reason: ")$(color "$C_YELLOW" "$keymsg")"
    fi
    if [ "$SHOW_LOG_ON_FAILURE" -eq 1 ] && [ "$VERBOSE" -eq 0 ]; then
      say "$(color "$C_DIM" "  Last log lines:")"
      print_tail "$log" 15 | sed 's/^/    /'
    fi
  fi
}

build_selected_idx_list() {
  local positions=$1 out="" pos idx i
  if [ "$positions" = "all" ]; then
    i=0
    while [ $i -lt ${#D_IDX[@]} ]; do
      idx=${D_IDX[$i]}
      out="$out $idx"
      i=$((i + 1))
    done
  else
    for pos in $positions; do
      idx=${D_IDX[$pos]}
      out="$out $idx"
    done
  fi
  printf '%s' "$out"
}

run_selected() {
  local selected=$1 total done_count=0 idx
  total=$(printf '%s\n' $selected 2>/dev/null | wc -w | tr -d ' ')
  [ "$total" -eq 0 ] && {
    say "Nothing selected."
    return 1
  }

  reset_results
  prepare_privileges
  hr
  say "$(color "$C_BOLD" "Starting Updates") $(color "$C_DIM" "($total manager(s))")"
  for idx in $selected; do
    done_count=$((done_count + 1))
    printf '%s %s\n' "$(progress_bar "$done_count" "$total")" "$(color "$C_DIM" "${done_count}/${total}")"
    run_manager "$idx"
    hr
  done
}

summary_report() {
  local selected=$1 ok=0 fail=0 idx id rc secs log keymsg
  say "$(color "$C_BOLD" "Execution Summary")"
  # FIX: iterate by idx and read R_*[$idx] so status always matches its manager,
  # regardless of selection order or sparseness.
  for idx in $selected; do
    id=${M_ID[$idx]}
    rc=${R_STATUS[$idx]:-999}
    secs=${R_SECONDS[$idx]:-0}
    log=${R_LOG[$idx]:-}
    keymsg=${R_KEYMSG[$idx]:-}
    if [ "$rc" -eq 0 ]; then
      ok=$((ok + 1))
      printf '  %s %-18s %6ss\n' "$(color "$C_GREEN" "$SYM_OK")" "$id" "$secs"
    else
      fail=$((fail + 1))
      printf '  %s %-18s %6ss  log: %s\n' "$(color "$C_RED" "$SYM_FAIL")" "$id" "$secs" "$log"
      # Echo the extracted failure reason in the summary too, so the user gets a
      # concise "why" at a glance without opening the log.
      if [ -n "$keymsg" ]; then
        printf '       %s%s\n' "$(color "$C_DIM" "reason: ")" "$(color "$C_YELLOW" "$keymsg")"
      fi
    fi
  done
  hr
  say "$(color "$C_GREEN" "$ok succeeded") / $(color "$C_RED" "$fail failed")"
  [ -n "$LOG_FILE" ] && say "Full combined log written to: $LOG_FILE"
  [ "$fail" -gt 0 ] && return 1 || return 0
}

# ------------------------------ Main Flow ---------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    -i | --interactive) INTERACTIVE="yes" ;;
    -y | --yes | --all)
      ASSUME_YES=1
      INTERACTIVE="no"
      ;;
    --list)
      LIST_ONLY=1
      INTERACTIVE="no"
      ;;
    --dry-run) DRY_RUN=1 ;;
    --only)
      shift
      if [ $# -eq 0 ] || [ -z "$1" ] || [ "${1:0:1}" = "-" ]; then
        echo "Error: --only requires a comma-separated list." >&2
        exit 2
      fi
      ONLY_LIST="$1"
      ;;
    --only=*) ONLY_LIST="${1#*=}" ;;
    --skip)
      shift
      if [ $# -eq 0 ] || [ -z "$1" ] || [ "${1:0:1}" = "-" ]; then
        echo "Error: --skip requires a comma-separated list." >&2
        exit 2
      fi
      SKIP_LIST="$1"
      ;;
    --skip=*) SKIP_LIST="${1#*=}" ;;
    --no-color) COLOR_MODE="never" ;;
    --color) COLOR_MODE="always" ;;
    --ascii) UNICODE_MODE="never" ;;
    --unicode) UNICODE_MODE="always" ;;
    --no-clear) NO_CLEAR=1 ;;
    --log-file)
      shift
      LOG_FILE="${1:-}"
      ;;
    --log-file=*) LOG_FILE="${1#*=}" ;;
    -v | --verbose) VERBOSE=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      say "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
    esac
    shift
  done
}

um_main() {
  # Isolate our shell-option needs from any caller (e.g. UtilityKit main.sh runs
  # `set -e`). We want unset-var safety + pipefail, but NOT errexit, so that a
  # single failing package manager cannot abort the whole batch. Options are
  # restored automatically because `local -` scopes `set` changes to this function
  # (Bash 4.4+); on older Bash we simply leave the relaxed options, which matches
  # the tool's long-standing standalone behavior.
  local -
  set +e -u -o pipefail 2>/dev/null || set +e

  parse_args "$@"
  check_deps
  resolve_tmp
  init_ui
  register_managers
  banner
  check_internet

  if [ -n "$LOG_FILE" ]; then
    : >"$LOG_FILE" 2>/dev/null || {
      say "Cannot write log file: $LOG_FILE" >&2
      exit 2
    }
  fi

  detect_managers
  print_detected

  if [ "$LIST_ONLY" -eq 1 ]; then exit 0; fi
  if [ ${#D_IDX[@]} -eq 0 ]; then
    say "Adjust your --only/--skip filters. No tools found."
    exit 0
  fi

  local selected_idx
  SELECTED_POSITIONS=""
  if [ "$INTERACTIVE" = "yes" ] || { [ "$INTERACTIVE" = "auto" ] && is_tty && [ "$ASSUME_YES" -ne 1 ]; }; then
    interactive_menu || {
      say "Operation cancelled."
      exit 0
    }
    selected_idx=$(build_selected_idx_list "$SELECTED_POSITIONS")
  else
    if [ "$ASSUME_YES" -ne 1 ]; then
      say "Refusing to run non-interactively without --yes/--all. Try --list or --dry-run." >&2
      exit 2
    fi
    selected_idx=$(build_selected_idx_list "all")
  fi

  run_selected "$selected_idx"
  summary_report "$selected_idx"
}

# Entry point (standalone-safe, UtilityKit convention).
# When executed directly we apply strict mode here; when sourced by main.sh this
# block is skipped and main.sh calls um_main itself. Note we intentionally use
# `set -uo pipefail` (no -e): um_main also relaxes errexit locally, so failures
# in one manager never abort the run.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -uo pipefail
  IFS=$' \t\n'
  um_main "$@"
fi
