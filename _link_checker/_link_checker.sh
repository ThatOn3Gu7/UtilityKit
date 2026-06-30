#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
  source "$SCRIPT_DIR/../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "Error: %s\n" "$*" >&2; }; fi
if ! declare -f uk_has_cmd >/dev/null 2>&1; then uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }; fi

lc_usage() {
  cat <<USAGE
Usage:
  _link_checker.sh FILE... [OPTIONS]

Options:
  --http           Check live HTTP(S) links (slow).
  --timeout N      Network timeout in seconds (default: 8).
  -h, --help       Show this help.
USAGE
}
lc_main() {
  uk_banner "link-checker" "Markdown link validator with optional HTTP/HTTPS checks" "" "$@"
  local http=0 timeout=8 files=()

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --http) http=1 ;;
    --timeout)
      shift
      timeout="${1:-8}"
      ;;
    -h | --help)
      lc_usage
      return 0
      ;;
    -*)
      uk_error "Unknown option: ${1:-}"
      lc_usage
      return 1
      ;;
    *) files+=("${1:-}") ;;
    esac
    shift
  done

  if [[ ${#files[@]} -eq 0 ]]; then
    lc_usage
    return 1
  fi

  if ! uk_has_cmd python3; then
    uk_error 'python3 is required.'
    return 1
  fi

  # Pass arguments safely to python using a list logic
  python3 - "$http" "$timeout" "${files[@]}" <<'PY'
import sys, re, urllib.request, urllib.error

do_http = sys.argv[1] == '1'
timeout = int(sys.argv[2])
files = sys.argv[3:]

for f in files:
    print(f"\nChecking: {f}")
    try:
        with open(f, 'r', encoding='utf-8') as file:
            text = file.read()
    except Exception as e:
        print(f"  ERR: Could not read file: {e}")
        continue

    links = re.findall(r'\[[^\]]*\]\(([^)\s]+)', text)
    for link in links:
        t = link.split('#', 1)[0]
        if not t or t.startswith(('mailto:', '#')): continue
        
        if t.startswith(('http://', 'https://')):
            if do_http:
                try:
                    # Enforce the timeout explicitly
                    urllib.request.urlopen(t, timeout=timeout)
                    print(f"  [OK] {t}")
                except Exception as e:
                    print(f"  [BAD] {t} ({e})")
            else:
                print(f"  [SKIPPED] {t}")
PY
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  lc_main "$@"
fi
