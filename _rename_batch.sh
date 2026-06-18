#!/usr/bin/env bash
# ==============================================================================
#  rename-batch.sh — Batch File Renamer  v3.0.3
# ==============================================================================
#  Recursively rename (or copy+rename) all non-hidden files in a directory
#  tree to a new extension, with interactive confirmation, live progress
#  bar, conflict resolution, and a full summary report.
#
#  Usage:  ./rename-batch.sh <source_dir> <new_extension> [output_dir]
#          ./rename-batch.sh --help
#          ./rename-batch.sh --version
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
#  0.  METADATA
# ==============================================================================
readonly SCRIPT_NAME="Batch File Renamer"
readonly SCRIPT_VERSION="3.0.3"
readonly SCRIPT_URL="https://github.com/Thaton3gu7/Utilitykit.git"

# ==============================================================================
#  1.  TERMINAL CAPABILITY DETECTION
# ==============================================================================
CAP_USE_COLOR=false
CAP_USE_UNICODE=false
CAP_IS_INTERACTIVE=false

init_terminal_caps() {
    if [[ -n "${NO_COLOR:-}" ]]; then
        CAP_USE_COLOR=false
    elif [[ ! -t 1 ]]; then
        CAP_USE_COLOR=false
    else
        CAP_USE_COLOR=true
    fi

    local is_limited=false
    if [[ -n "${ANDROID_ROOT:-}" ]] || [[ "${TERM_PROGRAM:-}" == "Termux" ]] || [[ "${TERM:-}" == "dumb" ]]; then
        is_limited=true
    fi

    if [[ ! -t 1 ]] || [[ "$is_limited" == true ]]; then
        CAP_USE_UNICODE=false
    else
        CAP_USE_UNICODE=true
    fi

    if [[ -t 0 ]]; then
        CAP_IS_INTERACTIVE=true
    else
        CAP_IS_INTERACTIVE=false
    fi
}

init_terminal_caps

# ==============================================================================
#  2.  ANSI ESCAPE CODES
# ==============================================================================
C_RESET=""
C_BOLD=""
C_DIM=""
C_ITALIC=""
C_UNDERLINE=""
C_STRIKETHROUGH=""
C_OVERLINE=""
C_RED=""
C_GREEN=""
C_YELLOW=""
C_BLUE=""
C_MAGENTA=""
C_CYAN=""
C_WHITE=""
C_GRAY=""
C_RED_BRIGHT=""
C_GREEN_BRIGHT=""
C_YELLOW_BRIGHT=""
C_BLUE_BRIGHT=""
C_MAGENTA_BRIGHT=""
C_CYAN_BRIGHT=""
C_WHITE_BRIGHT=""
C_BG_RED=""
C_BG_GREEN=""
C_BG_YELLOW=""
C_BG_BLUE=""
C_BG_CYAN=""
C_BG_GRAY=""

init_colors() {
    if [[ "$CAP_USE_COLOR" == false ]]; then
        C_RESET="" ; C_BOLD="" ; C_DIM="" ; C_ITALIC="" ; C_UNDERLINE=""
        C_STRIKETHROUGH="" ; C_OVERLINE=""
        C_RED="" ; C_GREEN="" ; C_YELLOW="" ; C_BLUE="" ; C_MAGENTA=""
        C_CYAN="" ; C_WHITE="" ; C_GRAY=""
        C_RED_BRIGHT="" ; C_GREEN_BRIGHT="" ; C_YELLOW_BRIGHT=""
        C_BLUE_BRIGHT="" ; C_MAGENTA_BRIGHT="" ; C_CYAN_BRIGHT="" ; C_WHITE_BRIGHT=""
        C_BG_RED="" ; C_BG_GREEN="" ; C_BG_YELLOW="" ; C_BG_BLUE=""
        C_BG_CYAN="" ; C_BG_GRAY=""
    else
        C_RESET=$'\033[0m'
        C_BOLD=$'\033[1m'
        C_DIM=$'\033[2m'
        C_ITALIC=$'\033[3m'
        C_UNDERLINE=$'\033[4m'
        C_STRIKETHROUGH=$'\033[9m'
        C_OVERLINE=$'\033[53m'

        C_RED=$'\033[31m'
        C_GREEN=$'\033[32m'
        C_YELLOW=$'\033[33m'
        C_BLUE=$'\033[34m'
        C_MAGENTA=$'\033[35m'
        C_CYAN=$'\033[36m'
        C_WHITE=$'\033[37m'
        C_GRAY=$'\033[90m'
        C_RED_BRIGHT=$'\033[91m'
        C_GREEN_BRIGHT=$'\033[92m'
        C_YELLOW_BRIGHT=$'\033[93m'
        C_BLUE_BRIGHT=$'\033[94m'
        C_MAGENTA_BRIGHT=$'\033[95m'
        C_CYAN_BRIGHT=$'\033[96m'
        C_WHITE_BRIGHT=$'\033[97m'

        C_BG_RED=$'\033[41m'
        C_BG_GREEN=$'\033[42m'
        C_BG_YELLOW=$'\033[43m'
        C_BG_BLUE=$'\033[44m'
        C_BG_CYAN=$'\033[46m'
        C_BG_GRAY=$'\033[100m'
    fi
}

init_colors

# ==============================================================================
#  3.  ICON SET  (Unicode → ASCII fallback)
# ==============================================================================
I_INFO=""
I_SUCCESS=""
I_ERROR=""
I_WARNING=""
I_WORKING=""
I_ARROW=""
I_STAR=""
I_BULLET=""
I_COLLAPSED=""
I_BOX_TL=""
I_BOX_TR=""
I_BOX_BL=""
I_BOX_BR=""
I_BOX_H=""
I_BOX_V=""
I_PROG_FILL=""
I_PROG_EMPTY=""
I_CHECK_OFF=""
I_CHECK_ON=""
I_LOZENGE=""
I_PLAY=""
I_TICK=""
I_CROSS=""
I_ELLIPSIS=""
I_SEPARATOR=""
I_GEAR=""
I_SEARCH=""

init_icons() {
    if [[ "$CAP_USE_UNICODE" == true ]]; then
        I_INFO="ℹ"
        I_SUCCESS="✔"
        I_ERROR="✖"
        I_WARNING="⚠"
        I_WORKING="⚙"
        I_ARROW="❯"
        I_STAR="★"
        I_BULLET="●"
        I_COLLAPSED="▸"
        I_BOX_TL="╭"
        I_BOX_TR="╮"
        I_BOX_BL="╰"
        I_BOX_BR="╯"
        I_BOX_H="─"
        I_BOX_V="│"
        I_PROG_FILL="█"
        I_PROG_EMPTY="░"
        I_CHECK_OFF="☐"
        I_CHECK_ON="☒"
        I_LOZENGE="◆"
        I_PLAY="▶"
        I_TICK="✔"
        I_CROSS="✘"
        I_ELLIPSIS="…"
        I_SEPARATOR="╱"
        I_GEAR="⚙"
        I_SEARCH="⌕"
    else
        I_INFO="i"
        I_SUCCESS="[OK]"
        I_ERROR="[ERR]"
        I_WARNING="[!]"
        I_WORKING="[*]"
        I_ARROW=">"
        I_STAR="*"
        I_BULLET="*"
        I_COLLAPSED=">"
        I_BOX_TL="+"
        I_BOX_TR="+"
        I_BOX_BL="+"
        I_BOX_BR="+"
        I_BOX_H="-"
        I_BOX_V="|"
        I_PROG_FILL="#"
        I_PROG_EMPTY="."
        I_CHECK_OFF="[ ]"
        I_CHECK_ON="[x]"
        I_LOZENGE="<>"
        I_PLAY=">"
        I_TICK="[OK]"
        I_CROSS="[ERR]"
        I_ELLIPSIS="..."
        I_SEPARATOR="|"
        I_GEAR="[*]"
        I_SEARCH="?"
    fi
}

init_icons

# ==============================================================================
#  4.  HELPER FUNCTIONS
# ==============================================================================

colorize() {
    local color="$1"
    local text="$2"
    if [[ "$CAP_USE_COLOR" == true ]]; then
        printf "%s%s%s" "$color" "$text" "$C_RESET"
    else
        printf "%s" "$text"
    fi
}

msg_info()    { printf "  %s    %s\n" "$(colorize "$C_BLUE"  "$I_INFO")" "$*"; }
msg_success() { printf "  %s %s\n" "$(colorize "$C_GREEN" "$I_SUCCESS")" "$*"; }
msg_error()   { printf "  %s   %s\n" "$(colorize "$C_RED"   "$I_ERROR")" "$*" >&2; }
msg_warning() { printf "  %s  %s\n" "$(colorize "$C_YELLOW" "$I_WARNING")" "$*"; }
msg_working() { printf "  %s %s\n" "$(colorize "$C_CYAN"  "$I_WORKING")" "$*"; }
msg_arrow()   { printf "  %s   %s\n" "$(colorize "$C_BLUE_BRIGHT" "$I_ARROW")" "$*"; }

box_line() {
    local content="$1"
    local width="$2"
    printf "  %s %-*s %s\n" "$I_BOX_V" "$width" "$content" "$I_BOX_V"
}

print_banner() {
    local title="$1"
    local subtitle="${2:-}"
    local maxlen=${#title}
    [[ ${#subtitle} -gt $maxlen ]] && maxlen=${#subtitle}
    local inner_width=$(( maxlen + 4 ))

    local hrule=""
    local i
    for ((i=0; i<inner_width; i++)); do hrule+="$I_BOX_H"; done

    printf "\n"
    printf "  %s%s%s\n" "$(colorize "$C_CYAN" "$I_BOX_TL")" "$(colorize "$C_CYAN" "$hrule")" "$(colorize "$C_CYAN" "$I_BOX_TR")"
    box_line "$(colorize "${C_BOLD}${C_CYAN}" "$title")" "$inner_width"
    if [[ -n "$subtitle" ]]; then
        box_line "$(colorize "$C_DIM" "$subtitle")" "$inner_width"
    fi
    printf "  %s%s%s\n" "$(colorize "$C_CYAN" "$I_BOX_BL")" "$(colorize "$C_CYAN" "$hrule")" "$(colorize "$C_CYAN" "$I_BOX_BR")"
    printf "\n"
}

format_size() {
    local size="$1"
    if (( size >= 1073741824 )); then
        awk "BEGIN { printf \"%.1f GB\", $size/1073741824 }"
    elif (( size >= 1048576 )); then
        awk "BEGIN { printf \"%.1f MB\", $size/1048576 }"
    elif (( size >= 1024 )); then
        awk "BEGIN { printf \"%.1f KB\", $size/1024 }"
    else
        printf "%s B" "$size"
    fi
}

format_duration() {
    local seconds=$1
    local mins=$(( seconds / 60 ))
    local secs=$(( seconds % 60 ))
    if (( mins > 0 )); then
        printf "%dm %02ds" "$mins" "$secs"
    else
        printf "%ds" "$secs"
    fi
}

# ==============================================================================
#  5.  PROGRESS BAR  (single-line, in-place, no cursor tricks)
# ==============================================================================

draw_progress() {
    local current="$1"
    local total="$2"
    local label="$3"
    local bar_width=20

    (( total == 0 )) && return

    local pct=$(( current * 100 / total ))
    local filled=$(( current * bar_width / total ))
    local empty=$(( bar_width - filled ))

    local bar=""
    local i
    for ((i=0; i<filled; i++)); do bar+="$I_PROG_FILL"; done
    for ((i=0; i<empty;  i++)); do bar+="$I_PROG_EMPTY"; done

    # Truncate label to keep the line from wrapping on narrow terminals
    local display_label="$label"
    if (( ${#display_label} > 35 )); then
        display_label="${display_label:0:32}..."
    fi

    if [[ "$CAP_USE_COLOR" == true ]]; then
        local prog_color="$C_CYAN"
        if (( pct >= 100 )); then
            prog_color="$C_GREEN"
        elif (( pct >= 66 )); then
            prog_color="$C_GREEN_BRIGHT"
        elif (( pct >= 33 )); then
            prog_color="$C_YELLOW"
        fi

        local gear_colored="$(colorize "$C_CYAN" "$I_GEAR")"
        local bar_colored="$(colorize "$prog_color" "$bar")"

        # \033[2K = clear entire line, \r = return to start
        # This guarantees the line is wiped clean before we redraw
        printf "%s" $'\033[2K\r'
        printf "  %s%s%s[%s]%s %s%3d%%%s  %s%d/%d%s  %s%s%s" \
            "$C_DIM" \
            "$gear_colored" \
            "$C_DIM" \
            "$bar_colored" \
            "$C_DIM" \
            "$C_BOLD" \
            "$pct" \
            "$C_RESET" \
            "$C_DIM" \
            "$current" \
            "$total" \
            "$C_RESET" \
            "$C_DIM" \
            "$display_label" \
            "$C_RESET"
    else
        printf "%s" $'\033[2K\r'
        printf "  %s [%s] %3d%%  %d/%d  %s" \
            "$I_GEAR" \
            "$bar" \
            "$pct" \
            "$current" \
            "$total" \
            "$display_label"
    fi
}

# ==============================================================================
#  6.  FILENAME COMPUTATION & EXTENSION NORMALISATION
# ==============================================================================

normalize_extension() {
    local ext="$1"
    ext="${ext#.}"
    printf "%s" "$ext"
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
        counter=$(( counter + 1 ))
    done

    printf "%s\n" "$dest"
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

# ==============================================================================
#  7.  HELP & VERSION
# ==============================================================================
show_help() {
    print_banner "$SCRIPT_NAME" "v${SCRIPT_VERSION}"

    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "USAGE")"
    printf "\n"
    printf "    %s %s %s %s\n" "$(colorize "$C_CYAN" "  $0")" "$(colorize "$C_GREEN" "<source_dir>")" "$(colorize "$C_YELLOW" "<new_extension>")" "$(colorize "$C_GRAY" "[output_dir]")"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "DESCRIPTION")"
    printf "\n"
    printf "    Recursively rename all non-hidden files in <source_dir> (and all\n"
    printf "    subdirectories) to a new file extension.\n"
    printf "\n"
    printf "    In-place mode (2 args):  Files are renamed where they sit.\n"
    printf "    Copy mode    (3 args):  Files are COPIED to output_dir with new names.\n"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "ARGUMENTS")"
    printf "\n"
    printf "    %-18s %s\n" "$(colorize "$C_GREEN"  "source_dir")" "Directory to scan"
    printf "    %-18s %s\n" "$(colorize "$C_YELLOW" "new_extension")" "Target extension (e.g. txt, md, py)"
    printf "    %-18s %s\n" "$(colorize "$C_GRAY"   "output_dir")" "(Optional) destination directory"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "OPTIONS")"
    printf "\n"
    printf "    %s      %s\n" "$(colorize "$C_CYAN" "-h, --help")" "Show this message"
    printf "    %s   %s\n" "$(colorize "$C_CYAN" "-v, --version")" "Show version info"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "EXAMPLES")"
    printf "\n"
    printf "    %s\n" "$(colorize "$C_DIM" "# Rename everything in ./ProjectR to .txt")"
    printf "    %s\n" "$(colorize "$C_GREEN" "  $0 ./ProjectR txt")"
    printf "\n"
    printf "    %s\n" "$(colorize "$C_DIM" "# Copy+rename to ./renamed-files")"
    printf "    %s\n" "$(colorize "$C_GREEN" "  $0 ./ProjectR md ./renamed-files")"
    printf "\n"
    printf "    %s\n" "$(colorize "$C_DIM" "# Rename current dir contents to .bak")"
    printf "    %s\n" "$(colorize "$C_GREEN" "  $0 . bak")"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "EXIT CODES")"
    printf "\n"
    printf "    %s   %s\n" "$(colorize "$C_GREEN" "0")" "All good (or all skipped)"
    printf "    %s   %s\n" "$(colorize "$C_RED"   "1")" "Fatal error (bad args, missing dir, ...)"
    printf "    %s   %s\n" "$(colorize "$C_YELLOW" "2")" "Partial failure (some files failed)"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "ENVIRONMENT")"
    printf "\n"
    printf "    %s   %s\n" "$(colorize "$C_CYAN" "NO_COLOR")" "Set to any value to disable ANSI"
    printf "\n"
}

show_version() {
    printf "%s %s\n" "$(colorize "${C_BOLD}${C_CYAN}" "$SCRIPT_NAME")" "$(colorize "$C_GREEN" "v${SCRIPT_VERSION}")"
    printf "%s\n" "$(colorize "$C_DIM" "$SCRIPT_URL")"
    printf "\n"
    printf "  Bash:          %s\n" "${BASH_VERSION}"
    printf "  Unicode:       %s\n" "$([[ "$CAP_USE_UNICODE" == true ]] && echo "enabled" || echo "disabled")"
    printf "  Color:         %s\n" "$([[ "$CAP_USE_COLOR"  == true ]] && echo "enabled" || echo "disabled")"
    printf "  Interactive:   %s\n" "$([[ "$CAP_IS_INTERACTIVE" == true ]] && echo "yes" || echo "no")"
}

# ==============================================================================
#  8.  MAIN
# ==============================================================================
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
    esac

    if [[ $# -lt 2 ]]; then
        msg_error "Missing arguments. Expected: <source_dir> <new_extension> [output_dir]"
        msg_info "Try '$0 --help' for details."
        exit 1
    fi

    local source_dir="$1"
    local new_ext_raw="$2"
    local output_dir="${3:-}"
    local mode="in-place"

    local new_ext
    new_ext="$(normalize_extension "$new_ext_raw")"

    if [[ ! -d "$source_dir" ]]; then
        msg_error "Source directory does not exist: $(colorize "$C_BOLD" "$source_dir")"
        exit 1
    fi

    source_dir="$(cd "$source_dir" 2>/dev/null && pwd)" || {
        msg_error "Cannot access source directory: $source_dir"
        exit 1
    }

    if [[ -n "$output_dir" ]]; then
        if [[ -f "$output_dir" ]]; then
            msg_error "Output path is an existing file: $(colorize "$C_BOLD" "$output_dir")"
            exit 1
        fi

        mkdir -p "$output_dir" 2>/dev/null || {
            msg_error "Cannot create output directory: $output_dir"
            exit 1
        }

        output_dir="$(cd "$output_dir" 2>/dev/null && pwd)" || {
            msg_error "Cannot access output directory: $output_dir"
            exit 1
        }

        if [[ "$source_dir" == "$output_dir" ]]; then
            msg_warning "Source and output directories are identical — switching to in-place mode."
            mode="in-place"
            output_dir=""
        else
            mode="copy"
        fi
    fi

    msg_working "Scanning for files in $(colorize "${C_BOLD}${C_CYAN}" "$source_dir") ..."

    local file_old_names=()
    local total_size=0
    local file_count=0

    while IFS= read -r -d '' filepath; do
        local base
        base="$(basename "$filepath")"
        [[ "$base" == .* ]] && continue
        [[ ! -f "$filepath" ]] && continue

        file_old_names+=("$filepath")

        local file_size=0
        file_size=$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath" 2>/dev/null || printf "0")
        total_size=$(( total_size + file_size ))
        file_count=$(( file_count + 1 ))
    done < <(find "$source_dir" -type f ! -path '*/\.*' -print0 2>/dev/null | sort -z)

    if (( file_count == 0 )); then
        msg_warning "No files found in $(colorize "$C_BOLD" "$source_dir")"
        print_banner "Operation Summary" "Nothing to process"
        printf "  %s  0 files processed\n" "$(colorize "$C_GREEN" "$I_TICK")"
        exit 0
    fi

    local dest_names=()
    local conflicts=0
    local already_skipped=0

    for filepath in "${file_old_names[@]}"; do
        if already_has_extension "$filepath" "$new_ext"; then
            dest_names+=("$filepath")
            already_skipped=$(( already_skipped + 1 ))
            continue
        fi

        local dest
        if [[ "$mode" == "copy" ]]; then
            dest="$(compute_new_name "$filepath" "$new_ext" "$output_dir")"
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
            conflicts=$(( conflicts + 1 ))
        fi
    done

    local total_files=${#file_old_names[@]}
    local active_count=$(( total_files - already_skipped ))

    local mode_label="In-place rename"
    [[ "$mode" == "copy" ]] && mode_label="Copy + rename → $(colorize "$C_CYAN" "$output_dir")"

    print_banner "Batch Rename Operation" "v${SCRIPT_VERSION}"

    msg_info "Source:      $(colorize "$C_BOLD" "$source_dir")"
    msg_info "Extension:   $(colorize "${C_BOLD}${C_YELLOW}" ".${new_ext}")"
    msg_info "Mode:        ${mode_label}"
    msg_info "Files found: $(colorize "${C_BOLD}${C_WHITE}" "$total_files")"
    msg_info "Total size:  $(colorize "$C_DIM" "$(format_size "$total_size")")"

    if (( already_skipped > 0 )); then
        msg_info "Already .${new_ext}: $(colorize "$C_DIM" "$already_skipped") (will be skipped)"
    fi

    if (( active_count == 0 )); then
        printf "\n"
        msg_warning "All files already have the .${new_ext} extension — nothing to do."
        exit 0
    fi

    if (( conflicts > 0 )); then
        msg_warning "Conflicts to resolve: $(colorize "$C_YELLOW_BRIGHT" "$conflicts") file(s) will be auto-renamed (_1, _2, …)"
    fi

    printf "\n"

    local preview_count=5
    (( file_count < preview_count )) && preview_count=$file_count

    printf "  %s  %s %s\n" "$(colorize "$C_BLUE_BRIGHT" "$I_COLLAPSED")" "$(colorize "$C_BOLD" "Preview")" "$(colorize "$C_DIM" "(first ${preview_count} of ${file_count} files):")"

    local idx
    for ((idx=0; idx<preview_count; idx++)); do
        local src_name
        src_name="$(basename "${file_old_names[$idx]}")"
        local dst_name
        dst_name="$(basename "${dest_names[$idx]}")"

        local src_rel="${file_old_names[$idx]#"$source_dir"/}"
        if [[ "$src_rel" == "${file_old_names[$idx]}" ]]; then
            src_rel="$src_name"
        fi

        if [[ "$src_name" == "$dst_name" ]]; then
            printf "    %s %s %s\n" \
                "$(colorize "$C_DIM" "${I_ARROW}")" \
                "$(colorize "$C_GRAY" "$src_rel")" \
                "$(colorize "$C_YELLOW" "(already .${new_ext})")"
        else
            printf "    %s %s %s %s\n" \
                "$(colorize "$C_DIM" "${I_ARROW}")" \
                "$(colorize "$C_GRAY" "$src_rel")" \
                "$(colorize "$C_CYAN" " ──→ ")" \
                "$(colorize "$C_GREEN_BRIGHT" "$dst_name")"
        fi
    done

    local remaining=$(( file_count - preview_count ))
    if (( remaining > 0 )); then
        printf "    %s\n" "$(colorize "$C_DIM" "${I_ELLIPSIS} and ${remaining} more file(s)")"
    fi

    printf "\n"

    if [[ "$CAP_IS_INTERACTIVE" == true ]]; then
        local proceed=""
        printf "  %s  Proceed with %s? %s %s" \
            "$(colorize "${C_BOLD}${C_YELLOW}" "$I_PLAY")" \
            "$(colorize "$C_BOLD" "$mode_label")" \
            "$(colorize "$C_GREEN" "[Y/n]")" \
            "$(colorize "$C_DIM" "> ")"
        read -r proceed
        case "${proceed,,}" in
            n|no)
                printf "\n"
                msg_warning "Operation cancelled by user."
                exit 0
                ;;
        esac
        printf "\n"
    fi

    local success_count=0
    local failed_count=0
    local skipped_count=$already_skipped
    local renamed_files=()
    local failed_files=()
    local skipped_list=()

    local start_time
    start_time=$(date +%s)

    msg_working "Processing $(colorize "$C_BOLD" "$active_count") file(s)..."
    printf "\n"

    local progress_current=0

    for ((idx=0; idx<total_files; idx++)); do
        local src="${file_old_names[$idx]}"
        local dst="${dest_names[$idx]}"
        local src_name
        src_name="$(basename "$src")"
        local dst_name
        dst_name="$(basename "$dst")"

        if [[ "$src" == "$dst" ]]; then
            skipped_count=$(( skipped_count + 1 ))
            skipped_list+=("$src_name (already .${new_ext})")
            continue
        fi

        progress_current=$(( progress_current + 1 ))
        draw_progress "$progress_current" "$active_count" "$src_name"

        if [[ -e "$dst" ]]; then
            skipped_count=$(( skipped_count + 1 ))
            skipped_list+=("$src_name (destination exists)")
            continue
        fi

        local op_status=0
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

        if (( op_status == 0 )); then
            success_count=$(( success_count + 1 ))
            renamed_files+=("$dst_name")
        else
            failed_count=$(( failed_count + 1 ))
            failed_files+=("$src_name (exit: ${op_status})")
            # Clear the progress line before printing the error
            printf "%s" $'\033[2K\r'
            msg_error "Failed: $(colorize "$C_BOLD" "$src") → $(colorize "$C_BOLD" "$dst") (exit: ${op_status})"
        fi
    done

    # Final draw at 100%, then move to a new line
    draw_progress "$active_count" "$active_count" "Complete"
    printf "\n\n"

    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - start_time ))

    print_banner "Operation Complete" "Processed in $(format_duration "$duration")"

    printf "  %s  %s\n" "$(colorize "$C_GREEN" "$I_TICK")" "$(colorize "$C_BOLD" "Summary")"
    printf "\n"
    printf "    %s  Success:  %s\n" "$(colorize "$C_GREEN"  "$I_SUCCESS")" "$(colorize "${C_BOLD}${C_GREEN}"   "$success_count")"
    printf "    %s  Skipped:  %s\n" "$(colorize "$C_YELLOW" "$I_WARNING")" "$(colorize "${C_BOLD}${C_YELLOW}"  "$skipped_count")"
    printf "    %s   Failed:   %s\n" "$(colorize "$C_RED"    "$I_ERROR")" "$(colorize "${C_BOLD}${C_RED}"     "$failed_count")"
    if (( total_files > 0 )); then
        local success_rate=$(( (success_count * 100) / total_files ))
        printf "    %s\n" "$(colorize "$C_DIM" "───────")"
        printf "    %s  Total:    %s  %s\n" "$(colorize "$C_CYAN" "$I_LOZENGE")" "$(colorize "$C_BOLD" "$total_files")" "$(colorize "$C_DIM" "(${success_rate}% success)")"
    fi
    printf "\n"

    if (( ${#renamed_files[@]} > 0 )); then
        printf "  %s  Renamed files:\n" "$(colorize "$C_GREEN" "$I_TICK")"
        local shown=0
        for f in "${renamed_files[@]}"; do
            (( shown >= 10 )) && break
            printf "    %s  %s\n" "$(colorize "$C_DIM" "${I_ARROW}")" "$(colorize "$C_GREEN_BRIGHT" "$f")"
            shown=$(( shown + 1 ))
        done
        if (( ${#renamed_files[@]} > 10 )); then
            printf "    %s\n" "$(colorize "$C_DIM" "${I_ELLIPSIS} and $(( ${#renamed_files[@]} - 10 )) more")"
        fi
        printf "\n"
    fi

    if (( ${#skipped_list[@]} > 0 )); then
        printf "  %s Skipped:\n" "$(colorize "$C_YELLOW" "$I_WARNING")"
        local shown=0
        for f in "${skipped_list[@]}"; do
            (( shown >= 10 )) && break
            printf "    %s  %s\n" "$(colorize "$C_DIM" "${I_ARROW}")" "$(colorize "$C_YELLOW" "$f")"
            shown=$(( shown + 1 ))
        done
        if (( ${#skipped_list[@]} > 10 )); then
            printf "    %s\n" "$(colorize "$C_DIM" "${I_ELLIPSIS} and $(( ${#skipped_list[@]} - 10 )) more")"
        fi
        printf "\n"
    fi

    if (( ${#failed_files[@]} > 0 )); then
        printf "  %s  Failed:\n" "$(colorize "$C_RED" "$I_ERROR")"
        for f in "${failed_files[@]}"; do
            printf "    %s  %s\n" "$(colorize "$C_DIM" "${I_ARROW}")" "$(colorize "$C_RED" "$f")"
        done
        printf "\n"
    fi

    if [[ "$mode" == "copy" ]]; then
        msg_info "Originals preserved in: $(colorize "$C_DIM" "$source_dir")"
        msg_info "Renamed copies in:    $(colorize "${C_BOLD}${C_CYAN}" "$output_dir")"
    else
        msg_info "Files renamed in-place at: $(colorize "$C_DIM" "$source_dir")"
    fi
    printf "\n"

    if (( failed_count > 0 && success_count > 0 )); then
        exit 2
    elif (( failed_count > 0 )); then
        exit 1
    fi
}

main "$@"
