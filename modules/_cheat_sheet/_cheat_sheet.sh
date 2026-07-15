#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

# Global variables
CS_ACTION=''
CS_NAME=''
CS_TEXT=''
CS_FILE=''
CS_TAGS=''
CS_TERM=''

# Data directory
cs_dir() {
  local dir
  dir="$(uk_data_dir)" || return 1
  dir="$dir/cheat_sheets"
  mkdir -p "$dir" || return 1
  printf '%s\n' "$dir"
}
# Usage
cs_usage() {
  cat <<'USAGE'
Usage:
  _cheat_sheet.sh --add NAME [--text TEXT|--file FILE] [--tags a,b]
  _cheat_sheet.sh --list | --show NAME | --search TERM

Options:
  --add NAME     Create a new snippet with the given name (slugified).
  --text TEXT    Provide the snippet content as a string (mutually exclusive with --file).
  --file FILE    Read the snippet content from a file (mutually exclusive with --text).
  --tags a,b,c   Comma-separated tags (stored as a comment in the snippet).
  --list         List all saved snippet names.
  --show NAME    Display the full content of a snippet.
  --search TERM  Search for a term across all snippets.
  --delete NAME  Permanently remove a saved snippet.
  -h, --help     Show this help.
USAGE
}
# Utility functions
cs_path() {
  local dir slug
  dir="$(cs_dir)" || return 1
  slug="$(uk_slugify "${1:-}")" || return 1
  [[ -n "$slug" && "$slug" != "." && "$slug" != ".." ]] || { uk_error "Snippet name has no safe slug: ${1:-}"; return 1; }
  printf '%s/%s.md\n' "$dir" "$slug"
}
cs_confirm_overwrite() {
  local path="${1:-}"
  if [[ -f "$path" ]]; then
    if [[ ! -t 0 ]]; then
      local slug
      slug="$(uk_slugify "$CS_NAME")" || return 1
      if [[ "$CS_NAME" == "$slug" ]]; then
        return 0
      fi
      uk_error "Snippet name normalizes to an existing path; refusing collision overwrite: $path"
      return 1
    fi
    printf '%sSnippet "%s" already exists. Overwrite? [y/N] %s' \
      "${UK_C_YELLOW:-}" "$CS_NAME" "${UK_C_RESET:-}"
    read -r response || return 1
    [[ "$response" =~ ^[Yy]$ ]] || return 1
  fi
  return 0
}
# Core actions
cs_add() {
  local path
  path=$(cs_path "$CS_NAME") || return 1

  # Validate input source
  if [[ -n "$CS_FILE" ]]; then
    if [[ ! -f "$CS_FILE" ]]; then
      uk_error "File not found: $CS_FILE"
      return 1
    fi
    # If both are provided, ignore TEXT (or could warn)
  fi

  # Check if we should overwrite
  cs_confirm_overwrite "$path" || {
    uk_warn "Snippet not saved (user declined overwrite)."
    return 0
  }

  # Write the file
  {
    printf '<!-- tags: %s -->\n\n' "$CS_TAGS"
    if [[ -n "$CS_FILE" ]]; then
      cat "$CS_FILE"
    else
      printf '%s\n' "$CS_TEXT"
    fi
  } >"$path" || { uk_error "Unable to save cheat sheet: $path"; return 1; }
  uk_success "Saved cheat sheet: $path"
}
cs_list() {
  local found=0
  uk_section_title 'Saved cheat sheets'
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    found=1
    printf '  - %s\n' "$file"
  done < <(find "$(cs_dir)" -maxdepth 1 -type f -name '*.md' -exec basename {} .md \; | sort)
  ((found == 1)) || printf '  %snone saved yet%s\n' "$UK_C_DIM" "$UK_C_RESET"
}
cs_show() {
  local path
  path=$(cs_path "$CS_NAME") || return 1
  if [[ ! -f "$path" ]]; then
    uk_warn "Snippet not found: $CS_NAME"
    return 0
  fi
  uk_section_title "Snippet: $CS_NAME"
  cat "$path"
}
cs_search() {
  uk_section_title "Search results for: $CS_TERM"
  local dir status=0
  dir="$(cs_dir)" || return 1
  grep -Rin --color=never -- "$CS_TERM" "$dir" || status=$?
  if ((status == 1)); then
    printf '%sNo matches found.%s\n' "$UK_C_DIM" "$UK_C_RESET"
  elif ((status != 0)); then
    return "$status"
  fi
}
cs_delete() {
  local path
  path=$(cs_path "$CS_NAME") || return 1
  if [[ ! -f "$path" ]]; then
    uk_warn "Snippet not found: $CS_NAME"
    return 0
  fi

  # Confirm deletion (if terminal is interactive)
  if [[ -t 0 ]]; then
    printf '%sDelete snippet "%s"? [y/N] %s' \
      "${UK_C_YELLOW:-}" "$CS_NAME" "${UK_C_RESET:-}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]] || {
      uk_warn "Deletion cancelled."
      return 0
    }
  fi

  rm -f "$path"
  uk_success "Deleted snippet: $CS_NAME"
}
# Interactive mode
cs_interactive() {
  local choice done_loop=0
  while ((done_loop == 0)); do
    clear
    printf '  %s1)%s List saved snippets     %s(show all snippet names you have stored)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s2)%s Add a new snippet       %s(save a one-liner or short block with tags)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s3)%s Show a snippet          %s(display full contents of a saved snippet)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s4)%s Search snippets         %s(grep across all saved snippet content)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s5)%s Delete a snippet        %s(remove a saved snippet permanently)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %sq)%s Return to dashboard\n' "$UK_C_BOLD" "$UK_C_RESET"
    printf '\n'
    printf ' %s Choose an action [1-4/q]: ' "$UK_I_ARROW"
    read -r choice
    case "$choice" in
    1) cs_list ;;
    2)
      CS_NAME="$(uk_prompt \
        'Enter a name for this snippet' \
        '' \
        'docker-logs  |  git-undo  |  ffmpeg-compress' \
        'This becomes the filename. Use short lowercase names with hyphens.')"
      CS_TAGS="$(uk_prompt \
        'Enter optional tags (comma separated, or leave blank)' \
        '' \
        'docker,logs  |  git,undo  |  ffmpeg,video' \
        'Tags are stored in the file header for your own organization only.')"
      CS_TEXT="$(uk_prompt \
        'Enter the snippet text (one line, or leave blank to type multi-line next)' \
        '' \
        'docker logs -f app  |  git reset HEAD~1  |  ffmpeg -i in.mp4 out.webm' \
        'For multi-line snippets leave this blank — you will be prompted to type freely.')"
      # If text is empty, prompt for multi-line
      if [[ -z "$CS_TEXT" ]]; then
        printf 'Enter cheat sheet text (multi‑line), then press Ctrl+D when done:\n'
        CS_TEXT=$(cat)
      fi
      CS_FILE='' # interactive does not support file input
      cs_add
      ;;
    3)
      CS_NAME="$(uk_prompt \
        'Enter the snippet name to display' \
        '' \
        'docker-logs  |  git-undo  |  ffmpeg-compress' \
        'Use the exact name shown in the list. Tab completion is not available here.')"
      cs_show
      ;;
    4)
      CS_TERM="$(uk_prompt \
        'Enter a search term to look for across all snippets' \
        '' \
        'docker  |  reset  |  ffmpeg' \
        'The search scans both snippet names and their full content.')"
      cs_search
      ;;
    5)
      CS_NAME="$(uk_prompt \
        'Enter the name of the snippet to delete' \
        '' \
        'docker-logs  |  git-undo  |  ffmpeg-compress' \
        'This will permanently remove the snippet.')"
      cs_delete
      ;;
    q | Q | quit | exit)
      done_loop=1
      continue
      ;;
    *)
      uk_warn 'Unknown cheat‑sheet action.'
      ;;
    esac
    printf '\n%sPress Enter to stay inside Cheat Sheet...%s' "$UK_C_DIM" "$UK_C_RESET"
    read -r
  done
}
# Main
cs_main() {
  uk_banner "cheat-sheet" "Personal markdown snippet store with tagging and search" "" "$@"
  CS_ACTION=''
  CS_NAME=''
  CS_TEXT=''
  CS_FILE=''
  CS_TAGS=''
  CS_TERM=''

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --add)
      shift
      CS_ACTION='add'
      CS_NAME="${1:-}"
      ;;
    --list) CS_ACTION='list' ;;
    --show)
      shift
      CS_ACTION='show'
      CS_NAME="${1:-}"
      ;;
    --search)
      shift
      CS_ACTION='search'
      CS_TERM="${1:-}"
      ;;
    --delete)
      shift
      CS_ACTION='delete'
      CS_NAME="${1:-}"
      ;;
    --text)
      shift
      CS_TEXT="${1:-}"
      ;;
    --file)
      shift
      CS_FILE="${1:-}"
      ;;
    --tags)
      shift
      CS_TAGS="${1:-}"
      ;;
    -h | --help)
      cs_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  if [[ -z "$CS_ACTION" ]]; then
    if [[ -t 0 ]]; then
      cs_interactive
    else
      CS_ACTION='list'
    fi
  fi

  case "$CS_ACTION" in
  add)
    [[ -n "$CS_NAME" ]] || {
      cs_usage
      return 1
    }
    if [[ -z "$CS_TEXT" && -z "$CS_FILE" && -t 0 ]]; then
      printf 'Enter cheat sheet text, then Ctrl+D:\n'
      CS_TEXT=$(cat)
    fi
    cs_add
    ;;
  list) cs_list ;;
  show)
    [[ -n "$CS_NAME" ]] || {
      cs_usage
      return 1
    }
    cs_show
    ;;
  search)
    [[ -n "$CS_TERM" ]] || {
      cs_usage
      return 1
    }
    cs_search
    ;;
  delete)
    [[ -n "$CS_NAME" ]] || {
      cs_usage
      return 1
    }
    cs_delete
    ;;
  esac
}
# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  cs_main "$@"
fi

