#!/usr/bin/env bash
CC_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CC_SCRIPT_DIR/../../lib/uk_common.sh"

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
CC_SCAN_FAILED=0
CC_ERRORS=()
# Usage function
cc_usage() {
  cat <<EOF
Usage: cacheclean [OPTIONS]

Options:
  -h, --help            Show help
  -y, --yes             Auto-confirm deletion
      --older-than DAYS
  -q, --quiet
      --no-color
      --fancy           Force nice Unicode
      --no-fancy        Force plain ASCII
      --debug
EOF
}
cc_parse_args() {
  while [ $# -gt 0 ]; do
    case "${1:-}" in
    -h | --help)
      cc_usage
      return 0
      ;;
    -V | --version)
      printf '_cache_clean %s\n' "$UK_VERSION"
      return 0
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
    -q | --quiet)
      CC_QUIET=1
      shift
      ;;
    -y | --yes)
      CC_YES=1
      shift
      ;;
    --delete)
      CC_DELETE=1
      CC_YES=1
      shift
      ;;
    --older-than)
      CC_OLDER_THAN="${2:-}"
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
      printf 'Unknown option: %s\n' "${1:-}" >&2
      return 1
      ;;
    *) break ;;
    esac
  done
  if ! [[ "$CC_OLDER_THAN" =~ ^[0-9]+$ ]] || [ "$CC_OLDER_THAN" -gt 36500 ]; then
    printf '%s\n' "--older-than must be an integer from 0 to 36500." >&2
    return 1
  fi
}
# COLORS (Gogh-inspired)
cc_setup_colors() {
  if [ "$CC_NO_COLOR" -eq 1 ] || [ ! -t 1 ]; then
    C_RESET='' C_BOLD='' C_DIM='' C_WHITE='' C_CYAN='' C_YELLOW='' C_RED=''
    C_LCYAN='' C_LGREEN='' C_LYELLOW='' C_LBLUE='' C_LRED='' C_LMAGENTA=''
    C_ACCENT='' C_SUCCESS='' C_WARN='' C_DANGER='' C_INFO='' C_PATH='' C_SIZE='' C_COUNT='' C_BG_ACCENT=''
    return
  fi

  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_WHITE=$'\033[37m'
  C_CYAN=$'\033[36m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'

  C_LCYAN=$'\033[38;5;123m'
  C_LGREEN=$'\033[38;5;157m'
  C_LYELLOW=$'\033[38;5;221m'
  C_LBLUE=$'\033[38;5;117m'
  C_LRED=$'\033[38;5;210m'
  C_LMAGENTA=$'\033[38;5;177m'
  C_ACCENT=$'\033[38;5;81m'
  C_SUCCESS=$'\033[38;5;114m'
  C_WARN=$'\033[38;5;215m'
  C_DANGER=$'\033[38;5;203m'
  C_INFO=$'\033[38;5;153m'
  C_PATH=$'\033[38;5;246m'
  C_SIZE=$'\033[38;5;157m'
  C_COUNT=$'\033[38;5;221m'
  C_BG_ACCENT=$'\033[48;5;24m'
}
# SYMBOLS (figures style) + Termux-safe
# Always space after symbol
cc_setup_box_chars() {
  local cols
  cols=$(cc_term_cols)

  local req=""
  if [ -n "${CC_FANCY_REQUESTED:-}" ]; then req="$CC_FANCY_REQUESTED"; fi

  if [ "$req" = "1" ]; then
    CC_FANCY_ICONS=1
    [ "$CC_OS" = "termux" ] && [ -z "${CACHECLEAN_FANCY_BORDERS:-}" ] && CC_FANCY_BORDERS=0 || CC_FANCY_BORDERS=1
  elif [ "$req" = "0" ]; then
    CC_FANCY_BORDERS=0
    CC_FANCY_ICONS=0
  else
    if [ "$CC_OS" = "termux" ]; then
      CC_FANCY_BORDERS=0
    elif [ -n "$cols" ] && [ "$cols" -lt 80 ]; then
      CC_FANCY_BORDERS=0
    else
      CC_FANCY_BORDERS=1
    fi
    CC_FANCY_ICONS=1
    ! cc_locale_is_utf8 && CC_FANCY_ICONS=0
  fi

  if [ "$CC_FANCY_BORDERS" -eq 1 ]; then
    B_H='─' B_V='│' B_TL='╭' B_TR='╮' B_BL='╰' B_BR='╯' B_VD='┆' B_ML='├' B_MR='┤'
  else
    B_H='-' B_V='|' B_TL='+' B_TR='+' B_BL='+' B_BR='+' B_VD='|' B_ML='+' B_MR='+'
  fi

  if [ "$CC_FANCY_ICONS" -eq 1 ]; then
    I_BROOM='✦' I_OK='✔' I_ERR='✖' I_WARN='⚠' I_PKG='◉' I_MAGIC='◆'
    I_STOP='◉' I_CHART='◈' I_ARROW='▸' I_INFO='ℹ' I_MINUS='◦' I_DOT='●'
  else
    I_BROOM='*' I_OK='[OK]' I_ERR='[X]' I_WARN='[ℹ]' I_PKG='[o]' I_MAGIC='[*]'
    I_STOP='[ℹ]' I_CHART='[#]' I_ARROW='>' I_INFO='i' I_MINUS='-' I_DOT='o'
  fi
}
cc_term_cols() {
  if [ -n "${COLUMNS:-}" ]; then
    printf '%s\n' "$COLUMNS"
    return 0
  fi
  if command -v tput >/dev/null 2>&1; then
    local cols
    cols=$(tput cols 2>/dev/null || true)
    if [ -n "$cols" ]; then
      printf '%s\n' "$cols"
      return 0
    fi
  fi
  if command -v stty >/dev/null 2>&1; then
    local cols
    cols=$(stty size 2>/dev/null | awk '{print $2}' || true)
    if [ -n "$cols" ]; then
      printf '%s\n' "$cols"
      return 0
    fi
  fi
  printf '80\n'
  return 0
}
cc_locale_is_utf8() {
  local loc="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
  case "$loc" in *UTF-8* | *utf-8* | *UTF8* | *utf8*) return 0 ;; esac
  return 1
}

cc_hbar() {
  local width=${1:-} char=${2:-$B_H}
  printf '%*s' "$width" '' | tr ' ' "$char"
}
# SAFE VISUAL BAR — ONLY # and - (this fixes the garbage symbols)
cc_progress_bar() {
  local current=${1:-} max=${2:-} width=${3:-28}
  if [ "${max:-0}" -le 0 ]; then
    printf '%s%s%s' "$C_DIM" "$(printf '%*s' "$width" '' | tr ' ' '-')" "$C_RESET"
    return
  fi
  local filled=$((current * width / max))
  [ "$filled" -gt "$width" ] && filled=$width
  local empty=$((width - filled))
  printf '%s%s%s%s%s' "$C_LGREEN" "$(printf '%*s' "$filled" '' | tr ' ' '#')" "$C_DIM" "$(printf '%*s' "$empty" '' | tr ' ' '-')" "$C_RESET"
}
cc_section_title() {
  local title=${1:-} width=${2:-52}
  local line=$(cc_hbar "$width" "$B_H")
  printf '\n%s%s %s %s %s%s\n' "$C_BG_ACCENT" "$C_WHITE$C_BOLD" "$I_BROOM" "$title" "$C_RESET" "$C_ACCENT"
  printf '%s%s%s\n' "$C_ACCENT" "$line" "$C_RESET"
}
cc_print_divider() {
  printf '  %s%s%s\n' "$C_DIM" "$(cc_hbar "${1:-44}" "$B_VD")" "$C_RESET"
}
# Core logic (unchanged)
cc_detect_os() {
  if [ -n "${TERMUX_VERSION:-}" ] || [ -n "${TERMUX_API_VERSION:-}" ] || [ -n "${PREFIX:-}" ]; then
    CC_OS="termux"
  elif [ "$(uname -s)" = "Darwin" ]; then
    CC_OS="macos"
  else
    CC_OS="linux"
  fi
}
cc_root_check() {
  if [ "$(id -u 2>/dev/null || echo 65534)" -eq 0 ] && [ "$CC_FORCE_ROOT" -eq 0 ]; then
    cc_log_error "Running as root is not allowed."
    return 1
  fi
  return 0
}
cc_require_basic_tools() {
  for cmd in id du find wc awk rm mkdir basename dirname cut sleep date uname; do
    command -v "$cmd" >/dev/null 2>&1 || {
      cc_log_error "Missing tool: $cmd"
      return 1
    }
  done
}
cc_get_script_dir() { (cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); }
cc_manager_for_binary() {
  case "${1:-}" in
  npm | yarn | pnpm | bun | pip* | cargo | go | gem | composer | dotnet | conan | vcpkg | apt* | pacman | dnf | yum | brew | apk) printf '%s' "${1:-}" | sed 's/3$//;s/-get$//' ;;
  *) printf '' ;;
  esac
}
cc_setup_tmp() {
  CC_TMPDIR="${TMPDIR:-$HOME/.cache/cacheclean}"
  mkdir -p "$CC_TMPDIR" || {
    cc_log_error "Cannot create $CC_TMPDIR"
    return 1
  }
  CC_STATE_DIR="$CC_TMPDIR/cacheclean-$$"
  mkdir -m 700 "$CC_STATE_DIR" || {
    cc_log_error "Cannot create $CC_STATE_DIR"
    return 1
  }
}
cc_cleanup_tmp() {
  if [ -n "${CC_STATE_DIR:-}" ] && [ -d "$CC_STATE_DIR" ]; then
    rm -rf "$CC_STATE_DIR" 2>/dev/null || true
  fi
  return 0
}
# (Trap registered in cc_main)
cc_format_bytes() {
  awk -v b="${1:-}" 'BEGIN{
    split("B KB MB GB TB",u);
    if(b<1024){printf "%d B",b;exit}
    n=b;i=1;while(n>=1024&&i<5){n/=1024;i++}
    printf "%.2f %s",n,u[i]
  }' 2>/dev/null || echo "${1:-} B"
}
cc_file_size() {
  local path="${1:-}" size=''
  if command -v stat >/dev/null; then
    if size="$(stat -c%s -- "$path" 2>&1)"; then
      printf '%s\n' "$size"
      return 0
    fi
    if size="$(stat -f%z -- "$path" 2>&1)"; then
      printf '%s\n' "$size"
      return 0
    fi
  fi
  # Truncate whitespace: `wc -c` emits space-padded output (e.g. "     123")
  # that would otherwise fail the caller's `^[0-9]+$` validation.
  wc -c <"$path" | awk '{print $1}'
}
cc_du_kb() { du -sk -- "${1:-}" | awk 'NR==1 {print $1}'; }
cc_find_old() { find "${1:-}" -type f -mtime +"${2:-}"; }
cc_find_partial() { find "${1:-}" -type f \( -empty -o -name '*.tmp' -o -name '*.part' -o -name '*.download' -o -name '*.incomplete' \); }
cc_encode_field() {
  local value="${1:-}"
  value="${value//%/%25}"
  value="${value//|/%7C}"
  value="${value//$'\r'/%0D}"
  value="${value//$'\n'/%0A}"
  printf '%s' "$value"
}
cc_decode_field() {
  local value="${1:-}"
  value="${value//%0A/$'\n'}"
  value="${value//%0D/$'\r'}"
  value="${value//%7C/|}"
  value="${value//%25/%}"
  printf '%s' "$value"
}
cc_emit_tot() { printf 'TOT|%s|%s\n' "$(cc_encode_field "${1:-}")" "${2:-}"; }
cc_emit_orphan() {
  local dir="${1:-}" path="${2:-}" reason="${3:-}" size
  size="$(cc_file_size "$path")" || {
    cc_emit_err "$dir" "unable to read file size: $path"
    return 1
  }
  printf 'ORPHAN|%s|%s|%s|%s\n' \
    "$(cc_encode_field "$dir")" "$(cc_encode_field "$path")" "$size" "$(cc_encode_field "$reason")"
}
cc_emit_err() { printf 'ERR|%s|%s\n' "$(cc_encode_field "${1:-}")" "$(cc_encode_field "${2:-}")"; }
cc_path_within_dir() {
  local dir="${1:-}" path="${2:-}" abs_dir abs_parent abs_path
  [[ -d "$dir" && -e "$path" ]] || return 1
  abs_dir="$(cd "$dir" && pwd -P)" || return 1
  abs_parent="$(cd "$(dirname "$path")" && pwd -P)" || return 1
  abs_path="$abs_parent/$(basename "$path")"
  [[ "$abs_path" == "$abs_dir"/* ]]
}
cc_clean_orphans_from_file() {
  local file=${1:-} deleted=0 failed=0 reclaimed=0
  local type encoded_dir encoded_path size encoded_reason dir path reason
  declare -A seen=()
  while IFS='|' read -r type encoded_dir encoded_path size encoded_reason; do
    [ "$type" = "ORPHAN" ] || continue
    dir="$(cc_decode_field "$encoded_dir")" || { failed=$((failed + 1)); continue; }
    path="$(cc_decode_field "$encoded_path")" || { failed=$((failed + 1)); continue; }
    reason="$(cc_decode_field "$encoded_reason")" || { failed=$((failed + 1)); continue; }
    [ -z "$path" ] && continue
    [ -n "${seen[$path]:-}" ] && continue
    seen[$path]=1
    [ -f "$path" ] || continue
    if ! cc_path_within_dir "$dir" "$path"; then
      cc_log_error "Refusing deletion outside approved cache root '$dir': $path ($reason)"
      failed=$((failed + 1))
      continue
    fi
    if rm -f -- "$path"; then
      deleted=$((deleted + 1))
      reclaimed=$((reclaimed + ${size:-0}))
    else
      cc_log_error "Failed to delete cache file: $path"
      failed=$((failed + 1))
    fi
  done <"$file"
  printf '%d|%d|%d\n' "$deleted" "$failed" "$reclaimed"
}
cc_spinner() {
  local pid=${1:-} msg=${2:-} rc=0
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r%s %s' "$C_LCYAN${spin:i%10:1}$C_RESET" "$msg"
    sleep 0.08
    i=$((i + 1))
  done
  wait "$pid" || rc=$?
  printf '\r\033[K'
  return "$rc"
}
cc_discover_plugins() {
  CC_PLUGINS_DIR="$(cc_get_script_dir)/plugins"
  [ -d "$CC_PLUGINS_DIR" ] || return

  local f base
  for f in "$CC_PLUGINS_DIR"/*.sh; do
    [ -f "$f" ] || continue
    base=$(basename "$f" .sh)
    source "$f" 2>/dev/null || continue

    local fi="${base}_plugin_info" fd="${base}_detect" fg="${base}_get_cache_dirs" fs="${base}_scan_cache" fc="${base}_clean_orphans"
    declare -f "$fi" >/dev/null 2>&1 || continue
    declare -f "$fd" >/dev/null 2>&1 || continue
    declare -f "$fg" >/dev/null 2>&1 || continue
    declare -f "$fs" >/dev/null 2>&1 || continue
    declare -f "$fc" >/dev/null 2>&1 || continue

    if "$fd" >/dev/null 2>&1; then
      CC_ACTIVE_PLUGINS+=("$base")
      CC_PLUGIN_INFO+=("$("$fi")")
    fi
  done
}
cc_print_env_summary() {
  local known='npm yarn pnpm bun pip pip3 cargo go gem composer dotnet conan vcpkg apt apt-get pacman dnf yum brew apk'
  cc_section_title "Environment scan"
  local found=0 active=0 bin plugin
  for bin in $known; do
    plugin=$(cc_manager_for_binary "$bin")
    if command -v "$bin" >/dev/null 2>&1; then
      found=$((found + 1))
      if [ -f "$CC_PLUGINS_DIR/${plugin}.sh" ]; then
        printf '  %s%-11s%s %s%s%s %s\n' "$C_LBLUE" "$bin" "$C_RESET" "$C_LGREEN" "$I_OK" "$C_RESET" "${C_SUCCESS}plugin loaded${C_RESET}"
        active=$((active + 1))
      else
        printf '  %s%-11s%s %s%s%s %s\n' "$C_LBLUE" "$bin" "$C_RESET" "$C_LYELLOW" "$I_OK" "$C_RESET" "${C_WARN}no plugin${C_RESET}"
      fi
    else
      printf '  %s%-11s%s %s%s%s\n' "$C_LBLUE" "$bin" "$C_RESET" "$C_DIM" "$I_MINUS" "$C_RESET"
    fi
  done
  printf '\n  %sFound: %s %s%d%s    %sActive: %s %s%d%s\n' "$C_BOLD" "$C_RESET" "$C_LGREEN" "$found" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_LCYAN" "$active" "$C_RESET"
  cc_print_divider 44
}
cc_scan_plugin() {
  local prefix=${1:-} name=${2:-} icon=${3:-} rc=0
  local sf="$CC_STATE_DIR/${prefix}.scan" ef="$CC_STATE_DIR/${prefix}.err"
  "${prefix}_scan_cache" >"$sf" 2>"$ef" &
  local pid=$!
  if [ "$CC_QUIET" -eq 0 ]; then
    cc_spinner "$pid" "  ${icon} ${name} scanning..." || rc=$?
  else
    wait "$pid" || rc=$?
  fi
  if [ -s "$ef" ]; then
    local err_text
    err_text="$(cat "$ef")" || err_text="unable to read plugin stderr log"
    cc_log_error "$name scan stderr: $err_text"
    cc_emit_err "$name" "$err_text" >>"$sf"
    rc=1
  fi
  rm -f "$ef" || {
    cc_log_error "Unable to remove plugin error log: $ef"
    rc=1
  }
  printf '%s' "$sf"
  return "$rc"
}
cc_run_scans() {
  local i p n ic
  CC_SCAN_FAILED=0
  for i in "${!CC_ACTIVE_PLUGINS[@]}"; do
    p="${CC_ACTIVE_PLUGINS[$i]}"
    IFS='|' read -r _ n ic _ <<<"${CC_PLUGIN_INFO[$i]}"
    if ! cc_scan_plugin "$p" "$n" "$ic" >/dev/null; then
      CC_SCAN_FAILED=1
    fi
  done
  ((CC_SCAN_FAILED == 0))
}
cc_print_report() {
  CC_TOTAL_CACHE_KB=0
  CC_TOTAL_ORPHAN_BYTES=0
  CC_TOTAL_ORPHAN_COUNT=0
  CC_ERRORS=()

  local -a rows_m rows_i rows_p rows_t rows_c rows_s
  declare -A seen_paths=()
  declare -A path_to_idx=()

  local i prefix scan_file line pname picon dir path reason kb bytes msg
  for i in "${!CC_ACTIVE_PLUGINS[@]}"; do
    prefix="${CC_ACTIVE_PLUGINS[$i]}"
    scan_file="$CC_STATE_DIR/${prefix}.scan"
    [ -f "$scan_file" ] || continue

    # Hoist plugin-info parsing out of the per-line loop (saves 2 forks per record)
    IFS='|' read -r _ pname picon _ <<<"${CC_PLUGIN_INFO[$i]}"

    while IFS= read -r line; do
      local type=${line%%|*}
      case "$type" in
      TOT)
        local encoded_dir
        IFS='|' read -r _ encoded_dir kb <<<"$line"
        dir="$(cc_decode_field "$encoded_dir")" || { CC_ERRORS+=("${pname}: invalid cache-root record"); CC_SCAN_FAILED=1; continue; }
        [[ "$kb" =~ ^[0-9]+$ ]] || { CC_ERRORS+=("${pname}: invalid cache size for $dir"); CC_SCAN_FAILED=1; continue; }
        rows_m+=("$pname")
        rows_i+=("$picon")
        rows_p+=("$dir")
        rows_t+=("$kb")
        rows_c+=(0)
        rows_s+=(0)
        path_to_idx[$dir]=$((${#rows_p[@]} - 1))
        CC_TOTAL_CACHE_KB=$((CC_TOTAL_CACHE_KB + kb))
        ;;
      ORPHAN)
        local encoded_dir encoded_path encoded_reason
        IFS='|' read -r _ encoded_dir encoded_path bytes encoded_reason <<<"$line"
        dir="$(cc_decode_field "$encoded_dir")" || { CC_ERRORS+=("${pname}: invalid orphan root record"); CC_SCAN_FAILED=1; continue; }
        path="$(cc_decode_field "$encoded_path")" || { CC_ERRORS+=("${pname}: invalid orphan path record"); CC_SCAN_FAILED=1; continue; }
        reason="$(cc_decode_field "$encoded_reason")" || { CC_ERRORS+=("${pname}: invalid orphan reason record"); CC_SCAN_FAILED=1; continue; }
        [[ "$bytes" =~ ^[0-9]+$ ]] || { CC_ERRORS+=("${pname}: invalid size for $path"); CC_SCAN_FAILED=1; continue; }
        local key="${dir}|${path}"
        [ -n "${seen_paths[$key]:-}" ] && continue
        seen_paths[$key]=1
        local idx="${path_to_idx[$dir]:-}"
        if [ -n "$idx" ]; then
          rows_c[$idx]=$((rows_c[$idx] + 1))
          rows_s[$idx]=$((rows_s[$idx] + bytes))
        else
          CC_ERRORS+=("${pname}: orphan has no approved cache root — $path")
          CC_SCAN_FAILED=1
          continue
        fi
        CC_TOTAL_ORPHAN_COUNT=$((CC_TOTAL_ORPHAN_COUNT + 1))
        CC_TOTAL_ORPHAN_BYTES=$((CC_TOTAL_ORPHAN_BYTES + bytes))
        ;;
      ERR)
        local encoded_dir encoded_msg
        IFS='|' read -r _ encoded_dir encoded_msg <<<"$line"
        dir="$(cc_decode_field "$encoded_dir")"
        msg="$(cc_decode_field "$encoded_msg")"
        CC_ERRORS+=("${pname}: ${dir} — ${msg}")
        ;;
      esac
    done <"$scan_file"
  done

  if [ "$CC_QUIET" -eq 0 ]; then
    cc_section_title "Cache report"

    local j max_kb=0
    for j in "${!rows_t[@]}"; do [ "${rows_t[$j]}" -gt "$max_kb" ] && max_kb=${rows_t[$j]}; done

    for j in "${!rows_m[@]}"; do
      printf '\n'
      printf '  %s%s%s %s%s%s\n' "$C_LCYAN" "${rows_i[$j]}" "$C_RESET" "$C_BOLD$C_WHITE" "${rows_m[$j]}" "$C_RESET"
      printf '    %sPath: %s    %s%s%s\n' "$C_LBLUE" "$C_RESET" "$C_DIM" "${rows_p[$j]}" "$C_RESET"
      printf '    %sTotal: %s   %s%s%s\n' "$C_LBLUE" "$C_RESET" "$C_LGREEN" "$(cc_format_bytes $((rows_t[$j] * 1024)))" "$C_RESET"

      # FIXED VISUAL BAR
      printf '    %sVisual: %s %s\n' "$C_LBLUE" "$C_RESET" "$(cc_progress_bar "${rows_t[$j]}" "$max_kb" 28)"

      printf '    %sOrphans: %s %s%s%s (%s%s%s)\n' \
        "$C_LBLUE" "$C_RESET" "$C_COUNT" "${rows_c[$j]}" "$C_RESET" "$C_LYELLOW" "$(cc_format_bytes ${rows_s[$j]})" "$C_RESET"

      [ "$j" -lt "$((${#rows_m[@]} - 1))" ] && cc_print_divider 48
    done

    cc_section_title "Summary"
    local w=46
    printf '  %s%s%s\n' "$C_ACCENT" "$(cc_hbar "$w" "$B_H")" "$C_RESET"
    printf '  %s%s %s%s Total cache scanned:%s %s%s%s\n' "$C_ACCENT" "$B_V" "$C_LCYAN" "$I_CHART" "$C_RESET" "$C_LCYAN$C_BOLD" "$(cc_format_bytes $((CC_TOTAL_CACHE_KB * 1024)))" "$C_RESET"
    printf '  %s%s %s%s Total recoverable:%s   %s%s%s\n' "$C_ACCENT" "$B_V" "$C_LGREEN" "$I_BROOM" "$C_RESET" "$C_LGREEN$C_BOLD" "$(cc_format_bytes "$CC_TOTAL_ORPHAN_BYTES")" "$C_RESET"
    printf '  %s%s %s%s Orphaned files:%s      %s%d%s\n' "$C_ACCENT" "$B_V" "$C_LYELLOW" "$I_PKG" "$C_RESET" "$C_COUNT$C_BOLD" "$CC_TOTAL_ORPHAN_COUNT" "$C_RESET"
    printf '  %s%s%s\n' "$C_ACCENT" "$(cc_hbar "$w" "$B_H")" "$C_RESET"

    if [ ${#CC_ERRORS[@]} -gt 0 ]; then
      cc_section_title "Errors / warnings" 52
      local err
      for err in "${CC_ERRORS[@]}"; do
        printf '  %s%s%s %s%s\n' "$C_LRED" "$I_WARN" "$C_RESET" "$C_DIM" "$err" "$C_RESET"
      done
    fi
  fi
}
cc_prompt_confirm() {
  [ "$CC_YES" -eq 1 ] && return 0
  [ ! -t 0 ] && return 1
  local ans
  while true; do
    printf '%s%s%s %sDelete all orphaned files? [y/N]%s ' "$C_LCYAN" "$I_ARROW" "$C_RESET" "$C_BOLD$C_WHITE" "$C_RESET"
    read -r ans
    case "$ans" in [Yy] | [Yy][Ee][Ss]) return 0 ;; [Nn] | [Nn][Oo] | '') return 1 ;; *) echo "yes or no" ;; esac
  done
}
cc_list_orphans_to_delete() {
  cc_section_title "Files that will be deleted" 52
  declare -A seen=()
  local i prefix name icon scan_file
  for i in "${!CC_ACTIVE_PLUGINS[@]}"; do
    prefix="${CC_ACTIVE_PLUGINS[$i]}"
    IFS='|' read -r _ name icon _ <<<"${CC_PLUGIN_INFO[$i]}"
    scan_file="$CC_STATE_DIR/${prefix}.scan"
    [ -f "$scan_file" ] || continue
    local mgr_printed=0 type encoded_dir encoded_path encoded_reason dir path bytes reason
    while IFS='|' read -r type encoded_dir encoded_path bytes encoded_reason; do
      [ "$type" = "ORPHAN" ] || continue
      dir="$(cc_decode_field "$encoded_dir")" || continue
      path="$(cc_decode_field "$encoded_path")" || continue
      reason="$(cc_decode_field "$encoded_reason")" || continue
      [ -z "$path" ] && continue
      local key="${dir}|${path}"
      [ -n "${seen[$key]:-}" ] && continue
      seen[$key]=1
      [ "$mgr_printed" -eq 0 ] && {
        printf '\n  %s%s%s %s%s%s\n' "$C_LCYAN" "$icon" "$C_RESET" "$C_BOLD$C_WHITE" "$name" "$C_RESET"
        mgr_printed=1
      }
      printf '    %s%s%s %s%s%s\n' "$C_LRED" "$I_DOT" "$C_RESET" "$C_DIM" "$path" "$C_RESET"
      printf '      %s%s %s— %s%s%s\n' "$C_LYELLOW" "$(cc_format_bytes "$bytes")" "$C_RESET" "$C_PATH" "$reason" "$C_RESET"
    done <"$scan_file"
  done

  printf '\n'
  local w=50
  printf '  %s%s%s\n' "$C_ACCENT" "$(cc_hbar "$w" "$B_H")" "$C_RESET"
  printf '  %s%s%s  %sTotal:%s %s%d file(s)%s, %s%s%s reclaimable\n' "$C_LYELLOW" "$I_PKG" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_COUNT" "$CC_TOTAL_ORPHAN_COUNT" "$C_RESET" "$C_LGREEN" "$(cc_format_bytes "$CC_TOTAL_ORPHAN_BYTES")" "$C_RESET"
  printf '  %s%s%s\n' "$C_ACCENT" "$(cc_hbar "$w" "$B_H")" "$C_RESET"
}
cc_prompt_final_confirm() {
  [ "$CC_YES" -eq 1 ] && return 0
  [ ! -t 0 ] && return 1
  local ans
  while true; do
    printf '%s%s%s %sAre you sure? These files will be permanently deleted. [y/N]%s ' "$C_LRED" "$I_STOP" "$C_RESET" "$C_BOLD$C_LRED" "$C_RESET"
    read -r ans
    case "$ans" in [Yy] | [Yy][Ee][Ss]) return 0 ;; [Nn] | [Nn][Oo] | '') return 1 ;; *) echo "yes or no" ;; esac
  done
}
cc_perform_deletion() {
  local total_deleted=0 total_failed=0 total_reclaimed=0
  local i prefix scan_file result d f r
  for i in "${!CC_ACTIVE_PLUGINS[@]}"; do
    prefix="${CC_ACTIVE_PLUGINS[$i]}"
    scan_file="$CC_STATE_DIR/${prefix}.scan"
    [ -f "$scan_file" ] || continue
    result=$("${prefix}_clean_orphans" "$scan_file")
    IFS='|' read -r d f r <<<"$result"
    total_deleted=$((total_deleted + d))
    total_failed=$((total_failed + f))
    total_reclaimed=$((total_reclaimed + r))
  done
  printf '%d|%d|%d\n' "$total_deleted" "$total_failed" "$total_reclaimed"
}
cc_print_final_summary() {
  local result=${1:-}
  local deleted failed reclaimed
  IFS='|' read -r deleted failed reclaimed <<<"$result"

  if [ "$CC_QUIET" -eq 0 ]; then
    local w=42
    local top="${B_TL}$(cc_hbar "$w" "$B_H")${B_TR}"
    local sep="${B_ML}$(cc_hbar "$w" "$B_H")${B_MR}"
    local bot="${B_BL}$(cc_hbar "$w" "$B_H")${B_BR}"
    printf '\n'
    printf '%s%s%s\n' "$C_LMAGENTA" "$top" "$C_RESET"
    printf '%s%s  %s%s %sCleanup complete%s\n' "$C_LMAGENTA" "$B_V" "$C_ACCENT" "$I_MAGIC" "$C_BOLD$C_LGREEN" "$C_RESET"
    printf '%s%s%s\n' "$C_LMAGENTA" "$sep" "$C_RESET"
    printf '%s%s  Files deleted:    %s%d%s\n' "$C_LGREEN" "$B_V" "$C_BOLD" "$deleted" "$C_RESET"
    printf '%s%s  Space reclaimed:  %s%s%s\n' "$C_LGREEN" "$B_V" "$C_BOLD$C_LGREEN" "$(cc_format_bytes "$reclaimed")" "$C_RESET"
    [ "$failed" -gt 0 ] && printf '%s%s  Errors:           %s%d%s\n' "$C_LRED" "$B_V" "$C_BOLD" "$failed" "$C_RESET"
    printf '%s%s%s\n' "$C_LMAGENTA" "$bot" "$C_RESET"
    printf '\n'
  else
    printf 'Reclaimed %s from %d file(s)' "$(cc_format_bytes "$reclaimed")" "$deleted"
    [ "$failed" -gt 0 ] && printf ', %d failed' "$failed"
    printf '\n'
  fi
  [ "$failed" -eq 0 ]
}
cc_log_debug() { [ "$CC_DEBUG" -eq 1 ] && printf '%s[DEBUG]%s %s\n' "$C_CYAN" "$C_RESET" "${1:-}" >&2; }
cc_log_warn() { printf '%s%s %s%s\n' "$C_YELLOW" "$I_WARN" "${1:-}" "$C_RESET" >&2; }
cc_log_error() { printf '%s%s %s%s\n' "$C_RED" "$I_ERR" "${1:-}" "$C_RESET" >&2; }
cc_main() {
  uk_banner "cacheclean" "intelligent cache cleaner for devs" "" "$@"
  case " ${*:-} " in
  *" --help "* | *" -h "*)
    cc_usage
    return 0
    ;;
  *" --version "* | *" -V "*)
    printf '_cache_clean %s\n' "$UK_VERSION"
    return 0
    ;;
  esac
  trap cc_cleanup_tmp EXIT
  cc_parse_args "$@" || return $?
  cc_setup_colors
  cc_require_basic_tools || return $?
  cc_detect_os
  cc_root_check || return $?
  cc_setup_box_chars
  cc_setup_tmp || return $?

  [ "$CC_DEBUG" -eq 1 ] && set -x

  cc_discover_plugins

  if [ ${#CC_ACTIVE_PLUGINS[@]} -eq 0 ]; then
    [ "$CC_QUIET" -eq 0 ] && cc_print_env_summary
    cc_log_warn "No supported package managers detected."
    return 0
  fi

  [ "$CC_QUIET" -eq 0 ] && cc_print_env_summary
  if ! cc_run_scans; then
    CC_SCAN_FAILED=1
  fi
  cc_print_report
  if [ "$CC_SCAN_FAILED" -ne 0 ]; then
    cc_log_error "One or more cache scans were incomplete; refusing deletion."
    return 1
  fi
  if [ "$CC_TOTAL_ORPHAN_COUNT" -eq 0 ]; then
    [ "$CC_QUIET" -eq 0 ] && printf '\n%s%s%s %sNo orphaned cache files found. Nothing to clean.%s\n  %sThe cache is within your --older-than threshold.%s\n' \
      "$C_LGREEN" "$I_MAGIC" "$C_RESET" "$C_BOLD$C_LGREEN" "$C_RESET" "$C_DIM" "$C_RESET"
    return 0
  fi
  if cc_prompt_confirm; then
    [ "$CC_QUIET" -eq 0 ] && cc_list_orphans_to_delete
    if cc_prompt_final_confirm; then
      local result
      result="$(cc_perform_deletion)" || {
        cc_log_error "Cache deletion worker failed."
        return 1
      }
      cc_print_final_summary "$result" || return 1
    else
      [ "$CC_QUIET" -eq 0 ] && printf '\n  %s%s%s %sAborted.%s\n' "$C_LRED" "$I_STOP" "$C_RESET" "$C_BOLD" "$C_RESET"
      return 0
    fi
  else
    [ "$CC_QUIET" -eq 0 ] && printf '\n  %s%s%s %sAborted.%s\n' "$C_LRED" "$I_STOP" "$C_RESET" "$C_BOLD" "$C_RESET"
    return 0
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  cc_main "$@"
fi
