#!/usr/bin/env bash

IFS=$'\n\t'

#  0.  METADATA
readonly SCRIPT_NAME="Batch File Renamer"
readonly SCRIPT_VERSION="1.0.3"
readonly SCRIPT_URL="https://github.com/Thaton3gu7/Utilitykit.git"

#  1.  TERMINAL CAPABILITY DETECTION
RB_CAP_USE_COLOR=false
RB_CAP_USE_UNICODE=false
RB_CAP_IS_INTERACTIVE=false
OPT_ALLOW_EXCLUDED=false # Global switch for exclusion overrides

init_terminal_caps() {
  if [[ -n "${NO_COLOR:-}" ]]; then
    RB_CAP_USE_COLOR=false
  elif [[ ! -t 1 ]]; then
    RB_CAP_USE_COLOR=false
  else
    RB_CAP_USE_COLOR=true
  fi

  local is_limited=false
  if [[ -n "${ANDROID_ROOT:-}" ]] || [[ "${TERM_PROGRAM:-}" == "Termux" ]] || [[ "${TERM:-}" == "dumb" ]]; then
    is_limited=true
  fi

  if [[ ! -t 1 ]] || [[ "$is_limited" == true ]]; then
    RB_CAP_USE_UNICODE=false
  else
    RB_CAP_USE_UNICODE=true
  fi

  if [[ -t 0 ]]; then
    RB_CAP_IS_INTERACTIVE=true
  else
    RB_CAP_IS_INTERACTIVE=false
  fi
}
#  2.  ANSI ESCAPE CODES
RB_C_RESET=""
RB_C_BOLD=""
RB_C_DIM=""
RB_C_ITALIC=""
RB_C_UNDERLINE=""
RB_C_STRIKETHROUGH=""
RB_C_OVERLINE=""
RB_C_RED=""
RB_C_GREEN=""
RB_C_YELLOW=""
RB_C_BLUE=""
RB_C_MAGENTA=""
RB_C_CYAN=""
RB_C_WHITE=""
RB_C_GRAY=""
RB_C_RED_BRIGHT=""
RB_C_GREEN_BRIGHT=""
RB_C_YELLOW_BRIGHT=""
RB_C_BLUE_BRIGHT=""
RB_C_MAGENTA_BRIGHT=""
RB_C_CYAN_BRIGHT=""
RB_C_WHITE_BRIGHT=""
RB_C_BG_RED=""
RB_C_BG_GREEN=""
RB_C_BG_YELLOW=""
RB_C_BG_BLUE=""
RB_C_BG_CYAN=""
RB_C_BG_GRAY=""

init_colors() {
  if [[ "$RB_CAP_USE_COLOR" == false ]]; then
    RB_C_RESET=""
    RB_C_BOLD=""
    RB_C_DIM=""
    RB_C_ITALIC=""
    RB_C_UNDERLINE=""
    RB_C_STRIKETHROUGH=""
    RB_C_OVERLINE=""
    RB_C_RED=""
    RB_C_GREEN=""
    RB_C_YELLOW=""
    RB_C_BLUE=""
    RB_C_MAGENTA=""
    RB_C_CYAN=""
    RB_C_WHITE=""
    RB_C_GRAY=""
    RB_C_RED_BRIGHT=""
    RB_C_GREEN_BRIGHT=""
    RB_C_YELLOW_BRIGHT=""
    RB_C_BLUE_BRIGHT=""
    RB_C_MAGENTA_BRIGHT=""
    RB_C_CYAN_BRIGHT=""
    RB_C_WHITE_BRIGHT=""
    RB_C_BG_RED=""
    RB_C_BG_GREEN=""
    RB_C_BG_YELLOW=""
    RB_C_BG_BLUE=""
    RB_C_BG_CYAN=""
    RB_C_BG_GRAY=""
  else
    RB_C_RESET=$'\033[0m'
    RB_C_BOLD=$'\033[1m'
    RB_C_DIM=$'\033[2m'
    RB_C_ITALIC=$'\033[3m'
    RB_C_UNDERLINE=$'\033[4m'
    RB_C_STRIKETHROUGH=$'\033[9m'
    RB_C_OVERLINE=$'\033[53m'

    RB_C_RED=$'\033[31m'
    RB_C_GREEN=$'\033[32m'
    RB_C_YELLOW=$'\033[33m'
    RB_C_BLUE=$'\033[34m'
    RB_C_MAGENTA=$'\033[35m'
    RB_C_CYAN=$'\033[36m'
    RB_C_WHITE=$'\033[37m'
    RB_C_GRAY=$'\033[90m'
    RB_C_RED_BRIGHT=$'\033[91m'
    RB_C_GREEN_BRIGHT=$'\033[92m'
    RB_C_YELLOW_BRIGHT=$'\033[93m'
    RB_C_BLUE_BRIGHT=$'\033[94m'
    RB_C_MAGENTA_BRIGHT=$'\033[95m'
    RB_C_CYAN_BRIGHT=$'\033[96m'
    RB_C_WHITE_BRIGHT=$'\033[97m'

    RB_C_BG_RED=$'\033[41m'
    RB_C_BG_GREEN=$'\033[42m'
    RB_C_BG_YELLOW=$'\033[43m'
    RB_C_BG_BLUE=$'\033[44m'
    RB_C_BG_CYAN=$'\033[46m'
    RB_C_BG_GRAY=$'\033[100m'
  fi
}
#  3.  ICON SET  (Unicode → ASCII fallback)
RB_I_INFO=""
RB_I_SUCCESS=""
RB_I_ERROR=""
RB_I_WARNING=""
RB_I_WORKING=""
RB_I_ARROW=""
RB_I_STAR=""
RB_I_BULLET=""
RB_I_COLLAPSED=""
RB_I_BOX_TL=""
RB_I_BOX_TR=""
RB_I_BOX_BL=""
RB_I_BOX_BR=""
RB_I_BOX_H=""
RB_I_BOX_V=""
RB_I_PROG_FILL=""
RB_I_PROG_EMPTY=""
RB_I_CHECK_OFF=""
RB_I_CHECK_ON=""
RB_I_LOZENGE=""
RB_I_PLAY=""
RB_I_TICK=""
RB_I_CROSS=""
RB_I_ELLIPSIS=""
RB_I_SEPARATOR=""
RB_I_GEAR=""
RB_I_SEARCH=""

init_icons() {
  if [[ "$RB_CAP_USE_UNICODE" == true ]]; then
    RB_I_INFO="ℹ"
    RB_I_SUCCESS="✔"
    RB_I_ERROR="✖"
    RB_I_WARNING="⚠"
    RB_I_WORKING="⚙"
    RB_I_ARROW="❯"
    RB_I_STAR="★"
    RB_I_BULLET="●"
    RB_I_COLLAPSED="▸"
    RB_I_BOX_TL="╭"
    RB_I_BOX_TR="╮"
    RB_I_BOX_BL="╰"
    RB_I_BOX_BR="╯"
    RB_I_BOX_H="─"
    RB_I_BOX_V="│"
    RB_I_PROG_FILL="█"
    RB_I_PROG_EMPTY="░"
    RB_I_CHECK_OFF="☐"
    RB_I_CHECK_ON="☒"
    RB_I_LOZENGE="◆"
    RB_I_PLAY="▶"
    RB_I_TICK="✔"
    RB_I_CROSS="✖"
    RB_I_ELLIPSIS="…"
    RB_I_SEPARATOR="╱"
    RB_I_GEAR="⚙"
    RB_I_SEARCH="⌕"
  else
    RB_I_INFO="i"
    RB_I_SUCCESS="[OK]"
    RB_I_ERROR="[ERR]"
    RB_I_WARNING="[ℹ]"
    RB_I_WORKING="[*]"
    RB_I_ARROW=">"
    RB_I_STAR="*"
    RB_I_BULLET="*"
    RB_I_COLLAPSED=">"
    RB_I_BOX_TL="+"
    RB_I_BOX_TR="+"
    RB_I_BOX_BL="+"
    RB_I_BOX_BR="+"
    RB_I_BOX_H="-"
    RB_I_BOX_V="|"
    RB_I_PROG_FILL="#"
    RB_I_PROG_EMPTY="."
    RB_I_CHECK_OFF="[ ]"
    RB_I_CHECK_ON="[x]"
    RB_I_LOZENGE="<>"
    RB_I_PLAY=">"
    RB_I_TICK="[OK]"
    RB_I_CROSS="[ERR]"
    RB_I_ELLIPSIS="..."
    RB_I_SEPARATOR="|"
    RB_I_GEAR="[*]"
    RB_I_SEARCH="?"
  fi
}
#  4.  HELPER FUNCTIONS
colorize() {
  local color="$1"
  local text="$2"
  if [[ "$RB_CAP_USE_COLOR" == true ]]; then
    printf "%s%s%s" "$color" "$text" "$RB_C_RESET"
  else
    printf "%s" "$text"
  fi
}
msg_info() { printf "  %s    %s\n" "$(colorize "$RB_C_BLUE" "$RB_I_INFO")" "$*"; }
msg_success() { printf "  %s %s\n" "$(colorize "$RB_C_GREEN" "$RB_I_SUCCESS")" "$*"; }
msg_error() { printf "  %s   %s\n" "$(colorize "$RB_C_RED" "$RB_I_ERROR")" "$*" >&2; }
msg_warning() { printf "  %s  %s\n" "$(colorize "$RB_C_YELLOW" "$RB_I_WARNING")" "$*"; }
msg_working() { printf "  %s %s\n" "$(colorize "$RB_C_CYAN" "$RB_I_WORKING")" "$*"; }
msg_arrow() { printf "  %s   %s\n" "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_ARROW")" "$*"; }
box_line() {
  local content="$1"
  local width="$2"
  printf "  %s %-*s %s\n" "$RB_I_BOX_V" "$width" "$content" "$RB_I_BOX_V"
}
print_banner() {
  local title="$1"
  local subtitle="${2:-}"
  local maxlen=${#title}
  [[ ${#subtitle} -gt $maxlen ]] && maxlen=${#subtitle}
  local inner_width=$((maxlen + 4))

  local hrule=""
  local i
  for ((i = 0; i < inner_width; i++)); do hrule+="$RB_I_BOX_H"; done

  printf "\n"
  # Top Border
  printf "  %s%s%s\n" "$(colorize "$RB_C_CYAN" "$RB_I_BOX_TL")" "$(colorize "$RB_C_CYAN" "$hrule")" "$(colorize "$RB_C_CYAN" "$RB_I_BOX_TR")"

  # Title Line
  # Calculate right padding using the raw ${#title} to avoid invisible character math
  local title_pad=$((inner_width - 2 - ${#title}))
  printf "  %s  %s%*s%s\n" \
    "$(colorize "$RB_C_CYAN" "$RB_I_BOX_V")" \
    "$(colorize "${RB_C_BOLD}${RB_C_CYAN}" "$title")" \
    "$title_pad" "" \
    "$(colorize "$RB_C_CYAN" "$RB_I_BOX_V")"

  # Subtitle Line (if provided)
  if [[ -n "$subtitle" ]]; then
    local sub_pad=$((inner_width - 2 - ${#subtitle}))
    printf "  %s  %s%*s%s\n" \
      "$(colorize "$RB_C_CYAN" "$RB_I_BOX_V")" \
      "$(colorize "$RB_C_DIM" "$subtitle")" \
      "$sub_pad" "" \
      "$(colorize "$RB_C_CYAN" "$RB_I_BOX_V")"
  fi

  # Bottom Border
  printf "  %s%s%s\n" "$(colorize "$RB_C_CYAN" "$RB_I_BOX_BL")" "$(colorize "$RB_C_CYAN" "$hrule")" "$(colorize "$RB_C_CYAN" "$RB_I_BOX_BR")"
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
#  5.  PROGRESS BAR  (single-line, in-place, no cursor tricks)
draw_progress() {
  local current="$1"
  local total="$2"
  local label="$3"

  ((total == 0)) && return

  # 1. Get terminal width dynamically (fallback to 80 if unsupported)
  local term_width=$(tput cols 2>/dev/null || echo 80)

  # 2. Scale the progress bar based on screen size, keeping it within sensible limits
  local bar_width=$((term_width / 4))
  ((bar_width > 30)) && bar_width=30
  ((bar_width < 10)) && bar_width=10

  local pct=$((current * 100 / total))
  local filled=$((current * bar_width / total))
  local empty=$((bar_width - filled))

  local bar=""
  local i
  for ((i = 0; i < filled; i++)); do bar+="$RB_I_PROG_FILL"; done
  for ((i = 0; i < empty; i++)); do bar+="$RB_I_PROG_EMPTY"; done

  # 3. Calculate exactly how many characters the static UI elements take up
  # Padding(2) + Gear(1) + Brackets(2) + Spaces(8) + % + Fractions
  local ui_reserved=$((14 + bar_width + 3 + ${#current} + ${#total}))

  # 4. Calculate available space for the filename label
  local max_label_len=$((term_width - ui_reserved))

  local display_label="$label"
  if ((max_label_len < 5)); then
    display_label="" # Screen is extremely narrow, hide the text to save the UI
  elif ((${#display_label} > max_label_len)); then
    display_label="${display_label:0:$((max_label_len - 3))}..."
  fi

  # 5. Print out the bar exactly as before
  if [[ "$RB_CAP_USE_COLOR" == true ]]; then
    local prog_color="$RB_C_CYAN"
    if ((pct >= 100)); then
      prog_color="$RB_C_GREEN"
    elif ((pct >= 66)); then
      prog_color="$RB_C_GREEN_BRIGHT"
    elif ((pct >= 33)); then
      prog_color="$RB_C_YELLOW"
    fi

    local gear_colored="$(colorize "$RB_C_CYAN" "$RB_I_GEAR")"
    local bar_colored="$(colorize "$prog_color" "$bar")"

    printf "%s" $'\033[2K\r'
    printf "  %s%s%s[%s]%s %s%3d%%%s  %s%d/%d%s  %s%s%s" \
      "$RB_C_DIM" "$gear_colored" "$RB_C_DIM" \
      "$bar_colored" \
      "$RB_C_DIM" "$RB_C_BOLD" "$pct" "$RB_C_RESET" \
      "$RB_C_DIM" "$current" "$total" "$RB_C_RESET" \
      "$RB_C_DIM" "$display_label" "$RB_C_RESET"
  else
    printf "%s" $'\033[2K\r'
    printf "  %s [%s] %3d%%  %d/%d  %s" \
      "$RB_I_GEAR" "$bar" "$pct" "$current" "$total" "$display_label"
  fi
}
#  6.  FILENAME COMPUTATION & EXTENSION NORMALISATION
normalize_extension() {
  local ext="$1"
  ext="${ext#.}"
  printf "%s" "$ext"
}
is_excluded_file() {
  # If the user forced the operation, nothing is excluded
  [[ "$OPT_ALLOW_EXCLUDED" == true ]] && return 1

  local filepath="$1"
  local base_name
  base_name="$(basename "$filepath")"

  # 1. Check exact filenames (lowercased for safety)
  local lower_base="${base_name,,}"
  case "$lower_base" in
  license | licence | copying | notice | readme | changelog | contributing | makefile | dockerfile | containerfile)
    return 0 # In Bash, 0 means "Success/True"
    ;;
  package-lock.json | yarn.lock | cargo.lock | pnpm-lock.yaml | composer.lock)
    return 0
    ;;
  esac

  # 2. Check by file extensions
  if [[ "$base_name" == *.* ]]; then
    local ext="${base_name##*.}"
    case "${ext,,}" in
    md | json | yaml | yml | toml | xml | ini | conf | html | log | lock)
      return 0
      ;;
    esac
  fi

  return 1 # 1 means "False/No Match"
}
compute_new_name() {
  local filepath="$1"
  local new_ext="$2"
  local output_dir="$3"
  local basename
  basename="$(basename "$filepath")"

  local name_part

  if [[ "$basename" != *.* ]]; then
    name_part="$basename"
  else
    if [[ "$basename" =~ ^\.[^.]+$ ]]; then
      name_part="$basename"
    else
      name_part="${basename%.*}"
      if [[ -z "$name_part" ]]; then
        name_part="$basename"
      fi
    fi
  fi

  local new_name="${name_part}.${new_ext}"
  local dest="${output_dir}/${new_name}"

  local counter=1
  while [[ -e "$dest" ]]; do
    new_name="${name_part}_${counter}.${new_ext}"
    dest="${output_dir}/${new_name}"
    counter=$((counter + 1))
  done

  printf "%s\n" "$dest"
}
compute_copy_destination() {
  local filepath="$1"
  local new_ext="$2"
  local source_dir="$3"
  local output_dir="$4"
  local rel_path rel_dir target_dir

  rel_path="${filepath#"$source_dir"/}"
  rel_dir="$(dirname "$rel_path")"
  if [[ "$rel_dir" == "." ]]; then
    target_dir="$output_dir"
  else
    target_dir="$output_dir/$rel_dir"
  fi

  compute_new_name "$filepath" "$new_ext" "$target_dir"
}
already_has_extension() {
  local filepath="$1"
  local new_ext="$2"
  local basename
  basename="$(basename "$filepath")"

  [[ "$basename" != *.* ]] && return 1

  local current_ext="${basename##*.}"
  [[ "$current_ext" == "$new_ext" ]]
}
#  7.  HELP & VERSION
show_help() {
  print_banner "$SCRIPT_NAME" "v${SCRIPT_VERSION}"

  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "USAGE")"
  printf "\n"
  printf "    %s %s %s %s %s\n" "$(colorize "$RB_C_CYAN" "  $0")" "$(colorize "$RB_C_GREEN" "<source_dir>")" "$(colorize "$RB_C_YELLOW" "<new_extension>")" "$(colorize "$RB_C_GRAY" "[output_dir]")" "$(colorize "$RB_C_CYAN" "[flags]")"
  printf "    %s %s\n" "$(colorize "$RB_C_CYAN" "  $0")" "$(colorize "$RB_C_DIM" "(runs Interactive Wizard if executed without arguments)")"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "DESCRIPTION")"
  printf "\n"
  printf "    Recursively rename all non-hidden files in <source_dir> (and all\n"
  printf "    subdirectories) to a new file extension.\n"
  printf "\n"
  printf "    In-place mode (2 args):  Files are renamed where they sit.\n"
  printf "    Copy mode    (3 args):  Files are COPIED to output_dir with new names.\n"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "ARGUMENTS")"
  printf "\n"
  printf "    %-18s %s\n" "$(colorize "$RB_C_GREEN" "source_dir")" "Directory to scan"
  printf "    %-18s %s\n" "$(colorize "$RB_C_YELLOW" "new_extension")" "Target extension (e.g. txt, md, py)"
  printf "    %-18s %s\n" "$(colorize "$RB_C_GRAY" "output_dir")" "(Optional) destination directory"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "OPTIONS / FLAGS")"
  printf "\n"
  printf "    %-18s %s\n" "$(colorize "$RB_C_CYAN" "-f, --force, --all")" "Force process protected files (README, LICENSE, etc.)"
  printf "    %-18s %s\n" "$(colorize "$RB_C_CYAN" "-h, --help")" "Show this message"
  printf "    %-18s %s\n" "$(colorize "$RB_C_CYAN" "-v, --version")" "Show version info"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "EXAMPLES")"
  printf "\n"
  printf "    %s\n" "$(colorize "$RB_C_DIM" "# Rename everything in ./ProjectR to .txt")"
  printf "    %s\n" "$(colorize "$RB_C_GREEN" "  $0 ./ProjectR txt")"
  printf "\n"
  printf "    %s\n" "$(colorize "$RB_C_DIM" "# Copy+rename to ./renamed-files")"
  printf "    %s\n" "$(colorize "$RB_C_GREEN" "  $0 ./ProjectR md ./renamed-files")"
  printf "\n"
  printf "    %s\n" "$(colorize "$RB_C_DIM" "# Force change extensions on every file, including Markdown files")"
  printf "    %s\n" "$(colorize "$RB_C_GREEN" "  $0 . bak --force")"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "EXIT CODES")"
  printf "\n"
  printf "    %s   %s\n" "$(colorize "$RB_C_GREEN" "0")" "All good (or all skipped)"
  printf "    %s   %s\n" "$(colorize "$RB_C_RED" "1")" "Fatal error (bad args, missing dir, ...)"
  printf "    %s   %s\n" "$(colorize "$RB_C_YELLOW" "2")" "Partial failure (some files failed)"
  printf "\n"
  printf "  %s\n" "$(colorize "${RB_C_BOLD}${RB_C_WHITE}" "ENVIRONMENT")"
  printf "\n"
  printf "    %s   %s\n" "$(colorize "$RB_C_CYAN" "NO_COLOR")" "Set to any value to disable ANSI"
  printf "\n"
}

show_version() {
  printf "%s %s\n" "$(colorize "${RB_C_BOLD}${RB_C_CYAN}" "$SCRIPT_NAME")" "$(colorize "$RB_C_GREEN" "v${SCRIPT_VERSION}")"
  printf "%s\n" "$(colorize "$RB_C_DIM" "$SCRIPT_URL")"
  printf "\n"
  printf "  Bash:          %s\n" "${BASH_VERSION}"
  printf "  Unicode:       %s\n" "$([[ "$RB_CAP_USE_UNICODE" == true ]] && echo "enabled" || echo "disabled")"
  printf "  Color:         %s\n" "$([[ "$RB_CAP_USE_COLOR" == true ]] && echo "enabled" || echo "disabled")"
  printf "  Interactive:   %s\n" "$([[ "$RB_CAP_IS_INTERACTIVE" == true ]] && echo "yes" || echo "no")"
}
#  8.  MAIN
rb_file_size() {
  local path="$1"
  stat -c '%s' -- "$path" 2>/dev/null || stat -f '%z' -- "$path" 2>/dev/null || wc -c <"$path"
}

rb_scan_files() {
  local source_dir="$1" filepath file_size
  if find "$source_dir" -type f -printf '' >/dev/null 2>&1; then
    find "$source_dir" -type f ! -path '*/\.*' -printf '%p\t%s\0' 2>/dev/null | sort -z
  else
    while IFS= read -r -d '' filepath; do
      file_size="$(rb_file_size "$filepath" 2>/dev/null || printf '0')"
      printf '%s\t%s\0' "$filepath" "$file_size"
    done < <(find "$source_dir" -type f ! -path '*/\.*' -print0 2>/dev/null | sort -z)
  fi
}
rb_main() {
  init_terminal_caps
  init_colors
  init_icons
  # 1. Parse incoming script flags and parameters
  local positional_args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      show_help
      exit 0
      ;;
    -v | --version)
      show_version
      exit 0
      ;;
    -f | --force | --all)
      OPT_ALLOW_EXCLUDED=true
      shift
      ;;
    *)
      positional_args+=("$1")
      shift
      ;;
    esac
  done

  # Structural tracking initializations
  local excluded_skipped=0
  declare -a ROLLBACK_SRC=()
  declare -a ROLLBACK_DST=()

  local source_dir=""
  local new_ext_raw=""
  local output_dir=""
  local mode="in-place"

  # 2. Dynamic Fallback to Conversational Menu if executed without target args
  if [[ ${#positional_args[@]} -eq 0 ]]; then
    if [[ "$RB_CAP_IS_INTERACTIVE" == false ]]; then
      msg_error "Non-interactive environment detected and no parameters supplied."
      msg_info "Usage: $0 <source_dir> <new_extension> [output_dir]"
      exit 1
    fi

    print_banner "Interactive Configuration" "UtilityKit Script Wizard Fallback"

    printf "  %s  Enter target directory to process [default: .] \n  %s " "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_ARROW")" "$(colorize "$RB_C_DIM" "> ")"
    read -r source_dir
    source_dir="${source_dir:-.}"

    printf "  %s  Enter target new extension format (e.g. sh, py, txt) \n  %s " "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_ARROW")" "$(colorize "$RB_C_DIM" "> ")"
    read -r new_ext_raw
    while [[ -z "$new_ext_raw" ]]; do
      msg_warning "Target configuration format extension cannot be blank."
      printf "  %s " "$(colorize "$RB_C_DIM" "> ")"
      read -r new_ext_raw
    done

    printf "  %s  Enter output export directory (Optional: leave blank for in-place) \n  %s " "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_ARROW")" "$(colorize "$RB_C_DIM" "> ")"
    read -r output_dir
  else
    # Fallback to normal CLI processing if parameters are present
    if [[ ${#positional_args[@]} -lt 2 ]]; then
      msg_error "Missing required parameters. Expected: <source_dir> <new_extension> [output_dir]"
      msg_info "Try '$0 --help' for syntax options."
      exit 1
    fi
    source_dir="${positional_args[0]}"
    new_ext_raw="${positional_args[1]}"
    output_dir="${positional_args[2]:-}"
  fi

  # 3. Path & Normalization Logic Continues ...
  local new_ext
  new_ext="$(normalize_extension "$new_ext_raw")"

  if [[ -z "$output_dir" ]]; then
    mode="in-place"
  elif [[ "$source_dir" == "$output_dir" ]]; then
    msg_warning "Source and output directories are identical — switching to in-place mode."
    mode="in-place"
    output_dir=""
  else
    mode="copy"
  fi

  msg_working "Scanning for files in $(colorize "${RB_C_BOLD}${RB_C_CYAN}" "$source_dir") ..."

  local file_old_names=()
  local total_size=0
  local file_count=0

  # High-Performance Scan: Zero external process forks inside the loop!
  while IFS=$'\t' read -r -d '' filepath file_size; do
    local base="${filepath##*/}"

    [[ "$base" == .* ]] && continue
    [[ ! -f "$filepath" ]] && continue

    file_old_names+=("$filepath")
    total_size=$((total_size + file_size))
    file_count=$((file_count + 1))
  done < <(rb_scan_files "$source_dir")

  if ((file_count == 0)); then
    msg_warning "No files found in $(colorize "$RB_C_BOLD" "$source_dir")"
    print_banner "Operation Summary" "Nothing to process"
    printf "  %s  0 files processed\n" "$(colorize "$RB_C_GREEN" "$RB_I_TICK")"
    exit 0
  fi

  local dest_names=()
  local conflicts=0
  local already_skipped=0

  for filepath in "${file_old_names[@]}"; do
    if already_has_extension "$filepath" "$new_ext"; then
      dest_names+=("$filepath")
      already_skipped=$((already_skipped + 1))
      continue
    fi

    if is_excluded_file "$filepath"; then
      dest_names+=("$filepath")
      excluded_skipped=$((excluded_skipped + 1))
      continue
    fi

    local dest
    if [[ "$mode" == "copy" ]]; then
      dest="$(compute_copy_destination "$filepath" "$new_ext" "$source_dir" "$output_dir")"
    else
      local dir
      dir="$(dirname "$filepath")"
      dest="$(compute_new_name "$filepath" "$new_ext" "$dir")"
    fi
    dest_names+=("$dest")

    local base_dest
    base_dest="$(basename "$dest")"
    local base_orig
    base_orig="$(basename "$filepath")"
    local expected="${base_orig%.*}.${new_ext}"
    if [[ "$base_dest" != "$expected" ]] && [[ "$base_dest" != "$base_orig" ]]; then
      conflicts=$((conflicts + 1))
    fi
  done

  local total_files=${#file_old_names[@]}
  local active_count=$((total_files - already_skipped - excluded_skipped))

  local mode_label="In-place rename"
  [[ "$mode" == "copy" ]] && mode_label="Copy + rename → $(colorize "$RB_C_CYAN" "$output_dir")"

  print_banner "Batch Rename Operation" "v${SCRIPT_VERSION}"

  msg_info "Source:      $(colorize "$RB_C_BOLD" "$source_dir")"
  msg_info "Extension:   $(colorize "${RB_C_BOLD}${RB_C_YELLOW}" ".${new_ext}")"
  msg_info "Mode:        ${mode_label}"
  msg_info "Files found: $(colorize "${RB_C_BOLD}${RB_C_WHITE}" "$total_files")"
  msg_info "Total size:  $(colorize "$RB_C_DIM" "$(format_size "$total_size")")"

  if ((already_skipped > 0)); then
    msg_info "Already .${new_ext}: $(colorize "$RB_C_DIM" "$already_skipped") (will be skipped)"
  fi

  if ((active_count == 0)); then
    printf "\n"
    msg_warning "All files already have the .${new_ext} extension — nothing to do."
    exit 0
  fi

  if ((conflicts > 0)); then
    msg_warning "Conflicts to resolve: $(colorize "$RB_C_YELLOW_BRIGHT" "$conflicts") file(s) will be auto-renamed (_1, _2, …)"
  fi

  printf "\n"

  # 1. Initialize budget tracking counters
  local idx=0
  local total_printed=0
  local exclusions_printed=0
  local actionable_printed=0

  # 2. Set quotas (adjust these numbers to change your preview balance)
  local max_exclusions=4
  local max_actionable=6

  printf "  %s  %s %s\n" "$(colorize "$RB_C_BLUE_BRIGHT" "$RB_I_COLLAPSED")" "$(colorize "$RB_C_BOLD" "Preview")" "$(colorize "$RB_C_DIM" "(balanced summary of discovered files):")"

  # 3. Dynamic search loop
  while ((idx < total_files)); do
    # Break early if we have completely satisfied both quotas
    if ((exclusions_printed >= max_exclusions && actionable_printed >= max_actionable)); then
      break
    fi

    local src_name="$(basename "${file_old_names[$idx]}")"
    local dst_name="$(basename "${dest_names[$idx]}")"
    local src_rel="${file_old_names[$idx]#"$source_dir"/}"
    [[ "$src_rel" == "${file_old_names[$idx]}" ]] && src_rel="$src_name"
    local dst_rel="$dst_name"
    if [[ "$mode" == "copy" && -n "$output_dir" ]]; then
      dst_rel="${dest_names[$idx]#"$output_dir"/}"
    elif [[ "$mode" == "in-place" ]]; then
      dst_rel="${dest_names[$idx]#"$source_dir"/}"
      [[ "$dst_rel" == "${dest_names[$idx]}" ]] && dst_rel="$dst_name"
    fi

    # Determine file status
    local is_ex=false
    if is_excluded_file "${file_old_names[$idx]}"; then
      is_ex=true
    fi

    # 4. Quota Filtering Logic
    local should_print=false
    if [[ "$is_ex" == true ]]; then
      if ((exclusions_printed < max_exclusions)); then
        should_print=true
      fi
    else
      if ((actionable_printed < max_actionable)); then
        should_print=true
      fi
    fi

    # 5. Render lines matching the allowed budget
    if [[ "$should_print" == true ]]; then
      total_printed=$((total_printed + 1))

      if [[ "$is_ex" == true ]]; then
        exclusions_printed=$((exclusions_printed + 1))
        printf "    %s %s %s\n" \
          "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" \
          "$(colorize "$RB_C_GRAY" "$src_rel")" \
          "$(colorize "$RB_C_YELLOW" "(excluded)")"
      else
        actionable_printed=$((actionable_printed + 1))
        printf "    %s %s %s %s\n" \
          "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" \
          "$(colorize "$RB_C_GRAY" "$src_rel")" \
          "$(colorize "$RB_C_CYAN" " ──→ ")" \
          "$(colorize "$RB_C_GREEN_BRIGHT" "$dst_rel")"
      fi
    fi

    idx=$((idx + 1))
  done

  # 6. Correctly calculate the unprinted remainder
  local remaining=$((total_files - total_printed))
  if ((remaining > 0)); then
    printf "    %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ELLIPSIS} and ${remaining} more file(s)")"
  fi

  printf "\n"

  if [[ "$RB_CAP_IS_INTERACTIVE" == true ]]; then
    local proceed=""
    printf "  %s  Proceed with %s? %s %s" \
      "$(colorize "${RB_C_BOLD}${RB_C_YELLOW}" "$RB_I_PLAY")" \
      "$(colorize "$RB_C_BOLD" "$mode_label")" \
      "$(colorize "$RB_C_GREEN" "[Y/n]")" \
      "$(colorize "$RB_C_DIM" "> ")"
    read -r proceed
    case "${proceed,,}" in
    n | no)
      printf "\n"
      msg_warning "Operation cancelled by user."
      exit 0
      ;;
    esac
    printf "\n"
  fi

  local success_count=0
  local failed_count=0
  local skipped_count=0
  local renamed_files=()
  local failed_files=()
  local skipped_list=()

  local start_time
  start_time=$(date +%s)

  handle_interrupt() {
    # Immediately disable the trap so a second Ctrl+C actually kills the script
    trap - SIGINT

    printf "\n\n"
    msg_warning "Process interrupted by user (Ctrl+C)!"

    local count=${#ROLLBACK_SRC[@]}
    if ((count == 0)); then
      msg_info "No files were modified yet. Exiting safely."
      exit 130
    fi

    printf "  %s  %d file(s) have already been processed.\n" "$(colorize "$RB_C_YELLOW" "$RB_I_WARNING")" "$count"

    if [[ "$RB_CAP_IS_INTERACTIVE" == true ]]; then
      local proceed=""
      printf "  %s  Do you want to roll back these changes? %s %s" \
        "$(colorize "${RB_C_BOLD}${RB_C_YELLOW}" "$RB_I_SEARCH")" \
        "$(colorize "$RB_C_GREEN" "[Y/n]")" \
        "$(colorize "$RB_C_DIM" "> ")"
      read -r proceed
      case "${proceed,,}" in
      y | yes | "")
        msg_working "Rolling back changes..."
        local fails=0

        # Loop backward through our history
        for ((i = ${#ROLLBACK_SRC[@]} - 1; i >= 0; i--)); do
          local r_src="${ROLLBACK_SRC[$i]}"
          local r_dst="${ROLLBACK_DST[$i]}"

          if [[ "$mode" == "copy" ]]; then
            # Reversing a copy means deleting the new file
            rm -f "$r_dst" || fails=$((fails + 1))
          else
            # Reversing a rename means moving it back
            mv -- "$r_dst" "$r_src" || fails=$((fails + 1))
          fi
        done

        if ((fails > 0)); then
          msg_error "Rollback completed with $fails error(s)."
        else
          msg_success "Rollback successful. Original state restored."
        fi
        ;;
      *)
        msg_info "Keeping changes. Exiting."
        ;;
      esac
    fi
    exit 130
  }

  msg_working "Processing $(colorize "$RB_C_BOLD" "$active_count") file(s)..."
  printf "\n"

  local progress_current=0

  # Activate the trap right before the loop starts
  trap 'handle_interrupt' SIGINT

  for ((idx = 0; idx < total_files; idx++)); do
    local src="${file_old_names[$idx]}"
    local dst="${dest_names[$idx]}"
    local src_name
    src_name="$(basename "$src")"
    local dst_name
    dst_name="$(basename "$dst")"

    if [[ "$src" == "$dst" ]]; then
      skipped_count=$((skipped_count + 1))

      # Use your helper function to tag the reason accurately in the summary
      if is_excluded_file "$src"; then
        skipped_list+=("$src_name (excluded)")
      else
        skipped_list+=("$src_name (already .${new_ext})")
      fi
      continue
    fi

    progress_current=$((progress_current + 1))
    draw_progress "$progress_current" "$active_count" "$src_name"

    if [[ -e "$dst" ]]; then
      skipped_count=$((skipped_count + 1))
      skipped_list+=("$src_name (destination exists)")
      continue
    fi

    local op_status=0
    mkdir -p "$(dirname "$dst")"
    if [[ "$mode" == "copy" ]]; then
      if cp -- "$src" "$dst"; then
        : # success
      else
        op_status=$?
      fi
    else
      if mv -- "$src" "$dst"; then
        : # success
      else
        op_status=$?
      fi
    fi

    if ((op_status == 0)); then
      success_count=$((success_count + 1))
      renamed_files+=("$dst_name")
      # Track the exact paths for a potential rollback
      ROLLBACK_SRC+=("$src")
      ROLLBACK_DST+=("$dst")
    else
      failed_count=$((failed_count + 1))
      failed_files+=("$src_name (exit: ${op_status})")
      # Clear the progress line before printing the error
      printf "%s" $'\033[2K\r'
      msg_error "Failed: $(colorize "$RB_C_BOLD" "$src") → $(colorize "$RB_C_BOLD" "$dst") (exit: ${op_status})"
    fi
  done

  # Final draw at 100%, then move to a new line
  draw_progress "$active_count" "$active_count" "Complete"
  printf "\n\n"

  # Deactivate the trap
  trap - SIGINT

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  print_banner "Operation Complete" "Processed in $(format_duration "$duration")"

  printf "  %s  %s\n" "$(colorize "$RB_C_GREEN" "$RB_I_TICK")" "$(colorize "$RB_C_BOLD" "Summary")"
  printf "\n"
  printf "    %s  Success:  %s\n" "$(colorize "$RB_C_GREEN" "$RB_I_SUCCESS")" "$(colorize "${RB_C_BOLD}${RB_C_GREEN}" "$success_count")"
  printf "    %s   Skipped:  %s\n" "$(colorize "$RB_C_YELLOW" "$RB_I_WARNING")" "$(colorize "${RB_C_BOLD}${RB_C_YELLOW}" "$skipped_count")"
  printf "    %s  Failed:   %s\n" "$(colorize "$RB_C_RED" "$RB_I_ERROR")" "$(colorize "${RB_C_BOLD}${RB_C_RED}" "$failed_count")"
  if ((total_files > 0)); then
    local success_rate=$(((success_count * 100) / total_files))
    printf "    %s\n" "$(colorize "$RB_C_DIM" "───────")"
    printf "    %s  Total:    %s  %s\n" "$(colorize "$RB_C_CYAN" "$RB_I_LOZENGE")" "$(colorize "$RB_C_BOLD" "$total_files")" "$(colorize "$RB_C_DIM" "(${success_rate}% success)")"
  fi
  printf "\n"

  if ((${#renamed_files[@]} > 0)); then
    printf "  %s  Renamed files:\n" "$(colorize "$RB_C_GREEN" "$RB_I_TICK")"
    local shown=0
    for f in "${renamed_files[@]}"; do
      ((shown >= 10)) && break
      printf "    %s  %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" "$(colorize "$RB_C_GREEN_BRIGHT" "$f")"
      shown=$((shown + 1))
    done
    if ((${#renamed_files[@]} > 10)); then
      printf "    %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ELLIPSIS} and $((${#renamed_files[@]} - 10)) more")"
    fi
    printf "\n"
  fi

  if ((${#skipped_list[@]} > 0)); then
    printf "  %s Skipped:\n" "$(colorize "$RB_C_YELLOW" "$RB_I_WARNING")"
    local shown=0
    for f in "${skipped_list[@]}"; do
      ((shown >= 10)) && break
      printf "    %s  %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" "$(colorize "$RB_C_YELLOW" "$f")"
      shown=$((shown + 1))
    done
    if ((${#skipped_list[@]} > 10)); then
      printf "    %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ELLIPSIS} and $((${#skipped_list[@]} - 10)) more")"
    fi
    printf "\n"
  fi

  if ((${#failed_files[@]} > 0)); then
    printf "  %s  Failed:\n" "$(colorize "$RB_C_RED" "$RB_I_ERROR")"
    for f in "${failed_files[@]}"; do
      printf "    %s  %s\n" "$(colorize "$RB_C_DIM" "${RB_I_ARROW}")" "$(colorize "$RB_C_RED" "$f")"
    done
    printf "\n"
  fi

  if [[ "$mode" == "copy" ]]; then
    msg_info "Originals preserved in: $(colorize "$RB_C_DIM" "$source_dir")"
    msg_info "Renamed copies in:    $(colorize "${RB_C_BOLD}${RB_C_CYAN}" "$output_dir")"
  else
    msg_info "Files renamed in-place at: $(colorize "$RB_C_DIM" "$source_dir")"
  fi
  printf "\n"

  if ((failed_count > 0 && success_count > 0)); then
    exit 2
  elif ((failed_count > 0)); then
    exit 1
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  rb_main "$@"
fi
