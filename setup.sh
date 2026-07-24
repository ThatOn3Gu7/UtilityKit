#!/usr/bin/env bash
set -euo pipefail

readonly SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SETUP_DIR/lib/uk_common.sh"

INTERACTIVE=1
LAUNCHER_NAME='utility'
INSTALL_DIR="$HOME/.local/share/utility"
BIN_DIR="$HOME/.local/bin"
ADD_TO_PATH=1
REPO_URL='https://github.com/Thaton3gu7/UtilityKit.git'

usage() {
printf '\n%sUsage: %sbash%s setup.sh %s[--no-menu] [--launcher-name NAME] [--install-dir DIR] [--bin-dir DIR] [--no-path]%s\n' "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
}
setup_expand_path() {
  local input="${1:-}"
  if [[ "$input" == ~* ]]; then
    printf '%s\n' "${input/#\~/$HOME}"
  else
    printf '%s\n' "$input"
  fi
}

setup_validate_launcher() {
  [[ "${1:-}" =~ ^[A-Za-z0-9._-]+$ ]] || {
    uk_error "Invalid launcher name: ${1:-}. Use letters, numbers, dot, underscore, dash."
    exit 1
  }
}

# ── Non-interactive progress visualization ──────────────────────────
# When --no-menu is used, nothing else prints step-by-step feedback, so we
# show a small numbered step tracker plus a spinner for longer-running
# operations (cloning, copying). Respects NO_COLOR / NO_UNICODE like the
# rest of the suite, and is skipped entirely in interactive mode since the
# uk_prompt/uk_header flow already gives the user feedback there.
SETUP_TOTAL_STEPS=8
SETUP_STEP_NUM=0

setup_step() {
  ((INTERACTIVE == 1)) && return 0
  SETUP_STEP_NUM=$((SETUP_STEP_NUM + 1))
  printf '\n  %s%s%s %s[%d/%d]%s %s%s%s\n' \
    "$UK_C_YELLOW" "$UK_I_CLAUDE" "$UK_C_RESET" \
    "$UK_C_BOLD$UK_C_CYAN" "$SETUP_STEP_NUM" "$SETUP_TOTAL_STEPS" "$UK_C_RESET" \
    "$UK_C_BOLD" "$1" "$UK_C_RESET"
}

setup_detail() {
  ((INTERACTIVE == 1)) && return 0
  printf '   %s%s %s%s\n' "$UK_C_DIM" "$UK_I_ARROW" "$1" "$UK_C_RESET"
}

# Runs "$@" in the background and shows the canonical uk_spinner (which
# degrades to ASCII frames under NO_UNICODE and a static "label... " on
# non-tty stdout) until it finishes. Preserves the command's exit status.
setup_run_with_spinner() {
  ((INTERACTIVE == 1)) && {
    "$@"
    return $?
  }

  local label="$1"
  shift
  local logfile
  logfile="$(mktemp)"

  "$@" >"$logfile" 2>&1 &
  local pid=$!

  local status=0
  uk_spinner "$pid" "$label" || status=$?

  if ((status == 0)); then
    printf '   %s%s%s %s\n' "$UK_C_GREEN" "$UK_I_OK" "$UK_C_RESET" "$label"
  else
    printf '   %s%s%s %s %s(failed, see below)%s\n' "$UK_C_RED" "$UK_I_ERR" "$UK_C_RESET" "$label" "$UK_C_DIM" "$UK_C_RESET"
    cat "$logfile" >&2
  fi
  rm -f "$logfile"
  return "$status"
}
while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-menu) INTERACTIVE=0 ;;
  --launcher-name)
    shift
    LAUNCHER_NAME="${1:-utility}"
    ;;
  --install-dir)
    shift
    INSTALL_DIR="${1:-$INSTALL_DIR}"
    ;;
  --bin-dir)
    shift
    BIN_DIR="${1:-$BIN_DIR}"
    ;;
  --no-path) ADD_TO_PATH=0 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    printf '%sUnknown option: %s%s\n' "$UK_C_RED" "$1" "$UK_C_RESET" >&2
    exit 1
    ;;
  esac
  shift
done

INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
BIN_DIR="${BIN_DIR/#\~/$HOME}"

if ((INTERACTIVE == 0)); then
  uk_header 'UtilityKit Setup' 'Non-interactive install (--no-menu)'
  setup_step 'Resolved configuration'
  setup_detail "Launcher name : $LAUNCHER_NAME"
  setup_detail "Install dir   : $INSTALL_DIR"
  setup_detail "Bin dir       : $BIN_DIR"
  setup_detail "Add to PATH   : $([[ $ADD_TO_PATH -eq 1 ]] && echo yes || echo no)"
  printf '  %s···%s\n' "$UK_C_DIM" "$UK_C_RESET"
fi

if ((INTERACTIVE == 1)); then
  uk_header 'UtilityKit Setup' 'Install the suite and generate a launcher command'
  LAUNCHER_NAME="$(uk_prompt 'Enter the launcher command name' "$LAUNCHER_NAME" 'utility' 'This is the command you will type later to launch UtilityKit.')"
  INSTALL_DIR="$(setup_expand_path "$(uk_prompt 'Enter installation directory for scripts and docs' "$INSTALL_DIR" '~/.local/share/utility' 'All UtilityKit modules will be copied here.')")"
  BIN_DIR="$(setup_expand_path "$(uk_prompt 'Enter binary directory for the launcher wrapper' "$BIN_DIR" '~/.local/bin' 'The generated launcher script will be written here.')")"
  if uk_confirm "Add $BIN_DIR to your shell PATH automatically?" 'Y'; then
    ADD_TO_PATH=1
  else
    ADD_TO_PATH=0
  fi
fi

setup_validate_launcher "$LAUNCHER_NAME"

SOURCE_DIR='.'
TEMP_CLONE=''
setup_step 'Locating source files'
if [[ ! -f "./main.sh" && ! -f "$SETUP_DIR/main.sh" ]]; then
  setup_detail "No local main.sh found — cloning $REPO_URL"
  uk_has_cmd git || {
    uk_error 'git is required to clone UtilityKit when setup.sh is not run from a full checkout.'
    exit 1
  }
  TEMP_CLONE="$(mktemp -d)"
  setup_run_with_spinner "Cloning UtilityKit repository" git clone --depth=1 --quiet "$REPO_URL" "$TEMP_CLONE"
  SOURCE_DIR="$TEMP_CLONE"
else
  SOURCE_DIR="$SETUP_DIR"
  setup_detail "Using local checkout: $SOURCE_DIR"
fi

setup_step 'Preparing install and bin directories'
setup_detail "mkdir -p $INSTALL_DIR"
setup_detail "mkdir -p $BIN_DIR"
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

setup_step 'Copying tool directories and shared files'
setup_copy_dirs() {
  while IFS= read -r dir_path; do
    [[ -n "$dir_path" ]] || continue
    dir="$(basename "$dir_path")"
    if [[ "$dir" == _* ]]; then
      # Tool directory — preserve the modules/ nesting main.sh expects.
      dest="$INSTALL_DIR/modules/$dir"
    else
      dest="$INSTALL_DIR/$dir"
    fi
    rm -rf "$dest"
    mkdir -p "$dest"
    cp -a "$dir_path/." "$dest/"
  done < <({
    find "$SOURCE_DIR/modules" -maxdepth 1 -mindepth 1 -type d -name '_*' 2>/dev/null | sort
    for d in lib docs tests scripts completions man; do [[ -d "$SOURCE_DIR/$d" ]] && echo "$SOURCE_DIR/$d"; done
  })

  for file in main.sh setup.sh README.md CHANGES.md changes.md CONTRIBUTING.md LICENSE; do
    [[ -f "$SOURCE_DIR/$file" ]] && cp -f "$SOURCE_DIR/$file" "$INSTALL_DIR/"
  done
  find "$INSTALL_DIR" -type f -name '*.sh' -exec chmod +x {} \;
}
if ((INTERACTIVE == 0)); then
  dir_count=$({
    find "$SOURCE_DIR/modules" -maxdepth 1 -mindepth 1 -type d -name '_*' 2>/dev/null
    for d in lib docs tests scripts completions man; do [[ -d "$SOURCE_DIR/$d" ]] && echo "$SOURCE_DIR/$d"; done
  } | wc -l | tr -d ' ')
  setup_detail "Copying $dir_count tool/support directories into $INSTALL_DIR"
  setup_run_with_spinner "Copying files" setup_copy_dirs
else
  setup_copy_dirs
fi

setup_step 'Generating launcher wrapper'
setup_detail "Writing $BIN_DIR/$LAUNCHER_NAME"
cat >"$BIN_DIR/$LAUNCHER_NAME" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/main.sh" "\$@"
EOF
chmod +x "$BIN_DIR/$LAUNCHER_NAME"
setup_detail "Marked executable (chmod +x)"

setup_step 'Configuring shell PATH'
if ((ADD_TO_PATH == 1)); then
  path_line='export PATH="'"$BIN_DIR"':$PATH"'
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    if ! grep -Fq "$path_line" "$rc" 2>/dev/null; then
      printf '\n# Added by UtilityKit\n%s\n' "$path_line" >>"$rc"
      setup_detail "Appended PATH export to $rc"
    else
      setup_detail "$rc already references $BIN_DIR — skipped"
    fi
  done
  # Also handle ZDOTDIR if it differs from HOME
  if [[ -n "${ZDOTDIR:-}" && "$ZDOTDIR" != "$HOME" && -f "$ZDOTDIR/.zshrc" ]]; then
    rc="$ZDOTDIR/.zshrc"
    if ! grep -Fq "$path_line" "$rc" 2>/dev/null; then
      printf '\n# Added by UtilityKit\n%s\n' "$path_line" >>"$rc"
      setup_detail "Appended PATH export to $rc"
    else
      setup_detail "$rc already references $BIN_DIR — skipped"
    fi
  fi
else
  setup_detail 'Skipped (--no-path or declined)'
fi

setup_step 'Installing shell tab-completions'
# The generated completion files register the default `utility` name and
# `main.sh`; a custom launcher name is picked up via UK_COMPLETE_CMD, which we
# export on the same rc line. Idempotent: matches on the source path, so
# re-running setup (even with a different launcher name) rewrites in place.
if [[ -f "$INSTALL_DIR/completions/utility.bash" ]]; then
  bash_comp_line="[[ -f \"$INSTALL_DIR/completions/utility.bash\" ]] && UK_COMPLETE_CMD='$LAUNCHER_NAME' source \"$INSTALL_DIR/completions/utility.bash\""
  zsh_comp_line="[[ -f \"$INSTALL_DIR/completions/utility.zsh\" ]] && UK_COMPLETE_CMD='$LAUNCHER_NAME' source \"$INSTALL_DIR/completions/utility.zsh\""
  install_comp_line() {
    local rc="$1" line="$2" marker="$3"
    [[ -f "$rc" ]] || return 0
    if grep -Fq "$marker" "$rc" 2>/dev/null; then
      # Replace the existing completion line so launcher renames take effect.
      awk -v marker="$marker" -v line="$line" \
        '{ if (index($0, marker)) print line; else print $0 }' "$rc" >"$rc.uk_tmp" &&
        mv "$rc.uk_tmp" "$rc"
      setup_detail "Updated completion line in $rc"
    else
      printf '\n# UtilityKit tab-completion\n%s\n' "$line" >>"$rc"
      setup_detail "Appended completion line to $rc"
    fi
  }
  install_comp_line "$HOME/.bashrc" "$bash_comp_line" "completions/utility.bash"
  install_comp_line "$HOME/.zshrc" "$zsh_comp_line" "completions/utility.zsh"
  if [[ -n "${ZDOTDIR:-}" && "$ZDOTDIR" != "$HOME" ]]; then
    install_comp_line "$ZDOTDIR/.zshrc" "$zsh_comp_line" "completions/utility.zsh"
  fi
else
  setup_detail 'No completions/ directory in source — skipped (run scripts/gen_completions.sh)'
fi

setup_step 'Configuring MANPATH for man pages'
if [[ -d "$INSTALL_DIR/man" ]]; then
  manpath_line='export MANPATH="'"$INSTALL_DIR/man"':$MANPATH"'
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    if ! grep -Fq "$manpath_line" "$rc" 2>/dev/null; then
      printf '\n# Added by UtilityKit\n%s\n' "$manpath_line" >>"$rc"
      setup_detail "Appended MANPATH export to $rc"
    else
      setup_detail "$rc already has MANPATH reference — skipped"
    fi
  done
  if [[ -n "${ZDOTDIR:-}" && "$ZDOTDIR" != "$HOME" && -f "$ZDOTDIR/.zshrc" ]]; then
    rc="$ZDOTDIR/.zshrc"
    if ! grep -Fq "$manpath_line" "$rc" 2>/dev/null; then
      printf '\n# Added by UtilityKit\n%s\n' "$manpath_line" >>"$rc"
      setup_detail "Appended MANPATH export to $rc"
    else
      setup_detail "$rc already has MANPATH reference — skipped"
    fi
  fi
else
  setup_detail 'No man/ directory in install — skipped (run scripts/gen_man.sh)'
fi

[[ -n "$TEMP_CLONE" ]] && rm -rf "$TEMP_CLONE"

if ((INTERACTIVE == 0)); then
  printf '\n  %s%s%s\n' "$UK_C_GREEN$UK_C_BOLD" "$(printf '%*s' 52 '' | tr ' ' -)" "$UK_C_RESET"
fi
uk_success "Installed UtilityKit to $INSTALL_DIR"
printf '  %s%s Run: %s%s%s\n' "$UK_C_CYAN" "$UK_I_ARROW" "$UK_C_BOLD" "$LAUNCHER_NAME" "$UK_C_RESET"
