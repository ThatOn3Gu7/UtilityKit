#!/usr/bin/env bash
# ==============================================================================
#  _move_in_batch.sh — Batch File Mover  v2.0.1
# ==============================================================================
#  Move or copy files from a target directory to an output directory, with
#  exclusion patterns, optional flattening, interactive confirmation, live
#  progress bar, collision resolution, and a full summary report.
#
#  Usage (executed):
#    bash _move_in_batch.sh -t <target> -o <output> [-e <ext> ...] [-f] [-m=cp|mv]
#
#  Usage (sourced):
#    source _move_in_batch.sh
#    move_in_batch -t <target> -o <output> [-e <ext> ...] [-f] [-m=cp|mv]
#
#  Flags:
#    -t, --target    Source directory to move files from          (required)
#    -o, --output    Destination directory to move files into     (required)
#    -e, --exclude   Extensions / patterns to skip (e.g. .git .md)
#    -f, --flatten   Strip subdirectory structure: all files land
#                    directly in the output directory root
#    -m, --method    Transfer method:  cp (copy)  or  mv (move)
#                    Default is cp for safety
#    -h, --help      Show this help message
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
#  0.  METADATA
# ==============================================================================
MIB_SCRIPT_NAME="Batch File Mover"
MIB_SCRIPT_VERSION="2.0.1"
MIB_SCRIPT_URL="https://github.com/Thaton3gu7/Utilitykit.git"

# ==============================================================================
#  1.  TERMINAL CAPABILITY DETECTION
# ==============================================================================

CAP_USE_COLOR=false
CAP_USE_UNICODE=false
CAP_IS_INTERACTIVE=false
METHOD="cp"          # default: safe copy
FLATTEN_MODE=false

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
C_RESET="" ; C_BOLD="" ; C_DIM="" ; C_ITALIC="" ; C_UNDERLINE=""
C_STRIKETHROUGH="" ; C_OVERLINE=""
C_RED="" ; C_GREEN="" ; C_YELLOW="" ; C_BLUE="" ; C_MAGENTA=""
C_CYAN="" ; C_WHITE="" ; C_GRAY=""
C_RED_BRIGHT="" ; C_GREEN_BRIGHT="" ; C_YELLOW_BRIGHT=""
C_BLUE_BRIGHT="" ; C_MAGENTA_BRIGHT="" ; C_CYAN_BRIGHT="" ; C_WHITE_BRIGHT=""
C_BG_RED="" ; C_BG_GREEN="" ; C_BG_YELLOW="" ; C_BG_BLUE="" ; C_BG_CYAN="" ; C_BG_GRAY=""

init_colors() {
    if [[ "$CAP_USE_COLOR" == false ]]; then
        return
    fi
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
}

init_colors

# ==============================================================================
#  3.  ICON SET  (Unicode → ASCII fallback)
# ==============================================================================
I_INFO="" ; I_SUCCESS="" ; I_ERROR="" ; I_WARNING="" ; I_WORKING=""
I_ARROW="" ; I_STAR="" ; I_BULLET="" ; I_COLLAPSED=""
I_BOX_TL="" ; I_BOX_TR="" ; I_BOX_BL="" ; I_BOX_BR="" ; I_BOX_H="" ; I_BOX_V=""
I_PROG_FILL="" ; I_PROG_EMPTY=""
I_CHECK_OFF="" ; I_CHECK_ON="" ; I_LOZENGE=""
I_PLAY="" ; I_TICK="" ; I_CROSS="" ; I_ELLIPSIS="" ; I_SEPARATOR=""
I_GEAR="" ; I_SEARCH="" ; I_FOLDER="" ; I_FILE="" ; I_FLATTEN="" ; I_PACKAGE=""

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
        I_CROSS="✖"
        I_ELLIPSIS="…"
        I_SEPARATOR="╱"
        I_GEAR="⚙"
        I_SEARCH="⌕"
        I_FOLDER="📁"
        I_FILE="📄"
        I_FLATTEN="↯"
        I_PACKAGE="📦"
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
        I_FOLDER="[D]"
        I_FILE="[F]"
        I_FLATTEN="|>"
        I_PACKAGE="[P]"
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

msg_info()     { printf "  %s    %s\n" "$(colorize "$C_BLUE"   "$I_INFO")"    "$*"; }
msg_success()  { printf "  %s %s\n"   "$(colorize "$C_GREEN"  "$I_SUCCESS")" "$*"; }
msg_error()    { printf "  %s   %s\n" "$(colorize "$C_RED"    "$I_ERROR")"   "$*" >&2; }
msg_warning()  { printf "  %s  %s\n"  "$(colorize "$C_YELLOW" "$I_WARNING")" "$*"; }
msg_working()  { printf "  %s %s\n"   "$(colorize "$C_CYAN"   "$I_WORKING")" "$*"; }
msg_arrow()    { printf "  %s   %s\n" "$(colorize "$C_BLUE_BRIGHT" "$I_ARROW")" "$*"; }

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
    printf "  %s%s%s\n" \
        "$(colorize "$C_CYAN" "$I_BOX_TL")" \
        "$(colorize "$C_CYAN" "$hrule")" \
        "$(colorize "$C_CYAN" "$I_BOX_TR")"

    local title_pad=$(( inner_width - 2 - ${#title} ))
    printf "  %s  %s%*s%s\n" \
        "$(colorize "$C_CYAN" "$I_BOX_V")" \
        "$(colorize "${C_BOLD}${C_CYAN}" "$title")" \
        "$title_pad" "" \
        "$(colorize "$C_CYAN" "$I_BOX_V")"

    if [[ -n "$subtitle" ]]; then
        local sub_pad=$(( inner_width - 2 - ${#subtitle} ))
        printf "  %s  %s%*s%s\n" \
            "$(colorize "$C_CYAN" "$I_BOX_V")" \
            "$(colorize "$C_DIM" "$subtitle")" \
            "$sub_pad" "" \
            "$(colorize "$C_CYAN" "$I_BOX_V")"
    fi

    printf "  %s%s%s\n" \
        "$(colorize "$C_CYAN" "$I_BOX_BL")" \
        "$(colorize "$C_CYAN" "$hrule")" \
        "$(colorize "$C_CYAN" "$I_BOX_BR")"
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
#  5.  PROGRESS BAR
# ==============================================================================

draw_progress() {
    local current="$1"
    local total="$2"
    local label="$3"

    (( total == 0 )) && return
    if [[ ! -t 1 ]]; then
        [[ "$label" == "Complete" ]] && printf "  %s Processed %d/%d file(s): %s\n" "$I_GEAR" "$current" "$total" "$label"
        return 0
    fi

    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)

    local bar_width=$(( term_width / 4 ))
    (( bar_width > 30 )) && bar_width=30
    (( bar_width < 10 )) && bar_width=10

    local pct=$(( current * 100 / total ))
    local filled=$(( current * bar_width / total ))
    local empty=$(( bar_width - filled ))

    local bar=""
    local i
    for ((i=0; i<filled; i++)); do bar+="$I_PROG_FILL"; done
    for ((i=0; i<empty;  i++)); do bar+="$I_PROG_EMPTY"; done

    local ui_reserved=$(( 14 + bar_width + 3 + ${#current} + ${#total} ))
    local max_label_len=$(( term_width - ui_reserved ))

    local display_label="$label"
    if (( max_label_len < 5 )); then
        display_label=""
    elif (( ${#display_label} > max_label_len )); then
        display_label="${display_label:0:$((max_label_len - 3))}..."
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

        printf "%s" $'\033[2K\r'
        printf "  %s%s%s[%s]%s %s%3d%%%s  %s%d/%d%s  %s%s%s" \
            "$C_DIM" "$(colorize "$C_CYAN" "$I_GEAR")" "$C_DIM" \
            "$(colorize "$prog_color" "$bar")" \
            "$C_DIM" "$C_BOLD" "$pct" "$C_RESET" \
            "$C_DIM" "$current" "$total" "$C_RESET" \
            "$C_DIM" "$display_label" "$C_RESET"
    else
        printf "%s" $'\033[2K\r'
        printf "  %s [%s] %3d%%  %d/%d  %s" \
            "$I_GEAR" "$bar" "$pct" "$current" "$total" "$display_label"
    fi
}

# ==============================================================================
#  6.  UTILITY:  tilde expansion
# ==============================================================================

_expand_tilde() {
    local path="$1"
    if [[ "$path" == "~" || "$path" == "~/"* ]]; then
        path="${HOME}${path:1}"
    fi
    printf '%s' "$path"
}

# ==============================================================================
#  7.  HELP & VERSION
# ==============================================================================

show_help() {
    print_banner "$MIB_SCRIPT_NAME" "v${MIB_SCRIPT_VERSION}"

    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "USAGE")"
    printf "\n"
    printf "    %s %s %s %s\n" \
        "$(colorize "$C_CYAN" "  bash _move_in_batch.sh")" \
        "$(colorize "$C_GREEN" "-t <target>")" \
        "$(colorize "$C_YELLOW" "-o <output>")" \
        "$(colorize "$C_GRAY" "[flags]")"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "FLAGS")"
    printf "\n"
    printf "    %-22s %s\n" "$(colorize "$C_GREEN"  "-t, --target")"     "Source directory (required)"
    printf "    %-22s %s\n" "$(colorize "$C_YELLOW" "-o, --output")"     "Destination directory (required)"
    printf "    %-22s %s\n" "$(colorize "$C_RED"    "-e, --exclude")"    "Extensions / patterns to skip"
    printf "    %-22s %s\n" "$(colorize "$C_MAGENTA" "-f, --flatten")"    "Strip subdirectory structure"
    printf "    %-22s %s\n" "$(colorize "$C_BLUE"   "-m, --method")"     "Transfer method: cp (default) or mv"
    printf "    %-22s %s\n" "$(colorize "$C_CYAN"   "-h, --help")"       "Show this help"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "EXAMPLES")"
    printf "\n"
    printf "    %s\n" "$(colorize "$C_DIM"   "# Copy files, excluding .md & .git, preserve structure")"
    printf "    %s\n" "$(colorize "$C_GREEN" "  bash _move_in_batch.sh -t ~/src -o ~/out -e .md .git")"
    printf "\n"
    printf "    %s\n" "$(colorize "$C_DIM"   "# Move files, flatten subdirectories")"
    printf "    %s\n" "$(colorize "$C_GREEN" "  bash _move_in_batch.sh -t ~/src -o ~/out -f -m=mv")"
    printf "\n"
    printf "    %s\n" "$(colorize "$C_DIM"   "# Same but using long flags")"
    printf "    %s\n" "$(colorize "$C_GREEN" "  bash _move_in_batch.sh --target ~/src --output ~/out --flatten --method=mv --exclude .git .md")"
    printf "\n"
    printf "  %s\n" "$(colorize "${C_BOLD}${C_WHITE}" "NOTES")"
    printf "\n"
    printf "    %s  %s\n" "$(colorize "$C_YELLOW" "$I_WARNING")" "$(colorize "$C_BOLD" "Default method is cp (copy) for safety.")"
    printf "    %s  %s\n" "$(colorize "$C_YELLOW" "$I_WARNING")" "$(colorize "$C_DIM" "Use -m=mv only if you intend to move/delete originals.")"
    printf "\n"
}

show_version() {
    printf "%s %s\n" \
        "$(colorize "${C_BOLD}${C_CYAN}" "$MIB_SCRIPT_NAME")" \
        "$(colorize "$C_GREEN" "v${MIB_SCRIPT_VERSION}")"
    printf "%s\n" "$(colorize "$C_DIM" "$MIB_SCRIPT_URL")"
    printf "\n"
    printf "  Bash:          %s\n" "${BASH_VERSION}"
    printf "  Unicode:       %s\n" "$([[ "$CAP_USE_UNICODE"  == true ]] && echo "enabled" || echo "disabled")"
    printf "  Color:         %s\n" "$([[ "$CAP_USE_COLOR"    == true ]] && echo "enabled" || echo "disabled")"
    printf "  Interactive:   %s\n" "$([[ "$CAP_IS_INTERACTIVE" == true ]] && echo "yes" || echo "no")"
}

# ==============================================================================
#  8.  EXCLUSION CHECK & GROUPING
# ==============================================================================

# Returns via stdout the "exclusion group label" for a file path, or empty
# string with non-zero exit if not excluded.
#   - For directory-like exclusions (.git, node_modules, ...) the group is
#     the directory name (e.g. ".git")
#   - For extension-based exclusions (.md, .tmp, ...) the group is the
#     individual filename (e.g. "readme.md")
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

# ==============================================================================
#  9. MAIN  —  move_in_batch
# ==============================================================================

move_in_batch() {
    local target=""
    local output=""
    local exclude=()
    FLATTEN_MODE=false
    METHOD="cp"

    # ---- rollback tracking ----
    declare -ga ROLLBACK_SRC=()
    declare -ga ROLLBACK_DST=()

    # ---- parse flags ----
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--target)
                target="$(_expand_tilde "$2")"
                shift 2
                ;;
            -o|--output)
                output="$(_expand_tilde "$2")"
                shift 2
                ;;
            -e|--exclude)
                shift
                while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                    exclude+=("$1")
                    shift
                done
                ;;
            -f|--flatten)
                FLATTEN_MODE=true
                shift
                ;;
            -m=*|--method=*)
                METHOD="${1#*=}"
                shift
                ;;
            -m|--method)
                METHOD="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                return 0
                ;;
            -v|--version)
                show_version
                return 0
                ;;
            *)
                msg_error "Unknown option: $1"
                msg_info  "Use -h or --help for usage."
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
    if [[ "$METHOD" != "cp" && "$METHOD" != "mv" ]]; then
        msg_warning "Unknown method '$METHOD' — falling back to 'cp' (copy)."
        METHOD="cp"
    fi

    local method_verb="Copying"
    local method_label="copy (cp)"
    if [[ "$METHOD" == "mv" ]]; then
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
    msg_working "Scanning for files in $(colorize "${C_BOLD}${C_CYAN}" "$target") ..."

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
        total_size=$(( total_size + file_size ))
    done < <(find "$target" -type f -print0 2>/dev/null | sort -z)

    local total_files=${#files[@]}

    if (( total_files == 0 )); then
        msg_warning "No files found in $(colorize "$C_BOLD" "$target")"
        print_banner "Operation Summary" "Nothing to process"
        printf "  %s  0 files processed\n" "$(colorize "$C_GREEN" "$I_TICK")"
        return 0
    fi

    # ---- classify files (with in-memory destination tracking for collisions) ----
    local dests=()
    local skipped_excluded=0
    local collision_count=0
    declare -A _seen_dests=()      # track assigned destinations to avoid collisions
    declare -A _excluded_groups=()  # group_label → count, for compact display

    for file in "${files[@]}"; do
        local basename
        basename="$(basename "$file")"
        local rel_path
        rel_path="${file#"$target"}"
        rel_path="${rel_path#/}"

        local group_label
        if group_label="$(_exclusion_group "$rel_path" "${exclude[@]}")"; then
            dests+=("__SKIP__:${group_label}")
            _excluded_groups["$group_label"]=$(( ${_excluded_groups["$group_label"]:-0} + 1 ))
            skipped_excluded=$(( skipped_excluded + 1 ))
            continue
        fi

        local dest
        if $FLATTEN_MODE; then
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
                    c=$(( c + 1 ))
                done
                collision_count=$(( collision_count + 1 ))
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
                    c=$(( c + 1 ))
                done
                collision_count=$(( collision_count + 1 ))
            fi
            dest="$candidate"
        fi
        _seen_dests["$dest"]=1
        dests+=("$dest")
    done
    unset _seen_dests

    local active_count=$(( total_files - skipped_excluded ))

    # ---- BANNER & PREVIEW ----
    local mode_tags=""
    if $FLATTEN_MODE; then
        mode_tags+="$(colorize "$C_MAGENTA" " [flatten]")"
    fi

    print_banner "Batch Move Operation" "v${MIB_SCRIPT_VERSION}"

    msg_info "Source:      $(colorize "$C_BOLD" "$target")"
    msg_info "Output:      $(colorize "${C_BOLD}${C_CYAN}" "$output")"
    msg_info "Method:      $(colorize "$C_BLUE" "$method_label")$mode_tags"
    msg_info "Files found: $(colorize "${C_BOLD}${C_WHITE}" "$total_files")"
    msg_info "Total size:  $(colorize "$C_DIM" "$(format_size "$total_size")")"

    if (( skipped_excluded > 0 )); then
        msg_info "Excluded:    $(colorize "$C_DIM" "$skipped_excluded") file(s)"
    fi
    if (( collision_count > 0 )); then
        msg_warning "Collisions:  $(colorize "$C_YELLOW_BRIGHT" "$collision_count") file(s) will be auto-renamed (_1, _2, …)"
    fi

    if (( active_count == 0 )); then
        printf "\n"
        msg_warning "All files were excluded — nothing to do."
        return 0
    fi

    # ---- file preview ----
    printf "\n"
    printf "  %s  %s %s\n" \
        "$(colorize "$C_BLUE_BRIGHT" "$I_COLLAPSED")" \
        "$(colorize "$C_BOLD" "Preview")" \
        "$(colorize "$C_DIM" "(showing up to 10 files):")"

    local preview_max_transfers=7
    local preview_max_groups=3
    local shown=0

    # (A) Show transfer previews first
    local idx=0
    while (( idx < total_files && shown < preview_max_transfers )); do
        local d="${dests[$idx]}"
        if [[ "$d" != __SKIP__:* ]]; then
            local fn
            fn="$(basename "${files[$idx]}")"
            local dn
            dn="$(basename "$d")"
            printf "    %s %s %s %s\n" \
                "$(colorize "$C_DIM" "${I_ARROW}")" \
                "$(colorize "$C_GRAY" "$fn")" \
                "$(colorize "$C_CYAN" " ──→ ")" \
                "$(colorize "$C_GREEN_BRIGHT" "$dn")"
            shown=$(( shown + 1 ))
        fi
        idx=$(( idx + 1 ))
    done

    # Count unshown transfers
    local unshown_transfers=0
    while (( idx < total_files )); do
        local d="${dests[$idx]}"
        [[ "$d" != __SKIP__:* ]] && unshown_transfers=$(( unshown_transfers + 1 ))
        idx=$(( idx + 1 ))
    done

    # (B) Show excluded groups (compact)
    local group_shown=0
    for grp in "${!_excluded_groups[@]}"; do
        (( group_shown >= preview_max_groups )) && break
        local cnt="${_excluded_groups[$grp]}"
        if (( cnt == 1 )); then
            printf "    %s %s %s\n" \
                "$(colorize "$C_DIM" "${I_ARROW}")" \
                "$(colorize "$C_GRAY" "$grp")" \
                "$(colorize "$C_YELLOW" "(excluded)")"
        else
            printf "    %s %s %s\n" \
                "$(colorize "$C_DIM" "${I_ARROW}")" \
                "$(colorize "$C_GRAY" "$grp")" \
                "$(colorize "$C_YELLOW" "(${cnt} files excluded)")"
        fi
        group_shown=$(( group_shown + 1 ))
    done

    # Count unshown groups for the "and more" line
    local total_groups=${#_excluded_groups[@]}
    local total_remaining=$(( unshown_transfers + (total_groups > preview_max_groups ? total_groups - preview_max_groups : 0) ))
    if (( total_remaining > 0 )); then
        printf "    %s\n" "$(colorize "$C_DIM" "${I_ELLIPSIS} and ${total_remaining} more")"
    fi

    printf "\n"

    # ---- interactive confirmation ----
    if [[ "$CAP_IS_INTERACTIVE" == true ]]; then
        local proceed=""
        printf "  %s  Proceed with %s? %s %s" \
            "$(colorize "${C_BOLD}${C_YELLOW}" "$I_PLAY")" \
            "$(colorize "$C_BOLD" "$method_verb $active_count file(s)")" \
            "$(colorize "$C_GREEN" "[Y/n]")" \
            "$(colorize "$C_DIM" "> ")"
        read -r proceed
        case "${proceed,,}" in
            n|no)
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
        if (( count == 0 )); then
            msg_info "No files were transferred yet. Exiting safely."
            return 130
        fi

        printf "  %s  %d file(s) have already been transferred.\n" \
            "$(colorize "$C_YELLOW" "$I_WARNING")" "$count"

        if [[ "$CAP_IS_INTERACTIVE" == true ]]; then
            local rb_choice=""
            printf "  %s  Roll back these changes? %s %s" \
                "$(colorize "${C_BOLD}${C_YELLOW}" "$I_SEARCH")" \
                "$(colorize "$C_GREEN" "[Y/n]")" \
                "$(colorize "$C_DIM" "> ")"
            read -r rb_choice
            case "${rb_choice,,}" in
                y|yes|"")
                    msg_working "Rolling back changes..."
                    local rb_fails=0
                    for (( i=${#ROLLBACK_SRC[@]}-1; i>=0; i-- )); do
                        local r_dst="${ROLLBACK_DST[$i]}"
                        if [[ -e "$r_dst" ]]; then
                            rm -f "$r_dst" || rb_fails=$(( rb_fails + 1 ))
                        fi
                    done
                    if (( rb_fails > 0 )); then
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

    msg_working "Processing $(colorize "$C_BOLD" "$active_count") file(s)..."
    printf "\n"

    local progress_current=0

    trap 'handle_interrupt' SIGINT

    for ((idx=0; idx<total_files; idx++)); do
        local src="${files[$idx]}"
        local dst="${dests[$idx]}"
        local src_name
        src_name="$(basename "$src")"

        # Skip excluded files (already counted in _excluded_groups)
        if [[ "$dst" == __SKIP__:* ]]; then
            continue
        fi

        progress_current=$(( progress_current + 1 ))
        draw_progress "$progress_current" "$active_count" "$src_name"

        # If destination already exists (e.g. from a previous partial run), skip
        if [[ -e "$dst" && "$dst" != "$src" ]]; then
            skipped_conflict=$(( skipped_conflict + 1 ))
            skipped_list+=("$src_name (destination exists)")
            continue
        fi

        # Ensure parent directories exist
        mkdir -p "$(dirname "$dst")"

        local op_status=0
        if [[ "$METHOD" == "cp" ]]; then
            cp -- "$src" "$dst" || op_status=$?
        else
            mv -- "$src" "$dst" || op_status=$?
        fi

        if (( op_status == 0 )); then
            success_count=$(( success_count + 1 ))
            processed_files+=("$(basename "$dst")")
            ROLLBACK_SRC+=("$src")
            ROLLBACK_DST+=("$dst")
        else
            failed_count=$(( failed_count + 1 ))
            failed_files+=("$src_name (exit: ${op_status})")
            printf "%s" $'\033[2K\r'
            msg_error "Failed: $(colorize "$C_BOLD" "$src") → $(colorize "$C_BOLD" "$dst") (exit: ${op_status})"
        fi
    done

    # Final 100% draw
    draw_progress "$active_count" "$active_count" "Complete"
    printf "\n\n"

    trap - SIGINT

    # ---- summary ----
    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - start_time ))

    print_banner "Operation Complete" "Processed in $(format_duration "$duration")"

    printf "  %s  %s\n" "$(colorize "$C_GREEN" "$I_TICK")" "$(colorize "$C_BOLD" "Summary")"
    printf "\n"
    printf "    %s  Success:  %s\n" \
        "$(colorize "$C_GREEN"  "$I_SUCCESS")" \
        "$(colorize "${C_BOLD}${C_GREEN}"   "$success_count")"
    printf "    %s   Skipped:  %s\n" \
        "$(colorize "$C_YELLOW" "$I_WARNING")" \
        "$(colorize "${C_BOLD}${C_YELLOW}"  "$(( skipped_excluded + skipped_conflict ))")"

    if (( failed_count > 0 )); then
        printf "    %s  Failed:   %s\n" \
            "$(colorize "$C_RED"    "$I_ERROR")" \
            "$(colorize "${C_BOLD}${C_RED}"    "$failed_count")"
    fi

    if (( total_files > 0 )); then
        local success_rate=$(( (success_count * 100) / active_count ))
        printf "    %s\n" "$(colorize "$C_DIM" "───────")"
        printf "    %s  Total:    %s  %s\n" \
            "$(colorize "$C_CYAN" "$I_LOZENGE")" \
            "$(colorize "$C_BOLD" "$active_count")" \
            "$(colorize "$C_DIM" "(${success_rate}% success)")"
    fi
    printf "\n"

    # ---- transferred list ----
    if (( ${#processed_files[@]} > 0 )); then
        printf "  %s  Transferred files:\n" "$(colorize "$C_GREEN" "$I_TICK")"
        local shown=0
        for f in "${processed_files[@]}"; do
            (( shown >= 10 )) && break
            printf "    %s  %s\n" "$(colorize "$C_DIM" "${I_ARROW}")" "$(colorize "$C_GREEN_BRIGHT" "$f")"
            shown=$(( shown + 1 ))
        done
        if (( ${#processed_files[@]} > 10 )); then
            printf "    %s\n" "$(colorize "$C_DIM" "${I_ELLIPSIS} and $(( ${#processed_files[@]} - 10 )) more")"
        fi
        printf "\n"
    fi

    # ---- skipped list (grouped exclusions + conflict skips) ----
    if (( ${#_excluded_groups[@]} > 0 )) || (( ${#skipped_list[@]} > 0 )); then
        printf "  %s Skipped:\n" "$(colorize "$C_YELLOW" "$I_WARNING")"
        local shown=0

        # Excluded groups first
        for grp in "${!_excluded_groups[@]}"; do
            (( shown >= 10 )) && break
            local cnt="${_excluded_groups[$grp]}"
            if (( cnt == 1 )); then
                printf "    %s  %s\n" \
                    "$(colorize "$C_DIM" "${I_ARROW}")" \
                    "$(colorize "$C_YELLOW" "$grp (excluded)")"
            else
                printf "    %s  %s\n" \
                    "$(colorize "$C_DIM" "${I_ARROW}")" \
                    "$(colorize "$C_YELLOW" "$grp (${cnt} files excluded)")"
            fi
            shown=$(( shown + 1 ))
        done

        # Conflict / already-exists skips
        for f in "${skipped_list[@]}"; do
            (( shown >= 10 )) && break
            printf "    %s  %s\n" "$(colorize "$C_DIM" "${I_ARROW}")" "$(colorize "$C_YELLOW" "$f")"
            shown=$(( shown + 1 ))
        done

        local total_skip_entries=$(( ${#_excluded_groups[@]} + ${#skipped_list[@]} ))
        if (( total_skip_entries > 10 )); then
            printf "    %s\n" "$(colorize "$C_DIM" "${I_ELLIPSIS} and $(( total_skip_entries - 10 )) more")"
        fi
        printf "\n"
    fi

    # ---- failed list ----
    if (( ${#failed_files[@]} > 0 )); then
        printf "  %s  Failed:\n" "$(colorize "$C_RED" "$I_ERROR")"
        for f in "${failed_files[@]}"; do
            printf "    %s  %s\n" "$(colorize "$C_DIM" "${I_ARROW}")" "$(colorize "$C_RED" "$f")"
        done
        printf "\n"
    fi

    if [[ "$METHOD" == "cp" ]]; then
        msg_info "Originals preserved in: $(colorize "$C_DIM" "$target")"
        msg_info "Copies now reside in:  $(colorize "${C_BOLD}${C_CYAN}" "$output")"
    else
        msg_info "Files moved from:  $(colorize "$C_DIM" "$target")"
        msg_info "Files now reside in:  $(colorize "${C_BOLD}${C_CYAN}" "$output")"
    fi
    printf "\n"

    if (( failed_count > 0 && success_count > 0 )); then
        return 2
    elif (( failed_count > 0 )); then
        return 1
    fi
}

mib_main() {
    move_in_batch "$@"
}

# ==============================================================================
#  11. ENTRY POINT
# ==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mib_main "$@"
fi
