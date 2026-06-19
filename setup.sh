#!/usr/bin/env bash
# ==============================================================================
# UtilityKit — Universal Setup & Configuration Installer
# ==============================================================================
# Interactive and remote-ready installer for UtilityKit.
# Can be executed locally or via curl/wget pipeline directly from GitHub.
#
# Usage:
#   bash setup.sh [options]
#   curl -sSL https://raw.githubusercontent.com/ThatOn3Gu7/UtilityKit/main/setup.sh | bash

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Configuration Defaults
# ------------------------------------------------------------------------------
INTERACTIVE=1
LAUNCHER_NAME="utility"
INSTALL_DIR="$HOME/.local/share/utility"
BIN_DIR="$HOME/.local/bin"
ADD_TO_PATH=1
REPO_URL="https://github.com/ThatOn3Gu7/UtilityKit.git"

# Visual setup
setup_visuals() {
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
    C_BRIGHT_CYAN=$'\033[96m'
    C_BRIGHT_WHITE=$'\033[97m'
  else
    C_RESET='' C_BOLD='' C_DIM='' C_INVERSE='' C_RED='' C_GREEN='' C_YELLOW=''
    C_BLUE='' C_MAGENTA='' C_CYAN='' C_WHITE='' C_BRIGHT_RED='' C_BRIGHT_GREEN=''
    C_BRIGHT_YELLOW='' C_BRIGHT_BLUE='' C_BRIGHT_CYAN='' C_BRIGHT_WHITE=''
  fi

  if [[ -t 1 && -z "${NO_UNICODE:-}" ]]; then
    I_SUCCESS="✔"
    I_ERROR="✖"
    I_WARN="⚠"
    I_INFO="ℹ"
    I_WORKING="⚙"
    I_ARROW="❯"
    I_BULLET="●"
    I_TOOL="🔧"
  else
    I_SUCCESS="√"
    I_ERROR="×"
    I_WARN="!!"
    I_INFO="i"
    I_WORKING="*"
    I_ARROW=">"
    I_BULLET="*"
    I_TOOL="tool"
  fi
}

setup_visuals

# ------------------------------------------------------------------------------
# 2. Argument Parsing
# ------------------------------------------------------------------------------
print_usage() {
  cat <<EOF
${C_BOLD}Usage:${C_RESET}
  bash setup.sh [OPTIONS]

${C_BOLD}Interactive Wizard:${C_RESET}
  Run without options (or with interactive prompt) to configure your installation step-by-step.

${C_BOLD}Options:${C_RESET}
  ${C_CYAN}--no-menu${C_RESET}                  Install immediately using defaults or passed flags without prompting.
  ${C_CYAN}--launcher-name <name>${C_RESET}     Set the launcher command name (default: ${C_BOLD}utility${C_RESET}).
  ${C_CYAN}--install-dir <path>${C_RESET}       Set the data/script installation folder (default: ${C_BOLD}~/.local/share/utility${C_RESET}).
  ${C_CYAN}--bin-dir <path>${C_RESET}           Set the executable bin wrapper directory (default: ${C_BOLD}~/.local/bin${C_RESET}).
  ${C_CYAN}--no-path${C_RESET}                  Do not automatically add the bin directory to your shell rc files.
  ${C_CYAN}-h, --help${C_RESET}                 Show this help message and exit.

${C_BOLD}Remote One-Liner Execution:${C_RESET}
  curl -sSL https://raw.githubusercontent.com/ThatOn3Gu7/UtilityKit/main/setup.sh | bash -s -- --no-menu
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-menu) INTERACTIVE=0 ;;
    --launcher-name)
      shift
      [[ $# -gt 0 ]] || { printf "  %s --launcher-name requires an argument.\n" "${C_RED}${I_ERROR}${C_RESET}" >&2; exit 1; }
      LAUNCHER_NAME="$1"
      ;;
    --launcher-name=*) LAUNCHER_NAME="${1#--launcher-name=}" ;;
    --install-dir)
      shift
      [[ $# -gt 0 ]] || { printf "  %s --install-dir requires an argument.\n" "${C_RED}${I_ERROR}${C_RESET}" >&2; exit 1; }
      INSTALL_DIR="$1"
      ;;
    --install-dir=*) INSTALL_DIR="${1#--install-dir=}" ;;
    --bin-dir)
      shift
      [[ $# -gt 0 ]] || { printf "  %s --bin-dir requires an argument.\n" "${C_RED}${I_ERROR}${C_RESET}" >&2; exit 1; }
      BIN_DIR="$1"
      ;;
    --bin-dir=*) BIN_DIR="${1#--bin-dir=}" ;;
    --no-path) ADD_TO_PATH=0 ;;
    -h|--help) print_usage; exit 0 ;;
    *)
      printf "  %s Unknown option '%s'. Run 'bash setup.sh --help' for details.\n" "${C_RED}${I_ERROR}${C_RESET}" "$1" >&2
      exit 1
      ;;
  esac
  shift
done

# Expand tildes if passed from command line
INSTALL_DIR="$(eval printf '%s' "$INSTALL_DIR")"
BIN_DIR="$(eval printf '%s' "$BIN_DIR")"

# ------------------------------------------------------------------------------
# 3. Interactive Wizard Menu
# ------------------------------------------------------------------------------
if [[ "$INTERACTIVE" -eq 1 ]]; then
  clear 2>/dev/null || printf "\n"
  cat <<EOF
${C_BRIGHT_GREEN}
██╗   ██╗████████╗██╗██╗     ██╗████████╗██╗   ██╗██╗  ██╗██╗████████╗
██║   ██║╚══██╔══╝██║██║     ██║╚══██╔══╝╚██╗ ██╔╝██║ ██╔╝██║╚══██╔══╝
██║   ██║   ██║   ██║██║     ██║   ██║    ╚████╔╝ █████╔╝ ██║   ██║   
██║   ██║   ██║   ██║██║     ██║   ██║     ╚██╔╝  ██╔═██╗ ██║   ██║   
╚██████╔╝   ██║   ██║███████╗██║   ██║      ██║   ██║  ██╗██║   ██║   
 ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝   ╚═╝${C_RESET}
EOF
  printf '%s\n' "${C_DIM}======================================================================${C_RESET}"
  printf "  %s Universal Setup & Configuration Wizard %s\n" "${C_BOLD}${C_WHITE}" "${C_RESET}"
  printf '%s\n\n' "${C_DIM}======================================================================${C_RESET}"
  
  printf "  Welcome! Let's get UtilityKit fully configured for your system.\n\n"

  # 1. Launcher Name
  printf "  %s1) Launcher Command Name%s\n" "${C_BOLD}${C_CYAN}" "${C_RESET}"
  printf "     What command would you like to type to launch UtilityKit?\n"
  printf "     [Press Enter to keep default: %s%s%s]: " "${C_BRIGHT_YELLOW}" "$LAUNCHER_NAME" "${C_RESET}"
  read -r input_name
  [[ -n "$input_name" ]] && LAUNCHER_NAME="$input_name"
  printf "\n"

  # 2. Install Directory
  printf "  %s2) Installation Storage Directory%s\n" "${C_BOLD}${C_CYAN}" "${C_RESET}"
  printf "     Where should the scripts and backend files be installed?\n"
  printf "     [Press Enter to keep default: %s%s%s]: " "${C_BRIGHT_YELLOW}" "$INSTALL_DIR" "${C_RESET}"
  read -r input_inst
  if [[ -n "$input_inst" ]]; then
    INSTALL_DIR="$(eval printf '%s' "$input_inst")"
  fi
  printf "\n"

  # 3. Bin Directory
  printf "  %s3) Executable Binary Directory%s\n" "${C_BOLD}${C_CYAN}" "${C_RESET}"
  printf "     Where should the executable shell wrapper be placed?\n"
  printf "     [Press Enter to keep default: %s%s%s]: " "${C_BRIGHT_YELLOW}" "$BIN_DIR" "${C_RESET}"
  read -r input_bin
  if [[ -n "$input_bin" ]]; then
    BIN_DIR="$(eval printf '%s' "$input_bin")"
  fi
  printf "\n"

  # 4. Add to PATH
  printf "  %s4) Shell PATH Configuration%s\n" "${C_BOLD}${C_CYAN}" "${C_RESET}"
  printf "     Would you like to automatically add %s to your PATH in .bashrc/.zshrc?\n" "${C_BOLD}$BIN_DIR${C_RESET}"
  printf "     [Press Enter for Yes (Y/n)]: "
  read -r input_path
  if [[ "$input_path" =~ ^[Nn] ]]; then
    ADD_TO_PATH=0
  fi

  printf "\n%s\n" "${C_DIM}----------------------------------------------------------------------${C_RESET}"
  printf "  %sConfiguration Summary:%s\n" "${C_BOLD}" "${C_RESET}"
  printf "    %s %-18s %s\n" "${I_BULLET}" "Launcher Command:" "${C_BRIGHT_GREEN}$LAUNCHER_NAME${C_RESET}"
  printf "    %s %-18s %s\n" "${I_BULLET}" "Install Folder:" "${C_BRIGHT_BLUE}$INSTALL_DIR${C_RESET}"
  printf "    %s %-18s %s\n" "${I_BULLET}" "Binary Wrapper:" "${C_BRIGHT_CYAN}$BIN_DIR/$LAUNCHER_NAME${C_RESET}"
  printf "    %s %-18s %s\n" "${I_BULLET}" "Add to PATH:" "$( (( ADD_TO_PATH == 1 )) && echo "${C_GREEN}Yes${C_RESET}" || echo "${C_YELLOW}No${C_RESET}" )"
  printf "%s\n\n" "${C_DIM}----------------------------------------------------------------------${C_RESET}"

  printf "  %sPress Enter to begin installation (or Ctrl+C to abort)...%s" "${C_BOLD}" "${C_RESET}"
  read -r
  printf "\n"
fi

# ------------------------------------------------------------------------------
# 4. Execution & File Installation
# ------------------------------------------------------------------------------
printf "  %s Starting installation process...\n" "${C_BRIGHT_YELLOW}${I_WORKING}${C_RESET}"

# A. Determine how we are executed (Remote vs Local Clone)
declare SOURCE_DIR="."
declare TEMP_CLONE=""

# If main.sh is not in our current directory, or if we are executed from a pipe
if [[ ! -f "./main.sh" && ! -f "$(dirname "${BASH_SOURCE[0]}")/main.sh" ]]; then
  printf "  %s Remote execution detected. Downloading live repository from GitHub...\n" "${C_CYAN}${I_INFO}${C_RESET}"
  TEMP_CLONE="$(mktemp -d 2>/dev/null || echo "$HOME/.utilitykit_clone_temp")"
  git clone "$REPO_URL" "$TEMP_CLONE" --depth=1
  SOURCE_DIR="$TEMP_CLONE"
else
  if [[ -f "$(dirname "${BASH_SOURCE[0]}")/main.sh" ]]; then
    SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  else
    SOURCE_DIR="."
  fi
  printf "  %s Local repository copy detected at: %s\n" "${C_CYAN}${I_INFO}${C_RESET}" "${SOURCE_DIR}"
fi

# B. Create Target Directories
printf "  %s Creating installation folders...\n" "${C_CYAN}${I_WORKING}${C_RESET}"
mkdir -p "$INSTALL_DIR"
for sub in _apply_changes _rename_batch _cache_clean _symlink_manager _disk_analyzer; do
  mkdir -p "$INSTALL_DIR/$sub"
done
mkdir -p "$BIN_DIR"

# C. Copy Files to Install Directory
printf "  %s Copying scripts and assets to %s...\n" "${C_CYAN}${I_WORKING}${C_RESET}" "${C_BOLD}$INSTALL_DIR${C_RESET}"

# Copy top-level files
for file in main.sh setup.sh README.md LICENSE CONTRIBUTING.md CHANGES.md; do
  if [[ -f "$SOURCE_DIR/$file" ]]; then
    cp -f "$SOURCE_DIR/$file" "$INSTALL_DIR/"
  fi
done

# Copy subdirectories
for sub in _apply_changes _rename_batch _cache_clean _symlink_manager _disk_analyzer; do
  if [[ -d "$SOURCE_DIR/$sub" ]]; then
    cp -rf "$SOURCE_DIR/$sub/"* "$INSTALL_DIR/$sub/"
  fi
done

# D. Set Executable Permissions
printf "  %s Setting executable permissions...\n" "${C_CYAN}${I_WORKING}${C_RESET}"
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# E. Create Binary Shell Wrapper
wrapper_path="$BIN_DIR/$LAUNCHER_NAME"
printf "  %s Generating shell launcher %s...\n" "${C_BRIGHT_GREEN}${I_TOOL}${C_RESET}" "${C_BOLD}$wrapper_path${C_RESET}"

cat << EOF > "$wrapper_path"
#!/usr/bin/env bash
# Automatically generated UtilityKit Launcher Wrapper
exec "$INSTALL_DIR/main.sh" "\$@"
EOF

chmod +x "$wrapper_path"

# F. Configure Shell Path if Requested
if [[ "$ADD_TO_PATH" -eq 1 ]]; then
  if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
    printf "  %s Shell PATH already includes %s.\n" "${C_GREEN}${I_SUCCESS}${C_RESET}" "$BIN_DIR"
  else
    printf "  %s Adding %s to shell rc files...\n" "${C_CYAN}${I_WORKING}${C_RESET}" "$BIN_DIR"
    
    added=0
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      if [[ -f "$rc" ]]; then
        if ! grep -q "export PATH=.*$BIN_DIR" "$rc"; then
          printf '\n# Added by UtilityKit Installer\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$rc"
          printf "  %s Updated %s\n" "${C_GREEN}${I_SUCCESS}${C_RESET}" "$rc"
          added=1
        fi
      fi
    done

    if [[ "$added" -eq 0 ]]; then
      printf "  %s Could not automatically update your rc files. Please add this line to your shell configuration:\n" "${C_YELLOW}${I_WARN}${C_RESET}"
      printf "       export PATH=\"%s:\$PATH\"\n" "$BIN_DIR"
    fi
  fi
fi

# Clean up temp clone if we created one
if [[ -n "$TEMP_CLONE" && -d "$TEMP_CLONE" ]]; then
  rm -rf "$TEMP_CLONE" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 5. Success Final Report
# ------------------------------------------------------------------------------
printf "\n"
printf '%s\n' "${C_DIM}======================================================================${C_RESET}"
printf "  %s %sSUCCESS! UtilityKit is successfully installed.%s\n" "${C_BRIGHT_GREEN}" "${I_SUCCESS}" "${C_RESET}"
printf '%s\n' "${C_DIM}======================================================================${C_RESET}"
printf "\n"
printf "  %sTo start the interactive dashboard right now, type:%s\n" "${C_BOLD}" "${C_RESET}"
printf "    %s\n\n" "${C_BRIGHT_GREEN}${C_BOLD}$LAUNCHER_NAME${C_RESET}"
printf "  %sOr run a specific utility directly:%s\n" "${C_BOLD}" "${C_RESET}"
printf "    %s rename      %s(Run Batch File Renamer)\n" "${C_BRIGHT_GREEN}$LAUNCHER_NAME${C_RESET}" "${C_DIM}"
printf "    %s cacheclean  %s(Run Intelligent Cache Cleaner)\n" "${C_BRIGHT_GREEN}$LAUNCHER_NAME${C_RESET}" "${C_DIM}"
printf "    %s apply       %s(Run Directory Sync)\n" "${C_BRIGHT_GREEN}$LAUNCHER_NAME${C_RESET}" "${C_DIM}"
printf "    %s symlink     %s(Run Symlink Manager)\n" "${C_BRIGHT_GREEN}$LAUNCHER_NAME${C_RESET}" "${C_DIM}"
printf "    %s disk        %s(Run Disk Space & Directory Analyzer)\n" "${C_BRIGHT_GREEN}$LAUNCHER_NAME${C_RESET}" "${C_DIM}"
printf "\n  (Note: If you added PATH to a new rc file, you may need to open a new terminal session or run 'source ~/.bashrc').\n\n"
