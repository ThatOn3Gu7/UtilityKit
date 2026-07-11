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
# --------------------------

jx_usage() {
  cat <<USAGE
Usage:
  _json_explorer.sh [FILE|-] [OPTIONS]

Options:
  --path a.b.0  Traverse JSON path (e.g., users.0.name)
  --keys        List keys at the current path
  --summary     Print summary of structure
  -h, --help    Show this help
USAGE
}
jx_main() {
  uk_banner "json-explorer" "JSON pretty-print, dot-path extraction, key listing" "" "$@"
  local file='-'
  local path=''
  local keys=0
  local summary=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --path)
      shift
      path="${1:-}"
      ;;
    --keys) keys=1 ;;
    --summary) summary=1 ;;
    -h | --help)
      jx_usage
      return 0
      ;;
    -*)
      uk_error "Unknown option: ${1:-}"
      jx_usage
      return 1
      ;;
    *) file="${1:-}" ;;
    esac
    shift
  done

  # Validate dependency
  if ! uk_has_cmd python3; then
    uk_error 'python3 is required for portable JSON parsing.'
    return 1
  fi

  # Validate file existence (unless reading from stdin)
  if [[ "$file" != "-" && ! -f "$file" ]]; then
    uk_error "File not found: $file"
    return 1
  fi

  # Execute Python logic
  python3 - "$file" "$path" "$keys" "$summary" <<'PY'
import json, sys

file, path, keys, summary = sys.argv[1], sys.argv[2], sys.argv[3] == '1', sys.argv[4] == '1'

# Read input
try:
    if file == '-':
        if sys.stdin.isatty():
            raise Exception("No input provided via pipe or file.")
        content = sys.stdin.read()
    else:
        with open(file, encoding='utf-8') as f:
            content = f.read()
    data = json.loads(content)
except Exception as e:
    print(f'[ERR] Invalid JSON input: {e}', file=sys.stderr)
    sys.exit(1)

# Traversal logic
def get(o, p):
    for part in [x for x in p.split('.') if x]:
        if isinstance(o, list) and part.isdigit():
            o = o[int(part)]
        elif isinstance(o, dict):
            o = o[part]
        else:
            raise KeyError(f"Path part '{part}' not found in {type(o)}")
    return o

try:
    obj = get(data, path) if path else data
except Exception as e:
    print(f'[ERR] Path not found: {e}', file=sys.stderr)
    sys.exit(1)

if keys:
    if isinstance(obj, dict):
        print('\n'.join(map(str, obj.keys())))
    elif isinstance(obj, list):
        print('\n'.join(map(str, range(len(obj)))))
elif summary:
    def walk(o, p="$"):
        if isinstance(o, dict):
            for k, v in o.items(): walk(v, f"{p}.{k}")
        elif isinstance(o, list):
            for i, v in enumerate(o): walk(v, f"{p}.{i}")
        else:
            print(f"{p} ({type(o).__name__})")
    walk(obj)
else:
    print(json.dumps(obj, indent=2))
PY
}
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  jx_main "$@"
fi
