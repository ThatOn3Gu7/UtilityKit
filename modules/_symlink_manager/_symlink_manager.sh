#!/usr/bin/env bash
SM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SM_SCRIPT_DIR/../../lib/uk_common.sh"

SM_VERSION="2.0.2"
SM_MODE="dry-run"
SM_BACKUP_DIR=""
SM_YES=0

# Colors & Symbols
sm_setup_colors() {
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

  # Unicode symbols with plain fallback
  if [[ -t 1 && -z "${NO_UNICODE:-}" ]]; then
    I_SUCCESS="✔"
    I_INFO="ℹ"
    I_WARN="⚠"
    I_ERROR="✘"
    I_ARROW="❯"
    I_LINK="⇢"
    I_BACKUP="⟳"
  else
    I_SUCCESS="√"
    I_INFO="i"
    I_WARN="!!"
    I_ERROR="×"
    I_ARROW=">"
    I_LINK="->"
    I_BACKUP="B"
  fi
}
sm_usage() {
  cat <<EOF
${C_BOLD}Usage:${C_RESET}
  _symlink_manager.sh [OPTIONS] <source_file_or_dir> <target_link_path>

${C_BOLD}Description:${C_RESET}
  Safely creates a symbolic link at <target_link_path> pointing to <source_file_or_dir>.
  If a file, directory, or symlink already exists at the target, it will be automatically
  backed up before creating the new link.

${C_BOLD}Options:${C_RESET}
  ${C_CYAN}--apply${C_RESET}              Actually create symlinks and backups (default is dry-run).
  ${C_CYAN}--backup-dir <dir>${C_RESET}   Specify a custom directory for storing backups.
  ${C_CYAN}-y, --yes${C_RESET}            Skip interactive confirmation.
  ${C_CYAN}-h, --help${C_RESET}           Show this help message and exit.

${C_BOLD}Examples:${C_RESET}
  # Dry-run test linking dotfiles:
  bash _symlink_manager.sh ~/.dotfiles/.bashrc ~/.bashrc

  # Apply link with confirmation:
  bash _symlink_manager.sh --apply ~/.dotfiles/.nvim ~/.config/nvim
EOF
}
sm_main() {
  uk_banner "symlink-manager" "Transactional symlink creator with backup of existing targets" "" "$@"
  sm_setup_colors
  SM_MODE="dry-run"
  SM_BACKUP_DIR=""
  SM_YES=0

  local positional=()
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --apply) SM_MODE="apply" ;;
    --backup-dir)
      shift
      [[ $# -gt 0 ]] || {
        printf "%s%s --backup-dir requires a directory argument.%s\n" "$C_RED" "$I_ERROR" "$C_RESET" >&2
        return 1
      }
      SM_BACKUP_DIR="${1:-}"
      ;;
    --backup-dir=*) SM_BACKUP_DIR="${1#--backup-dir=}" ;;
    -y | --yes) SM_YES=1 ;;
    -h | --help)
      sm_usage
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

  if [[ ${#positional[@]} -ne 2 ]]; then
    sm_usage >&2
    return 2
  fi

  local src_raw="${positional[0]}"
  local dst_raw="${positional[1]}"

  # Resolve absolute source path
  local src
  if ! src="$(realpath "$src_raw" 2>/dev/null)"; then
    src="$src_raw"
  fi

  printf "\n  %s %sSymlink Manager (%s)%s\n\n" "${C_CYAN}${I_LINK}" "${C_BOLD}" "${SM_MODE^^}" "${C_RESET}"

  if [[ ! -e "$src" ]]; then
    printf "  %s %sSource does not exist:%s %s\n\n" "$C_RED" "$I_ERROR" "$C_RESET" "$src" >&2
    return 1
  fi

  # Resolve target path
  local dst
  if [[ "${dst_raw}" == */ || -d "${dst_raw}" && ! -L "${dst_raw}" ]]; then
    dst="${dst_raw%/}/$(basename "$src")"
  else
    dst="${dst_raw}"
  fi

  local dst_dir
  dst_dir="$(dirname "$dst")"

  printf "  %s Source: %s\n" "${C_BLUE}${I_ARROW}${C_RESET}" "${C_BOLD}$src${C_RESET}"
  printf "  %s Target: %s\n\n" "${C_BLUE}${I_ARROW}${C_RESET}" "${C_BOLD}$dst${C_RESET}"

  # Check what currently exists at target
  local action_needed="create"
  local existing_type="none"

  if [[ -L "$dst" ]]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$src" ]]; then
      printf "  %s Target symlink already points to source correctly. Nothing to do.\n\n" "${C_GREEN}${I_SUCCESS}${C_RESET}"
      return 0
    else
      existing_type="symlink pointing to $current_target"
      action_needed="replace"
    fi
  elif [[ -e "$dst" ]]; then
    if [[ -d "$dst" ]]; then
      existing_type="directory"
    else
      existing_type="file"
    fi
    action_needed="replace"
  fi

  if [[ "$action_needed" == "replace" ]]; then
    printf "  %s Conflict detected: Target exists as a %s.\n" "${C_YELLOW}${I_WARN}${C_RESET}" "${C_BOLD}$existing_type${C_RESET}"
  else
    printf "  %s No conflict: Target path is available.\n" "${C_GREEN}${I_SUCCESS}${C_RESET}"
  fi

  if [[ "$SM_MODE" == "dry-run" ]]; then
    printf "\n  %s Dry-run Mode: Run with %s--apply%s to perform this operation.\n\n" "${C_YELLOW}${I_INFO}${C_RESET}" "${C_BOLD}${C_CYAN}" "${C_RESET}"
    return 0
  fi

  if [[ "$SM_YES" -eq 0 ]]; then
    printf "\n  %sProceed with symlink creation? [y/N]: %s" "${C_BOLD}" "${C_RESET}"
    local response
    read -r response
    if [[ ! "$response" =~ ^[Yy] ]]; then
      printf "\n  %s Operation aborted by user.\n\n" "${C_RED}${I_ERROR}${C_RESET}"
      return 0
    fi
  fi

  printf "\n"

  # Ensure destination directory exists
  if [[ ! -d "$dst_dir" ]]; then
    printf "  %s Creating parent directory: %s\n" "${C_CYAN}⚙${C_RESET}" "$dst_dir"
    mkdir -p "$dst_dir"
  fi

  # Handle backup if needed
  if [[ "$action_needed" == "replace" ]]; then
    local timestamp
    timestamp="$(date '+%Y%m%d_%H%M%S')"
    local bak_path
    if [[ -n "$SM_BACKUP_DIR" ]]; then
      mkdir -p "$SM_BACKUP_DIR"
      bak_path="${SM_BACKUP_DIR}/$(basename "$dst").$timestamp.bak"
    else
      bak_path="${dst}.$timestamp.bak"
    fi

    printf "  %s Backing up existing target to: %s\n" "${C_MAGENTA}${I_BACKUP}${C_RESET}" "${C_DIM}$bak_path${C_RESET}"
    mv "$dst" "$bak_path"
  fi

  # Create symlink
  printf "  %s Creating symbolic link...\n" "${C_CYAN}⚙${C_RESET}"
  ln -s "$src" "$dst"

  printf "\n  %s Symbolic link successfully created!\n\n" "${C_GREEN}${C_BOLD}${I_SUCCESS}${C_RESET}"
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sm_main "$@"
fi
