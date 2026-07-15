#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
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
  [[ "$timeout" =~ ^[1-9][0-9]*$ ]] && ((timeout <= 300)) || { uk_error "--timeout must be in 1..300."; return 1; }
  python3 - "$http" "$timeout" "${files[@]}" <<'PY'
import sys, re, urllib.request, urllib.parse, socket, ipaddress, os

do_http = sys.argv[1] == '1'
timeout = int(sys.argv[2])
files = sys.argv[3:]
failures = 0

def public_http_target(url):
    host = urllib.parse.urlsplit(url).hostname
    if not host:
        return False, 'missing hostname'
    try:
        addresses = {item[4][0] for item in socket.getaddrinfo(host, None)}
    except OSError as e:
        return False, f'DNS failure: {e}'
    for address in addresses:
        ip = ipaddress.ip_address(address.split('%', 1)[0])
        if not ip.is_global:
            return False, f'blocked non-public address: {ip}'
    return True, ''

for f in files:
    print(f"\nChecking: {f}")
    try:
        with open(f, 'r', encoding='utf-8') as file:
            text = file.read()
    except Exception as e:
        print(f"  ERR: Could not read file: {e}")
        failures += 1
        continue

    base = os.path.dirname(os.path.abspath(f))
    links = re.findall(r'\[[^\]]*\]\(([^)\s]+)', text)
    for link in links:
        target = link.split('#', 1)[0]
        if not target or target.startswith(('mailto:', '#')):
            continue
        if target.startswith(('http://', 'https://')):
            if do_http:
                allowed, reason = public_http_target(target)
                if not allowed:
                    print(f"  [BAD] {target} ({reason})")
                    failures += 1
                    continue
                try:
                    with urllib.request.urlopen(target, timeout=timeout) as response:
                        response.read(1)
                    print(f"  [OK] {target}")
                except Exception as e:
                    print(f"  [BAD] {target} ({e})")
                    failures += 1
            else:
                print(f"  [SKIPPED] {target}")
        else:
            local = os.path.normpath(os.path.join(base, urllib.parse.unquote(target)))
            if os.path.exists(local):
                print(f"  [OK] {target}")
            else:
                print(f"  [BAD] {target} (missing local target)")
                failures += 1
sys.exit(1 if failures else 0)
PY
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  lc_main "$@"
fi
