#!/usr/bin/env bash
# =============================================================================
# gen_completions.sh — generate shell completions from UK_REGISTRY
# -----------------------------------------------------------------------------
# Version: 1.2.0
#
# Parses the UK_REGISTRY block in main.sh (the single source of truth for all
# tools) and emits:
#
#   completions/utility.bash   — bash completion (source from ~/.bashrc)
#   completions/utility.zsh    — zsh completion (source from ~/.zshrc after
#                                compinit, or drop in $fpath as _utility)
#
# Per-command flags are harvested from each tool's argument-parsing `case`
# labels (lines like `--kill)` or `-h | --help)`), so the completions stay in
# sync with the code. Re-run this script whenever the registry or a tool's
# flags change:
#
#   bash scripts/gen_completions.sh
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN="$ROOT/main.sh"
OUT_DIR="$ROOT/completions"
mkdir -p "$OUT_DIR"

[[ -f "$MAIN" ]] || { printf 'gen_completions: main.sh not found at %s\n' "$MAIN" >&2; exit 1; }

# --- 1. Parse UK_REGISTRY records out of main.sh -----------------------------
mapfile -t RECORDS < <(sed -n '/^UK_REGISTRY=(/,/^)$/p' "$MAIN" | sed -n 's/^  "\(.*\)"$/\1/p')
if [[ ${#RECORDS[@]} -eq 0 ]]; then
  printf 'gen_completions: could not extract UK_REGISTRY from %s\n' "$MAIN" >&2
  exit 1
fi

# --- 2. Flag harvesting -------------------------------------------------------
# Pull option tokens from argument-parsing case labels in a script, e.g.:
#   --kill)            ->  --kill
#   -h | --help)       ->  -h --help
flags_from_script() {
  local script="$1"
  [[ -f "$script" ]] || return 0
  grep -oE '^[[:space:]]*(-{1,2}[A-Za-z0-9][A-Za-z0-9-]*([[:space:]]*\|[[:space:]]*-{1,2}[A-Za-z0-9][A-Za-z0-9-]*)*)\)' "$script" 2>/dev/null |
    grep -oE '\-{1,2}[A-Za-z0-9][A-Za-z0-9-]*' | sort -u || true
}

# Same harvest, restricted to one function body inside a file.
flags_from_function() {
  local file="$1" func="$2"
  sed -n "/^${func}()/,/^}/p" "$file" |
    grep -oE '^[[:space:]]*(-{1,2}[A-Za-z0-9][A-Za-z0-9-]*([[:space:]]*\|[[:space:]]*-{1,2}[A-Za-z0-9][A-Za-z0-9-]*)*)\)' 2>/dev/null |
    grep -oE '\-{1,2}[A-Za-z0-9][A-Za-z0-9-]*' | sort -u || true
}

# --- 3. Build command list + per-command flag map -----------------------------
ACTIONS=()
declare -A ACTION_DESC=()
declare -A ACTION_FLAGS=()

for rec in "${RECORDS[@]}"; do
  IFS='|' read -r key action _icon _color _name desc _menu <<<"$rec"
  ACTIONS+=("$action")
  ACTION_DESC["$action"]="$desc"
  flags="$(flags_from_script "$ROOT/modules/_${key}/_${key}.sh" | tr '\n' ' ')"
  case " $flags " in *" --help "*) ;; *) flags="--help $flags" ;; esac
  ACTION_FLAGS["$action"]="${flags% }"
done

# Non-tool commands routed directly by run_tool.
EXTRA_ACTIONS=(setup doctor help version)
ACTION_DESC[setup]='run the installer (setup.sh)'
ACTION_DESC[doctor]='registry + installation integrity checks'
ACTION_DESC[help]='show top-level help'
ACTION_DESC[version]='print UtilityKit version'
ACTION_FLAGS[setup]="$(flags_from_script "$ROOT/setup.sh" | tr '\n' ' ')"
ACTION_FLAGS[setup]="${ACTION_FLAGS[setup]% }"
ACTION_FLAGS[doctor]="$(flags_from_function "$MAIN" uk_doctor | tr '\n' ' ')"
ACTION_FLAGS[doctor]="${ACTION_FLAGS[doctor]% }"
ACTION_FLAGS[help]=''
ACTION_FLAGS[version]=''

ALL_ACTIONS=("${ACTIONS[@]}" "${EXTRA_ACTIONS[@]}")

# --- 4. Emit completions/utility.bash -----------------------------------------
{
  printf '# bash completion for utility (UtilityKit)\n'
  printf '# Auto-generated from UK_REGISTRY by scripts/gen_completions.sh — DO NOT EDIT.\n'
  printf '# Install: source this file from ~/.bashrc\n\n'
  printf '_utility() {\n'
  printf '  local cur cmd\n'
  printf '  cur="${COMP_WORDS[COMP_CWORD]}"\n'
  printf '  cmd="${COMP_WORDS[1]:-}"\n\n'
  printf '  if [[ $COMP_CWORD -eq 1 ]]; then\n'
  printf '    COMPREPLY=($(compgen -W "%s" -- "$cur"))\n' "${ALL_ACTIONS[*]}"
  printf '    return\n'
  printf '  fi\n\n'
  printf '  local flags=""\n'
  printf '  case "$cmd" in\n'
  for action in "${ALL_ACTIONS[@]}"; do
    printf '  %s) flags="%s" ;;\n' "$action" "${ACTION_FLAGS[$action]}"
  done
  printf '  esac\n\n'
  printf '  # Empty word after the command offers flags too (not only after "-"),\n'
  printf '  # so `utility <cmd> <TAB>` shows the available options up front.\n'
  printf '  if [[ ( "$cur" == -* || -z "$cur" ) && -n "$flags" ]]; then\n'
  printf '    COMPREPLY=($(compgen -W "$flags" -- "$cur"))\n'
  printf '  fi\n'
  printf '}\n\n'
  printf '# Register for the default launcher and direct ./main.sh runs.\n'
  printf 'complete -o default -F _utility utility main.sh\n'
  printf '# setup.sh sets UK_COMPLETE_CMD when the launcher has a custom name.\n'
  printf 'if [[ -n "${UK_COMPLETE_CMD:-}" ]]; then\n'
  printf '  complete -o default -F _utility "$UK_COMPLETE_CMD"\n'
  printf 'fi\n'
} >"$OUT_DIR/utility.bash"

# --- 5. Emit completions/utility.zsh -------------------------------------------
zq() { # single-quote-escape for zsh array literals
  printf '%s' "${1//\'/\'\\\'\'}"
}

{
  printf '#compdef utility\n'
  printf '# zsh completion for utility (UtilityKit)\n'
  printf '# Auto-generated from UK_REGISTRY by scripts/gen_completions.sh — DO NOT EDIT.\n'
  printf '# Install (either):\n'
  printf '#   source /path/to/completions/utility.zsh    # in ~/.zshrc, after compinit\n'
  printf '#   cp utility.zsh ~/.zsh/completions/_utility # any dir in $fpath\n\n'
  printf '_utility() {\n'
  printf '  local -a commands\n'
  printf '  commands=(\n'
  for action in "${ALL_ACTIONS[@]}"; do
    printf "    '%s:%s'\n" "$(zq "$action")" "$(zq "${ACTION_DESC[$action]}")"
  done
  printf '  )\n\n'
  printf '  if (( CURRENT == 2 )); then\n'
  printf "    _describe -t commands 'utility command' commands\n"
  printf '    return\n'
  printf '  fi\n\n'
  printf '  local -a flags\n'
  printf '  case "${words[2]}" in\n'
  for action in "${ALL_ACTIONS[@]}"; do
    printf '  %s) flags=(%s) ;;\n' "$action" "${ACTION_FLAGS[$action]}"
  done
  printf '  esac\n\n'
  printf '  if [[ "${words[CURRENT]}" == -* && ${#flags[@]} -gt 0 ]]; then\n'
  printf '    compadd -- "${flags[@]}"\n'
  printf '  elif [[ -z "${words[CURRENT]}" && ${#flags[@]} -gt 0 ]]; then\n'
  printf '    # Empty word after the command: offer flags up front, files as well.\n'
  printf '    compadd -- "${flags[@]}"\n'
  printf '    _files\n'
  printf '  else\n'
  printf '    _files\n'
  printf '  fi\n'
  printf '}\n\n'
  printf 'if (( ${+functions[compdef]} )); then\n'
  printf '  # Register for the default launcher and direct ./main.sh runs.\n'
  printf '  compdef _utility utility main.sh\n'
  printf '  # setup.sh sets UK_COMPLETE_CMD when the launcher has a custom name.\n'
  printf '  if [[ -n "${UK_COMPLETE_CMD:-}" ]]; then\n'
  printf '    compdef _utility "$UK_COMPLETE_CMD"\n'
  printf '  fi\n'
  printf 'elif [[ "${funcstack[1]:-}" == _utility ]]; then\n'
  printf '  # Autoloaded from $fpath by compinit — act as the completion function.\n'
  printf '  _utility "$@"\n'
  printf 'fi\n'
  printf '# Sourced before compinit: nothing registered — run compinit first.\n'
} >"$OUT_DIR/utility.zsh"

printf 'Generated %s (%d commands)\n' "$OUT_DIR/utility.bash" "${#ALL_ACTIONS[@]}"
printf 'Generated %s (%d commands)\n' "$OUT_DIR/utility.zsh" "${#ALL_ACTIONS[@]}"
