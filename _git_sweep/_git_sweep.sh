#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
  source "$SCRIPT_DIR/../lib/uk_common.sh"
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
if ! declare -f uk_header >/dev/null 2>&1; then uk_header() { printf "\n=== %s ===\n%s\n" "$1" "$2"; }; fi
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
  git -C "$GS_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    uk_error "Not a git repository: $GS_REPO"
    return 1
  }
}
_gs_default_branch() {
  local head
  head=$(git -C "$GS_REPO" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
  head=${head##*/}
  [[ -n "$head" ]] && {
    printf '%s\n' "$head"
    return 0
  }
  for branch in main master trunk; do
    git -C "$GS_REPO" show-ref --verify --quiet "refs/heads/$branch" && {
      printf '%s\n' "$branch"
      return 0
    }
  done
  git -C "$GS_REPO" rev-parse --abbrev-ref HEAD
}
_gs_local_merged() {
  local base="${1:-}" current
  current=$(git -C "$GS_REPO" rev-parse --abbrev-ref HEAD)
  git -C "$GS_REPO" branch --merged "$base" | sed 's/^..//' | grep -Ev "^(${base}|${current}|main|master|trunk)$" || true
}
_gs_remote_merged() {
  local base="${1:-}"
  git -C "$GS_REPO" branch -r --merged "$base" | sed 's/^..//' | grep -v 'HEAD' | sed 's#^origin/##' | grep -Ev "^(${base}|main|master|trunk)$" | sort -u || true
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
  local base="${1:-}"
  local -a local_branches remote_branches stashes clean_preview

  # Protect the subshells with || true to prevent pipefail errors during previews
  mapfile -t local_branches < <(_gs_local_merged "$base" 2>/dev/null || true)
  mapfile -t remote_branches < <(_gs_remote_merged "$base" 2>/dev/null || true)
  mapfile -t stashes < <(git -C "$GS_REPO" stash list 2>/dev/null || true)
  mapfile -t clean_preview < <(git -C "$GS_REPO" clean -fdxn 2>/dev/null || true)

  uk_section_title "Repository: $(uk_abs_path "$GS_REPO") | Base branch: $base"
  gs_print_lines_or_none 'Merged local branches:' "${local_branches[@]}"
  gs_print_lines_or_none 'Merged remote branches:' "${remote_branches[@]}"
  gs_print_lines_or_none 'Git stashes:' "${stashes[@]}"
  gs_print_lines_or_none 'Untracked build artifacts preview:' "${clean_preview[@]}"
}
gs_run() {
  local base="${1:-}" branch

  if ((GS_LOCAL == 1)); then
    while IFS= read -r branch; do
      [[ -n "$branch" ]] || continue
      if ((GS_APPLY == 1)); then
        git -C "$GS_REPO" branch -d "$branch"
        uk_success "Deleted local branch $branch"
      else
        uk_note "Would delete local branch $branch"
      fi
    done < <(_gs_local_merged "$base" 2>/dev/null || true)
  fi

  if ((GS_REMOTE == 1)); then
    while IFS= read -r branch; do
      [[ -n "$branch" ]] || continue
      if ((GS_APPLY == 1)); then
        git -C "$GS_REPO" push origin --delete "$branch"
        uk_success "Deleted remote branch origin/$branch"
      else
        uk_note "Would delete remote branch origin/$branch"
      fi
    done < <(_gs_remote_merged "$base" 2>/dev/null || true)
  fi

  if ((GS_STASH == 1)); then
    if ((GS_APPLY == 1)); then
      git -C "$GS_REPO" stash clear
      uk_success 'Cleared git stashes.'
    else
      uk_note 'Would clear git stashes.'
    fi
  fi

  if ((GS_CLEAN == 1)); then
    if ((GS_APPLY == 1)); then
      git -C "$GS_REPO" clean -fdx
      uk_success 'Removed untracked build artifacts.'
    else
      uk_note 'Would run git clean -fdx.'
    fi
  fi

  if ((GS_GC == 1)); then
    if ((GS_APPLY == 1)); then
      git -C "$GS_REPO" gc --prune=now
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
    case "$1" in
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
      uk_error "Unknown option: $1"
      return 1
      ;;
    esac
    shift
  done
  _gs_repo_check
  base=$(_gs_default_branch)

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
