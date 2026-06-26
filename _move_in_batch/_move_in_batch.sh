#!/usr/bin/env bash

IFS=$'\n\t'

#  0.  METADATA
MIB_SCRIPT_NAME="Batch File Mover"
MIB_SCRIPT_VERSION="2.0.2"
MIB_SCRIPT_URL="https://github.com/Thaton3gu7/Utilitykit.git"

#  1.  TERMINAL CAPABILITY DETECTION
MIB_CAP_USE_COLOR=false
MIB_CAP_USE_UNICODE=false
MIB_CAP_IS_INTERACTIVE=false
MIB_METHOD="cp" # default: safe copy
MIB_FLATTEN_MODE=false

init_terminal_caps() {
  if [[ -n "${NO_COLOR:-}" ]]; then
    MIB_CAP_USE_COLOR=false
  elif [[ ! -t 1 ]]; then
    MIB_CAP_USE_COLOR=false
  else
    MIB_CAP_USE_COLOR=true
  fi

  local is_limited=false
  if [[ -n "${ANDROID_ROOT:-}" ]] || [[ "${TERM_PROGRAM:-}" == "Termux" ]] || [[ "${TERM:-}" == "dumb" ]]; then
    is_limited=true
  fi

  if [[ ! -t 1 ]] || [[ "$is_limited" == true ]]; then
    MIB_CAP_USE_UNICODE=false
  else
    MIB_CAP_USE_UNICODE=true
  fi

  if [[ -t 0 ]]; then
    MIB_CAP_IS_INTERACTIVE=true
  else
    MIB_CAP_IS_INTERACTIVE=false
  fi
}

#  2.  ANSI ESCAPE CODES
MIB_C_RESET=""
MIB_C_BOLD=""
MIB_C_DIM=""
MIB_C_ITALIC=""
MIB_C_UNDERLINE=""
MIB_C_STRIKETHROUGH=""
MIB_C_OVERLINE=""
MIB_C_RED=""
MIB_C_GREEN=""
MIB_C_YELLOW=""
MIB_C_BLUE=""
MIB_C_MAGENTA=""
MIB_C_CYAN=""
MIB_C_WHITE=""
MIB_C_GRAY=""
MIB_C_RED_BRIGHT=""
MIB_C_GREEN_BRIGHT=""
MIB_C_YELLOW_BRIGHT=""
MIB_C_BLUE_BRIGHT=""
MIB_C_MAGENTA_BRIGHT=""
MIB_C_CYAN_BRIGHT=""
MIB_C_WHITE_BRIGHT=""
MIB_C_BG_RED=""
MIB_C_BG_GREEN=""
MIB_C_BG_YELLOW=""
MIB_C_BG_BLUE=""
MIB_C_BG_CYAN=""
MIB_C_BG_GRAY=""

init_colors() {
  if [[ "$MIB_CAP_USE_COLOR" == false ]]; then
    return
  fi
  MIB_C_RESET=$'\033[0m'
  MIB_C_BOLD=$'\033[1m'
  MIB_C_DIM=$'\033[2m'
  MIB_C_ITALIC=$'\033[3m'
  MIB_C_UNDERLINE=$'\033[4m'
  MIB_C_STRIKETHROUGH=$'\033[9m'
  MIB_C_OVERLINE=$'\033[53m'
  MIB_C_RED=$'\033[31m'
  MIB_C_GREEN=$'\033[32m'
  MIB_C_YELLOW=$'\033[33m'
  MIB_C_BLUE=$'\033[34m'
  MIB_C_MAGENTA=$'\033[35m'
  MIB_C_CYAN=$'\033[36m'
  MIB_C_WHITE=$'\033[37m'
  MIB_C_GRAY=$'\033[90m'
  MIB_C_RED_BRIGHT=$'\033[91m'
  MIB_C_GREEN_BRIGHT=$'\033[92m'
  MIB_C_YELLOW_BRIGHT=$'\033[93m'
  MIB_C_BLUE_BRIGHT=$'\033[94m'
  MIB_C_MAGENTA_BRIGHT=$'\033[95m'
  MIB_C_CYAN_BRIGHT=$'\033[96m'
  MIB_C_WHITE_BRIGHT=$'\033[97m'
  MIB_C_BG_RED=$'\033[41m'
  MIB_C_BG_GREEN=$'\033[42m'
  MIB_C_BG_YELLOW=$'\033[43m'
  MIB_C_BG_BLUE=$'\033[44m'
  MIB_C_BG_CYAN=$'\033[46m'
  MIB_C_BG_GRAY=$'\033[100m'
}

#  3.  ICON SET  (Unicode → ASCII fallback)
MIB_I_INFO=""
MIB_I_SUCCESS=""
MIB_I_ERROR=""
MIB_I_WARNING=""
MIB_I_WORKING=""
MIB_I_ARROW=""
MIB_I_STAR=""
MIB_I_BULLET=""
MIB_I_COLLAPSED=""
MIB_I_BOX_TL=""
MIB_I_BOX_TR=""
MIB_I_BOX_BL=""
MIB_I_BOX_BR=""
MIB_I_BOX_H=""
MIB_I_BOX_V=""
MIB_I_PROG_FILL=""
MIB_I_PROG_EMPTY=""
MIB_I_CHECK_OFF=""
MIB_I_CHECK_ON=""
MIB_I_LOZENGE=""
MIB_I_PLAY=""
MIB_I_TICK=""
MIB_I_CROSS=""
MIB_I_ELLIPSIS=""
MIB_I_SEPARATOR=""
MIB_I_GEAR=""
MIB_I_SEARCH=""
MIB_I_FOLDER=""
MIB_I_FILE=""
MIB_I_FLATTEN=""
MIB_I_PACKAGE=""

init_icons() {
  if [[ "$MIB_CAP_USE_UNICODE" == true ]]; then
    MIB_I_INFO="ℹ"
    MIB_I_SUCCESS="✔"
    MIB_I_ERROR="✖"
    MIB_I_WARNING="⚠"
    MIB_I_WORKING="⚙"
    MIB_I_ARROW="❯"
    MIB_I_STAR="★"
    MIB_I_BULLET="●"
    MIB_I_COLLAPSED="▸"
    MIB_I_BOX_TL="╭"
    MIB_I_BOX_TR="╮"
    MIB_I_BOX_BL="╰"
    MIB_I_BOX_BR="╯"
    MIB_I_BOX_H="─"
    MIB_I_BOX_V="│"
    MIB_I_PROG_FILL="█"
    MIB_I_PROG_EMPTY="░"
    MIB_I_CHECK_OFF="☐"
    MIB_I_CHECK_ON="☒"
    MIB_I_LOZENGE="◆"
    MIB_I_PLAY="▶"
    MIB_I_TICK="✔"
    MIB_I_CROSS="✖"
    MIB_I_ELLIPSIS="…"
    MIB_I_SEPARATOR="╱"
    MIB_I_GEAR="⚙"
    MIB_I_SEARCH="⌕"
    MIB_I_FOLDER="📁"
    MIB_I_FILE="📄"
    MIB_I_FLATTEN="↯"
    MIB_I_PACKAGE="📦"
  else
    MIB_I_INFO="i"
    MIB_I_SUCCESS="[OK]"
    MIB_I_ERROR="[ERR]"
    MIB_I_WARNING="[!]"
    MIB_I_WORKING="[*]"
    MIB_I_ARROW=">"
    MIB_I_STAR="*"
    MIB_I_BULLET="*"
    MIB_I_COLLAPSED=">"
    MIB_I_BOX_TL="+"
    MIB_I_BOX_TR="+"
    MIB_I_BOX_BL="+"
    MIB_I_BOX_BR="+"
    MIB_I_BOX_H="-"
    MIB_I_BOX_V="|"
    MIB_I_PROG_FILL="#"
    MIB_I_PROG_EMPTY="."
    MIB_I_CHECK_OFF="[ ]"
    MIB_I_CHECK_ON="[x]"
    MIB_I_LOZENGE="<>"
    MIB_I_PLAY=">"
    MIB_I_TICK="[OK]"
    MIB_I_CROSS="[ERR]"
    MIB_I_ELLIPSIS="..."
    MIB_I_SEPARATOR="|"
    MIB_I_GEAR="[*]"
    MIB_I_SEARCH="?"
    MIB_I_FOLDER="[D]"
    MIB_I_FILE="[F]"
    MIB_I_FLATTEN="|>"
    MIB_I_PACKAGE="[P]"
  fi
}

#  4.  HELPER FUNCTIONS
colorize() {
  local color="$1"
  local text="$2"
  if [[ "$MIB_CAP_USE_COLOR" == true ]]; then
    printf "%s%s%s" "$color" "$text" "$MIB_C_RESET"
  else
    printf "%s" "$text"
  fi
}

msg_info() { printf "  %s    %s\n" "$(colorize "$MIB_C_BLUE" "$MIB_I_INFO")" "$*"; }
msg_success() { printf "  %s %s\n" "$(colorize "$MIB_C_GREEN" "$MIB_I_SUCCESS")" "$*"; }
msg_error() { printf "  %s   %s\n" "$(colorize "$MIB_C_RED" "$MIB_I_ERROR")" "$*" >&2; }
msg_warning() { printf "  %s  %s\n" "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")" "$*"; }
msg_working() { printf "  %s %s\n" "$(colorize "$MIB_C_CYAN" "$MIB_I_WORKING")" "$*"; }
msg_arrow() { printf "  %s   %s\n" "$(colorize "$MIB_C_BLUE_BRIGHT" "$MIB_I_ARROW")" "$*"; }

print_banner() {
  local title="$1"
  local subtitle="${2:-}"
  local maxlen=${#title}
  [[ ${#subtitle} -gt $maxlen ]] && maxlen=${#subtitle}
  local inner_width=$((maxlen + 4))

  local hrule=""
  local i
  for ((i = 0; i < inner_width; i++)); do hrule+="$MIB_I_BOX_H"; done

  printf "\n"
  printf "  %s%s%s\n" \
    "$(colorize "$MIB_C_CYAN" "$MIB_I_BOX_TL")" \
    "$(colorize "$MIB_C_CYAN" "$hrule")" \
    "$(colorize "$MIB_C_CYAN" "$MIB_I_BOX_TR")"

  local title_pad=$((inner_width - 2 - ${#title}))
  printf "  %s  %s%*s%s\n" \
    "$(colorize "$MIB_C_CYAN" "$MIB_I_BOX_V")" \
    "$(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$title")" \
    "$title_pad" "" \
    "$(colorize "$MIB_C_CYAN" "$MIB_I_BOX_V")"

  if [[ -n "$subtitle" ]]; then
    local sub_pad=$((inner_width - 2 - ${#subtitle}))
    printf "  %s  %s%*s%s\n" \
      "$(colorize "$MIB_C_CYAN" "$MIB_I_BOX_V")" \
      "$(colorize "$MIB_C_DIM" "$subtitle")" \
      "$sub_pad" "" \
      "$(colorize "$MIB_C_CYAN" "$MIB_I_BOX_V")"
  fi

  printf "  %s%s%s\n" \
    "$(colorize "$MIB_C_CYAN" "$MIB_I_BOX_BL")" \
    "$(colorize "$MIB_C_CYAN" "$hrule")" \
    "$(colorize "$MIB_C_CYAN" "$MIB_I_BOX_BR")"
  printf "\n"
}
format_size() {
  local size="$1"
  if ((size >= 1073741824)); then
    awk "BEGIN { printf \"%.1f GB\", $size/1073741824 }"
  elif ((size >= 1048576)); then
    awk "BEGIN { printf \"%.1f MB\", $size/1048576 }"
  elif ((size >= 1024)); then
    awk "BEGIN { printf \"%.1f KB\", $size/1024 }"
  else
    printf "%s B" "$size"
  fi
}
format_duration() {
  local seconds=$1
  local mins=$((seconds / 60))
  local secs=$((seconds % 60))
  if ((mins > 0)); then
    printf "%dm %02ds" "$mins" "$secs"
  else
    printf "%ds" "$secs"
  fi
}
#  5.  PROGRESS BAR
draw_progress() {
  local current="$1"
  local total="$2"
  local label="$3"

  ((total == 0)) && return
  if [[ ! -t 1 ]]; then
    [[ "$label" == "Complete" ]] && printf "  %s Processed %d/%d file(s): %s\n" "$MIB_I_GEAR" "$current" "$total" "$label"
    return 0
  fi

  local term_width
  term_width=$(tput cols 2>/dev/null || echo 80)

  local bar_width=$((term_width / 4))
  ((bar_width > 30)) && bar_width=30
  ((bar_width < 10)) && bar_width=10

  local pct=$((current * 100 / total))
  local filled=$((current * bar_width / total))
  local empty=$((bar_width - filled))

  local bar=""
  local i
  for ((i = 0; i < filled; i++)); do bar+="$MIB_I_PROG_FILL"; done
  for ((i = 0; i < empty; i++)); do bar+="$MIB_I_PROG_EMPTY"; done

  local ui_reserved=$((14 + bar_width + 3 + ${#current} + ${#total}))
  local max_label_len=$((term_width - ui_reserved))

  local display_label="$label"
  if ((max_label_len < 5)); then
    display_label=""
  elif ((${#display_label} > max_label_len)); then
    display_label="${display_label:0:$((max_label_len - 3))}..."
  fi

  if [[ "$MIB_CAP_USE_COLOR" == true ]]; then
    local prog_color="$MIB_C_CYAN"
    if ((pct >= 100)); then
      prog_color="$MIB_C_GREEN"
    elif ((pct >= 66)); then
      prog_color="$MIB_C_GREEN_BRIGHT"
    elif ((pct >= 33)); then
      prog_color="$MIB_C_YELLOW"
    fi

    printf "%s" $'\033[2K\r'
    printf "  %s%s%s[%s]%s %s%3d%%%s  %s%d/%d%s  %s%s%s" \
      "$MIB_C_DIM" "$(colorize "$MIB_C_CYAN" "$MIB_I_GEAR")" "$MIB_C_DIM" \
      "$(colorize "$prog_color" "$bar")" \
      "$MIB_C_DIM" "$MIB_C_BOLD" "$pct" "$MIB_C_RESET" \
      "$MIB_C_DIM" "$current" "$total" "$MIB_C_RESET" \
      "$MIB_C_DIM" "$display_label" "$MIB_C_RESET"
  else
    printf "%s" $'\033[2K\r'
    printf "  %s [%s] %3d%%  %d/%d  %s" \
      "$MIB_I_GEAR" "$bar" "$pct" "$current" "$total" "$display_label"
  fi
}
#  6.  UTILITY:  tilde expansion
_expand_tilde() {
  local path="$1"
  if [[ "$path" == "~" || "$path" == "~/"* ]]; then
    path="${HOME}${path:1}"
  fi
  printf '%s' "$path"
}
#  7.  HELP & VERSION
show_help() {
  print_banner "$MIB_SCRIPT_NAME" "v${MIB_SCRIPT_VERSION}"

  printf "  %s\n" "$(colorize "${MIB_C_BOLD}${MIB_C_WHITE}" "USAGE")"
  printf "\n"
  printf "    %s %s %s %s\n" \
    "$(colorize "$MIB_C_CYAN" "  bash _move_in_batch.sh")" \
    "$(colorize "$MIB_C_GREEN" "-t <target>")" \
    "$(colorize "$MIB_C_YELLOW" "-o <output>")" \
    "$(colorize "$MIB_C_GRAY" "[flags]")"
  printf "\n"
  printf "  %s\n" "$(colorize "${MIB_C_BOLD}${MIB_C_WHITE}" "FLAGS")"
  printf "\n"
  printf "    %-22s %s\n" "$(colorize "$MIB_C_GREEN" "-t, --target")" "Source directory (required)"
  printf "    %-22s %s\n" "$(colorize "$MIB_C_YELLOW" "-o, --output")" "Destination directory (required)"
  printf "    %-22s %s\n" "$(colorize "$MIB_C_RED" "-e, --exclude")" "Extensions / patterns to skip"
  printf "    %-22s %s\n" "$(colorize "$MIB_C_MAGENTA" "-f, --flatten")" "Strip subdirectory structure"
  printf "    %-22s %s\n" "$(colorize "$MIB_C_BLUE" "-m, --method")" "Transfer method: cp (default) or mv"
  printf "    %-22s %s\n" "$(colorize "$MIB_C_CYAN" "-h, --help")" "Show this help"
  printf "\n"
  printf "  %s\n" "$(colorize "${MIB_C_BOLD}${MIB_C_WHITE}" "EXAMPLES")"
  printf "\n"
  printf "    %s\n" "$(colorize "$MIB_C_DIM" "# Copy files, excluding .md & .git, preserve structure")"
  printf "    %s\n" "$(colorize "$MIB_C_GREEN" "  bash _move_in_batch.sh -t ~/src -o ~/out -e .md .git")"
  printf "\n"
  printf "    %s\n" "$(colorize "$MIB_C_DIM" "# Move files, flatten subdirectories")"
  printf "    %s\n" "$(colorize "$MIB_C_GREEN" "  bash _move_in_batch.sh -t ~/src -o ~/out -f -m=mv")"
  printf "\n"
  printf "    %s\n" "$(colorize "$MIB_C_DIM" "# Same but using long flags")"
  printf "    %s\n" "$(colorize "$MIB_C_GREEN" "  bash _move_in_batch.sh --target ~/src --output ~/out --flatten --method=mv --exclude .git .md")"
  printf "\n"
  printf "  %s\n" "$(colorize "${MIB_C_BOLD}${MIB_C_WHITE}" "NOTES")"
  printf "\n"
  printf "    %s  %s\n" "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")" "$(colorize "$MIB_C_BOLD" "Default method is cp (copy) for safety.")"
  printf "    %s  %s\n" "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")" "$(colorize "$MIB_C_DIM" "Use -m=mv only if you intend to move/delete originals.")"
  printf "\n"
}
show_version() {
  printf "%s %s\n" \
    "$(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$MIB_SCRIPT_NAME")" \
    "$(colorize "$MIB_C_GREEN" "v${MIB_SCRIPT_VERSION}")"
  printf "%s\n" "$(colorize "$MIB_C_DIM" "$MIB_SCRIPT_URL")"
  printf "\n"
  printf "  Bash:          %s\n" "${BASH_VERSION}"
  printf "  Unicode:       %s\n" "$([[ "$MIB_CAP_USE_UNICODE" == true ]] && echo "enabled" || echo "disabled")"
  printf "  Color:         %s\n" "$([[ "$MIB_CAP_USE_COLOR" == true ]] && echo "enabled" || echo "disabled")"
  printf "  Interactive:   %s\n" "$([[ "$MIB_CAP_IS_INTERACTIVE" == true ]] && echo "yes" || echo "no")"
}
#  8.  EXCLUSION CHECK & GROUPING
_exclusion_group() {
  local filepath="$1"
  local basename
  basename="$(basename "$filepath")"
  shift
  local exts=("$@")
  for ext in "${exts[@]}"; do
    local clean_ext="${ext#.}"
    # Path-component match first (e.g. ".git" matches ".git/config" or
    # "sub/.git/objects/…")
    if [[ "/${filepath}" == *"/${clean_ext}/"* || "/${filepath}" == *"/${ext}"* ]]; then
      printf '%s' "${ext}"
      return 0
    fi
    # Basename match (e.g. ".md" matches "readme.md")
    if [[ "$basename" == *"$ext" ]]; then
      printf '%s' "${basename}"
      return 0
    fi
  done
  return 1
}
_is_excluded() {
  local filepath="$1"
  local basename
  basename="$(basename "$filepath")"
  shift
  local exts=("$@")
  for ext in "${exts[@]}"; do
    if [[ "$basename" == *"$ext" ]]; then
      return 0
    fi
    if [[ "/${filepath}" == *"/${ext#.}/"* || "/${filepath}" == *"/${ext}"* ]]; then
      return 0
    fi
  done
  return 1
}
#  9. MAIN  —  move_in_batch
move_in_batch() {
  init_terminal_caps
  init_colors
  init_icons
  local target=""
  local output=""
  local exclude=()
  MIB_FLATTEN_MODE=false
  MIB_METHOD="cp"

  # ---- rollback tracking ----
  declare -ga ROLLBACK_SRC=()
  declare -ga ROLLBACK_DST=()

  # ---- parse flags ----
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -t | --target)
      target="$(_expand_tilde "$2")"
      shift 2
      ;;
    -o | --output)
      output="$(_expand_tilde "$2")"
      shift 2
      ;;
    -e | --exclude)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        exclude+=("$1")
        shift
      done
      ;;
    -f | --flatten)
      MIB_FLATTEN_MODE=true
      shift
      ;;
    -m=* | --method=*)
      MIB_METHOD="${1#*=}"
      shift
      ;;
    -m | --method)
      MIB_METHOD="$2"
      shift 2
      ;;
    -h | --help)
      show_help
      return 0
      ;;
    -v | --version)
      show_version
      return 0
      ;;
    *)
      msg_error "Unknown option: $1"
      msg_info "Use -h or --help for usage."
      return 1
      ;;
    esac
  done

  # ---- validate flags ----
  if [[ -z "$target" ]]; then
    msg_error "Target directory (-t) is required."
    return 1
  fi
  if [[ -z "$output" ]]; then
    msg_error "Output directory (-o) is required."
    return 1
  fi
  if [[ ! -d "$target" ]]; then
    msg_error "Target directory does not exist: $target"
    return 1
  fi

  # ---- validate method ----
  if [[ "$MIB_METHOD" != "cp" && "$MIB_METHOD" != "mv" ]]; then
    msg_warning "Unknown method '$MIB_METHOD' — falling back to 'cp' (copy)."
    MIB_METHOD="cp"
  fi

  local method_verb="Copying"
  local method_label="copy (cp)"
  if [[ "$MIB_METHOD" == "mv" ]]; then
    method_verb="Moving"
    method_label="move  (mv)"
  fi

  # ---- same-directory guard ----
  if [[ "$(realpath "$target" 2>/dev/null || echo "$target")" == "$(realpath "$output" 2>/dev/null || echo "$output")" ]]; then
    msg_error "Target and output directories are the same. Refusing to transfer."
    return 1
  fi

  mkdir -p "$output"

  # Refuse destination nesting inside the source tree; otherwise a re-run can
  # recursively copy/move the previous output back into itself.
  local real_target real_output
  real_target="$(realpath "$target" 2>/dev/null || (cd "$target" && pwd -P))"
  real_output="$(realpath "$output" 2>/dev/null || (cd "$output" && pwd -P))"
  if [[ "$real_output" == "$real_target" || "$real_output" == "$real_target"/* ]]; then
    msg_error "Output directory must not be the source directory or inside it: $output"
    return 1
  fi

  # ---- scan files ----
  msg_working "Scanning for files in $(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$target") ..."

  local files=()
  local total_size=0
  while IFS= read -r -d '' filepath; do
    local file_size
    if file_size=$(stat -c '%s' "$filepath" 2>/dev/null); then
      :
    elif file_size=$(stat -f '%z' "$filepath" 2>/dev/null); then
      :
    else
      file_size=0
    fi
    files+=("$filepath")
    total_size=$((total_size + file_size))
  done < <(find "$target" -type f -print0 2>/dev/null | sort -z)

  local total_files=${#files[@]}

  if ((total_files == 0)); then
    msg_warning "No files found in $(colorize "$MIB_C_BOLD" "$target")"
    print_banner "Operation Summary" "Nothing to process"
    printf "  %s  0 files processed\n" "$(colorize "$MIB_C_GREEN" "$MIB_I_TICK")"
    return 0
  fi

  # ---- classify files (with in-memory destination tracking for collisions) ----
  local dests=()
  local skipped_excluded=0
  local collision_count=0
  declare -A _seen_dests=()      # track assigned destinations to avoid collisions
  declare -A _excluded_groups=() # group_label → count, for compact display

  for file in "${files[@]}"; do
    local basename
    basename="$(basename "$file")"
    local rel_path
    rel_path="${file#"$target"}"
    rel_path="${rel_path#/}"

    local group_label
    if group_label="$(_exclusion_group "$rel_path" "${exclude[@]}")"; then
      dests+=("__SKIP__:${group_label}")
      _excluded_groups["$group_label"]=$((${_excluded_groups["$group_label"]:-0} + 1))
      skipped_excluded=$((skipped_excluded + 1))
      continue
    fi

    local dest
    if $MIB_FLATTEN_MODE; then
      local candidate="${output}/${basename}"
      if [[ -e "$candidate" ]] || [[ -n "${_seen_dests[$candidate]:-}" ]]; then
        local name="${basename%.*}"
        local ext="${basename##*.}"
        if [[ "$name" == "$ext" ]]; then ext=""; else ext=".${ext}"; fi
        local c=1
        while true; do
          candidate="${output}/${name}_${c}${ext}"
          if [[ ! -e "$candidate" ]] && [[ -z "${_seen_dests[$candidate]:-}" ]]; then
            break
          fi
          c=$((c + 1))
        done
        collision_count=$((collision_count + 1))
      fi
      dest="$candidate"
    else
      local parent_dir="${rel_path%/*}"
      if [[ "$parent_dir" == "$rel_path" ]]; then
        parent_dir=""
      fi
      local dest_dir="$output"
      [[ -n "$parent_dir" ]] && dest_dir="${output}/${parent_dir}"
      mkdir -p "$dest_dir"

      local candidate="${dest_dir}/${basename}"
      if [[ -e "$candidate" ]] || [[ -n "${_seen_dests[$candidate]:-}" ]]; then
        local name="${basename%.*}"
        local ext="${basename##*.}"
        if [[ "$name" == "$ext" ]]; then ext=""; else ext=".${ext}"; fi
        local c=1
        while true; do
          candidate="${dest_dir}/${name}_${c}${ext}"
          if [[ ! -e "$candidate" ]] && [[ -z "${_seen_dests[$candidate]:-}" ]]; then
            break
          fi
          c=$((c + 1))
        done
        collision_count=$((collision_count + 1))
      fi
      dest="$candidate"
    fi
    _seen_dests["$dest"]=1
    dests+=("$dest")
  done
  unset _seen_dests

  local active_count=$((total_files - skipped_excluded))

  # ---- BANNER & PREVIEW ----
  local mode_tags=""
  if $MIB_FLATTEN_MODE; then
    mode_tags+="$(colorize "$MIB_C_MAGENTA" " [flatten]")"
  fi

  print_banner "Batch Move Operation" "v${MIB_SCRIPT_VERSION}"

  msg_info "Source:      $(colorize "$MIB_C_BOLD" "$target")"
  msg_info "Output:      $(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$output")"
  msg_info "Method:      $(colorize "$MIB_C_BLUE" "$method_label")$mode_tags"
  msg_info "Files found: $(colorize "${MIB_C_BOLD}${MIB_C_WHITE}" "$total_files")"
  msg_info "Total size:  $(colorize "$MIB_C_DIM" "$(format_size "$total_size")")"

  if ((skipped_excluded > 0)); then
    msg_info "Excluded:    $(colorize "$MIB_C_DIM" "$skipped_excluded") file(s)"
  fi
  if ((collision_count > 0)); then
    msg_warning "Collisions:  $(colorize "$MIB_C_YELLOW_BRIGHT" "$collision_count") file(s) will be auto-renamed (_1, _2, …)"
  fi

  if ((active_count == 0)); then
    printf "\n"
    msg_warning "All files were excluded — nothing to do."
    return 0
  fi

  # ---- file preview ----
  printf "\n"
  printf "  %s  %s %s\n" \
    "$(colorize "$MIB_C_BLUE_BRIGHT" "$MIB_I_COLLAPSED")" \
    "$(colorize "$MIB_C_BOLD" "Preview")" \
    "$(colorize "$MIB_C_DIM" "(showing up to 10 files):")"

  local preview_max_transfers=7
  local preview_max_groups=3
  local shown=0

  # (A) Show transfer previews first
  local idx=0
  while ((idx < total_files && shown < preview_max_transfers)); do
    local d="${dests[$idx]}"
    if [[ "$d" != __SKIP__:* ]]; then
      local fn
      fn="$(basename "${files[$idx]}")"
      local dn
      dn="$(basename "$d")"
      printf "    %s %s %s %s\n" \
        "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
        "$(colorize "$MIB_C_GRAY" "$fn")" \
        "$(colorize "$MIB_C_CYAN" " ──→ ")" \
        "$(colorize "$MIB_C_GREEN_BRIGHT" "$dn")"
      shown=$((shown + 1))
    fi
    idx=$((idx + 1))
  done

  # Count unshown transfers
  local unshown_transfers=0
  while ((idx < total_files)); do
    local d="${dests[$idx]}"
    [[ "$d" != __SKIP__:* ]] && unshown_transfers=$((unshown_transfers + 1))
    idx=$((idx + 1))
  done

  # (B) Show excluded groups (compact)
  local group_shown=0
  for grp in "${!_excluded_groups[@]}"; do
    ((group_shown >= preview_max_groups)) && break
    local cnt="${_excluded_groups[$grp]}"
    if ((cnt == 1)); then
      printf "    %s %s %s\n" \
        "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
        "$(colorize "$MIB_C_GRAY" "$grp")" \
        "$(colorize "$MIB_C_YELLOW" "(excluded)")"
    else
      printf "    %s %s %s\n" \
        "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
        "$(colorize "$MIB_C_GRAY" "$grp")" \
        "$(colorize "$MIB_C_YELLOW" "(${cnt} files excluded)")"
    fi
    group_shown=$((group_shown + 1))
  done

  # Count unshown groups for the "and more" line
  local total_groups=${#_excluded_groups[@]}
  local total_remaining=$((unshown_transfers + (total_groups > preview_max_groups ? total_groups - preview_max_groups : 0)))
  if ((total_remaining > 0)); then
    printf "    %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ELLIPSIS} and ${total_remaining} more")"
  fi

  printf "\n"

  # ---- interactive confirmation ----
  if [[ "$MIB_CAP_IS_INTERACTIVE" == true ]]; then
    local proceed=""
    printf "  %s  Proceed with %s? %s %s" \
      "$(colorize "${MIB_C_BOLD}${MIB_C_YELLOW}" "$MIB_I_PLAY")" \
      "$(colorize "$MIB_C_BOLD" "$method_verb $active_count file(s)")" \
      "$(colorize "$MIB_C_GREEN" "[Y/n]")" \
      "$(colorize "$MIB_C_DIM" "> ")"
    read -r proceed
    case "${proceed,,}" in
    n | no)
      printf "\n"
      msg_warning "Operation cancelled by user."
      return 0
      ;;
    esac
    printf "\n"
  fi

  # ---- processing ----
  local success_count=0
  local failed_count=0
  local skipped_conflict=0
  local processed_files=()
  local failed_files=()
  local skipped_list=()

  local start_time
  start_time=$(date +%s)

  # ---- Ctrl+C handler with rollback ----
  handle_interrupt() {
    trap - SIGINT
    printf "\n\n"
    msg_warning "Process interrupted by user (Ctrl+C)!"

    local count=${#ROLLBACK_SRC[@]}
    if ((count == 0)); then
      msg_info "No files were transferred yet. Exiting safely."
      return 130
    fi

    printf "  %s  %d file(s) have already been transferred.\n" \
      "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")" "$count"

    if [[ "$MIB_CAP_IS_INTERACTIVE" == true ]]; then
      local rb_choice=""
      printf "  %s  Roll back these changes? %s %s" \
        "$(colorize "${MIB_C_BOLD}${MIB_C_YELLOW}" "$MIB_I_SEARCH")" \
        "$(colorize "$MIB_C_GREEN" "[Y/n]")" \
        "$(colorize "$MIB_C_DIM" "> ")"
      read -r rb_choice
      case "${rb_choice,,}" in
      y | yes | "")
        msg_working "Rolling back changes..."
        local rb_fails=0
        for ((i = ${#ROLLBACK_SRC[@]} - 1; i >= 0; i--)); do
          local r_dst="${ROLLBACK_DST[$i]}"
          if [[ -e "$r_dst" ]]; then
            rm -f "$r_dst" || rb_fails=$((rb_fails + 1))
          fi
        done
        if ((rb_fails > 0)); then
          msg_error "Rollback completed with $rb_fails error(s)."
        else
          msg_success "Rollback successful. Output directory restored."
        fi
        ;;
      *)
        msg_info "Keeping transferred files. Exiting."
        ;;
      esac
    fi
    return 130
  }

  msg_working "Processing $(colorize "$MIB_C_BOLD" "$active_count") file(s)..."
  printf "\n"

  local progress_current=0

  trap 'handle_interrupt' SIGINT

  for ((idx = 0; idx < total_files; idx++)); do
    local src="${files[$idx]}"
    local dst="${dests[$idx]}"
    local src_name
    src_name="$(basename "$src")"

    # Skip excluded files (already counted in _excluded_groups)
    if [[ "$dst" == __SKIP__:* ]]; then
      continue
    fi

    progress_current=$((progress_current + 1))
    draw_progress "$progress_current" "$active_count" "$src_name"

    # If destination already exists (e.g. from a previous partial run), skip
    if [[ -e "$dst" && "$dst" != "$src" ]]; then
      skipped_conflict=$((skipped_conflict + 1))
      skipped_list+=("$src_name (destination exists)")
      continue
    fi

    # Ensure parent directories exist
    mkdir -p "$(dirname "$dst")"

    local op_status=0
    if [[ "$MIB_METHOD" == "cp" ]]; then
      cp -- "$src" "$dst" || op_status=$?
    else
      mv -- "$src" "$dst" || op_status=$?
    fi

    if ((op_status == 0)); then
      success_count=$((success_count + 1))
      processed_files+=("$(basename "$dst")")
      ROLLBACK_SRC+=("$src")
      ROLLBACK_DST+=("$dst")
    else
      failed_count=$((failed_count + 1))
      failed_files+=("$src_name (exit: ${op_status})")
      printf "%s" $'\033[2K\r'
      msg_error "Failed: $(colorize "$MIB_C_BOLD" "$src") → $(colorize "$MIB_C_BOLD" "$dst") (exit: ${op_status})"
    fi
  done

  # Final 100% draw
  draw_progress "$active_count" "$active_count" "Complete"
  printf "\n\n"

  trap - SIGINT

  # ---- summary ----
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  print_banner "Operation Complete" "Processed in $(format_duration "$duration")"

  printf "  %s  %s\n" "$(colorize "$MIB_C_GREEN" "$MIB_I_TICK")" "$(colorize "$MIB_C_BOLD" "Summary")"
  printf "\n"
  printf "    %s  Success:  %s\n" \
    "$(colorize "$MIB_C_GREEN" "$MIB_I_SUCCESS")" \
    "$(colorize "${MIB_C_BOLD}${MIB_C_GREEN}" "$success_count")"
  printf "    %s   Skipped:  %s\n" \
    "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")" \
    "$(colorize "${MIB_C_BOLD}${MIB_C_YELLOW}" "$((skipped_excluded + skipped_conflict))")"

  if ((failed_count > 0)); then
    printf "    %s  Failed:   %s\n" \
      "$(colorize "$MIB_C_RED" "$MIB_I_ERROR")" \
      "$(colorize "${MIB_C_BOLD}${MIB_C_RED}" "$failed_count")"
  fi

  if ((total_files > 0)); then
    local success_rate=$(((success_count * 100) / active_count))
    printf "    %s\n" "$(colorize "$MIB_C_DIM" "───────")"
    printf "    %s  Total:    %s  %s\n" \
      "$(colorize "$MIB_C_CYAN" "$MIB_I_LOZENGE")" \
      "$(colorize "$MIB_C_BOLD" "$active_count")" \
      "$(colorize "$MIB_C_DIM" "(${success_rate}% success)")"
  fi
  printf "\n"

  # ---- transferred list ----
  if ((${#processed_files[@]} > 0)); then
    printf "  %s  Transferred files:\n" "$(colorize "$MIB_C_GREEN" "$MIB_I_TICK")"
    local shown=0
    for f in "${processed_files[@]}"; do
      ((shown >= 10)) && break
      printf "    %s  %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" "$(colorize "$MIB_C_GREEN_BRIGHT" "$f")"
      shown=$((shown + 1))
    done
    if ((${#processed_files[@]} > 10)); then
      printf "    %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ELLIPSIS} and $((${#processed_files[@]} - 10)) more")"
    fi
    printf "\n"
  fi

  # ---- skipped list (grouped exclusions + conflict skips) ----
  if ((${#_excluded_groups[@]} > 0)) || ((${#skipped_list[@]} > 0)); then
    printf "  %s Skipped:\n" "$(colorize "$MIB_C_YELLOW" "$MIB_I_WARNING")"
    local shown=0

    # Excluded groups first
    for grp in "${!_excluded_groups[@]}"; do
      ((shown >= 10)) && break
      local cnt="${_excluded_groups[$grp]}"
      if ((cnt == 1)); then
        printf "    %s  %s\n" \
          "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
          "$(colorize "$MIB_C_YELLOW" "$grp (excluded)")"
      else
        printf "    %s  %s\n" \
          "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" \
          "$(colorize "$MIB_C_YELLOW" "$grp (${cnt} files excluded)")"
      fi
      shown=$((shown + 1))
    done

    # Conflict / already-exists skips
    for f in "${skipped_list[@]}"; do
      ((shown >= 10)) && break
      printf "    %s  %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" "$(colorize "$MIB_C_YELLOW" "$f")"
      shown=$((shown + 1))
    done

    local total_skip_entries=$((${#_excluded_groups[@]} + ${#skipped_list[@]}))
    if ((total_skip_entries > 10)); then
      printf "    %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ELLIPSIS} and $((total_skip_entries - 10)) more")"
    fi
    printf "\n"
  fi
  # ---- failed list ----
  if ((${#failed_files[@]} > 0)); then
    printf "  %s  Failed:\n" "$(colorize "$MIB_C_RED" "$MIB_I_ERROR")"
    for f in "${failed_files[@]}"; do
      printf "    %s  %s\n" "$(colorize "$MIB_C_DIM" "${MIB_I_ARROW}")" "$(colorize "$MIB_C_RED" "$f")"
    done
    printf "\n"
  fi

  if [[ "$MIB_METHOD" == "cp" ]]; then
    msg_info "Originals preserved in: $(colorize "$MIB_C_DIM" "$target")"
    msg_info "Copies now reside in:  $(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$output")"
  else
    msg_info "Files moved from:  $(colorize "$MIB_C_DIM" "$target")"
    msg_info "Files now reside in:  $(colorize "${MIB_C_BOLD}${MIB_C_CYAN}" "$output")"
  fi
  printf "\n"

  if ((failed_count > 0 && success_count > 0)); then
    return 2
  elif ((failed_count > 0)); then
    return 1
  fi
}
mib_main() {
  init_terminal_caps
  init_colors
  init_icons
  move_in_batch "$@"
}
#  11. ENTRY POINT
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  mib_main "$@"
fi
