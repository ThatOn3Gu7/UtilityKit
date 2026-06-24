#!/usr/bin/env bash
#
# _disk_analyzer.sh — Disk Space & Directory Size Analyzer with Quick Archiving


DA_VERSION="1.1.0"
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
  da_setup_colors
  DA_COUNT=10

  local target_dir="."
  local positional=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--count)
        shift
        [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]] || { printf "%s%s --count requires a positive number.%s\n" "$C_RED" "$I_ERROR" "$C_RESET" >&2; return 1; }
        DA_COUNT="$1"
        ;;
      --count=*)
        local val="${1#--count=}"
        [[ "$val" =~ ^[0-9]+$ ]] || { printf "%s%s --count requires a positive number.%s\n" "$C_RED" "$I_ERROR" "$C_RESET" >&2; return 1; }
        DA_COUNT="$val"
        ;;
      -h|--help) da_usage; return 0 ;;
      --) shift; while [[ $# -gt 0 ]]; do positional+=("$1"); shift; done; break ;;
      --*) printf "%s%s Unknown option: %s%s\n" "$C_RED" "$I_ERROR" "$1" "$C_RESET" >&2; return 1 ;;
      *) positional+=("$1") ;;
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
  printf "  %s Target: %s\n" "${C_BLUE}${I_ARROW}${C_RESET}" "${C_BOLD}$(realpath "$target_dir" 2>/dev/null || echo "$target_dir")${C_RESET}"
  printf "  %s Scanning largest %d visible items (metadata folders like .git are skipped)...\n\n" "${C_YELLOW}${I_INFO}${C_RESET}" "$DA_COUNT"

  local items=()
  while IFS= read -r line; do
    items+=("$line")
  done < <(du -ah --max-depth=1 "$target_dir" 2>/dev/null | grep -Ev "$DA_EXCLUDE_REGEX" | sort -hr | head -n $((DA_COUNT + 1)) || true)

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
    size="$(printf '%s' "$line" | awk '{print $1}')"
    path="$(printf '%s' "$line" | awk '{$1=""; print $0}' | sed 's/^ *//')"

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

  if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#item_paths[@]} )); then
    local chosen="${item_paths[$((sel - 1))]}"
    local arch_name
    arch_name="$(basename "$chosen")_$(date '+%Y%m%d_%H%M%S').tar.gz"
    printf "\n  %s Creating archive %s for %s...\n" "${C_CYAN}${I_INFO}${C_RESET}" "${C_BOLD}$arch_name${C_RESET}" "$chosen"
    if tar -czf "$arch_name" -C "$(dirname "$chosen")" "$(basename "$chosen")"; then
      printf "  %s Archive successfully created at: %s\n\n" "${C_GREEN}${I_SUCCESS}${C_RESET}" "${C_BOLD}$arch_name${C_RESET}"
    else
      printf "  %s Failed to create archive.\n\n" "${C_RED}${I_ERROR}${C_RESET}"
    fi
  else
    printf "\n  %s Done.\n\n" "${C_GREEN}${I_SUCCESS}${C_RESET}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  da_main "$@"
fi
