#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi
# --- Fallback Functions if not defined in uk_common.sh ---
if ! declare -f uk_has_cmd >/dev/null 2>&1; then
  uk_has_cmd() {
    command -v "${1:-}" >/dev/null 2>&1
  }
fi
if ! declare -f uk_warn >/dev/null 2>&1; then
  uk_warn() {
    printf "Warning: %s\n" "$*" >&2
  }
fi
fi_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s %s_font_inspector.sh [--list] [--filter NAME] [--glyphs]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Options" \
    "--list" "List available fonts on the system." \
    "--filter NAME" "Filter fonts by name pattern." \
    "--glyphs" "Display terminal glyph samples."
  uk_help_section "$w" "Examples" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_font_inspector.sh${UK_C_RESET:-}" "Show terminal glyph samples" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_font_inspector.sh${UK_C_RESET:-} ${UK_C_DIM:-}--list${UK_C_RESET:-}" "List all available fonts" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_font_inspector.sh${UK_C_RESET:-} ${UK_C_DIM:-}--filter 'Mono' --glyphs${UK_C_RESET:-}" "Filter fonts and show glyphs"
}
fi_main() {
  uk_banner "font-inspector" "Terminal glyph samples and optional font enumeration" "" "$@"
  local list=0
  local filter=''
  local glyphs=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --list)
      list=1
      shift
      ;;
    --filter)
      if [[ $# -gt 1 ]]; then
        shift
        filter="${1:-}"
        shift
      else
        uk_warn "Option --filter requires an argument."
        fi_usage
        return 1
      fi
      ;;
    --glyphs)
      glyphs=1
      shift
      ;;
    -h | --help)
      fi_usage
      return 0
      ;;
    *)
      # Safely skip/shift unknown arguments
      shift
      ;;
    esac
  done

  # Print glyph samples if explicitly requested, or if no options are specified (default behavior)
  if ((glyphs == 1 || list == 0)); then
    printf 'ASCII ABC 123\n'
    printf 'Box ┌─┐ │ ╰─╯\n'
    printf 'Powerline    \n'
  fi
  if ((list == 1)); then
    if uk_has_cmd fc-list; then
      # Under pipefail, we guard the pipeline with "|| true" to ensure it never crashes if grep finds zero matches
      fc-list : family | sort -u | grep -i -- "$filter" | head -n 10 || true
    else
      uk_warn 'fc-list unavailable; cannot list system fonts.'
    fi
  fi

  return 0
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  fi_main "$@"
fi
