#!/usr/bin/env bash
# _git_hooks — install / remove / list git hook templates.
# Prefix: gh_
# Templates dir: $SCRIPT_DIR/templates/ (bundled) or custom path.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback helpers ---
if ! declare -f uk_has_cmd >/dev/null 2>&1; then uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }; fi
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "[ERR] %s\n" "$*" >&2; }; fi
if ! declare -f uk_warn >/dev/null 2>&1; then uk_warn() { printf "[WRN] %s\n" "$*" >&2; }; fi
if ! declare -f uk_info >/dev/null 2>&1; then uk_info() { printf "[INF] %s\n" "$*"; }; fi
if ! declare -f uk_success >/dev/null 2>&1; then uk_success() { printf "[OK]  %s\n" "$*"; }; fi
if ! declare -f uk_note >/dev/null 2>&1; then uk_note() { printf "-> %s\n" "$*"; }; fi
if ! declare -f uk_banner >/dev/null 2>&1; then uk_banner() { :; }; fi
if ! declare -f uk_confirm >/dev/null 2>&1; then
  uk_confirm() {
    local reply=''; printf '> %s [y/N]: ' "${1:-Confirm?}" >&2
    [[ -r /dev/tty ]] && read -r reply </dev/tty || read -r reply
    [[ "$reply" =~ ^[Yy] ]]
  }
fi
if ! declare -f uk_prompt >/dev/null 2>&1; then
  uk_prompt() {
    local label="${1:-}" default="${2:-}" reply=''
    printf '> %s%s: ' "$label" "${default:+ [$default]}" >&2
    [[ -r /dev/tty ]] && read -r reply </dev/tty || read -r reply
    printf '%s\n' "${reply:-$default}"
  }
fi
# --------------------------

GH_TEMPLATES_DIR="$SCRIPT_DIR/templates"

GH_BUNDLED_HOOKS=(
  "pre-commit"
  "commit-msg"
  "pre-push"
)

gh_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s %s_git_hooks.sh <install|remove|list|show> [PATH]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Commands" \
    "install [PATH]" "Install hooks in repo at PATH (default: .)" \
    "remove [PATH]" "Remove UtilityKit hooks from repo at PATH" \
    "list [PATH]" "List hooks installed in repo at PATH" \
    "show [NAME]" "Display bundled hook template contents" \
    "--no-color" "Disable ANSI" \
    "-h, --help" "Show this help"
  uk_help_section "$w" "Bundled templates" \
    "pre-commit" "Lint staged shell/Python files" \
    "commit-msg" "Validate commit message format" \
    "pre-push" "Run tests before push"
  uk_help_section "$w" "Examples" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_git_hooks.sh${UK_C_RESET:-} ${UK_C_DIM:-}install /path/to/repo${UK_C_RESET:-}" "Install hooks in a repository" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_git_hooks.sh${UK_C_RESET:-} ${UK_C_DIM:-}list${UK_C_RESET:-}" "List hooks in current repo" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_git_hooks.sh${UK_C_RESET:-} ${UK_C_DIM:-}show pre-commit${UK_C_RESET:-}" "Display pre-commit template"
}

gh_git_dir() {
  local path="${1:-.}"
  local git_dir
  git_dir="$(git -C "$path" rev-parse --absolute-git-dir 2>&1)" || { uk_error "Not a git repo: $path ($git_dir)"; return 1; }
  printf '%s\n' "$git_dir"
}

gh_template() {
  local name="$1"
  case "$name" in pre-commit | commit-msg | pre-push) ;; *) uk_error "Unknown template: $name"; return 1 ;; esac
  local file="$GH_TEMPLATES_DIR/$name"
  if [[ -s "$file" ]]; then
    cat "$file"
    return 0
  fi
  # Built-in fallback templates
  case "$name" in
    pre-commit)
      cat <<'HOOK'
#!/usr/bin/env bash
# UtilityKit — pre-commit hook
set -euo pipefail

echo "→ pre-commit: linting staged files..."
while IFS= read -r -d '' f; do
  case "$f" in
    *.sh) bash -n "$f" || { echo "✗ bash syntax error: $f"; exit 1; } ;;
    *.py) python3 -m py_compile "$f" || { echo "✗ python syntax error: $f"; exit 1; } ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACM -z)
echo "✓ pre-commit passed"
HOOK
      ;;
    commit-msg)
      cat <<'HOOK'
#!/usr/bin/env bash
# UtilityKit — commit-msg hook
set -euo pipefail

msg_file="$1"
first=$(head -1 "$msg_file" 2>/dev/null || true)

# Reject empty messages
if [[ -z "$first" ]]; then
  echo "✗ Commit message cannot be empty" >&2; exit 1
fi

# Reject merge messages (let git handle those)
[[ "$first" =~ ^Merge ]] && exit 0

# Enforce conventional commit format: type(scope): desc
if ! echo "$first" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\([^)]+\))?:\s.+'; then
  echo "✗ Commit message must follow conventional format:" >&2
  echo "  type(scope): description" >&2
  echo "  types: feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert" >&2
  exit 1
fi
echo "✓ commit-msg format OK"
HOOK
      ;;
    pre-push)
      cat <<'HOOK'
#!/usr/bin/env bash
# UtilityKit — pre-push hook
set -euo pipefail

echo "→ pre-push: running tests..."
if [[ -f "tests/smoke_test.sh" ]]; then
  bash tests/smoke_test.sh || { echo "✗ Smoke tests failed"; exit 1; }
elif [[ -f "Makefile" ]] && grep -q '^test' Makefile 2>/dev/null; then
  make test || { echo "✗ make test failed"; exit 1; }
elif [[ -f "package.json" ]] && grep -q '"test"' package.json 2>/dev/null; then
  npm test || { echo "✗ npm test failed"; exit 1; }
else
  echo "  (no test runner detected, skipping)"
fi
echo "✓ pre-push passed"
HOOK
      ;;
    *)
      uk_error "Unknown template: $name. Available: ${GH_BUNDLED_HOOKS[*]}"
      return 1
      ;;
  esac
}

gh_install() {
  local path="${1:-.}"
  local git_dir; git_dir="$(gh_git_dir "$path")" || return 1
  local hooks_dir="$git_dir/hooks"
  local installed=0

  for hook in "${GH_BUNDLED_HOOKS[@]}"; do
    local target="$hooks_dir/$hook"
    if [[ -f "$target" ]] && ! grep -q "UtilityKit" "$target" 2>/dev/null; then
      if uk_confirm "Overwrite existing $hook hook in $path?"; then
        gh_template "$hook" > "$target"
        chmod +x "$target"
        uk_note "Overwrote $hook"
        installed=$((installed+1))
      else
        uk_note "Skipped $hook"
      fi
    else
      gh_template "$hook" > "$target"
      chmod +x "$target"
      uk_note "Installed $hook"
      installed=$((installed+1))
    fi
  done
  uk_success "Installed $installed hook(s) in $path"
}

gh_remove() {
  local path="${1:-.}"
  local git_dir; git_dir="$(gh_git_dir "$path")" || return 1
  local hooks_dir="$git_dir/hooks"
  local removed=0

  for hook in "${GH_BUNDLED_HOOKS[@]}"; do
    local target="$hooks_dir/$hook"
    if [[ -f "$target" ]] && grep -q "UtilityKit" "$target" 2>/dev/null; then
      rm "$target"
      uk_note "Removed $hook"
      removed=$((removed+1))
    fi
  done
  if (( removed )); then
    uk_success "Removed $removed hook(s)"
  else
    uk_note "No UtilityKit hooks found in $path"
  fi
}

gh_list() {
  local path="${1:-.}" as_json=0
  [[ "${2:-}" == "--json" ]] && as_json=1
  local git_dir; git_dir="$(gh_git_dir "$path")" || return 1
  local hooks_dir="$git_dir/hooks"
  local found=0

  if (( as_json )); then
    printf '['
    local first=1 hook
    for hook in "${GH_BUNDLED_HOOKS[@]}"; do
      (( first )) || printf ','
      local target="$hooks_dir/$hook" inst=0 uk=0
      [[ -f "$target" ]] && inst=1
      [[ -f "$target" ]] && grep -q "UtilityKit" "$target" 2>/dev/null && uk=1
      printf '{"hook":"%s","installed":%d,"uk_hook":%d}' "$hook" "$inst" "$uk"
      first=0
    done
    printf ']\n'
    return 0
  fi

  echo ""
  for hook in "${GH_BUNDLED_HOOKS[@]}"; do
    local target="$hooks_dir/$hook"
    if [[ -f "$target" ]]; then
      local label
      if grep -q "UtilityKit" "$target" 2>/dev/null; then
        label="${UK_C_GREEN:-}UK${UK_C_RESET:-}"
      else
        label="${UK_C_YELLOW:-}custom${UK_C_RESET:-}"
      fi
      printf "  %s  %s\n" "$label" "$hook"
      found=$((found+1))
    else
      printf "  %s  %s\n" "${UK_C_DIM:-}—${UK_C_RESET:-}" "$hook"
    fi
  done
  if (( !found )); then
    uk_info "No hooks installed in $path"
  fi
}

gh_show() {
  local name="${1:-}"
  [[ -z "$name" ]] && { uk_error "hook name required"; return 2; }
  gh_template "$name"
}

gh_ensure_templates_dir() {
  local dir="${1:-$GH_TEMPLATES_DIR}"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" 2>/dev/null || true
    for hook in "${GH_BUNDLED_HOOKS[@]}"; do
      local t="$dir/$hook"
      if [[ ! -f "$t" ]]; then
        gh_template "$hook" > "$t" 2>/dev/null || true
        chmod +x "$t" 2>/dev/null || true
      fi
    done
  fi
}

gh_main() {
  uk_banner "git-hooks" "Install / remove / list git hook templates" "" "$@"
  local sub="" path="." name="" json=0
  [[ $# -gt 0 ]] && {
    case "${1:-}" in install|remove|list|show) sub="$1"; shift;; -h|--help) gh_usage; return 0;; esac
  }
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --no-color)
        UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN='' UK_C_YELLOW='' UK_C_BRIGHT_CYAN=''
        ;;
      --json) json=1 ;;
      -h|--help) gh_usage; return 0;;
      -*) uk_error "Unknown: ${1:-}"; gh_usage; return 2;;
      *) [[ -z "$path" || "$path" == "." ]] && path="$1" || name="$1";;
    esac
    shift || true
  done
  gh_ensure_templates_dir
  case "$sub" in
    install) gh_install "$path";;
    remove)  gh_remove "$path";;
    list)    if (( json )); then gh_list "$path" --json; else gh_list "$path"; fi;;
    show)    [[ -z "$name" ]] && name="$path"
             gh_template "$name";;
    *)       gh_usage; return 2;;
  esac
}

gh_wizard() {
  uk_banner "git-hooks" "Install / remove / list git hook templates" ""
  local a; a="$(uk_prompt 'Action: install, remove, list, show' 'list' 'install|remove|list|show' '')"
  case "$a" in
    install|remove|list)
      local p; p="$(uk_prompt 'Git repo path' '.' '/path/to/repo' '')"
      gh_main "$a" "$p"
      ;;
    show)
      local n; n="$(uk_prompt 'Hook name' 'pre-commit' 'pre-commit|commit-msg|pre-push' '')"
      gh_main show "$n"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    gh_wizard
  else
    gh_main "$@"
  fi
fi
