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
  cat <<'USAGE'
Usage:
  bash setup.sh [--no-menu] [--launcher-name NAME] [--install-dir DIR] [--bin-dir DIR] [--no-path]
USAGE
}

setup_expand_path() {
  local input="$1"
  if [[ "$input" == ~* ]]; then
    printf '%s\n' "${input/#\~/$HOME}"
  else
    printf '%s\n' "$input"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-menu) INTERACTIVE=0 ;;
    --launcher-name) shift; LAUNCHER_NAME="${1:-utility}" ;;
    --install-dir) shift; INSTALL_DIR="${1:-$INSTALL_DIR}" ;;
    --bin-dir) shift; BIN_DIR="${1:-$BIN_DIR}" ;;
    --no-path) ADD_TO_PATH=0 ;;
    -h|--help) usage; exit 0 ;;
    *) printf '%sUnknown option: %s%s\n' "$UK_C_RED" "$1" "$UK_C_RESET" >&2; exit 1 ;;
  esac
  shift
done

INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
BIN_DIR="${BIN_DIR/#\~/$HOME}"

if (( INTERACTIVE == 1 )); then
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

SOURCE_DIR='.'
TEMP_CLONE=''
if [[ ! -f "./main.sh" && ! -f "$SETUP_DIR/main.sh" ]]; then
  TEMP_CLONE="$(mktemp -d)"
  git clone --depth=1 "$REPO_URL" "$TEMP_CLONE"
  SOURCE_DIR="$TEMP_CLONE"
else
  SOURCE_DIR="$SETUP_DIR"
fi

mkdir -p "$INSTALL_DIR" "$BIN_DIR"
while IFS= read -r dir; do
  [[ -n "$dir" ]] || continue
  rm -rf "$INSTALL_DIR/$dir"
  mkdir -p "$INSTALL_DIR/$dir"
  cp -a "$SOURCE_DIR/$dir/." "$INSTALL_DIR/$dir/"
done < <(find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 -type d \( -name '_*' -o -name 'lib' -o -name 'docs' -o -name 'tests' \) -printf '%f\n')

for file in main.sh setup.sh README.md CHANGES.md changes.md CONTRIBUTING.md LICENSE; do
  [[ -f "$SOURCE_DIR/$file" ]] && cp -f "$SOURCE_DIR/$file" "$INSTALL_DIR/"
done
find "$INSTALL_DIR" -type f -name '*.sh' -exec chmod +x {} \;

cat > "$BIN_DIR/$LAUNCHER_NAME" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/main.sh" "\$@"
EOF
chmod +x "$BIN_DIR/$LAUNCHER_NAME"

if (( ADD_TO_PATH == 1 )); then
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -Fq "$BIN_DIR" "$rc"; then
      printf '\n# Added by UtilityKit\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$rc"
    fi
  done
fi

[[ -n "$TEMP_CLONE" ]] && rm -rf "$TEMP_CLONE"
uk_success "Installed UtilityKit to $INSTALL_DIR"
printf 'Run: %s%s%s\n' "$UK_C_BOLD" "$LAUNCHER_NAME" "$UK_C_RESET"
