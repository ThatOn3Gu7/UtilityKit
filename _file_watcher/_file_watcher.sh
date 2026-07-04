#!/usr/bin/env bash
# _file_watcher — run a command when files matching a glob change.
# Prefix: fw_
# Backends: inotifywait (Linux), fswatch (macOS/Termux), polling fallback

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_has_cmd  >/dev/null 2>&1; then uk_has_cmd()  { command -v "${1:-}" >/dev/null 2>&1; }; fi
if ! declare -f uk_error    >/dev/null 2>&1; then uk_error()    { printf "[ERR] %s\n" "$*" >&2; }; fi
if ! declare -f uk_warn     >/dev/null 2>&1; then uk_warn()     { printf "[WRN] %s\n" "$*" >&2; }; fi
if ! declare -f uk_info     >/dev/null 2>&1; then uk_info()     { printf "[INF] %s\n" "$*"; }; fi
if ! declare -f uk_success  >/dev/null 2>&1; then uk_success()  { printf "[OK]  %s\n" "$*"; }; fi
if ! declare -f uk_note     >/dev/null 2>&1; then uk_note()     { printf "-> %s\n" "$*"; }; fi
if ! declare -f uk_banner   >/dev/null 2>&1; then uk_banner()   { :; }; fi
if ! declare -f uk_prompt   >/dev/null 2>&1; then
  uk_prompt() {
    local label="${1:-}" default="${2:-}" reply=''
    printf '> %s%s: ' "$label" "${default:+ [$default]}" >&2
    [[ -r /dev/tty ]] && read -r reply </dev/tty || read -r reply
    printf '%s\n' "${reply:-$default}"
  }
fi
if ! declare -f uk_confirm  >/dev/null 2>&1; then
  uk_confirm() {
    local reply=''
    printf '> %s [y/N]: ' "${1:-Confirm?}" >&2
    [[ -r /dev/tty ]] && read -r reply </dev/tty || read -r reply
    [[ "$reply" =~ ^[Yy] ]]
  }
fi
if ! declare -f uk_platform >/dev/null 2>&1; then
  uk_platform() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then echo termux
    elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then echo macos
    else echo linux; fi
  }
fi
# --------------------------

fw_usage() {
  cat <<'USAGE'
Usage:
  _file_watcher.sh [OPTIONS] [-- CMD]

Options:
  -p, --pattern GLOB   Watch files matching GLOB (repeatable, default **/*).
  -d, --dir DIR        Watch directory (default .).
  -c, --cmd CMD        Command to run when files change.
  -s, --debounce SEC   Debounce interval (default 1).
  -i, --ignore GLOB    Ignore files matching GLOB (repeatable).
  -r, --initial        Run command once on start.
  --polling INTERVAL   Use polling instead of inotify (INTERVAL = seconds).
  --json               Machine-readable JSON output.
  --no-color           Disable ANSI (also respects NO_COLOR=1).
  -h, --help           Show this help.

Backends: inotifywait (Linux), fswatch (macOS/Termux), fallback: polling.
Install: apt install inotify-tools  |  brew install fswatch

Examples:
  _file_watcher.sh -p '*.sh' -c 'make test'
  _file_watcher.sh -p '*.py' -p '*.js' -c 'npm test' --debounce 2
  _file_watcher.sh -p '*' --polling 5 -c 'rsync ...'
USAGE
}

# ---- Backend detection ----------------------------------------------------

fw_detect_backend() {
  if uk_has_cmd inotifywait; then
    printf 'inotifywait\n'; return 0
  fi
  if uk_has_cmd fswatch; then
    printf 'fswatch\n'; return 0
  fi
  printf 'poll\n'; return 0
}

# ---- Watch loop -----------------------------------------------------------

fw_watch_inotify() {
  local dir="$1" debounce="$2"
  shift 2
  local -a patterns=("$@")

  if [[ ${#patterns[@]} -eq 0 ]]; then
    patterns=("--include" ".*")
  fi

  local -a inotify_args=("-m" "-r" "$dir" "-e" "modify" "-e" "create" "-e" "delete" "-e" "move")
  local p
  for p in "${patterns[@]}"; do
    inotify_args+=("--include" "$p")
  done

  inotifywait "${inotify_args[@]}" 2>/dev/null | while IFS= read -r event; do
    printf '%s\n' "$event"
  done
}

fw_watch_fswatch() {
  local dir="$1" debounce="$2"
  shift 2
  local -a patterns=("$@")

  local -a args=("-0" "-1" "$dir")
  [[ "$debounce" =~ ^[0-9]+(\.[0-9]+)?$ ]] && args+=("--latency=$debounce")

  fswatch "${args[@]}" 2>/dev/null | while IFS= read -r -d '' path; do
    printf '%s\n' "$path"
  done
}

fw_watch_poll() {
  local dir="$1" interval="$2"
  shift 2

  local -A snap=()
  local file

  while true; do
    while IFS= read -r -d '' file; do
      local mtime
      mtime="$(stat -c '%Y' "$file" 2>/dev/null || stat -f '%m' "$file" 2>/dev/null || echo '0')"
      if [[ -n "${snap[$file]:-}" ]] && [[ "${snap[$file]}" != "$mtime" ]]; then
        printf '%s (changed)\n' "$file"
      fi
      snap[$file]="$mtime"
    done < <(find "$dir" -type f -not -path '*/\.*' -print0 2>/dev/null)

    sleep "$interval" 2>/dev/null || sleep "$((interval))"
  done
}

# ---- Main ------------------------------------------------------------------

fw_main() {
  uk_banner "file-watcher" "Run command when files change" "" "$@"

  local dir="."
  local debounce=1
  local cmd="" poll_interval=""
  local initial=0
  local -a patterns=() ignores=()
  local as_json=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -p|--pattern) shift; patterns+=("${1:-}") ;;
      -d|--dir)     shift; dir="${1:-}" ;;
      -c|--cmd)     shift; cmd="${1:-}" ;;
      -s|--debounce) shift; debounce="${1:-1}" ;;
      -i|--ignore)  shift; ignores+=("${1:-}") ;;
      -r|--initial) initial=1 ;;
      --polling)    shift; poll_interval="${1:-2}" ;;
      --json)       as_json=1 ;;
      --no-color)   UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                    UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help)    fw_usage; return 0 ;;
      -*)           uk_error "Unknown: ${1:-}"; fw_usage; return 2 ;;
      --)           shift; cmd="$*"; break ;;
      *)            cmd="${1:-}" ;;
    esac
    shift || true
  done

  [[ -z "$cmd" ]] && { uk_error "Command required (--cmd or trailing --)."; fw_usage; return 2; }
  [[ ! -d "$dir" ]] && { uk_error "Directory not found: $dir"; return 2; }

  local backend
  if [[ -n "$poll_interval" ]]; then
    backend="poll"
  else
    backend="$(fw_detect_backend)"
  fi

  if (( initial )); then
    uk_info "Initial run..."
    eval "$cmd" 2>&1 | while IFS= read -r line; do printf '  [output] %s\n' "$line"; done
  fi

  if (( as_json )); then
    printf '{"watching":"%s","backend":"%s","command":%s}\n' \
      "$dir" "$backend" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$cmd" 2>/dev/null || echo '"'"$cmd"'"')"
    return 0
  fi

  printf '\n  %sWatching:%s %s  (%s backend)\n' \
    "${UK_C_BOLD:-}" "${UK_C_RESET:-}" "$dir" "$backend"
  printf '  %sCommand:%s %s\n\n' "${UK_C_BOLD:-}" "${UK_C_RESET:-}" "$cmd"

  case "$backend" in
    inotifywait)
      fw_watch_inotify "$dir" "$debounce" "${patterns[@]}" 2>/dev/null | while IFS= read -r event; do
        printf '  %schange detected:%s %s\n' "${UK_C_GREEN:-}" "${UK_C_RESET:-}" "$event"
        sleep "$debounce" 2>/dev/null || true
        eval "$cmd" 2>&1 | while IFS= read -r line; do printf '    [output] %s\n' "$line"; done
      done
      ;;
    fswatch)
      fw_watch_fswatch "$dir" "$debounce" "${patterns[@]}" | while IFS= read -r path; do
        printf '  %schange detected:%s %s\n' "${UK_C_GREEN:-}" "${UK_C_RESET:-}" "$path"
        sleep "$debounce" 2>/dev/null || true
        eval "$cmd" 2>&1 | while IFS= read -r line; do printf '    [output] %s\n' "$line"; done
      done
      ;;
    poll)
      uk_info "Polling every ${poll_interval}s..."
      local -A snap=()
      while true; do
        while IFS= read -r -d '' file; do
          local mtime
          mtime="$(stat -c '%Y' "$file" 2>/dev/null || stat -f '%m' "$file" 2>/dev/null || echo '0')"
          if [[ -n "${snap[$file]:-}" ]] && [[ "${snap[$file]}" != "$mtime" ]]; then
            printf '  %schange detected:%s %s\n' "${UK_C_GREEN:-}" "${UK_C_RESET:-}" "$file"
            eval "$cmd" 2>&1 | while IFS= read -r line; do printf '    [output] %s\n' "$line"; done
            break
          fi
          snap[$file]="$mtime"
        done < <(find "$dir" -type f -not -path '*/\.*' -print0 2>/dev/null)
        sleep "$poll_interval" 2>/dev/null || sleep "$((poll_interval))"
      done
      ;;
  esac
}

fw_wizard() {
  uk_banner "file-watcher" "Run command when files change" ""
  local dir pattern cmd debounce polling initial

  dir="$(uk_prompt 'Watch directory' '.' './src/' 'Directory to monitor for changes.')"
  pattern="$(uk_prompt 'File pattern (glob, blank = all files)' '' '*.sh' 'e.g. *.sh, *.py, **/*.md')"
  cmd="$(uk_prompt 'Command to run on change' 'echo files changed' 'make test' 'Shell command executed when files change.')"
  debounce="$(uk_prompt 'Debounce (seconds)' '1' '2' 'Ignore repeated changes within this window.')"
  if uk_confirm 'Run command once on start?' 'N'; then initial="--initial"; else initial=""; fi
  if uk_confirm 'Use polling (slower but compatible)?' 'N'; then
    polling="$(uk_prompt 'Poll interval (seconds)' '2' '5' '')"
  fi

  local -a a=("$dir" -c "$cmd" --debounce "$debounce")
  [[ -n "$pattern" ]] && a+=(-p "$pattern")
  [[ -n "$initial" ]] && a+=("$initial")
  [[ -n "$polling"  ]] && a+=(--polling "$polling")
  fw_main "${a[@]}"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    fw_wizard
  else
    fw_main "$@"
  fi
fi
