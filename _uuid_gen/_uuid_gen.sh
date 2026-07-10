#!/usr/bin/env bash
# _uuid_gen — generate UUID v4, v7 (time-ordered), ULID, nanoid, short IDs.
# Prefix: ug_
# Backends: uuidgen → /dev/urandom → python3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../lib/uk_common.sh"
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
# ug_usage prints the command-line usage, supported identifier types, options, and examples.

ug_usage() {
  cat <<'USAGE'
Usage:
  _uuid_gen.sh [TYPE] [OPTIONS]

Types:
  uuid4       UUID v4 (random) — default
  uuid7       UUID v7 (time-ordered, RFC 9562)
  ulid        ULID (time-sortable, Crockford Base32)
  nanoid      NanoID (URL-safe, 21 chars default)
  short       Short ID (alphanumeric, 8 chars default)
  hex         Hex string (32 chars default)
  snowflake   Twitter-style snowflake ID (64-bit)

Options:
  --count N       Generate N IDs at once (default 1).
  --len N         Custom length (nanoid, short, hex).
  --alphabet ABC  Custom alphabet for nanoid/short.
  --upper         Uppercase output (default: lowercase).
  --sep SEP       Separator between bulk IDs (default: newline).
  --json          Machine-readable JSON array output.
  --clip          Copy result to clipboard.
  --quiet         Suppress info output.
  --no-color      Disable ANSI (also respects NO_COLOR=1).
  -h, --help      Show this help.

Examples:
  _uuid_gen.sh
  _uuid_gen.sh uuid7 --count 5
  _uuid_gen.sh nanoid --len 16
  _uuid_gen.sh ulid --count 3 --json
  _uuid_gen.sh short --upper --count 10 --sep ','
USAGE
}

# ---- Generators -----------------------------------------------------------

ug_gen_uuid4() {
  local n="$1"
  if uk_has_cmd python3; then
    python3 -c '
import sys, uuid
n = int(sys.argv[1])
for _ in range(n):
    print(uuid.uuid4())
' "$n"
  elif uk_has_cmd uuidgen; then
    local i
    for ((i=0; i<n; i++)); do uuidgen; done
  else
    local i
    for ((i=0; i<n; i++)); do
      printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x\n' \
        $((RANDOM%65536)) $((RANDOM%65536)) \
        $((RANDOM%65536)) \
        $(( (RANDOM%4096) | 0x4000 )) \
        $(( (RANDOM%16384) | 0x8000 )) \
        $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536))
    done
  fi
}

ug_gen_uuid7() {
  local n="$1"
  if uk_has_cmd python3; then
    python3 -c '
import sys, time, os, struct

n = int(sys.argv[1])
for _ in range(n):
    # UUID v7 layout: 48-bit Unix ms timestamp | 74 random bits
    ts = int(time.time() * 1000)
    rand_a = int.from_bytes(os.urandom(10), "big")
    # version = 7 in the 13th hex digit (0x7)
    hex_str = f"{ts:012x}{rand_a:010x}"
    # set version nibble (bits 48-51 = version 7)
    hex_str = hex_str[:12] + "7" + hex_str[13:16] + "8" + hex_str[17:]
    print(f"{hex_str[:8]}-{hex_str[8:12]}-{hex_str[12:16]}-{hex_str[16:20]}-{hex_str[20:]}")
' "$n"
  else
    uk_warn "uuid7 requires python3. Falling back to uuid4."
    ug_gen_uuid4 "$n"
  fi
}

# ug_gen_ulid generates `n` ULIDs and writes one identifier per line.
# When Python 3 is unavailable, it generates UUIDv4 identifiers instead.
ug_gen_ulid() {
  local n="$1"
  if uk_has_cmd python3; then
    python3 -c '
import sys, time, os

CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
n = int(sys.argv[1])
for _ in range(n):
    ts = int(time.time() * 1000)
    rand = int.from_bytes(os.urandom(10), "big")
    # 10 chars timestamp + 16 chars random
    val = (ts << 80) | rand
    ulid = ""
    for _ in range(26):
        ulid = CROCKFORD[val & 0x1f] + ulid
        val >>= 5
    print(ulid)
' "$n"
  else
    uk_warn "ULID requires python3. Falling back to uuid4."
    ug_gen_uuid4 "$n"
  fi
}

# ug_gen_nanoid generates NanoID strings using the specified alphabet.
ug_gen_nanoid() {
  local n="$1" len="$2" alphabet="${3:-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-}"
  if uk_has_cmd python3; then
    python3 -c '
import sys, secrets
n = int(sys.argv[1])
length = int(sys.argv[2])
abc = sys.argv[3]
for _ in range(n):
    print("".join(secrets.choice(abc) for _ in range(length)))
' "$n" "$len" "$alphabet"
  else
    local i
    for ((i=0; i<n; i++)); do
      LC_ALL=C tr -dc "$alphabet" </dev/urandom | head -c "$len"
      printf '\n'
    done
  fi
}

# ug_gen_short generates short identifier strings using the specified length and alphabet.
ug_gen_short() {
  local n="$1" len="$2" alphabet="${3:-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789}"
  if uk_has_cmd python3; then
    python3 -c '
import sys, secrets
n = int(sys.argv[1])
length = int(sys.argv[2])
abc = sys.argv[3]
for _ in range(n):
    print("".join(secrets.choice(abc) for _ in range(length)))
' "$n" "$len" "$alphabet"
  else
    local i
    for ((i=0; i<n; i++)); do
      LC_ALL=C tr -dc "$alphabet" </dev/urandom | head -c "$len"
      printf '\n'
    done
  fi
}

# ug_gen_hex generates `n` hexadecimal strings of the specified length.
ug_gen_hex() {
  local n="$1" len="$2"
  if uk_has_cmd python3; then
    python3 -c '
import sys, os
n = int(sys.argv[1])
length = int(sys.argv[2])
for _ in range(n):
    print(os.urandom(length // 2 + 1).hex()[:length])
' "$n" "$len"
  else
    local i j id=''
    local hexchars="0123456789abcdef"
    for ((i=0; i<n; i++)); do
      id=''
      for ((j=0; j<len; j++)); do
        id+="${hexchars:$((RANDOM % 16)):1}"
      done
      printf '%s\n' "$id"
    done
  fi
}

ug_gen_snowflake() {
  local n="$1"
  if uk_has_cmd python3; then
    python3 -c '
import sys, time, os

n = int(sys.argv[1])
# Twitter snowflake: 41-bit timestamp | 10-bit worker | 12-bit sequence
worker_id = int.from_bytes(os.urandom(1), "big") & 0x3ff
epoch = 1288834974657  # Twitter epoch (2010-11-04)
seq = 0
for _ in range(n):
    ts = int(time.time() * 1000) - epoch
    sid = ((ts & 0x1ffffffffff) << 22) | ((worker_id & 0x3ff) << 12) | (seq & 0xfff)
    print(sid)
    seq = (seq + 1) & 0xfff
' "$n"
  else
    uk_warn "Snowflake requires python3. Falling back to random hex."
    ug_gen_hex "$n" 16
  fi
}

# ug_main parses command-line options, generates identifiers, formats the output, and optionally copies it to the clipboard.

ug_main() {
  uk_banner "uuid-gen" "Generate UUID v4/v7, ULID, NanoID, short IDs" "" "$@"

  local type="uuid4"
  local count=1 length=0 upper=0 sep=$'\n' as_json=0 clip=0 quiet=0
  local alphabet=""

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      uuid4|uuid7|ulid|nanoid|short|hex|snowflake)
        type="$1" ;;
      --count)  shift; count="${1:-1}" ;;
      --len)    shift; length="${1:-0}" ;;
      --alphabet) shift; alphabet="${1:-}" ;;
      --upper)  upper=1 ;;
      --sep)    shift; sep="${1:-$'\n'}" ;;
      --json)   as_json=1 ;;
      --clip)   clip=1 ;;
      --quiet)  quiet=1 ;;
      --no-color) UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                  UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help) ug_usage; return 0 ;;
      -*)       uk_error "Unknown option: ${1:-}"; ug_usage; return 2 ;;
      *)        type="$1" ;;
    esac
    shift || true
  done

  [[ "$count" =~ ^[0-9]+$ ]] || { uk_error "--count must be a positive integer."; return 2; }
  (( count >= 1 )) || { uk_error "--count must be >= 1."; return 2; }
  (( count <= 100000 )) || { uk_error "--count is too large (max 100000)."; return 2; }
  [[ "$length" =~ ^[0-9]+$ ]] || { uk_error "--len must be a non-negative integer."; return 2; }
  (( length <= 4096 )) || { uk_error "--len is too large (max 4096)."; return 2; }

  # Default lengths per type
  case "$type" in
    nanoid)   (( length > 0 )) || length=21; [[ -z "$alphabet" ]] && alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-' ;;
    short)    (( length > 0 )) || length=8;  [[ -z "$alphabet" ]] && alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' ;;
    hex)      (( length > 0 )) || length=32 ;;
    *)        length=0 ;;
  esac
  if [[ "$type" =~ ^(nanoid|short)$ ]]; then
    (( ${#alphabet} >= 2 )) || { uk_error "--alphabet must contain at least 2 characters."; return 2; }
  fi

  local result
  case "$type" in
    uuid4)     result="$(ug_gen_uuid4 "$count")" ;;
    uuid7)     result="$(ug_gen_uuid7 "$count")" ;;
    ulid)      result="$(ug_gen_ulid "$count")" ;;
    nanoid)    result="$(ug_gen_nanoid "$count" "$length" "$alphabet")" ;;
    short)     result="$(ug_gen_short "$count" "$length" "$alphabet")" ;;
    hex)       result="$(ug_gen_hex "$count" "$length")" ;;
    snowflake) result="$(ug_gen_snowflake "$count")" ;;
    *)         uk_error "Unknown type: $type"; ug_usage; return 2 ;;
  esac

  # Upper case conversion
  if (( upper )); then
    result="$(printf '%s' "$result" | tr '[:lower:]' '[:upper:]')"
  fi

  if (( as_json )); then
    # Emit JSON array
    if uk_has_cmd python3; then
      printf '%s' "$result" | python3 -c '
import sys, json
lines = [l.rstrip("\n") for l in sys.stdin if l.strip()]
print(json.dumps(lines, ensure_ascii=False))'
    else
      printf '['; local first=1 line
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        (( first )) || printf ','
        printf '"%s"' "$(printf '%s' "$line" | sed 's/"/\\"/g')"
        first=0
      done <<<"$result"
      printf ']\n'
    fi
    return 0
  fi

  if (( count > 1 )); then
    local joined='' first=1 line
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      (( first )) || joined+="$sep"
      joined+="$line"
      first=0
    done <<<"$result"
    printf '%s\n' "$joined"
  else
    printf '%s\n' "$result"
  fi

  if (( clip )); then
    if declare -f uk_copy_to_clipboard >/dev/null 2>&1; then
      uk_copy_to_clipboard "$(printf '%s' "$result" | head -n1)"
      [[ "$quiet" == "1" ]] || uk_success "Copied to clipboard."
    else
      uk_note "Clipboard unavailable — printed to stdout."
    fi
  fi
}

ug_wizard() {
  uk_banner "uuid-gen" "Generate UUID v4/v7, ULID, NanoID, short IDs" ""
  local type count len="" upper="" jsonf="" clipf=""

  type="$(uk_prompt 'Type: uuid4, uuid7, ulid, nanoid, short, hex, snowflake' 'uuid4' \
    'uuid4 | uuid7 | ulid | nanoid | short | hex | snowflake' \
    'uuid4 = random. uuid7 = time-ordered. ulid = sortable. nanoid = URL-safe.')"
  count="$(uk_prompt 'Count (how many to generate)' '1' '5' 'Use bulk generation for scripts.')"
  [[ "$type" =~ ^(nanoid|short|hex)$ ]] && \
    len="$(uk_prompt "Custom length (default varies by type)" '' '16' 'Leave blank for type default.')"
  if uk_confirm 'Uppercase output?' 'N'; then upper="--upper"; else upper=""; fi
  if uk_confirm 'Copy to clipboard?' 'N'; then clipf="--clip"; else clipf=""; fi
  if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi

  local -a a=("$type" --count "$count")
  [[ -n "$len"    ]] && a+=(--len "$len")
  [[ -n "$upper"  ]] && a+=("$upper")
  [[ -n "$clipf"  ]] && a+=("$clipf")
  [[ -n "$jsonf"  ]] && a+=("$jsonf")
  ug_main "${a[@]}"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    ug_wizard
  else
    ug_main "$@"
  fi
fi
