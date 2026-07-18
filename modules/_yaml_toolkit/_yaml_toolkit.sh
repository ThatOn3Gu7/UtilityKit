#!/usr/bin/env bash
# _yaml_toolkit — lint, validate, YAML↔JSON convert, key extract, merge.
# Prefix: yt_
# Backends: yq (Go version, preferred), python3 with PyYAML (fallback)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_has_cmd  >/dev/null 2>&1; then uk_has_cmd()  { command -v "${1:-}" >/dev/null 2>&1; }; fi
if ! declare -f uk_error    >/dev/null 2>&1; then uk_error()    { printf "[ERR] %s\n" "$*" >&2; }; fi
if ! declare -f uk_warn     >/dev/null 2>&1; then uk_warn()     { printf "[WRN] %s\n" "$*" >&2; }; fi
if ! declare -f uk_info     >/dev/null 2>&1; then uk_info()     { printf "[INF] %s\n" "$*"; }; fi
if ! declare -f uk_success  >/dev/null 2>&1; then uk_success()  { printf "[OK]  %s\n" "$*"; }; fi
if ! declare -f uk_note     >/dev/null 2>&1; then uk_note()     { printf "-> %s\n" "$*"; }; fi
if ! declare -f uk_banner   >/dev/null 2>&1; then uk_banner()   { :; }; fi
if ! declare -f uk_prompt   >/dev/null 2>&1; then
  uk_prompt() {
    local label="${1:-}" default="${2:-}" reply=''
    printf '> %s%s: ' "$label" "${default:+ [$default]}" >&2
    if [[ -r /dev/tty ]]; then read -r reply </dev/tty; else read -r reply; fi
    printf '%s\n' "${reply:-$default}"
  }
fi
if ! declare -f uk_confirm  >/dev/null 2>&1; then
  uk_confirm() {
    local reply=''
    printf '> %s [y/N]: ' "${1:-Confirm?}" >&2
    if [[ -r /dev/tty ]]; then read -r reply </dev/tty; else read -r reply; fi
    [[ "$reply" =~ ^[Yy] ]]
  }
fi
if ! declare -f uk_platform >/dev/null 2>&1; then
  uk_platform() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then echo termux
    elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then echo macos
    else echo linux; fi
  }
fi
if ! declare -f uk_expand_path >/dev/null 2>&1; then
  uk_expand_path() { local i="${1:-}"; printf '%s\n' "${i/#\~/$HOME}"; }
fi
# --------------------------

yt_usage() {
  cat <<'USAGE'
Usage:
  _yaml_toolkit.sh <subcommand> FILE [OPTIONS]

Subcommands:
  lint FILE         Validate YAML syntax.
  tojson FILE       Convert YAML to JSON.
  toyml FILE        Convert JSON to YAML.
  get FILE KEY      Extract a value by dot-notation key (e.g. a.b.c).
  merge BASE OVERLAY  Merge OVERLAY YAML into BASE YAML.
  keys FILE         List top-level keys.
  pretty FILE       Pretty-print with syntax highlighting.

Options:
  --indent N        Indentation spaces for output (default 2).
  --no-doc          Strip document separators (---, ...).
  --json            Machine-readable JSON output (for lint, keys).
  --no-color        Disable ANSI (also respects NO_COLOR=1).
  -h, --help        Show this help.

Backends: yq (preferred, Go) → python3 + PyYAML (fallback).

Examples:
  _yaml_toolkit.sh lint config.yaml
  _yaml_toolkit.sh tojson config.yaml
  _yaml_toolkit.sh get config.yaml database.host
  _yaml_toolkit.sh keys config.yaml
  _yaml_toolkit.sh merge base.yaml overlay.yaml
USAGE
}

# ---- Helpers ---------------------------------------------------------------

yt_hr() {
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}

yt_section() {
  local title="${1:-}"
  printf '\n%s%s%s%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$title" "${UK_C_RESET:-}"
  yt_hr
}

# Reuse the canonical escaping helper from uk_common.sh.
# shellcheck disable=SC2312
yt_json_escape() { uk_json_escape "${1:-}"; }
if ! declare -f uk_json_escape >/dev/null 2>&1; then
  yt_json_escape() {
    local s="${1:-}"
    if uk_has_cmd python3; then
      python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
    else
      s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
      s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
      printf '"%s"' "$s"
    fi
  }
fi

yt_detect_backend() {
  if uk_has_cmd yq; then
    printf 'yq\n'; return 0
  fi
  if uk_has_cmd python3 && python3 -c 'import yaml' >/dev/null 2>&1; then
    printf 'python\n'; return 0
  fi
  return 1
}

yt_require_backend() {
  local backend
  backend="$(yt_detect_backend 2>/dev/null || true)"
  if [[ -z "$backend" ]]; then
    uk_error "No YAML backend found. Install one of:"
    printf '   %s* yq (Go)    —  snap install yq  |  brew install yq%s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    printf '   %s* python3 yaml —  pip install pyyaml%s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    case "$(uk_platform 2>/dev/null || echo unknown)" in
      termux) printf '   %sTermux:%s pip install pyyaml\n' "${UK_C_YELLOW:-}" "${UK_C_RESET:-}" ;;
      linux)  printf '   %sLinux:%s  pip install pyyaml  |  snap install yq\n' "${UK_C_YELLOW:-}" "${UK_C_RESET:-}" ;;
    esac
    return 2
  fi
  printf '%s\n' "$backend"
}

# ---- Lint ------------------------------------------------------------------

yt_cmd_lint() {
  local file="$1" as_json="$2"
  local backend
  backend="$(yt_require_backend)" || return $?

  case "$backend" in
    yq)
      if yq eval '.' "$file" >/dev/null 2>&1; then
        (( as_json )) && printf '{"ok":true,"file":%s}\n' "$(yt_json_escape "$file")" || uk_success "Valid YAML: $file"
        return 0
      else
        local err
        err="$(yq eval '.' "$file" 2>&1 || true)"
        (( as_json )) && printf '{"ok":false,"file":%s,"error":%s}\n' "$(yt_json_escape "$file")" "$(yt_json_escape "$err")" || {
          uk_error "Invalid YAML: $file"
          printf '  %s\n' "$err"
        }
        return 1
      fi
      ;;
    python)
      if python3 -c '
import sys, yaml
try:
    with open(sys.argv[1]) as f:
        yaml.safe_load(f)
    print("OK")
except yaml.YAMLError as e:
    print(f"INVALID: {e}")
    sys.exit(1)
' "$file" >/dev/null 2>&1; then
        (( as_json )) && printf '{"ok":true,"file":%s}\n' "$(yt_json_escape "$file")" || uk_success "Valid YAML: $file"
        return 0
      else
        local err
        err="$(python3 -c '
import sys, yaml
try:
    with open(sys.argv[1]) as f:
        yaml.safe_load(f)
except yaml.YAMLError as e:
    print(e)
' "$file" 2>/dev/null)"
        (( as_json )) && printf '{"ok":false,"file":%s,"error":%s}\n' "$(yt_json_escape "$file")" "$(yt_json_escape "$err")" || {
          uk_error "Invalid YAML: $file"
          printf '  %s\n' "$err"
        }
        return 1
      fi
      ;;
  esac
}

# ---- To JSON ----------------------------------------------------------------

yt_cmd_tojson() {
  local file="$1" indent="$2"
  local backend
  backend="$(yt_require_backend)" || return $?

  case "$backend" in
    yq)
      yq eval -o=json -I="$indent" '.' "$file" 2>/dev/null || {
        uk_error "yq conversion failed."
        return 1
      }
      ;;
    python)
      python3 -c '
import sys, json, yaml
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f)
indent = int(sys.argv[2]) if len(sys.argv) > 2 else 2
print(json.dumps(data, indent=indent, ensure_ascii=False))
' "$file" "$indent" 2>/dev/null || {
        uk_error "Python YAML conversion failed."
        return 1
      }
      ;;
  esac
}

# ---- To YAML ----------------------------------------------------------------

yt_cmd_toyml() {
  local file="$1" indent="$2"
  local backend
  backend="$(yt_require_backend)" || return $?

  case "$backend" in
    yq)
      yq eval -P -I="$indent" '.' "$file" 2>/dev/null || {
        uk_error "yq conversion failed."
        return 1
      }
      ;;
    python)
      python3 -c '
import sys, json, yaml
with open(sys.argv[1]) as f:
    data = json.load(f)
indent = int(sys.argv[2]) if len(sys.argv) > 2 else 2
yaml.dump(data, sys.stdout, indent=indent, allow_unicode=True, sort_keys=False)
' "$file" "$indent" 2>/dev/null || {
        uk_error "Python JSON→YAML conversion failed."
        return 1
      }
      ;;
  esac
}

# ---- Get key ----------------------------------------------------------------

yt_cmd_get() {
  local file="$1" key="$2" indent="$3"
  [[ "$key" =~ ^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)*$ ]] || { uk_error "Invalid dot-path key: $key"; return 1; }
  local backend
  backend="$(yt_require_backend)" || return $?

  case "$backend" in
    yq)
      yq eval ".${key}" "$file" 2>/dev/null || {
        uk_error "Key not found: $key"
        return 1
      }
      ;;
    python)
      python3 -c '
import sys, yaml
path, file = sys.argv[1], sys.argv[2]
with open(file) as f:
    data = yaml.safe_load(f)
parts = path.split(".")
cur = data
for p in parts:
    if isinstance(cur, dict):
        cur = cur.get(p)
    elif isinstance(cur, list) and p.isdigit():
        cur = cur[int(p)]
    else:
        print(f"Key not found: {path}", file=sys.stderr)
        sys.exit(1)
if cur is None:
    print("null")
elif isinstance(cur, (dict, list)):
    import json
    print(json.dumps(cur, indent=2, ensure_ascii=False))
else:
    print(cur)
' "$key" "$file" 2>/dev/null || return 1
      ;;
  esac
}

# ---- Merge ------------------------------------------------------------------

yt_cmd_merge() {
  local base="$1" overlay="$2" indent="$3"
  local backend
  backend="$(yt_require_backend)" || return $?

  case "$backend" in
    yq)
      yq eval-all -I="$indent" 'select(fi == 0) * select(fi == 1)' "$base" "$overlay" 2>/dev/null || {
        uk_error "Merge failed."
        return 1
      }
      ;;
    python)
      python3 -c '
import sys, yaml
base_file, overlay_file = sys.argv[1], sys.argv[2]
indent = int(sys.argv[3]) if len(sys.argv) > 3 else 2
with open(base_file) as f:
    base = yaml.safe_load(f)
with open(overlay_file) as f:
    overlay = yaml.safe_load(f)
import copy
def deep_merge(a, b):
    result = copy.deepcopy(a)
    for k, v in b.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = deep_merge(result[k], v)
        else:
            result[k] = copy.deepcopy(v)
    return result
merged = deep_merge(base or {}, overlay or {})
yaml.dump(merged, sys.stdout, indent=indent, allow_unicode=True, sort_keys=False)
' "$base" "$overlay" "$indent" 2>/dev/null || {
        uk_error "Merge failed."
        return 1
      }
      ;;
  esac
}

# ---- Keys -------------------------------------------------------------------

yt_cmd_keys() {
  local file="$1" as_json="$2"
  local backend
  backend="$(yt_require_backend)" || return $?

  case "$backend" in
    yq)
      if (( as_json )); then
        yq eval -o=json '.' "$file" 2>/dev/null | python3 -c '
import sys, json
data = json.load(sys.stdin)
if isinstance(data, dict):
    print(json.dumps(list(data.keys()), ensure_ascii=False))
else:
    print("[]")
' 2>/dev/null || { uk_error "Unable to enumerate YAML keys."; return 1; }
      else
        yq eval 'keys | .[]' "$file" 2>/dev/null | sort || { uk_error "Unable to enumerate YAML keys."; return 1; }
      fi
      ;;
    python)
      python3 -c '
import sys, yaml, json
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f)
as_json = len(sys.argv) > 2 and sys.argv[2] == "1"
if isinstance(data, dict):
    keys = sorted(data.keys())
    if as_json:
        import json
        print(json.dumps(keys, ensure_ascii=False))
    else:
        for k in keys:
            print(k)
' "$file" "$as_json" 2>/dev/null
      ;;
  esac
}

# ---- Pretty ----------------------------------------------------------------

yt_cmd_pretty() {
  local file="$1" indent="$2"
  local backend
  backend="$(yt_require_backend)" || return $?

  case "$backend" in
    yq)
      yq eval -P -I="$indent" '.' "$file" 2>/dev/null || {
        uk_error "yq processing failed."
        return 1
      }
      ;;
    python)
      python3 -c '
import sys, yaml
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f)
indent = int(sys.argv[2]) if len(sys.argv) > 2 else 2
yaml.dump(data, sys.stdout, indent=indent, allow_unicode=True, sort_keys=False, default_flow_style=False)
' "$file" "$indent" 2>/dev/null || {
        uk_error "Processing failed."
        return 1
      }
      ;;
  esac
}

# ---- Main ------------------------------------------------------------------

yt_main() {
  uk_banner "yaml-toolkit" "Lint, convert, query, and merge YAML files" "" "$@"

  local sub="" indent=2 as_json=0
  local -a args=()

  if [[ $# -gt 0 ]]; then
    case "${1:-}" in
      lint|tojson|toyml|get|merge|keys|pretty) sub="$1"; shift ;;
      -h|--help) yt_usage; return 0 ;;
    esac
  fi

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --indent)  shift; indent="${1:-2}" ;;
      --no-doc)  ;;
      --json)    as_json=1 ;;
      --no-color) UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                  UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help) yt_usage; return 0 ;;
      -*)        uk_error "Unknown option: ${1:-}"; yt_usage; return 2 ;;
      *)         args+=("$1") ;;
    esac
    shift || true
  done

  [[ "$indent" =~ ^[0-9]+$ ]] || { uk_error "--indent must be numeric."; return 2; }

  local file="" key="" base="" overlay=""
  case "$sub" in
    lint|tojson|toyml|keys|pretty)
      file="${args[0]:-}"
      [[ -z "$file" ]] && { uk_error "FILE required."; yt_usage; return 2; }
      [[ -f "$file" ]] || { uk_error "File not found: $file"; return 2; }
      ;;
    get)
      file="${args[0]:-}"; key="${args[1]:-}"
      [[ -z "$file" || -z "$key" ]] && { uk_error "get requires FILE and KEY."; return 2; }
      [[ -f "$file" ]] || { uk_error "File not found: $file"; return 2; }
      ;;
    merge)
      base="${args[0]:-}"; overlay="${args[1]:-}"
      [[ -z "$base" || -z "$overlay" ]] && { uk_error "merge requires BASE and OVERLAY files."; return 2; }
      [[ -f "$base" ]] || { uk_error "File not found: $base"; return 2; }
      [[ -f "$overlay" ]] || { uk_error "File not found: $overlay"; return 2; }
      ;;
    *) yt_usage; return 2 ;;
  esac

  case "$sub" in
    lint)    yt_cmd_lint "$file" "$as_json" ;;
    tojson)  yt_cmd_tojson "$file" "$indent" ;;
    toyml)   yt_cmd_toyml "$file" "$indent" ;;
    get)     yt_cmd_get "$file" "$key" "$indent" ;;
    merge)   yt_cmd_merge "$base" "$overlay" "$indent" ;;
    keys)    yt_cmd_keys "$file" "$as_json" ;;
    pretty)  yt_cmd_pretty "$file" "$indent" ;;
  esac
}

yt_wizard() {
  uk_banner "yaml-toolkit" "Lint, convert, query, and merge YAML files" ""
  local sub file key base overlay jsonf

  sub="$(uk_prompt 'Action: lint, tojson, toyml, get, merge, keys, pretty' 'lint' \
    'lint | tojson | toyml | get | merge | keys | pretty' \
    'lint = validate syntax. tojson = YAML→JSON. get = extract key by path.')"

  case "$sub" in
    lint|tojson|toyml|keys|pretty)
      file="$(uk_prompt 'YAML file path' './config.yaml' './docker-compose.yml' 'Required.')"
      file="$(uk_expand_path "$file" 2>/dev/null || printf '%s' "$file")"
      if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
      local -a a=("$sub" "$file")
      [[ -n "$jsonf" ]] && a+=("$jsonf")
      yt_main "${a[@]}"
      ;;
    get)
      file="$(uk_prompt 'YAML file path' './config.yaml' './values.yaml' 'Required.')"
      file="$(uk_expand_path "$file" 2>/dev/null || printf '%s' "$file")"
      key="$(uk_prompt 'Dot-notation key' 'database.host' 'spec.containers[0].image' 'e.g. a.b.c or a[0].b')"
      yt_main get "$file" "$key"
      ;;
    merge)
      base="$(uk_prompt 'Base YAML file' './base.yaml' './values.yaml' 'The base config.')"
      base="$(uk_expand_path "$base" 2>/dev/null || printf '%s' "$base")"
      overlay="$(uk_prompt 'Overlay YAML file' './overlay.yaml' './production.yaml' 'Overrides the base.')"
      overlay="$(uk_expand_path "$overlay" 2>/dev/null || printf '%s' "$overlay")"
      yt_main merge "$base" "$overlay"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    yt_wizard
  else
    yt_main "$@"
  fi
fi
