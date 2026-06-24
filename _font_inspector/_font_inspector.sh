#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
  source "$SCRIPT_DIR/../lib/uk_common.sh"
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
# --------------------------------------------------------

fi_usage() {
  echo 'Usage: _font_inspector.sh [--list] [--filter NAME] [--glyphs]'
}

fi_main() {
  local list=0
  local filter=''
  local glyphs=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
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
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" font
  else
    fi_main "$@"
  fi
fi
