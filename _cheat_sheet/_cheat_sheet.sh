#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

CS_ACTION=''
CS_NAME=''
CS_TEXT=''
CS_FILE=''
CS_TAGS=''
CS_TERM=''

cs_dir() {
  local dir="$(uk_data_dir)/cheat_sheets"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

cs_usage() {
  cat <<'USAGE'
Usage:
  _cheat_sheet.sh --add NAME [--text TEXT|--file FILE] [--tags a,b]
  _cheat_sheet.sh --list | --show NAME | --search TERM
USAGE
}

cs_path() { printf '%s/%s.md\n' "$(cs_dir)" "$(uk_slugify "$1")"; }

cs_add() {
  local path
  path=$(cs_path "$CS_NAME")
  {
    printf '<!-- tags: %s -->\n\n' "$CS_TAGS"
    if [[ -n "$CS_FILE" ]]; then
      cat "$CS_FILE"
    else
      printf '%s\n' "$CS_TEXT"
    fi
  } > "$path"
  uk_success "Saved cheat sheet: $path"
}

cs_list() {
  local found=0
  uk_section_title 'Saved cheat sheets'
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    found=1
    printf '  - %s\n' "$file"
  done < <(find "$(cs_dir)" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sed 's/\.md$//' | sort)
  (( found == 1 )) || printf '  %snone saved yet%s\n' "$UK_C_DIM" "$UK_C_RESET"
}

cs_show() {
  local path
  path=$(cs_path "$CS_NAME")
  [[ -f "$path" ]] || { uk_warn "Snippet not found: $CS_NAME"; return 0; }
  uk_section_title "Snippet: $CS_NAME"
  cat "$path"
}

cs_search() {
  uk_section_title "Search results for: $CS_TERM"
  grep -Rin --color=never "$CS_TERM" "$(cs_dir)" || printf '%sNo matches found.%s\n' "$UK_C_DIM" "$UK_C_RESET"
}

cs_interactive() {
  local choice done_loop=0
  while (( done_loop == 0 )); do
    uk_header 'UtilityKit Cheat Sheet' 'Your personal markdown snippet store'
    printf '  %s1)%s List saved snippets     %s(show all snippet names you have stored)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s2)%s Add a new snippet       %s(save a one-liner or short block with tags)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s3)%s Show a snippet          %s(display full contents of a saved snippet)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s4)%s Search snippets         %s(grep across all saved snippet content)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    printf '  %sq)%s Return to dashboard\n' "$UK_C_BOLD" "$UK_C_RESET"
    printf '\n'
    printf ' %s Choose an action [1-4/q]: ' "$UK_I_ARROW"
    read -r choice
    case "$choice" in
      1)
        cs_list
        ;;
      2)
        CS_ACTION='add'
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
      q|Q|quit|exit)
        done_loop=1
        continue
        ;;
      *)
        uk_warn 'Unknown cheat-sheet action.'
        ;;
    esac
    printf '\n%sPress Enter to stay inside Cheat Sheet...%s' "$UK_C_DIM" "$UK_C_RESET"
    read -r
  done
}

cs_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --add) shift; CS_ACTION='add'; CS_NAME="${1:-}" ;;
      --list) CS_ACTION='list' ;;
      --show) shift; CS_ACTION='show'; CS_NAME="${1:-}" ;;
      --search) shift; CS_ACTION='search'; CS_TERM="${1:-}" ;;
      --text) shift; CS_TEXT="${1:-}" ;;
      --file) shift; CS_FILE="${1:-}" ;;
      --tags) shift; CS_TAGS="${1:-}" ;;
      -h|--help) cs_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
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
      [[ -n "$CS_NAME" ]] || { cs_usage; return 1; }
      if [[ -z "$CS_TEXT" && -z "$CS_FILE" && -t 0 ]]; then
        printf 'Enter cheat sheet text, then Ctrl+D:\n'
        CS_TEXT=$(cat)
      fi
      cs_add
      ;;
    list) cs_list ;;
    show) [[ -n "$CS_NAME" ]] || { cs_usage; return 1; }; cs_show ;;
    search) [[ -n "$CS_TERM" ]] || { cs_usage; return 1; }; cs_search ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cs_main "$@"
fi
