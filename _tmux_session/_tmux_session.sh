#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try sourcing the common library if available
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/../lib/uk_common.sh"
fi

# --- Fallback Utilities (Ensures standalone robustness) ---
if ! declare -F uk_has_cmd &>/dev/null; then
  uk_has_cmd() { command -v "${1:-}" &>/dev/null; }
fi

# Modern Premium Color Palette (only set if not already provided by a parent shell)
: "${C_DARK_GRAY:=\033[90m}" "${C_CYAN:=\033[38;5;81m}" "${C_GREEN:=\033[38;5;120m}" \
  "${C_RED:=\033[38;5;203m}" "${C_WHITE:=\033[97m}" "${C_BOLD:=\033[1m}" "${C_RESET:=\033[0m}"

# Aesthetic UI Glyphs
GLYPH_ACTIVE="●"
GLYPH_INACTIVE="○"
PROMPT_CHAR="❯"

# Clean session name to prevent Tmux syntax issues
sanitize_session_name() {
  local name="${1:-}"
  name="${name//[\.\: ]/-}"
  name="${name//--/-}"
  name="${name#-}"
  name="${name%-}"
  echo "$name"
}
# Format helper for Unix Timestamps
format_timestamp() {
  local ts="${1:-}"
  if [[ "$ts" =~ ^[0-9]+$ ]]; then
    printf -v formatted '%(%Y-%m-%d %H:%M)T' "$ts" 2>/dev/null ||
      formatted=$(date -d "@$ts" +"%Y-%m-%d %H:%M" 2>/dev/null) ||
      formatted=$(date -r "$ts" +"%Y-%m-%d %H:%M" 2>/dev/null) ||
      formatted="Unknown"
    echo "$formatted"
  else
    echo "Unknown"
  fi
}
# Helper to dynamically grab all running sessions in a clean array
get_live_sessions() {
  local sess=()
  while read -r s; do
    if [[ -n "$s" ]]; then
      sess+=("$s")
    fi
  done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
  echo "${sess[@]}"
}
# Helper to grab the absolute latest active session name
get_latest_active_session() {
  tmux list-sessions -F '#{session_activity} #{session_name}' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-
}
# INTERACTIVE PROMPT ENGINE
ask_user() {
  local prompt="${1:-}"
  local default="${2:-}"
  local example="${3:-}"
  local desc="${4:-}"
  local result_var="${5:-}"

  echo -e "${C_WHITE}${PROMPT_CHAR} ${C_BOLD}${prompt}${C_RESET} ${C_DARK_GRAY}[default: ${default}]${C_RESET}"
  if [[ -n "$example" ]]; then
    echo -e "  ${C_DARK_GRAY}Example: ${example}${C_RESET}"
  fi
  if [[ -n "$desc" ]]; then
    echo -e "  ${C_DARK_GRAY}${desc}${C_RESET}"
  fi

  echo -ne "${C_WHITE}${PROMPT_CHAR}${C_RESET} "
  read -r user_input

  if [[ -z "$user_input" ]]; then
    eval "$result_var=\"\$default\""
  else
    eval "$result_var=\"\$user_input\""
  fi
}
# CORE FUNCTIONS
tms_list_pretty() {
  local raw_list
  raw_list=$(tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_attached}|#{session_created}' 2>/dev/null || true)

  if [[ -z "$raw_list" ]]; then
    echo -e "  ${C_DARK_GRAY}No active tmux sessions found.${C_RESET}\n"
    return 1
  fi

  # Perfectly aligned fixed-width headers
  echo -e "\n  ${C_BOLD}${C_WHITE}┌──────────────────────────────────────────────────────────┐${C_RESET}"
  printf "  ${C_BOLD}${C_WHITE}│ %-2s  %-20s  %-12s  %-16s │${C_RESET}\n" "St" "Session Name" "Windows" "Created Date"
  echo -e "  ${C_DARK_GRAY}├──────────────────────────────────────────────────────────┤${C_RESET}"

  while IFS='|' read -r name windows attached created_ts; do
    local formatted_time
    formatted_time=$(format_timestamp "$created_ts")

    # Truncate names for perfect column alignment
    local display_name="$name"
    if [ ${#display_name} -gt 19 ]; then
      display_name="${display_name:0:16}..."
    fi

    # Format strings
    local display_win="${windows} idle"
    local c_row="${C_DARK_GRAY}"
    local status_icon="${GLYPH_INACTIVE}"

    if [[ "$attached" -eq 1 ]]; then
      c_row="${C_GREEN}"
      status_icon="${GLYPH_ACTIVE}"
      display_win="${windows} active"
    fi

    # Apply ANSI color codes outside the %s formatter to keep alignment locked
    printf "  │ ${c_row}%b${C_RESET}   ${c_row}%-20s${C_RESET}  ${c_row}%-12s${C_RESET}  ${c_row}%-16s${C_RESET} │\n" "$status_icon" "$display_name" "$display_win" "$formatted_time"
  done <<<"$raw_list"

  echo -e "  ${C_BOLD}${C_WHITE}└──────────────────────────────────────────────────────────┘${C_RESET}\n"
}
tms_new() {
  local name
  name=$(sanitize_session_name "${1:-}")

  if tmux has-session -t "$name" 2>/dev/null; then
    echo -e "${C_DARK_GRAY}Session '${name}' already exists. Switching to it...${C_RESET}"
    tms_attach "$name"
    return 0
  fi

  tmux new-session -d -s "$name"
  echo -e "${C_GREEN}✔ Created detached session '${name}' successfully!${C_RESET}"
}
tms_attach() {
  local name="${1:-}"

  if ! tmux has-session -t "$name" 2>/dev/null; then
    echo -e "${C_RED}✖ Error: Session '${name}' does not exist.${C_RESET}"
    return 1
  fi

  if [[ -n "${TMUX:-}" ]]; then
    echo -e "${C_CYAN}Switching context to '${name}'...${C_RESET}"
    tmux switch-client -t "$name"
  else
    echo -e "${C_CYAN}Attaching to session '${name}'...${C_RESET}"
    exec tmux attach -t "$name"
  fi
}
tms_kill() {
  local name="${1:-}"

  if ! tmux has-session -t "$name" 2>/dev/null; then
    echo -e "${C_RED}✖ Error: Session '${name}' does not exist.${C_RESET}"
    return 1
  fi

  tmux kill-session -t "$name"
  echo -e "${C_GREEN}✔ Session '${name}' has been terminated.${C_RESET}"
}
# STEP-BY-STEP WIZARD (100% Real-Time Live Data)
tms_wizard() {
  echo -e "\n${C_CYAN}${C_BOLD}Tmux Session${C_RESET}"

  local action
  ask_user "Action: list, new, attach, or kill" "list" "new" "Requires tmux; Termux users can install with pkg install tmux." action

  case "$action" in
  list)
    tms_list_pretty
    ;;
  new)
    # Dynamic Fallback: Safely sanitize the current directory name
    local current_dir="${PWD##*/}"
    current_dir="${current_dir,,}"
    current_dir="${current_dir//[^a-z0-9_-]/-}"
    local def_new="${current_dir:-temp-session}"

    local new_name
    ask_user "New session name" "$def_new" "e.g., dev, sandbox, api-server" "Short memorable names are best." new_name
    tms_new "$new_name"
    ;;
  attach)
    # Pull live list of active sessions
    read -ra sess_arr <<<"$(get_live_sessions)"

    if [[ ${#sess_arr[@]} -eq 0 ]]; then
      echo -e "  ${C_RED}✖ Error: No active sessions to attach to. Create one first!${C_RESET}"
      return 1
    fi

    # Format real-time list of all sessions for the "Example:" prompt line
    local session_examples
    session_examples=$(
      IFS=", "
      echo "${sess_arr[*]}"
    )

    # Automatically set default to the most active/recent session
    local latest_active
    latest_active=$(get_latest_active_session)

    local attach_name
    ask_user "Session name to attach" "$latest_active" "$session_examples" "Attaching hands control to tmux." attach_name
    tms_attach "$attach_name"
    ;;
  kill)
    # Pull live list of active sessions
    read -ra sess_arr <<<"$(get_live_sessions)"
    local active_count=${#sess_arr[@]}

    if [[ $active_count -eq 0 ]]; then
      echo -e "  ${C_RED}✖ Error: No active sessions running to kill.${C_RESET}"
      return 1
    fi

    # Format real-time list of all sessions for the "Example:" prompt line
    local session_examples
    session_examples=$(
      IFS=", "
      echo "${sess_arr[*]}"
    )

    # Automatically set default to the most active/recent session
    local latest_active
    latest_active=$(get_latest_active_session)

    local kill_name
    ask_user "Session name to kill" "$latest_active" "$session_examples" "This closes the tmux session (${active_count} active)." kill_name
    tms_kill "$kill_name"
    ;;
  *)
    echo -e "${C_RED}✖ Unknown action: $action${C_RESET}"
    ;;
  esac
}
# ROUTING LOGIC
tms_usage() {
  echo -e "Usage: $(basename "$0") [--list | --new NAME | --attach NAME | --kill NAME]"
}

tms_main() {
  uk_banner "tmux-session" "Friendly wrapper for tmux list / new / attach / kill" "" "$@"
  local action="wizard"
  local name=""

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    -l | --list) action="list" ;;
    -n | --new)
      action="new"
      shift
      name="${1:-}"
      ;;
    -a | --attach)
      action="attach"
      shift
      name="${1:-}"
      ;;
    -k | --kill)
      action="kill"
      shift
      name="${1:-}"
      ;;
    -h | --help)
      tms_usage
      return 0
      ;;
    *)
      tms_usage
      return 1
      ;;
    esac
    shift
  done

  uk_has_cmd tmux || {
    echo -e "${C_RED}✖ Error: tmux is not installed.${C_RESET}" >&2
    return 1
  }
  case "$action" in
  wizard) tms_wizard ;;
  list) tms_list_pretty ;;
  new) tms_new "$name" ;;
  attach) tms_attach "$name" ;;
  kill) tms_kill "$name" ;;
  esac
}
# Entry point execution guard
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  tms_main "$@"
fi
