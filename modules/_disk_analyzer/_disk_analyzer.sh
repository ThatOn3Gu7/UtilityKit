#!/usr/bin/env bash
DA_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DA_SCRIPT_DIR/../../lib/uk_common.sh"

DA_COUNT=10

DA_EXCLUDE_REGEX='/(\.git|\.hg|\.svn)$'

da_setup_colors() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_CYAN=$'\033[36m'
    C_MAGENTA=$'\033[35m'
  else
    C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN='' C_MAGENTA=''
  fi

  if [[ -t 1 && -z "${NO_UNICODE:-}" ]]; then
    I_SUCCESS="✔"
    I_INFO="ℹ"
    I_WARN="⚠"
    I_ERROR="✘"
    I_ARROW="❯"
    I_BULLET="●"
    I_DISK="◆"
  else
    I_SUCCESS="√"
    I_INFO="i"
    I_WARN="!!"
    I_ERROR="×"
    I_ARROW=">"
    I_BULLET="*"
    I_DISK="O"
  fi
}
da_fake_progress() {
  local pid="${1:-}" rc=0
  local width=28
  local pct=0
  local fill empty bar bar_fill bar_empty

  # Choose characters
  local ch_fill ch_empty
  if [[ -t 1 && -z "${NO_UNICODE:-}" ]]; then
    ch_fill='█'
    ch_empty='░'
  else
    ch_fill='#'
    ch_empty='-'
  fi

  local color_bar color_done
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    color_bar="${C_CYAN}"
    color_done="${C_GREEN}"
  else
    color_bar=''
    color_done=''
  fi

  printf '\n'

  while kill -0 "$pid" 2>/dev/null; do
    # Acceleration curve
    if ((pct < 50)); then
      increment=3
    elif ((pct < 75)); then
      increment=2
    elif ((pct < 85)); then
      increment=1
    elif ((pct < 99)); then
      increment=1
    else
      increment=0
    fi

    pct=$((pct + increment))
    ((pct > 99)) && pct=99

    fill=$((pct * width / 100))
    empty=$((width - fill))

    # Build the bar without tr
    printf -v bar_fill '%*s' "$fill" ''
    printf -v bar_empty '%*s' "$empty" ''
    bar_fill="${bar_fill// /$ch_fill}"
    bar_empty="${bar_empty// /$ch_empty}"
    bar="${color_bar}${bar_fill}${C_DIM}${bar_empty}${C_RESET}"

    printf '\r  %s%s%s  %s%3d%%%s  Scanning...' \
      "${C_BOLD}" "${I_BULLET}" "${C_RESET}" \
      "${C_BOLD}" "$pct" "${C_RESET}"

    printf ' [%s]' "$bar"

    # Check again before sleeping so we exit immediately when du finishes,
    # rather than burning up to 0.55s of wall time on the final tick.
    kill -0 "$pid" 2>/dev/null || break

    # Pacing
    if ((pct < 50)); then
      sleep 0.08
    elif ((pct < 85)); then
      sleep 0.18
    else
      sleep 0.55
    fi
  done

  wait "$pid" || rc=$?

  # Final 100% bar
  printf -v bar_fill '%*s' "$width" ''
  bar_fill="${bar_fill// /$ch_fill}"
  bar="${color_done}${bar_fill}${C_RESET}"

  printf '\r  %s%s%s  %s%3d%%%s  ' \
    "${C_GREEN}" "${I_SUCCESS}" "${C_RESET}" \
    "${C_BOLD}" 100 "${C_RESET}"
  printf '[%s]' "$bar"
  if ((rc == 0)); then
    printf '  %s%sScan complete.%s\n\n' "${C_GREEN}" "${C_BOLD}" "${C_RESET}"
  else
    printf '  %s%sScan failed (exit %d).%s\n\n' "${C_RED}" "${C_BOLD}" "$rc" "${C_RESET}" >&2
  fi
  return "$rc"
}
da_scan() {
  local mode="${1:-}" target_dir="${2:-}" output="${3:-}"
  local raw="${output}.raw" sorted="${output}.sorted"
  if [[ "$mode" == "gnu" ]]; then
    du -ah --max-depth=1 "$target_dir" >"$raw" || return 1
  else
    du -ah -d 1 "$target_dir" >"$raw" || return 1
  fi
  awk -v re="$DA_EXCLUDE_REGEX" '$0 !~ re' "$raw" >"${raw}.filtered" || return 1
  sort -hr "${raw}.filtered" >"$sorted" || return 1
  head -n $((DA_COUNT + 1)) "$sorted" >"$output" || return 1
  rm -f "$raw" "${raw}.filtered" "$sorted"
}
da_usage() {
  cat <<EOF
${C_BOLD}Usage:${C_RESET}
  _disk_analyzer.sh [OPTIONS] [DIRECTORY]

${C_BOLD}Options:${C_RESET}
  ${C_CYAN}-n, --count <num>${C_RESET}    Number of top items to display (default: 10).
  ${C_CYAN}-h, --help${C_RESET}           Show this help message and exit.
EOF
}
da_main() {
  uk_banner "disk-analyzer" "Largest-items disk usage explorer with optional archiving" "" "$@"
  da_setup_colors
  DA_COUNT=10

  local target_dir="."
  local positional=()

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    -n | --count)
      shift
      [[ $# -gt 0 && "${1:-}" =~ ^[0-9]+$ ]] || {
        printf "%s%s --count requires a positive number.%s\n" "$C_RED" "$I_ERROR" "$C_RESET" >&2
        return 1
      }
      DA_COUNT="${1:-}"
      ;;
    --count=*)
      local val="${1#--count=}"
      [[ "$val" =~ ^[0-9]+$ ]] || {
        printf "%s%s --count requires a positive number.%s\n" "$C_RED" "$I_ERROR" "$C_RESET" >&2
        return 1
      }
      DA_COUNT="$val"
      ;;
    -h | --help)
      da_usage
      return 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        positional+=("${1:-}")
        shift
      done
      break
      ;;
    --*)
      printf "%s%s Unknown option: %s%s\n" "$C_RED" "$I_ERROR" "${1:-}" "$C_RESET" >&2
      return 1
      ;;
    *) positional+=("${1:-}") ;;
    esac
    shift
  done

  if [[ ${#positional[@]} -gt 0 ]]; then
    target_dir="${positional[0]}"
  fi

  if [[ ! -d "$target_dir" ]]; then
    printf "\n  %s %sTarget is not a valid directory:%s %s\n\n" "$C_RED" "$I_ERROR" "$C_RESET" "$target_dir" >&2
    return 1
  fi

  printf "\n  %s %sDisk Space Analyzer%s\n\n" "${C_CYAN}${I_DISK}" "${C_BOLD}" "${C_RESET}"
  local target_display resolve_error=''
  if ! target_display="$(realpath "$target_dir" 2>&1)"; then
    resolve_error="$target_display"
    target_display="$target_dir"
    printf "  %s %sCould not canonicalize target:%s %s\n" "$C_YELLOW" "$I_WARN" "$C_RESET" "$resolve_error" >&2
  fi
  printf "  %s Target: %s\n" "${C_BLUE}${I_ARROW}${C_RESET}" "${C_BOLD}${target_display}${C_RESET}"
  printf "  %s Scanning largest %d visible items (metadata folders like .git are skipped)...\n" "${C_YELLOW}${I_INFO}${C_RESET}" "$DA_COUNT"

  # Write du output to a temp file in the background so we can show a progress bar
  local _da_tmp _da_err _da_mode='bsd' probe_error=''
  _da_tmp=$(mktemp) || {
    printf "  %s %sUnable to create disk-scan temporary file.%s\n" "$C_RED" "$I_ERROR" "$C_RESET" >&2
    return 1
  }
  _da_err="${_da_tmp}.err"

  # Use -d 1 as a fallback for BSD/macOS where --max-depth is not supported.
  if probe_error="$(du --version 2>&1 >/dev/null)"; then
    _da_mode='gnu'
  elif [[ -n "$probe_error" ]]; then
    printf "  %s %sGNU du unavailable; using BSD-compatible -d mode:%s %s\n" "$C_YELLOW" "$I_INFO" "$C_RESET" "$probe_error" >&2
  fi
  da_scan "$_da_mode" "$target_dir" "$_da_tmp" 2>"$_da_err" &
  local _da_bg_pid=$! scan_status=0

  # Only show the progress bar when output is a TTY
  if [[ -t 1 ]]; then
    da_fake_progress "$_da_bg_pid" || scan_status=$?
  else
    wait "$_da_bg_pid" || scan_status=$?
  fi

  if [[ -s "$_da_err" ]]; then
    cat "$_da_err" >&2 || scan_status=1
  fi
  if ((scan_status != 0)); then
    if ! rm -f "$_da_tmp" "$_da_err" "${_da_tmp}.raw" "${_da_tmp}.raw.filtered" "${_da_tmp}.sorted"; then
      printf "  %s %sUnable to remove failed disk-scan temporary files.%s\n" "$C_YELLOW" "$I_WARN" "$C_RESET" >&2
    fi
    printf "  %s %sDisk scan failed; no partial results will be shown.%s\n" "$C_RED" "$I_ERROR" "$C_RESET" >&2
    return "$scan_status"
  fi

  local items=()
  while IFS= read -r line; do
    items+=("$line")
  done <"$_da_tmp"
  rm -f "$_da_tmp" "$_da_err" || {
    printf "  %s %sUnable to remove disk-scan temporary files.%s\n" "$C_RED" "$I_ERROR" "$C_RESET" >&2
    return 1
  }

  if [[ ${#items[@]} -eq 0 ]]; then
    printf "  %s No items found or permission denied.\n\n" "${C_YELLOW}${I_WARN}${C_RESET}"
    return 0
  fi

  printf "  %s %-12s %s\n" "${C_BOLD}" "Size" "Path${C_RESET}"
  printf "  %s%s\n" "${C_DIM}" "------------------------------------------------------------${C_RESET}"

  local item_idx=0
  local item_paths=()

  for line in "${items[@]}"; do
    local size path
    read -r size path <<< "$line"

    if [[ "$path" == "$target_dir" || "$path" == "." ]]; then
      printf "  %s %-12s %s (Total)%s\n" "${C_GREEN}${I_BULLET}" "${size}" "${path}" "${C_RESET}"
    else
      item_idx=$((item_idx + 1))
      item_paths+=("$path")
      printf "  %s%2d)%s %-12s %s\n" "${C_CYAN}" "$item_idx" "${C_RESET}" "${size}" "${path}"
    fi
  done

  if [[ ! -t 0 ]]; then
    return 0
  fi

  printf "\n  %sCreate a compressed archive (.tar.gz) of one of the items above? [number or 0]: %s" "${C_BOLD}" "${C_RESET}"
  local sel
  read -r sel

  if [[ "$sel" =~ ^[0-9]+$ ]] && ((sel >= 1 && sel <= ${#item_paths[@]})); then
    local chosen="${item_paths[$((sel - 1))]}"
    local arch_name
    arch_name="$(basename "$chosen")_$(date '+%Y%m%d_%H%M%S').tar.gz"
    printf "\n  %s Creating archive %s for %s...\n" "${C_CYAN}${I_INFO}${C_RESET}" "${C_BOLD}$arch_name${C_RESET}" "$chosen"
    if tar -czf "$arch_name" -C "$(dirname "$chosen")" "$(basename "$chosen")"; then
      printf "  %s Archive successfully created at: %s\n\n" "${C_GREEN}${I_SUCCESS}${C_RESET}" "${C_BOLD}$arch_name${C_RESET}"
    else
      printf "  %s Failed to create archive.\n\n" "${C_RED}${I_ERROR}${C_RESET}" >&2
      return 1
    fi
  else
    printf "\n  %s Done.\n\n" "${C_GREEN}${I_SUCCESS}${C_RESET}"
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  da_main "$@"
fi
