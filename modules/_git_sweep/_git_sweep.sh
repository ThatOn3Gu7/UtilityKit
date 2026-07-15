#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

GS_APPLY=0
GS_LOCAL=0
GS_REMOTE=0
GS_STASH=0
GS_CLEAN=0
GS_GC=0
GS_REPO='.'

# --- Fallback Functions & Variables ---
UK_C_BOLD=${UK_C_BOLD:-}
UK_C_CYAN=${UK_C_CYAN:-}
UK_C_RESET=${UK_C_RESET:-}
UK_C_DIM=${UK_C_DIM:-}
UK_I_DOT=${UK_I_DOT:-'•'}

if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "Error: %s\n" "$*"; }; fi
if ! declare -f uk_note >/dev/null 2>&1; then uk_note() { printf "Note: %s\n" "$*"; }; fi
if ! declare -f uk_success >/dev/null 2>&1; then uk_success() { printf "Success: %s\n" "$*"; }; fi
if ! declare -f uk_header >/dev/null 2>&1; then uk_header() { printf "\n=== %s ===\n%s\n" "${1:-}" "${2:-}"; }; fi
if ! declare -f uk_abs_path >/dev/null 2>&1; then
  uk_abs_path() {
    if command -v realpath >/dev/null; then
      realpath "${1:-.}"
    else
      local dir file
      dir="$(cd "$(dirname "${1:-.}")" && pwd -P)"
      file="$(basename "${1:-.}")"
      printf '%s/%s\n' "$dir" "$file"
    fi
  }
fi
if ! declare -f uk_confirm >/dev/null 2>&1; then
  uk_confirm() {
    local prompt="${1:-Continue?}" default="${2:-N}"
    local answer
    printf '%s [%s/%s]: ' "$prompt" \
      "$([[ "$default" == "Y" ]] && echo "Y" || echo "y")" \
      "$([[ "$default" == "N" ]] && echo "N" || echo "n")" >&2
    read -r answer </dev/tty
    case "$answer" in
    Y | y) return 0 ;;
    N | n) return 1 ;;
    *) [[ "$default" == "Y" || "$default" == "y" ]] && return 0 || return 1 ;;
    esac
  }
fi
_gs_repo_check() {
  local result
  if ! result="$(git -C "$GS_REPO" rev-parse --is-inside-work-tree 2>&1)" || [[ "$result" != "true" ]]; then
    uk_error "Not a git repository: $GS_REPO${result:+ ($result)}"
    return 1
  fi
}
_gs_default_branch() {
  local head error=''
  if head="$(git -C "$GS_REPO" symbolic-ref refs/remotes/origin/HEAD 2>&1)"; then
    head=${head##*/}
    printf '%s\n' "$head"
    return 0
  else
    error="$head"
    [[ -n "$error" ]] && uk_warn "origin/HEAD unavailable; checking local default branches."
  fi
  for branch in main master trunk; do
    if git -C "$GS_REPO" show-ref --verify --quiet "refs/heads/$branch"; then
      printf '%s\n' "$branch"
      return 0
    fi
  done
  git -C "$GS_REPO" rev-parse --abbrev-ref HEAD
}
_gs_local_merged() {
  local base="${1:-}" current output branch
  current=$(git -C "$GS_REPO" rev-parse --abbrev-ref HEAD) || return 1
  output=$(git -C "$GS_REPO" branch --format='%(refname:short)' --merged "$base") || return 1
  while IFS= read -r branch; do
    [[ -n "$branch" ]] || continue
    case "$branch" in "$base" | "$current" | main | master | trunk) continue ;; esac
    printf '%s\n' "$branch"
  done <<<"$output"
}
_gs_remote_merged() {
  local base="${1:-}" output ref remote branch
  output=$(git -C "$GS_REPO" branch -r --format='%(refname:short)' --merged "$base") || return 1
  while IFS= read -r ref; do
    [[ -n "$ref" && "$ref" != *' -> '* && "$ref" == */* ]] || continue
    remote="${ref%%/*}"
    branch="${ref#*/}"
    case "$branch" in "$base" | main | master | trunk) continue ;; esac
    printf '%s/%s\n' "$remote" "$branch"
  done <<<"$output"
}
gs_usage() {
  cat <<USAGE
Usage:
  _git_sweep.sh [OPTIONS]

Options:
  --repo DIR              Repository directory (default: .)
  --delete-merged-local   Delete fully merged local branches.
  --delete-merged-remote  Delete fully merged remote branches.
  --drop-stashes          Clear git stashes.
  --clean-artifacts       Run git clean -fdx after preview.
  --gc                    Run git gc --prune=now.
  --apply                 Execute destructive actions.
  -h, --help              Show this help.
USAGE
}
gs_print_lines_or_none() {
  local heading="${1:-}"
  shift || true
  printf '\n  %s%s%s\n' "$UK_C_BOLD" "$heading" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  if [[ $# -eq 0 ]]; then
    printf '  %s(none found)%s\n' "$UK_C_DIM" "$UK_C_RESET"
    return 0
  fi
  local item
  for item in "$@"; do
    [[ -n "$item" ]] && printf '  %s%s%s %s\n' "$UK_C_CYAN" "$UK_I_DOT" "$UK_C_RESET" "$item"
  done
}
gs_preview() {
  local base="${1:-}" local_output remote_output stash_output clean_output repo_path
  local -a local_branches=() remote_branches=() stashes=() clean_preview=()

  local_output="$(_gs_local_merged "$base")" || { uk_error "Failed to enumerate merged local branches."; return 1; }
  remote_output="$(_gs_remote_merged "$base")" || { uk_error "Failed to enumerate merged remote branches."; return 1; }
  stash_output="$(git -C "$GS_REPO" stash list)" || { uk_error "Failed to list stashes."; return 1; }
  clean_output="$(git -C "$GS_REPO" clean -fdxn)" || { uk_error "Failed to preview untracked files."; return 1; }
  [[ -n "$local_output" ]] && mapfile -t local_branches <<<"$local_output"
  [[ -n "$remote_output" ]] && mapfile -t remote_branches <<<"$remote_output"
  [[ -n "$stash_output" ]] && mapfile -t stashes <<<"$stash_output"
  [[ -n "$clean_output" ]] && mapfile -t clean_preview <<<"$clean_output"
  repo_path="$(uk_abs_path "$GS_REPO")" || return 1

  uk_section_title "Repository: $repo_path | Base branch: $base"
  gs_print_lines_or_none 'Merged local branches:' "${local_branches[@]}"
  gs_print_lines_or_none 'Merged remote branches:' "${remote_branches[@]}"
  gs_print_lines_or_none 'Git stashes:' "${stashes[@]}"
  gs_print_lines_or_none 'Untracked build artifacts preview:' "${clean_preview[@]}"
}
gs_run() {
  local base="${1:-}" branch output remote

  if ((GS_LOCAL == 1)); then
    output="$(_gs_local_merged "$base")" || { uk_error "Failed to enumerate merged local branches."; return 1; }
    while IFS= read -r branch; do
      [[ -n "$branch" ]] || continue
      if ((GS_APPLY == 1)); then
        git -C "$GS_REPO" branch -d "$branch" || return 1
        uk_success "Deleted local branch $branch"
      else
        uk_note "Would delete local branch $branch"
      fi
    done <<<"$output"
  fi

  if ((GS_REMOTE == 1)); then
    output="$(_gs_remote_merged "$base")" || { uk_error "Failed to enumerate merged remote branches."; return 1; }
    while IFS= read -r branch; do
      [[ -n "$branch" && "$branch" == */* ]] || continue
      remote="${branch%%/*}"
      branch="${branch#*/}"
      if ((GS_APPLY == 1)); then
        git -C "$GS_REPO" push "$remote" --delete "$branch" || return 1
        uk_success "Deleted remote branch $remote/$branch"
      else
        uk_note "Would delete remote branch $remote/$branch"
      fi
    done <<<"$output"
  fi

  if ((GS_STASH == 1)); then
    if ((GS_APPLY == 1)); then
      git -C "$GS_REPO" stash clear || return 1
      uk_success 'Cleared git stashes.'
    else
      uk_note 'Would clear git stashes.'
    fi
  fi

  if ((GS_CLEAN == 1)); then
    if ((GS_APPLY == 1)); then
      git -C "$GS_REPO" clean -fdx || return 1
      uk_success 'Removed untracked build artifacts.'
    else
      uk_note 'Would run git clean -fdx.'
    fi
  fi

  if ((GS_GC == 1)); then
    if ((GS_APPLY == 1)); then
      git -C "$GS_REPO" gc --prune=now || return 1
      uk_success 'Ran git gc --prune=now.'
    else
      uk_note 'Would run git gc --prune=now.'
    fi
  fi
}
gs_interactive() {
  local base="${1:-}"
  gs_preview "$base"
  printf '\n'
  uk_note 'Select which actions to perform. Only checked items will run.'
  printf '\n'

  # Wrap confirmations in if-statements to protect against set -e termination on 'No' answers
  if uk_confirm 'Delete merged local branches shown above? (safe — only fully merged branches qualify)' 'N'; then
    GS_LOCAL=1
  fi

  if uk_confirm 'Delete merged remote branches shown above? (pushes a delete to origin)' 'N'; then
    GS_REMOTE=1
  fi

  if uk_confirm 'Clear ALL git stashes in this repo? (cannot be undone)' 'N'; then
    GS_STASH=1
  fi

  if uk_confirm 'Remove untracked build artifacts with git clean -fdx? (deletes untracked files and dirs)' 'N'; then
    GS_CLEAN=1
  fi

  if uk_confirm 'Run git gc --prune=now? (safe — compresses object storage, speeds up git operations)' 'Y'; then
    GS_GC=1
  fi

  printf '\n'
  if uk_confirm 'Apply all selected actions now? (nothing has changed yet until you confirm here)' 'N'; then
    GS_APPLY=1
  fi

  gs_run "$base"
}
gs_main() {
  uk_banner "git-sweep" "Merged-branch cleanup, stash purge, repo garbage collection" "" "$@"
  GS_APPLY=0
  GS_LOCAL=0
  GS_REMOTE=0
  GS_STASH=0
  GS_CLEAN=0
  GS_GC=0
  GS_REPO='.'
  local base

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --repo)
      if [[ $# -gt 1 ]]; then
        shift
        GS_REPO="${1:-}"
      else
        uk_error "Option --repo requires an argument."
        gs_usage
        return 1
      fi
      ;;
    --delete-merged-local) GS_LOCAL=1 ;;
    --delete-merged-remote) GS_REMOTE=1 ;;
    --drop-stashes) GS_STASH=1 ;;
    --clean-artifacts) GS_CLEAN=1 ;;
    --gc) GS_GC=1 ;;
    --apply) GS_APPLY=1 ;;
    -h | --help)
      gs_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done
  _gs_repo_check || return 1
  base=$(_gs_default_branch) || { uk_error "Unable to determine the base branch."; return 1; }

  if ((GS_LOCAL + GS_REMOTE + GS_STASH + GS_CLEAN + GS_GC == 0)); then
    gs_interactive "$base"
  else
    gs_preview "$base"
    gs_run "$base"
  fi
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  gs_main "$@"
fi
