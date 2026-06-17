#!/usr/bin/env bash
#
# cacheclean.sh — Intelligent, safe, cross-platform cache cleaner for
# development package managers.
#
# README / INSTALL
# ----------------
# 1. Make executable:   chmod +x cacheclean.sh
# 2. Add to PATH:       ln -s "$PWD/cacheclean.sh" ~/.local/bin/cacheclean
#                        (or copy the whole directory and run ./cacheclean.sh)
# 3. Run:               cacheclean
# 4. Adding a new package manager: drop a new plugin into the plugins/ directory.
#    A plugin must define five functions named ${plugin_name}_plugin_info,
#    ${plugin_name}_detect, ${plugin_name}_get_cache_dirs,
#    ${plugin_name}_scan_cache and ${plugin_name}_clean_orphans. See the
#    bundled plugins (npm.sh, pip.sh, cargo.sh) for templates.
#
# Default behavior: dry-run preview + interactive confirmation before deletion.
# Use --yes to skip the prompt. Use --no-color to disable ANSI output.
#
# Author: Arena.ai Agent Mode
# Version: 1.0.0

set -o pipefail

VERSION="1.0.0"

# ---------------------------------------------------------------------------
# Defaults & globals
# ---------------------------------------------------------------------------
CC_OLDER_THAN=60
CC_YES=0
CC_DELETE=0
CC_QUIET=0
CC_DEBUG=0
CC_NO_COLOR=0
CC_FORCE_ROOT=0
CC_FANCY_REQUESTED=""

CC_OS="linux"
CC_TMPDIR=""
CC_STATE_DIR=""
CC_PLUGINS_DIR=""

CC_ACTIVE_PLUGINS=()
CC_PLUGIN_INFO=()

CC_TOTAL_CACHE_KB=0
CC_TOTAL_ORPHAN_BYTES=0
CC_TOTAL_ORPHAN_COUNT=0
CC_ERRORS=()

# ---------------------------------------------------------------------------
# CLI parsing
# ---------------------------------------------------------------------------
cc_usage() {
  cat <<EOF
Usage: cacheclean [OPTIONS]

Intelligently clean stale/orphaned cache files from development package
managers. Safe by default: always shows a preview and asks for confirmation.

Options:
  -h, --help            Show this help message and exit.
  -V, --version         Show version and exit.
  -y, --yes             Auto-confirm deletion after the preview.
      --delete          Explicitly enable deletion (alias for --yes).
      --older-than DAYS Mark files older than DAYS days as orphans (default: 60).
  -q, --quiet           Only print the final summary.
      --no-color        Disable ANSI colors.
      --fancy           Force Unicode symbols and colors.
      --no-fancy        Force plain ASCII symbols and borders.
      --debug           Print verbose internal steps (sets -x).
      --force-root      Allow running as root (normally refused for safety).

Examples:
  cacheclean
  cacheclean --older-than 30 --yes
  cacheclean --no-color --quiet

EOF
}

cc_parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        cc_usage
        exit 0
        ;;
      -V|--version)
        printf 'cacheclean %s\n' "$VERSION"
        exit 0
        ;;
      --debug)
        CC_DEBUG=1
        shift
        ;;
      --no-color)
        CC_NO_COLOR=1
        shift
        ;;
      --fancy)
        CC_FANCY_REQUESTED=1
        shift
        ;;
      --no-fancy)
        CC_FANCY_REQUESTED=0
        shift
        ;;
      -q|--quiet)
        CC_QUIET=1
        shift
        ;;
      -y|--yes)
        CC_YES=1
        shift
        ;;
      --delete)
        CC_DELETE=1
        CC_YES=1
        shift
        ;;
      --older-than)
        if [ -z "${2:-}" ] || ! printf '%s' "$2" | grep -qE '^[0-9]+$'; then
          printf 'Error: --older-than requires a positive integer.\n' >&2
          exit 1
        fi
        CC_OLDER_THAN="$2"
        shift 2
        ;;
      --force-root)
        CC_FORCE_ROOT=1
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        printf 'Error: unknown option: %s\n' "$1" >&2
        cc_usage >&2
        exit 1
        ;;
      *)
        printf 'Error: unexpected argument: %s\n' "$1" >&2
        cc_usage >&2
        exit 1
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Colors / UI helpers
# ---------------------------------------------------------------------------
cc_setup_colors() {
  if [ "$CC_NO_COLOR" -eq 1 ] || [ ! -t 1 ]; then
    C_RED=''
    C_GREEN=''
    C_YELLOW=''
    C_BLUE=''
    C_MAGENTA=''
    C_CYAN=''
    C_BOLD=''
    C_RESET=''
  else
    C_RED=$'\033[0;31m'
    C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m'
    C_BLUE=$'\033[0;34m'
    C_MAGENTA=$'\033[0;35m'
    C_CYAN=$'\033[0;36m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_ITALIC=$'\033[3m'
    C_UNDERLINE=$'\033[4m'
    C_RESET=$'\033[0m'
    # Bright variants (commonly used for accents)
    C_LRED=$'\033[91m'
    C_LGREEN=$'\033[92m'
    C_LYELLOW=$'\033[93m'
    C_LBLUE=$'\033[94m'
    C_LMAGENTA=$'\033[95m'
    C_LCYAN=$'\033[96m'
    C_WHITE=$'\033[97m'
    # Background colors
    C_BG_BLUE=$'\033[44m'
    C_BG_MAGENTA=$'\033[45m'
    C_BG_CYAN=$'\033[46m'
    C_BG_LBLUE=$'\033[104m'
    C_BG_LMAGENTA=$'\033[105m'
    C_BG_LCYAN=$'\033[106m'
  fi
}

cc_term_cols() {
  if [ -n "${COLUMNS:-}" ]; then
    printf '%s\n' "$COLUMNS"
  elif command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
    tput cols 2>/dev/null
  elif command -v stty >/dev/null 2>&1 && [ -t 1 ]; then
    stty size 2>/dev/null | awk '{print $2}'
  fi
}

cc_locale_is_utf8() {
  local loc
  loc="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
  case "$loc" in
    *UTF-8*|*utf-8*|*UTF8*|*utf8*|*C.UTF-8*) return 0 ;;
  esac
  return 1
}

cc_setup_box_chars() {
  local cols
  cols=$(cc_term_cols)

  # Fancy mode can be forced on/off via flags or env vars.
  local req=""
  if [ -n "${CC_FANCY_REQUESTED:-}" ]; then
    req="$CC_FANCY_REQUESTED"
  elif [ "${CACHECLEAN_FANCY:-}" = "1" ]; then
    req=1
  elif [ "${CACHECLEAN_NO_FANCY:-}" = "1" ]; then
    req=0
  fi

  if [ "$req" = "1" ]; then
    CC_FANCY_ICONS=1
    # On Termux fonts often break box-drawing, so keep ASCII borders there
    # unless the user explicitly requested borders via the env var.
    if [ "$CC_OS" = "termux" ] && [ -z "${CACHECLEAN_FANCY_BORDERS:-}" ]; then
      CC_FANCY_BORDERS=0
    else
      CC_FANCY_BORDERS=1
    fi
  elif [ "$req" = "0" ]; then
    CC_FANCY_BORDERS=0
    CC_FANCY_ICONS=0
  else
    # Auto-detect. Termux fonts often lack good box-drawing glyphs, so default
    # to ASCII borders there while keeping emojis/icons. Narrow or non-UTF-8
    # terminals also get ASCII borders. Icons stay Unicode when the locale supports it.
    if [ "$CC_OS" = "termux" ]; then
      CC_FANCY_BORDERS=0
    elif [ -n "$cols" ] && [ "$cols" -lt 90 ]; then
      CC_FANCY_BORDERS=0
    elif ! cc_locale_is_utf8 || [ ! -t 1 ] || [ "${TERM:-}" = "dumb" ]; then
      CC_FANCY_BORDERS=0
    else
      CC_FANCY_BORDERS=1
    fi

    if ! cc_locale_is_utf8 || [ ! -t 1 ]; then
      CC_FANCY_ICONS=0
    else
      CC_FANCY_ICONS=1
    fi
  fi

  if [ "$CC_FANCY_BORDERS" -eq 1 ]; then
    # Light single-line borders (similar to modern CLI dashboards)
    B_H='─'; B_V='│'; B_TL='┌'; B_TM='┬'; B_TR='┐'
    B_ML='├'; B_MM='┼'; B_MR='┤'
    B_BL='└'; B_BM='┴'; B_BR='┘'
  else
    B_H='-'; B_V='|'; B_TL='+'; B_TM='+'; B_TR='+'
    B_ML='+'; B_MM='+'; B_MR='+'
    B_BL='+'; B_BM='+'; B_BR='+'
  fi

  if [ "$CC_FANCY_ICONS" -eq 1 ]; then
    # Accent emojis (no broom/package-box pictographs).
    I_BROOM='⚡'
    I_OK='✅'
    I_ERR='❌'
    I_WARN='⚠️'
    I_PKG='🗑️'
    I_MAGIC='✨'
    I_STOP='🛑'
    I_CHART='📊'
    I_ARROW='⚡'
    I_INFO='ℹ️'
    I_MINUS='•'
  else
    I_BROOM='*'
    I_OK='[OK]'
    I_ERR='[ERR]'
    I_WARN='[WARN]'
    I_PKG='[del]'
    I_MAGIC='[clean]'
    I_STOP='[STOP]'
    I_CHART='[chart]'
    I_ARROW='>'
    I_INFO='[info]'
    I_MINUS='[no]'
  fi
}

cc_log_debug() {
  if [ "$CC_DEBUG" -eq 1 ]; then
    printf '%s[DEBUG]%s %s\n' "$C_CYAN" "$C_RESET" "$1" >&2
  fi
}

cc_log_warn() {
  printf '%s%s %s%s\n' "$C_YELLOW" "$I_WARN" "$1" "$C_RESET" >&2
}

cc_log_error() {
  printf '%s%s %s%s\n' "$C_RED" "$I_ERR" "$1" "$C_RESET" >&2
}

cc_hbar() {
  local width=$1 char=$2
  printf '%*s' "$width" '' | tr ' ' "$char"
}

cc_print_banner() {
  local c1 c2 line
  c1="  ${I_BROOM} cacheclean ${VERSION}  "
  c2="  intelligent cache cleaner  "
  local inner=${#c1}
  [ ${#c2} -gt "$inner" ] && inner=${#c2}

  line="$(cc_hbar "$((inner + 2))" "$B_H")"

  printf '\n'
  printf '%s%s%s%s%s\n' "$C_LCYAN" "$B_TL" "$line" "$B_TR" "$C_RESET"
  printf '%s%s%s%*s%s\n' "$C_LCYAN" "$B_V" "$c1" "$((inner - ${#c1}))" '' "$B_V$C_RESET"
  printf '%s%s%s%*s%s\n' "$C_LMAGENTA" "$B_V" "$c2" "$((inner - ${#c2}))" '' "$B_V$C_RESET"
  printf '%s%s%s%s%s\n' "$C_LCYAN" "$B_BL" "$line" "$B_BR" "$C_RESET"
}

cc_section_title() {
  local title=$1
  local width=${2:-48}
  printf '\n'
  printf '%s%s %s%s\n' "$C_BOLD$C_WHITE$C_BG_LCYAN" "${I_BROOM}" "$title" "$C_RESET"
  printf '%s%s%s\n' "$C_LCYAN" "$(cc_hbar "$width" "$B_H")" "$C_RESET"
}

# ---------------------------------------------------------------------------
# Environment detection
# ---------------------------------------------------------------------------
cc_detect_os() {
  local uname_s
  uname_s=$(uname -s)
  if [ -n "${TERMUX_VERSION:-}" ] || [ -n "${TERMUX_API_VERSION:-}" ] || [ -n "${PREFIX:-}" ]; then
    CC_OS="termux"
  elif [ "$uname_s" = "Darwin" ]; then
    CC_OS="macos"
  elif [ "$uname_s" = "Linux" ]; then
    CC_OS="linux"
  else
    CC_OS="other"
  fi
  cc_log_debug "OS detected as: $CC_OS"
}

cc_root_check() {
  local uid
  uid=$(id -u 2>/dev/null || echo 65534)
  if [ "$uid" -eq 0 ] && [ "$CC_FORCE_ROOT" -eq 0 ]; then
    cc_log_error "Running as root is not allowed. Use --force-root if you really mean it."
    exit 1
  fi
  if [ "$uid" -eq 0 ] && [ "$CC_FORCE_ROOT" -eq 1 ]; then
    cc_log_warn "Running as root by request. Be careful."
  fi
}

cc_require_basic_tools() {
  local cmd missing=()
  for cmd in id du find wc awk rm mkdir basename dirname cut sleep date uname; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    cc_log_error "Missing required tools: ${missing[*]}"
    exit 1
  fi
  cc_log_debug "Basic tools check passed"
}

cc_get_script_dir() {
  # Works when script is invoked via relative or absolute path.
  local src=${BASH_SOURCE[0]}
  local dir
  dir=$(dirname "$src")
  (cd "$dir" && pwd)
}

cc_manager_for_binary() {
  case "$1" in
    npm)       printf 'npm' ;;
    yarn)      printf 'yarn' ;;
    pnpm)      printf 'pnpm' ;;
    bun)       printf 'bun' ;;
    pip|pip3)  printf 'pip' ;;
    cargo)     printf 'cargo' ;;
    go)        printf 'go' ;;
    gem)       printf 'gem' ;;
    composer)  printf 'composer' ;;
    dotnet)    printf 'dotnet' ;;
    conan)     printf 'conan' ;;
    vcpkg)     printf 'vcpkg' ;;
    apt|apt-get) printf 'apt' ;;
    pacman)    printf 'pacman' ;;
    dnf|yum)   printf 'dnf' ;;
    brew)      printf 'brew' ;;
    apk)       printf 'apk' ;;
    *)         printf '' ;;
  esac
}

# ---------------------------------------------------------------------------
# Temporary state
# ---------------------------------------------------------------------------
cc_setup_tmp() {
  if [ -z "${TMPDIR:-}" ]; then
    CC_TMPDIR="$HOME/.cache/cacheclean"
  else
    CC_TMPDIR="$TMPDIR"
  fi
  if [ ! -d "$CC_TMPDIR" ]; then
    mkdir -p "$CC_TMPDIR" || {
      cc_log_error "Cannot create temp directory: $CC_TMPDIR"
      exit 1
    }
  fi
  CC_STATE_DIR="$CC_TMPDIR/cacheclean-$$"
  mkdir -p "$CC_STATE_DIR" || {
    cc_log_error "Cannot create state directory: $CC_STATE_DIR"
    exit 1
  }
  cc_log_debug "State directory: $CC_STATE_DIR"
}

cc_cleanup_tmp() {
  if [ -n "${CC_STATE_DIR:-}" ] && [ -d "$CC_STATE_DIR" ]; then
    rm -rf "$CC_STATE_DIR"
  fi
}

trap cc_cleanup_tmp EXIT

# ---------------------------------------------------------------------------
# Size / stat helpers (portable GNU/BSD/Termux)
# ---------------------------------------------------------------------------
cc_format_bytes() {
  local bytes=$1
  if command -v awk >/dev/null 2>&1; then
    awk -v b="$bytes" 'BEGIN {
      split("B KB MB GB TB PB", u);
      if (b < 1024) { printf "%d B", b; exit 0; }
      n = b; i = 1;
      while (n >= 1024 && i < 6) { n = n / 1024; i++; }
      printf "%.2f %s", n, u[i];
    }'
  else
    if [ "$bytes" -lt 1024 ]; then
      printf '%d B' "$bytes"
    else
      printf '%d KB' "$((bytes / 1024))"
    fi
  fi
}

cc_file_size() {
  local file=$1
  local sz
  if command -v stat >/dev/null 2>&1; then
    if stat --version >/dev/null 2>&1; then
      # GNU stat
      sz=$(stat -c%s -- "$file" 2>/dev/null) && { printf '%s' "$sz"; return; }
    else
      # BSD stat (macOS, etc.)
      sz=$(stat -f%z -- "$file" 2>/dev/null) && { printf '%s' "$sz"; return; }
    fi
  fi
  if [ -r "$file" ]; then
    wc -c < "$file" 2>/dev/null
  else
    printf '0'
  fi
}

cc_du_kb() {
  local dir=$1
  local kb
  kb=$(du -sk -- "$dir" 2>/dev/null | awk '{print $1}')
  if [ -z "$kb" ]; then
    printf '0'
  else
    printf '%s' "$kb"
  fi
}

# ---------------------------------------------------------------------------
# Orphan detection helpers (operate only inside the supplied directory)
# ---------------------------------------------------------------------------
cc_find_old() {
  local dir=$1 days=$2
  find "$dir" -type f -mtime +"$days" 2>/dev/null
}

cc_find_partial() {
  local dir=$1
  find "$dir" -type f \( \
    -name '*.part' -o \
    -name '*.download' -o \
    -name '*.tmp' -o \
    -name '*.temp' -o \
    -size 0 \
  \) 2>/dev/null
}

cc_find_locks() {
  local dir=$1
  if ! command -v lsof >/dev/null 2>&1; then
    return
  fi
  find "$dir" -type f \( -name '*.lock' -o -name '*.lck' \) 2>/dev/null | while IFS= read -r f; do
    if ! lsof "$f" >/dev/null 2>&1; then
      printf '%s\n' "$f"
    fi
  done
}

# ---------------------------------------------------------------------------
# Plugin output format helpers
#   TOT|cache_dir|size_in_kb
#   ORPHAN|cache_dir|path|size_in_bytes|reason
#   ERR|cache_dir|message
# ---------------------------------------------------------------------------
cc_emit_tot() {
  printf 'TOT|%s|%s\n' "$1" "$2"
}

cc_emit_orphan() {
  local dir=$1 path=$2 reason=$3
  local size
  size=$(cc_file_size "$path")
  printf 'ORPHAN|%s|%s|%s|%s\n' "$dir" "$path" "$size" "$reason"
}

cc_emit_err() {
  printf 'ERR|%s|%s\n' "$1" "$2"
}

# Generic deletion helper used by most plugins.
cc_clean_orphans_from_file() {
  local file=$1
  local type dir path size reason
  local -a seen=()
  local deleted=0 failed=0 reclaimed=0
  while IFS='|' read -r type dir path size reason; do
    [ "$type" = "ORPHAN" ] || continue
    [ -z "$path" ] && continue

    local dup=0 j
    for j in "${!seen[@]}"; do
      if [ "${seen[$j]}" = "$path" ]; then
        dup=1
        break
      fi
    done
    [ "$dup" -eq 1 ] && continue
    seen+=("$path")

    if [ ! -f "$path" ]; then
      cc_log_debug "Already gone: $path"
      continue
    fi
    if rm -f -- "$path"; then
      deleted=$((deleted + 1))
      reclaimed=$((reclaimed + ${size:-0}))
      cc_log_debug "Deleted: $path (${size:-0} bytes)"
    else
      failed=$((failed + 1))
      cc_log_error "Failed to delete: $path"
    fi
  done < "$file"
  printf '%d|%d|%d\n' "$deleted" "$failed" "$reclaimed"
}

# ---------------------------------------------------------------------------
# Spinner
# ---------------------------------------------------------------------------
cc_spinner() {
  local pid=$1 msg=$2
  local spin='|/-\' i=0 char
  while kill -0 "$pid" 2>/dev/null; do
    char=${spin:i%4:1}
    printf '\r%s %s' "$char" "$msg"
    sleep 0.1
    i=$((i + 1))
  done
  wait "$pid" 2>/dev/null
  printf '\r\033[K'
}

# ---------------------------------------------------------------------------
# Plugin discovery
# ---------------------------------------------------------------------------
cc_discover_plugins() {
  local script_dir
  script_dir=$(cc_get_script_dir)
  CC_PLUGINS_DIR="$script_dir/plugins"

  if [ ! -d "$CC_PLUGINS_DIR" ]; then
    cc_log_warn "Plugin directory not found: $CC_PLUGINS_DIR"
    return
  fi
  cc_log_debug "Plugins directory: $CC_PLUGINS_DIR"

  local f base func_info func_detect func_get func_scan func_clean info
  for f in "$CC_PLUGINS_DIR"/*.sh; do
    [ -f "$f" ] || continue
    base=$(basename "$f" .sh)
    cc_log_debug "Loading plugin: $f (prefix $base)"

    # shellcheck source=/dev/null
    source "$f" || {
      cc_log_warn "Failed to load plugin: $f"
      continue
    }

    func_info="${base}_plugin_info"
    func_detect="${base}_detect"
    func_get="${base}_get_cache_dirs"
    func_scan="${base}_scan_cache"
    func_clean="${base}_clean_orphans"

    if ! declare -f "$func_info" >/dev/null 2>&1; then
      cc_log_warn "Plugin $base missing $func_info"
      continue
    fi
    if ! declare -f "$func_detect" >/dev/null 2>&1; then
      cc_log_warn "Plugin $base missing $func_detect"
      continue
    fi
    if ! declare -f "$func_get" >/dev/null 2>&1; then
      cc_log_warn "Plugin $base missing $func_get"
      continue
    fi
    if ! declare -f "$func_scan" >/dev/null 2>&1; then
      cc_log_warn "Plugin $base missing $func_scan"
      continue
    fi
    if ! declare -f "$func_clean" >/dev/null 2>&1; then
      cc_log_warn "Plugin $base missing $func_clean"
      continue
    fi

    if "$func_detect" >/dev/null 2>&1; then
      info=$("$func_info")
      CC_ACTIVE_PLUGINS+=("$base")
      CC_PLUGIN_INFO+=("$info")
      cc_log_debug "Active plugin: $base ($info)"
    else
      cc_log_debug "Plugin $base: manager not detected"
    fi
  done
}

cc_print_env_summary() {
  local bin plugin plugin_path status found=0 active=0
  local -a active_plugins=()
  local known
  known='npm yarn pnpm bun pip pip3 cargo go gem composer dotnet conan vcpkg apt apt-get pacman dnf yum brew apk'

  cc_section_title "Environment scan"
  for bin in $known; do
    plugin=$(cc_manager_for_binary "$bin")
    plugin_path="$CC_PLUGINS_DIR/${plugin}.sh"
    if command -v "$bin" >/dev/null 2>&1; then
      found=$((found + 1))
      if [ -f "$plugin_path" ]; then
        status="${C_LGREEN}${I_OK} found  → plugin loaded${C_RESET}"
        local dup=0 p
        for p in "${active_plugins[@]}"; do
          [ "$p" = "$plugin" ] && dup=1
        done
        if [ "$dup" -eq 0 ]; then
          active_plugins+=("$plugin")
          active=$((active + 1))
        fi
      else
        status="${C_LYELLOW}${I_OK} found  → no plugin${C_RESET}"
      fi
    else
      status="${C_DIM}${I_MINUS} not found${C_RESET}"
    fi
    printf '  %s%-11s%s %s\n' "$C_LBLUE" "$bin" "$C_RESET" "$status"
  done
  printf '\n'
  printf '  %sFound:%s %s%d%s    %sActive:%s %s%d%s\n' \
    "$C_BOLD" "$C_RESET" "$C_LGREEN" "$found" "$C_RESET" \
    "$C_BOLD" "$C_RESET" "$C_LCYAN" "$active" "$C_RESET"
}

# ---------------------------------------------------------------------------
# Scanning
# ---------------------------------------------------------------------------
cc_scan_plugin() {
  local prefix=$1 name=$2 icon=$3
  local scan_file="$CC_STATE_DIR/${prefix}.scan"
  local err_file="$CC_STATE_DIR/${prefix}.err"
  local func="${prefix}_scan_cache"

  cc_log_debug "Scanning $name → $scan_file"

  "$func" > "$scan_file" 2> "$err_file" &
  local pid=$!

  if [ "$CC_QUIET" -eq 0 ]; then
    cc_spinner "$pid" "  ${icon} ${name} ..."
  else
    wait "$pid"
  fi

  if [ -s "$err_file" ]; then
    while IFS= read -r line; do
      cc_log_debug "${name} scan stderr: $line"
    done < "$err_file"
  fi

  printf '%s' "$scan_file"
}

cc_run_scans() {
  local i prefix name icon
  for i in "${!CC_ACTIVE_PLUGINS[@]}"; do
    prefix="${CC_ACTIVE_PLUGINS[$i]}"
    name=$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f2)
    icon=$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f3)
    cc_scan_plugin "$prefix" "$name" "$icon" >/dev/null
  done
}

# ---------------------------------------------------------------------------
# Report generation
# ---------------------------------------------------------------------------
cc_print_report() {
  CC_TOTAL_CACHE_KB=0
  CC_TOTAL_ORPHAN_BYTES=0
  CC_TOTAL_ORPHAN_COUNT=0
  CC_ERRORS=()

  local -a rows_m=()
  local -a rows_i=()
  local -a rows_p=()
  local -a rows_t=()
  local -a rows_c=()
  local -a rows_s=()
  local -a seen_paths=()

  local i prefix scan_file line
  local dir kb path bytes reason msg
  local type field2

  for i in "${!CC_ACTIVE_PLUGINS[@]}"; do
    prefix="${CC_ACTIVE_PLUGINS[$i]}"
    scan_file="$CC_STATE_DIR/${prefix}.scan"
    [ -f "$scan_file" ] || continue

    while IFS= read -r line; do
      type=${line%%|*}
      case "$type" in
        TOT)
          # TOT|dir|kb
          IFS='|' read -r _ dir kb <<< "$line"
          rows_m+=("$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f2)")
          rows_i+=("$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f3)")
          rows_p+=("$dir")
          rows_t+=("${kb:-0}")
          rows_c+=(0)
          rows_s+=(0)
          CC_TOTAL_CACHE_KB=$((CC_TOTAL_CACHE_KB + ${kb:-0}))
          ;;
        ORPHAN)
          # ORPHAN|dir|path|bytes|reason
          IFS='|' read -r _ dir path bytes reason <<< "$line"
          local key="${dir}|${path}"
          local dup=0 j
          for j in "${!seen_paths[@]}"; do
            if [ "${seen_paths[$j]}" = "$key" ]; then
              dup=1
              break
            fi
          done
          if [ "$dup" -eq 0 ]; then
            seen_paths+=("$key")
            local idx=-1
            for j in "${!rows_p[@]}"; do
              if [ "${rows_p[$j]}" = "$dir" ]; then
                idx=$j
                break
              fi
            done
            if [ "$idx" -ge 0 ]; then
              rows_c[$idx]=$((rows_c[$idx] + 1))
              rows_s[$idx]=$((rows_s[$idx] + ${bytes:-0}))
            fi
            CC_TOTAL_ORPHAN_COUNT=$((CC_TOTAL_ORPHAN_COUNT + 1))
            CC_TOTAL_ORPHAN_BYTES=$((CC_TOTAL_ORPHAN_BYTES + ${bytes:-0}))
          fi
          ;;
        ERR)
          # ERR|dir|message
          IFS='|' read -r _ dir msg <<< "$line"
          local mgr_name
          mgr_name=$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f2)
          CC_ERRORS+=("${mgr_name}: ${dir} — ${msg}")
          ;;
      esac
    done < "$scan_file"
  done

  if [ "$CC_QUIET" -eq 0 ]; then
    cc_section_title "Cache report"

    local j
    for j in "${!rows_m[@]}"; do
      printf '\n'
      printf '  %s%s%s %s%s%s\n' \
        "$C_LCYAN" "${rows_i[$j]}" "$C_RESET" "$C_BOLD$C_WHITE" "${rows_m[$j]}" "$C_RESET"
      printf '    %sPath:%s    %s%s%s\n' \
        "$C_LBLUE" "$C_RESET" "$C_DIM" "${rows_p[$j]}" "$C_RESET"
      printf '    %sTotal:%s   %s%s%s\n' \
        "$C_LBLUE" "$C_RESET" "$C_LGREEN" "$(cc_format_bytes $((rows_t[$j] * 1024)))" "$C_RESET"
      printf '    %sOrphans:%s %s%s%s (%s%s%s)\n' \
        "$C_LBLUE" "$C_RESET" \
        "$C_LYELLOW" "${rows_c[$j]}" "$C_RESET" \
        "$C_LYELLOW" "$(cc_format_bytes ${rows_s[$j]})" "$C_RESET"
      if [ "$j" -lt "$(( ${#rows_m[@]} - 1 ))" ]; then
        printf '  %s%s%s\n' "$C_DIM" "$(cc_hbar 44 "$B_H")" "$C_RESET"
      fi
    done

    cc_section_title "Summary"
    printf '  %s%s%s  %sTotal cache scanned:%s %s%s%s\n' \
      "$C_LCYAN" "$I_CHART" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_LCYAN" "$(cc_format_bytes $((CC_TOTAL_CACHE_KB * 1024)))" "$C_RESET"
    printf '  %s%s%s  %sTotal recoverable:%s   %s%s%s\n' \
      "$C_LGREEN" "$I_BROOM" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_LGREEN" "$(cc_format_bytes "$CC_TOTAL_ORPHAN_BYTES")" "$C_RESET"
    printf '  %s%s%s  %sOrphaned files:%s      %s%d%s\n' \
      "$C_LYELLOW" "$I_PKG" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_LYELLOW" "$CC_TOTAL_ORPHAN_COUNT" "$C_RESET"

    if [ "$CC_TOTAL_ORPHAN_COUNT" -gt 0 ] && [ "$CC_TOTAL_ORPHAN_BYTES" -eq 0 ]; then
      printf '\n  %s%s Note:%s %sThe found orphans are empty/partial files (0 B).\n' \
        "$C_LYELLOW" "$I_WARN" "$C_RESET" "$C_DIM"
      printf '  %s      %sUse --older-than DAYS to target older cache entries.%s\n' \
        "$C_DIM" "" "$C_RESET"
    fi

    if [ ${#CC_ERRORS[@]} -gt 0 ]; then
      cc_section_title "Errors / warnings" 52
      local err
      for err in "${CC_ERRORS[@]}"; do
        printf '  %s%s%s %s%s\n' "$C_LRED" "$I_WARN" "$C_RESET" "$C_DIM" "$err" "$C_RESET"
      done
    fi
  fi
}

# ---------------------------------------------------------------------------
# Confirmation & deletion
# ---------------------------------------------------------------------------
cc_prompt_confirm() {
  if [ "$CC_YES" -eq 1 ]; then
    cc_log_debug "Auto-confirming via --yes/--delete"
    return 0
  fi
  if [ ! -t 0 ]; then
    cc_log_warn "stdin is not a terminal; cannot prompt. Use --yes to delete."
    return 1
  fi

  local ans
  while true; do
    printf '%s%s%s %sDelete all orphaned files? [y/N]%s ' \
      "$C_LCYAN" "$I_ARROW" "$C_RESET" "$C_BOLD$C_WHITE" "$C_RESET"
    read -r ans
    case "$ans" in
      [Yy]|[Yy][Ee][Ss])
        return 0
        ;;
      [Nn]|[Nn][Oo]|'')
        return 1
        ;;
      *)
        printf 'Please answer yes or no.\n'
        ;;
    esac
  done
}

cc_list_orphans_to_delete() {
  cc_section_title "Files that will be deleted" 52

  local -a seen=()
  local i prefix name icon scan_file
  local line type dir path bytes reason

  for i in "${!CC_ACTIVE_PLUGINS[@]}"; do
    prefix="${CC_ACTIVE_PLUGINS[$i]}"
    name=$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f2)
    icon=$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f3)
    scan_file="$CC_STATE_DIR/${prefix}.scan"
    [ -f "$scan_file" ] || continue

    local mgr_printed=0
    while IFS='|' read -r type dir path bytes reason; do
      [ "$type" = "ORPHAN" ] || continue
      [ -z "$path" ] && continue

      local key="${dir}|${path}"
      local dup=0 j
      for j in "${!seen[@]}"; do
        if [ "${seen[$j]}" = "$key" ]; then
          dup=1
          break
        fi
      done
      [ "$dup" -eq 1 ] && continue
      seen+=("$key")

      if [ "$mgr_printed" -eq 0 ]; then
        printf '\n  %s%s%s %s%s%s\n' "$C_LCYAN" "$icon" "$C_RESET" "$C_BOLD$C_WHITE" "$name" "$C_RESET"
        mgr_printed=1
      fi
      printf '    %s%s%s %s%s%s\n' "$C_LRED" "•" "$C_RESET" "$C_DIM" "$path" "$C_RESET"
      printf '      %s%s%s %s— %s%s\n' \
        "$C_LYELLOW" "$(cc_format_bytes "$bytes")" "$C_RESET" \
        "$C_DIM" "$reason" "$C_RESET"
    done < "$scan_file"
  done

  printf '\n'
  printf '  %s%s%s  %sTotal:%s %s%d file(s)%s, %s%s%s reclaimable\n' \
    "$C_LYELLOW" "$I_PKG" "$C_RESET" "$C_BOLD" "$C_RESET" \
    "$C_LYELLOW" "$CC_TOTAL_ORPHAN_COUNT" "$C_RESET" \
    "$C_LGREEN" "$(cc_format_bytes "$CC_TOTAL_ORPHAN_BYTES")" "$C_RESET"
}

cc_prompt_final_confirm() {
  if [ "$CC_YES" -eq 1 ]; then
    cc_log_debug "Auto-confirming final deletion via --yes"
    return 0
  fi
  if [ ! -t 0 ]; then
    cc_log_warn "stdin is not a terminal; cannot prompt. Use --yes to delete."
    return 1
  fi

  local ans
  while true; do
    printf '%s%s%s %s%s%s' "$C_LRED" "$I_STOP" "$C_RESET" "$C_BOLD$C_LRED" "Are you sure? These files will be permanently deleted. [y/N]" "$C_RESET"
    read -r ans
    case "$ans" in
      [Yy]|[Yy][Ee][Ss])
        return 0
        ;;
      [Nn]|[Nn][Oo]|'')
        return 1
        ;;
      *)
        printf 'Please answer yes or no.\n'
        ;;
    esac
  done
}

cc_perform_deletion() {
  local total_deleted=0 total_failed=0 total_reclaimed=0
  local i prefix name icon scan_file result
  local d f r

  for i in "${!CC_ACTIVE_PLUGINS[@]}"; do
    prefix="${CC_ACTIVE_PLUGINS[$i]}"
    name=$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f2)
    icon=$(printf '%s' "${CC_PLUGIN_INFO[$i]}" | cut -d'|' -f3)
    scan_file="$CC_STATE_DIR/${prefix}.scan"
    [ -f "$scan_file" ] || continue

    cc_log_debug "Cleaning $name using ${prefix}_clean_orphans"
    result=$("${prefix}_clean_orphans" "$scan_file")
    IFS='|' read -r d f r <<< "$result"
    total_deleted=$((total_deleted + d))
    total_failed=$((total_failed + f))
    total_reclaimed=$((total_reclaimed + r))
  done

  printf '%d|%d|%d\n' "$total_deleted" "$total_failed" "$total_reclaimed"
}

cc_print_final_summary() {
  local result=$1
  local deleted failed reclaimed
  IFS='|' read -r deleted failed reclaimed <<< "$result"

  if [ "$CC_QUIET" -eq 0 ]; then
    local w=32
    local top sep bot
    top="${B_TL}$(cc_hbar "$w" "$B_H")${B_TR}"
    sep="${B_ML}$(cc_hbar "$w" "$B_H")${B_MR}"
    bot="${B_BL}$(cc_hbar "$w" "$B_H")${B_BR}"
    local c_border="$C_LMAGENTA"
    local c_text="$C_LGREEN"
    local c_err="$C_LRED"
    local c_rst="$C_RESET"

    printf '\n'
    printf '%s%s%s\n' "$c_border" "$top" "$c_rst"
    printf '%s%s%s\n' "$c_text" "${B_V}  ${I_MAGIC} Cleanup complete" "$c_rst"
    printf '%s%s%s\n' "$c_border" "$sep" "$c_rst"
    printf '%s%s%s\n' "$c_text" "${B_V}  Files deleted:    $deleted" "$c_rst"
    printf '%s%s%s\n' "$c_text" "${B_V}  Space reclaimed:  $(cc_format_bytes "$reclaimed")" "$c_rst"
    if [ "$failed" -gt 0 ]; then
      printf '%s%s%s\n' "$c_err" "${B_V}  Errors:           $failed" "$c_rst"
    fi
    printf '%s%s%s\n' "$c_border" "$bot" "$c_rst"
  else
    printf 'Reclaimed %s from %d file(s)' "$(cc_format_bytes "$reclaimed")" "$deleted"
    if [ "$failed" -gt 0 ]; then
      printf ', %d failed' "$failed"
    fi
    printf '\n'
  fi
}

# ---------------------------------------------------------------------------
# Main driver
# ---------------------------------------------------------------------------
cc_main() {
  cc_parse_args "$@"
  cc_setup_colors
  cc_require_basic_tools
  cc_detect_os
  cc_root_check
  cc_setup_box_chars
  cc_setup_tmp

  if [ "$CC_DEBUG" -eq 1 ]; then
    set -x
  fi

  cc_discover_plugins

  if [ ${#CC_ACTIVE_PLUGINS[@]} -eq 0 ]; then
    if [ "$CC_QUIET" -eq 0 ]; then
      cc_print_banner
      cc_print_env_summary
    fi
    cc_log_warn "No supported package managers detected. Nothing to do."
    exit 0
  fi

  if [ "$CC_QUIET" -eq 0 ]; then
    cc_print_banner
    cc_print_env_summary
  fi

  cc_run_scans
  cc_print_report

  if [ "$CC_TOTAL_ORPHAN_COUNT" -eq 0 ]; then
    if [ "$CC_QUIET" -eq 0 ]; then
      printf '\n%s%s%s %sNo orphaned cache files found. Nothing to clean.%s\n' \
        "$C_LGREEN" "$I_MAGIC" "$C_RESET" "$C_BOLD$C_LGREEN" "$C_RESET"
      printf '  %sThe cache is within your --older-than threshold.%s\n' "$C_DIM" "$C_RESET"
    fi
    exit 0
  fi

  if cc_prompt_confirm; then
    if [ "$CC_QUIET" -eq 0 ]; then
      cc_list_orphans_to_delete
    fi
    if cc_prompt_final_confirm; then
      local result
      result=$(cc_perform_deletion)
      cc_print_final_summary "$result"
    else
      if [ "$CC_QUIET" -eq 0 ]; then
        printf '\n  %s%s%s %sAborted. No files were deleted.%s\n' \
          "$C_LRED" "$I_STOP" "$C_RESET" "$C_BOLD" "$C_RESET"
      fi
      exit 0
    fi
  else
    if [ "$CC_QUIET" -eq 0 ]; then
      printf '\n  %s%s%s %sAborted. No files were deleted.%s\n' \
        "$C_LRED" "$I_STOP" "$C_RESET" "$C_BOLD" "$C_RESET"
    fi
    exit 0
  fi
}

cc_main "$@"
