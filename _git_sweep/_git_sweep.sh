#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

GS_APPLY=0
GS_LOCAL=0
GS_REMOTE=0
GS_STASH=0
GS_CLEAN=0
GS_GC=0
GS_REPO='.'

_gs_repo_check() {
  git -C "$GS_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { uk_error "Not a git repository: $GS_REPO"; return 1; }
}

_gs_default_branch() {
  local head
  head=$(git -C "$GS_REPO" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
  head=${head##*/}
  [[ -n "$head" ]] && { printf '%s\n' "$head"; return 0; }
  for branch in main master trunk; do
    git -C "$GS_REPO" show-ref --verify --quiet "refs/heads/$branch" && { printf '%s\n' "$branch"; return 0; }
  done
  git -C "$GS_REPO" rev-parse --abbrev-ref HEAD
}

_gs_local_merged() {
  local base="$1" current
  current=$(git -C "$GS_REPO" rev-parse --abbrev-ref HEAD)
  git -C "$GS_REPO" branch --merged "$base" | sed 's/^..//' | grep -Ev "^(${base}|${current}|main|master|trunk)$" || true
}

_gs_remote_merged() {
  local base="$1"
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
  local heading="$1"
  shift || true
  uk_note "$heading"
  if [[ $# -eq 0 ]]; then
    printf '  %snone found%s\n' "$UK_C_DIM" "$UK_C_RESET"
    return 0
  fi
  local item
  for item in "$@"; do
    [[ -n "$item" ]] && printf '  - %s\n' "$item"
  done
}

gs_preview() {
  local base="$1"
  local -a local_branches remote_branches stashes clean_preview
  mapfile -t local_branches < <(_gs_local_merged "$base")
  mapfile -t remote_branches < <(_gs_remote_merged "$base")
  mapfile -t stashes < <(git -C "$GS_REPO" stash list || true)
  mapfile -t clean_preview < <(git -C "$GS_REPO" clean -fdxn || true)

  uk_header "UtilityKit Git Sweep" "Repository: $(uk_abs_path "$GS_REPO") | Base branch: $base"
  gs_print_lines_or_none 'Merged local branches:' "${local_branches[@]}"
  gs_print_lines_or_none 'Merged remote branches:' "${remote_branches[@]}"
  gs_print_lines_or_none 'Git stashes:' "${stashes[@]}"
  gs_print_lines_or_none 'Untracked build artifacts preview:' "${clean_preview[@]}"
}

gs_run() {
  local base="$1" branch
  (( GS_LOCAL == 1 )) && while IFS= read -r branch; do
    [[ -n "$branch" ]] || continue
    if (( GS_APPLY == 1 )); then
      git -C "$GS_REPO" branch -d "$branch"
      uk_success "Deleted local branch $branch"
    else
      uk_note "Would delete local branch $branch"
    fi
  done < <(_gs_local_merged "$base")

  (( GS_REMOTE == 1 )) && while IFS= read -r branch; do
    [[ -n "$branch" ]] || continue
    if (( GS_APPLY == 1 )); then
      git -C "$GS_REPO" push origin --delete "$branch"
      uk_success "Deleted remote branch origin/$branch"
    else
      uk_note "Would delete remote branch origin/$branch"
    fi
  done < <(_gs_remote_merged "$base")

  if (( GS_STASH == 1 )); then
    if (( GS_APPLY == 1 )); then
      git -C "$GS_REPO" stash clear
      uk_success 'Cleared git stashes.'
    else
      uk_note 'Would clear git stashes.'
    fi
  fi

  if (( GS_CLEAN == 1 )); then
    if (( GS_APPLY == 1 )); then
      git -C "$GS_REPO" clean -fdx
      uk_success 'Removed untracked build artifacts.'
    else
      uk_note 'Would run git clean -fdx.'
    fi
  fi

  if (( GS_GC == 1 )); then
    if (( GS_APPLY == 1 )); then
      git -C "$GS_REPO" gc --prune=now
      uk_success 'Ran git gc --prune=now.'
    else
      uk_note 'Would run git gc --prune=now.'
    fi
  fi
}

gs_interactive() {
  gs_preview "$1"
  uk_confirm 'Delete merged local branches?' 'N' && GS_LOCAL=1
  uk_confirm 'Delete merged remote branches?' 'N' && GS_REMOTE=1
  uk_confirm 'Clear stashes?' 'N' && GS_STASH=1
  uk_confirm 'Sweep untracked artifacts with git clean -fdx?' 'N' && GS_CLEAN=1
  uk_confirm 'Run git gc --prune=now?' 'Y' && GS_GC=1
  uk_confirm 'Apply selected actions?' 'N' && GS_APPLY=1
  gs_run "$1"
}

gs_main() {
  local base
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) shift; GS_REPO="${1:-}" ;;
      --delete-merged-local) GS_LOCAL=1 ;;
      --delete-merged-remote) GS_REMOTE=1 ;;
      --drop-stashes) GS_STASH=1 ;;
      --clean-artifacts) GS_CLEAN=1 ;;
      --gc) GS_GC=1 ;;
      --apply) GS_APPLY=1 ;;
      -h|--help) gs_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done
  _gs_repo_check
  base=$(_gs_default_branch)
  if (( GS_LOCAL + GS_REMOTE + GS_STASH + GS_CLEAN + GS_GC == 0 )); then
    gs_interactive "$base"
  else
    gs_preview "$base"
    gs_run "$base"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  gs_main "$@"
fi
