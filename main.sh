#!/usr/bin/env bash
# ==============================================================================
# UtilityKit — Interactive Central Dashboard & Script Interface
# ==============================================================================
# Sources all utility scripts in the repository and provides a beautiful,
# interactive dashboard and command-line entry point.
#
# Design heavily inspired by Gogh palettes, Antigravity status bars, and
# rich Unicode icons. Safe, modular, and Termux/Android/Linux ready.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly UK_VERSION="3.5.0"

# ------------------------------------------------------------------------------
# 1. Colors & Symbols (ANSI / Unicode)
# ------------------------------------------------------------------------------
uk_setup_visuals() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_INVERSE=$'\033[7m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_MAGENTA=$'\033[35m'
    C_CYAN=$'\033[36m'
    C_WHITE=$'\033[37m'
    C_BRIGHT_RED=$'\033[91m'
    C_BRIGHT_GREEN=$'\033[92m'
    C_BRIGHT_YELLOW=$'\033[93m'
    C_BRIGHT_BLUE=$'\033[94m'
    C_BRIGHT_MAGENTA=$'\033[95m'
    C_BRIGHT_CYAN=$'\033[96m'
    C_BRIGHT_WHITE=$'\033[97m'
  else
    C_RESET='' C_BOLD='' C_DIM='' C_INVERSE='' C_RED='' C_GREEN='' C_YELLOW=''
    C_BLUE='' C_MAGENTA='' C_CYAN='' C_WHITE='' C_BRIGHT_RED='' C_BRIGHT_GREEN=''
    C_BRIGHT_YELLOW='' C_BRIGHT_BLUE='' C_BRIGHT_MAGENTA='' C_BRIGHT_CYAN='' C_BRIGHT_WHITE=''
  fi

  if [[ -t 1 && -z "${NO_UNICODE:-}" ]]; then
    I_SUCCESS="✔"
    I_ERROR="✖"
    I_WARN="⚠"
    I_INFO="ℹ"
    I_WORKING="⚙"
    I_THINKING="◆"
    I_READY="●"
    I_TOOL="🔧"
    I_ARROW="❯"
    I_SEP="╱"
    I_BOX_TOP="▀"
    I_BOX_BOT="▄"
  else
    I_SUCCESS="√"
    I_ERROR="×"
    I_WARN="!!"
    I_INFO="i"
    I_WORKING="*"
    I_THINKING=">"
    I_READY="+"
    I_TOOL="tool"
    I_ARROW=">"
    I_SEP="/"
    I_BOX_TOP="-"
    I_BOX_BOT="-"
  fi
}

uk_setup_visuals

# ------------------------------------------------------------------------------
# 2. Source All Sub-Scripts Safely
# ------------------------------------------------------------------------------
source_scripts() {
  local error_count=0

  # Source _apply_changes/_apply_changes.sh
  if [[ -f "$SCRIPT_DIR/_apply_changes/_apply_changes.sh" ]]; then
    source "$SCRIPT_DIR/_apply_changes/_apply_changes.sh"
  else
    printf "%s%s [Warning] Missing _apply_changes/_apply_changes.sh script.%s\n" "$C_YELLOW" "$I_WARN" "$C_RESET" >&2
    error_count=$((error_count + 1))
  fi

  # Source _rename_batch/_rename_batch.sh
  if [[ -f "$SCRIPT_DIR/_rename_batch/_rename_batch.sh" ]]; then
    source "$SCRIPT_DIR/_rename_batch/_rename_batch.sh"
  else
    printf "%s%s [Warning] Missing _rename_batch/_rename_batch.sh script.%s\n" "$C_YELLOW" "$I_WARN" "$C_RESET" >&2
    error_count=$((error_count + 1))
  fi

  # Source _cache_clean/cacheclean.sh
  if [[ -f "$SCRIPT_DIR/_cache_clean/cacheclean.sh" ]]; then
    source "$SCRIPT_DIR/_cache_clean/cacheclean.sh"
  else
    printf "%s%s [Warning] Missing _cache_clean/cacheclean.sh script.%s\n" "$C_YELLOW" "$I_WARN" "$C_RESET" >&2
    error_count=$((error_count + 1))
  fi

  # Source _symlink_manager/_symlink_manager.sh
  if [[ -f "$SCRIPT_DIR/_symlink_manager/_symlink_manager.sh" ]]; then
    source "$SCRIPT_DIR/_symlink_manager/_symlink_manager.sh"
  else
    printf "%s%s [Warning] Missing _symlink_manager/_symlink_manager.sh script.%s\n" "$C_YELLOW" "$I_WARN" "$C_RESET" >&2
    error_count=$((error_count + 1))
  fi

  # Source _disk_analyzer/_disk_analyzer.sh
  if [[ -f "$SCRIPT_DIR/_disk_analyzer/_disk_analyzer.sh" ]]; then
    source "$SCRIPT_DIR/_disk_analyzer/_disk_analyzer.sh"
  else
    printf "%s%s [Warning] Missing _disk_analyzer/_disk_analyzer.sh script.%s\n" "$C_YELLOW" "$I_WARN" "$C_RESET" >&2
    error_count=$((error_count + 1))
  fi
}

source_scripts

# ------------------------------------------------------------------------------
# 3. Helpers & Banners
# ------------------------------------------------------------------------------
print_banner() {
  clear 2>/dev/null || printf "\n"
  cat <<EOF
${C_BRIGHT_CYAN}███████╗████████╗██╗██╗     ██╗████████╗██╗   ██╗██╗  ██╗██╗████████╗
██╔════╝╚══██╔══╝██║██║     ██║╚══██╔══╝╚██╗ ██╔╝██║ ██╔╝██║╚══██╔══╝
███████╗   ██║   ██║██║     ██║   ██║    ╚████╔╝ █████╔╝ ██║   ██║   
╚════██║   ██║   ██║██║     ██║   ██║     ╚██╔╝  ██╔═██╗ ██║   ██║   
███████║   ██║   ██║███████╗██║   ██║      ██║   ██║  ██╗██║   ██║   
╚══════╝   ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝   ╚═╝${C_RESET}
EOF
  printf '%s\n' "${C_DIM}----------------------------------------------------------------------${C_RESET}"
  printf "  %s %sREADY%s   %s %s UtilityKit Central Hub %s Suite %sv%s%s\n" \
         "${C_BRIGHT_GREEN}" "${I_READY}" "${C_RESET}" "${C_DIM}${I_SEP}${C_RESET}" \
         "${C_BOLD}${C_WHITE}" "${C_RESET}${C_DIM}${I_SEP}${C_RESET}" "${C_BRIGHT_BLUE}" "${UK_VERSION}" "${C_RESET}"
  printf '%s\n\n' "${C_DIM}----------------------------------------------------------------------${C_RESET}"
}

# ------------------------------------------------------------------------------
# 4. Interactive Command Wizards
# ------------------------------------------------------------------------------
run_apply_changes_wizard() {
  printf "\n  %s %sDirectory Synchronization (Apply Changes)%s\n\n" "${C_BRIGHT_GREEN}${I_TOOL}" "${C_BOLD}" "${C_RESET}"
  
  printf "  Enter %sSource Directory%s: " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local src
  read -r src
  src="$(eval printf '%s' "$src")" # Expand tilde if typed
  
  printf "  Enter %sTarget Directory%s: " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local dst
  read -r dst
  dst="$(eval printf '%s' "$dst")" # Expand tilde if typed

  printf "  Extra arguments/flags (e.g. %s--apply --mirror%s) [or leave empty for default dry-run]: " "${C_BRIGHT_CYAN}" "${C_RESET}"
  local flags
  read -r flags

  printf "\n  %s Executing: %s _apply_changes/_apply_changes.sh %s %s %s...\n\n" "${C_BRIGHT_YELLOW}${I_WORKING}${C_RESET}" "${C_DIM}" "$flags" "$src" "$dst"
  
  # Run in subshell to safeguard current environment
  (
    eval ac_main $flags "$src" "$dst"
  ) || printf "\n  %s Synchronize operation exited or reported an issue.\n" "${C_RED}${I_ERROR}${C_RESET}"
}

run_rename_batch_wizard() {
  printf "\n  %s %sBatch File Renamer%s\n\n" "${C_BRIGHT_BLUE}${I_TOOL}" "${C_BOLD}" "${C_RESET}"
  
  printf "  Enter %sSource Directory%s to scan: " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local src
  read -r src
  src="$(eval printf '%s' "$src")"

  printf "  Enter %sNew File Extension%s (e.g. txt, md, bak): " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local ext
  read -r ext

  printf "  Enter %sOutput Directory%s (for copy mode) [or leave empty for in-place mode]: " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local out
  read -r out
  out="$(eval printf '%s' "$out")"

  if [[ -n "$out" ]]; then
    printf "\n  %s Executing: %s _rename_batch/_rename_batch.sh %s %s %s...\n\n" "${C_BRIGHT_YELLOW}${I_WORKING}${C_RESET}" "${C_DIM}" "$src" "$ext" "$out"
    ( rb_main "$src" "$ext" "$out" ) || printf "\n  %s Renaming operation exited or reported an issue.\n" "${C_RED}${I_ERROR}${C_RESET}"
  else
    printf "\n  %s Executing: %s _rename_batch/_rename_batch.sh %s %s...\n\n" "${C_BRIGHT_YELLOW}${I_WORKING}${C_RESET}" "${C_DIM}" "$src" "$ext"
    ( rb_main "$src" "$ext" ) || printf "\n  %s Renaming operation exited or reported an issue.\n" "${C_RED}${I_ERROR}${C_RESET}"
  fi
}

run_cache_clean_wizard() {
  printf "\n  %s %sIntelligent Cache Cleaner%s\n\n" "${C_BRIGHT_MAGENTA}${I_TOOL}" "${C_BOLD}" "${C_RESET}"
  
  printf "  Options/flags (e.g. %s-y%s for auto-confirm, %s--older-than 30%s) [or leave empty]: " "${C_BRIGHT_CYAN}" "${C_RESET}" "${C_BRIGHT_CYAN}" "${C_RESET}"
  local flags
  read -r flags

  printf "\n  %s Executing: %s cacheclean.sh %s...\n\n" "${C_BRIGHT_YELLOW}${I_WORKING}${C_RESET}" "${C_DIM}" "$flags"
  (
    eval cc_main $flags
  ) || printf "\n  %s Cache clean operation exited or reported an issue.\n" "${C_RED}${I_ERROR}${C_RESET}"
}

run_symlink_manager_wizard() {
  printf "\n  %s %sSymlink Manager (Dotfiles & Configs)%s\n\n" "${C_BRIGHT_YELLOW}${I_TOOL}" "${C_BOLD}" "${C_RESET}"
  
  printf "  Enter %sSource File or Directory%s: " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local src
  read -r src
  src="$(eval printf '%s' "$src")"

  printf "  Enter %sTarget Link Path%s: " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local dst
  read -r dst
  dst="$(eval printf '%s' "$dst")"

  printf "  Extra arguments/flags (e.g. %s--apply%s) [or leave empty for default dry-run]: " "${C_BRIGHT_CYAN}" "${C_RESET}"
  local flags
  read -r flags

  printf "\n  %s Executing: %s _symlink_manager/_symlink_manager.sh %s %s %s...\n\n" "${C_BRIGHT_YELLOW}${I_WORKING}${C_RESET}" "${C_DIM}" "$flags" "$src" "$dst"
  (
    eval sm_main $flags "$src" "$dst"
  ) || printf "\n  %s Symlink operation exited or reported an issue.\n" "${C_RED}${I_ERROR}${C_RESET}"
}

run_disk_analyzer_wizard() {
  printf "\n  %s %sDisk Space & Directory Analyzer%s\n\n" "${C_BRIGHT_CYAN}${I_TOOL}" "${C_BOLD}" "${C_RESET}"
  
  printf "  Enter %sTarget Directory%s to scan [or leave empty for current dir (.)]: " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local dir
  read -r dir
  dir="$(eval printf '%s' "$dir")"
  [[ -z "$dir" ]] && dir="."

  printf "  Enter %sNumber of Items%s to display [or leave empty for 10]: " "${C_CYAN}${C_BOLD}" "${C_RESET}"
  local count
  read -r count
  [[ -z "$count" ]] && count=10

  printf "\n  %s Executing: %s _disk_analyzer/_disk_analyzer.sh --count %s %s...\n\n" "${C_BRIGHT_YELLOW}${I_WORKING}${C_RESET}" "${C_DIM}" "$count" "$dir"
  (
    da_main --count "$count" "$dir"
  ) || printf "\n  %s Disk analyzer operation exited or reported an issue.\n" "${C_RED}${I_ERROR}${C_RESET}"
}

run_setup_wizard() {
  printf "\n  %s Executing Project Setup & Launcher Configuration...\n\n" "${C_BRIGHT_GREEN}${I_WORKING}${C_RESET}"
  if [[ -f "$SCRIPT_DIR/setup.sh" ]]; then
    bash "$SCRIPT_DIR/setup.sh"
  else
    printf "  %s Missing setup.sh file in script directory.\n" "${C_RED}${I_ERROR}${C_RESET}"
  fi
}

# ------------------------------------------------------------------------------
# 5. Dashboard Menu Loop
# ------------------------------------------------------------------------------
interactive_menu() {
  while true; do
    print_banner
    printf "  Please select a utility from the suite below:\n\n"
    printf "    %s1)%s %s %s↻ Apply Changes%s      (Robust Directory Synchronization)\n" "${C_BOLD}" "${C_RESET}" "${C_BRIGHT_GREEN}" "${C_BOLD}" "${C_RESET}"
    printf "    %s2)%s %s %s✎ Batch Rename%s       (Recursive File Renaming & Copying)\n" "${C_BOLD}" "${C_RESET}" "${C_BRIGHT_BLUE}" "${C_BOLD}" "${C_RESET}"
    printf "    %s3)%s %s %s🗑 Cache Cleaner%s      (Intelligent System Cache Cleanup)\n" "${C_BOLD}" "${C_RESET}" "${C_BRIGHT_MAGENTA}" "${C_BOLD}" "${C_RESET}"
    printf "    %s4)%s %s %s⇢ Symlink Manager%s    (Dotfiles & System Config Management)\n" "${C_BOLD}" "${C_RESET}" "${C_BRIGHT_YELLOW}" "${C_BOLD}" "${C_RESET}"
    printf "    %s5)%s %s %s◆ Disk Analyzer%s      (Storage Inspection & Quick Archiving)\n" "${C_BOLD}" "${C_RESET}" "${C_BRIGHT_CYAN}" "${C_BOLD}" "${C_RESET}"
    printf "    %s6)%s %s %s⚙ Run Setup / Install%s (System Symlink & Path Configuration)\n" "${C_BOLD}" "${C_RESET}" "${C_BRIGHT_WHITE}" "${C_BOLD}" "${C_RESET}"
    printf "    %sq)%s %s %s✖ Quit UtilityKit%s\n\n" "${C_BOLD}" "${C_RESET}" "${C_RED}" "${C_BOLD}" "${C_RESET}"
    
    printf "  %sChoose an option [1-6/q]: %s" "${C_BOLD}${C_CYAN}${I_ARROW} " "${C_RESET}"
    local choice
    read -r choice

    case "$choice" in
      1) run_apply_changes_wizard ;;
      2) run_rename_batch_wizard ;;
      3) run_cache_clean_wizard ;;
      4) run_symlink_manager_wizard ;;
      5) run_disk_analyzer_wizard ;;
      6) run_setup_wizard ;;
      q|Q)
        printf "\n  %s Thank you for using UtilityKit. Goodbye! %s\n\n" "${C_BRIGHT_GREEN}${I_SUCCESS}" "${C_RESET}"
        exit 0
        ;;
      *)
        printf "\n  %s Invalid selection. Please enter a number between 1 and 6, or q to quit.\n" "${C_RED}${I_ERROR}${C_RESET}"
        ;;
    esac

    printf "\n  %sPress Enter to return to the UtilityKit Dashboard...%s" "${C_DIM}" "${C_RESET}"
    read -r
  done
}

# ------------------------------------------------------------------------------
# 6. CLI Entry Point (Direct Command Routing)
# ------------------------------------------------------------------------------
if [[ $# -gt 0 ]]; then
  subcmd="$1"
  shift
  case "$subcmd" in
    apply|apply-changes)
      ( ac_main "$@" )
      ;;
    rename|rename-batch)
      ( rb_main "$@" )
      ;;
    cacheclean|cache-clean)
      ( cc_main "$@" )
      ;;
    symlink|symlink-manager)
      ( sm_main "$@" )
      ;;
    disk|disk-analyzer)
      ( da_main "$@" )
      ;;
    setup|install)
      bash "$SCRIPT_DIR/setup.sh" "$@"
      ;;
    help|--help|-h)
      print_banner
      cat <<EOF
${C_BOLD}Direct CLI Usage:${C_RESET}
  ./main.sh <command> [arguments]

${C_BOLD}Available Commands:${C_RESET}
  ${C_CYAN}apply${C_RESET}       Run Apply Changes (Directory Sync)
  ${C_CYAN}rename${C_RESET}      Run Batch File Renamer
  ${C_CYAN}cacheclean${C_RESET}  Run Intelligent Cache Cleaner
  ${C_CYAN}symlink${C_RESET}     Run Symlink Manager
  ${C_CYAN}disk${C_RESET}        Run Disk Space & Directory Analyzer
  ${C_CYAN}setup${C_RESET}       Run System Setup & Configuration
  ${C_CYAN}help${C_RESET}        Show this help message

Run any command with ${C_BOLD}--help${C_RESET} to see detailed options (e.g. ${C_DIM}./main.sh rename --help${C_RESET}).
If you run ${C_BOLD}./main.sh${C_RESET} without arguments, it opens the interactive dashboard.
EOF
      ;;
    *)
      printf "  %s Unknown command '%s'. Run './main.sh help' for a list of available commands.\n" "${C_RED}${I_ERROR}${C_RESET}" "$subcmd" >&2
      exit 1
      ;;
  esac
else
  # If run without arguments, launch the interactive dashboard
  interactive_menu
fi
