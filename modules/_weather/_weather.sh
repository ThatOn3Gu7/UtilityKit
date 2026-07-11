#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try sourcing the common library if available
if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Utilities (Ensures standalone robustness) ---
if ! declare -F uk_has_cmd &>/dev/null; then
  uk_has_cmd() { command -v "${1:-}" &>/dev/null; }
fi

if ! declare -F uk_state_dir &>/dev/null; then
  uk_state_dir() {
    local dir="${XDG_STATE_HOME:-$HOME/.local/state}/uk"
    mkdir -p "$dir"
    echo "$dir"
  }
fi

# Modern Premium Color Palette. Use real ANSI escapes only on TTYs and honor
# NO_COLOR; otherwise keep help/piped output plain text.
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  : "${C_DARK_GRAY:=$'\033[90m'}" "${C_CYAN:=${UK_C_CYAN:-$'\033[38;5;81m'}}" "${C_GREEN:=${UK_C_GREEN:-$'\033[38;5;120m'}}" \
    "${C_RED:=${UK_C_RED:-$'\033[38;5;203m'}}" "${C_YELLOW:=${UK_C_YELLOW:-$'\033[38;5;221m'}}" "${C_WHITE:=${UK_C_WHITE:-$'\033[97m'}}" \
    "${C_BOLD:=${UK_C_BOLD:-$'\033[1m'}}" "${C_RESET:=${UK_C_RESET:-$'\033[0m'}}"
else
  : "${C_DARK_GRAY:=}" "${C_CYAN:=}" "${C_GREEN:=}" "${C_RED:=}" "${C_YELLOW:=}" "${C_WHITE:=}" "${C_BOLD:=}" "${C_RESET:=}"
fi

if [[ -t 1 && -z "${NO_UNICODE:-}" ]]; then PROMPT_CHAR="❯"; else PROMPT_CHAR=">"; fi

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
# CORE WEATHER ENGINE
wt_fetch() {
  local loc="${1:-}"
  local units="${2:-}"
  local style="${3:-}"

  local cache_dir
  cache_dir="$(uk_state_dir)"
  local cache="${cache_dir}/weather_last.txt"

  # u=m for metric, u=u for imperial
  local u="m"
  [[ "$units" == "imperial" ]] && u="u"

  # URL encode location if one is provided
  local encoded_loc=""
  if [[ -n "$loc" && "$loc" != "auto" ]]; then
    encoded_loc="$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))' "$loc")"
  fi

  # Build target query url
  local query="https://wttr.in/${encoded_loc}?${u}"
  if [[ "$style" == "concise" ]]; then
    # format=3 outputs the crisp 1-liner
    query="https://wttr.in/${encoded_loc}?format=3&${u}"
  fi

  # Guard: Curl required
  if ! uk_has_cmd curl; then
    echo -e "  ${C_RED}✖ Error: curl is not installed.${C_RESET}"
    if [[ -f "$cache" ]]; then
      echo -e "  ${C_YELLOW}⚠ Showing last cached weather:${C_RESET}"
      cat "$cache"
    fi
    return 1
  fi

  echo -e "  ${C_CYAN}Fetching live weather data...${C_RESET}"

  local raw_output
  # Execute curl silently, capture output, enforce 8s max timeout
  if ! raw_output=$(curl -fsS --max-time 8 "$query"); then
    # Clear the "Fetching..." text
    echo -ne "\033[1A\033[2K"
    echo -e "  ${C_RED}✖ Error: Weather lookup failed (Timeout or Offline).${C_RESET}"

    # Graceful Cache Fallback
    if [[ -f "$cache" ]]; then
      echo -e "\n  ${C_YELLOW}Showing last cached data:${C_RESET}"
      echo -e "  ${C_DARK_GRAY}│${C_RESET}"
      while IFS= read -r line || [[ -n "$line" ]]; do
        echo -e "  ${C_DARK_GRAY}│${C_RESET}  ${line}"
      done <"$cache"
      echo -e "  ${C_DARK_GRAY}│${C_RESET}\n"
    fi
    return 1
  fi

  # Cache the successful output
  echo "$raw_output" >"$cache"

  # Clear the "Fetching..." text line
  echo -ne "\033[1A\033[2K"

  # Display logic based on chosen style
  if [[ "$style" == "concise" ]]; then
    # Print the sleek modern vertical UI bar for concise 1-liners
    echo -e "  ${C_CYAN}│${C_RESET}"
    echo -e "  ${C_CYAN}│${C_RESET}  ${raw_output}"
    echo -e "  ${C_CYAN}│${C_RESET}\n"
  else
    # Full wttr.in ascii art layout
    echo ""
    echo "$raw_output"
    echo ""
  fi
}
# INTERACTIVE WIZARD
wt_wizard() {
  echo -e "\n${C_CYAN}${C_BOLD}✦ Weather Station${C_RESET}"

  local loc
  ask_user "Location" "auto" "London, Tokyo, 90210" "Leave as 'auto' for IP-based detection." loc

  # Map 'auto' back to empty string for wttr.in to handle
  [[ "$loc" == "auto" ]] && loc=""

  local style
  ask_user "Display Style" "concise" "concise, full" "Full shows a beautiful 3-day ASCII forecast." style

  local units
  ask_user "Units" "metric" "metric, imperial" "Temperature format." units

  echo ""
  wt_fetch "$loc" "$units" "$style"
}
# ROUTING & CLI LOGIC
wt_usage() {
  cat <<EOF
${C_BOLD}${C_CYAN}Weather Station CLI${C_RESET}
Usage: $(basename "$0") [LOCATION] [OPTIONS]

Options:
  --units metric|imperial  Set temperature format (default: metric)
  --full                   Show full 3-day ASCII forecast
  --concise                Show compact 1-line weather (default)
  -h, --help               Show this help screen

Examples:
  $(basename "$0")                  # Launches the interactive wizard!
  $(basename "$0") London           # Quick concise check for London
  $(basename "$0") Tokyo --full     # Full 3-day forecast for Tokyo
EOF
}
wt_main() {
  uk_banner "weather" "Current weather from wttr.in with offline cache fallback" "" "$@"
  local loc=""
  local units="metric"
  local style="concise"
  local action="wizard"

  # If arguments are passed, bypass the wizard and act instantly
  if [[ $# -gt 0 ]]; then
    action="cli"
  fi

  # Parse command line flags
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --units)
      shift
      units="${1:-metric}"
      ;;
    --full)
      style="full"
      ;;
    --concise)
      style="concise"
      ;;
    -h | --help)
      wt_usage
      return 0
      ;;
    *)
      # Accumulate unquoted strings (e.g., New York -> New York)
      if [[ -z "$loc" ]]; then
        loc="${1:-}"
      else
        loc="$loc ${1:-}"
      fi
      ;;
    esac
    shift
  done

  # Execute desired flow
  if [[ "$action" == "wizard" ]]; then
    wt_wizard
  else
    wt_fetch "$loc" "$units" "$style"
  fi
}
# ENTRY POINT (Standalone Safe)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  wt_main "$@"
fi
