#!/usr/bin/env bash
# _time_convert — epoch ↔ ISO 8601 ↔ RFC 3339 ↔ human; cron → next N fires.
# Prefix: tc_
# Backends: date (GNU + BSD), python3 for cron parsing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Functions ---
if ! declare -f uk_has_cmd >/dev/null 2>&1; then uk_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }; fi
if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "[ERR] %s\n" "$*" >&2; }; fi
if ! declare -f uk_warn >/dev/null 2>&1; then uk_warn() { printf "[WRN] %s\n" "$*" >&2; }; fi
if ! declare -f uk_info >/dev/null 2>&1; then uk_info() { printf "[INF] %s\n" "$*"; }; fi
if ! declare -f uk_success >/dev/null 2>&1; then uk_success() { printf "[OK]  %s\n" "$*"; }; fi
if ! declare -f uk_note >/dev/null 2>&1; then uk_note() { printf "-> %s\n" "$*"; }; fi
if ! declare -f uk_banner >/dev/null 2>&1; then uk_banner() { :; }; fi
if ! declare -f uk_prompt >/dev/null 2>&1; then
  uk_prompt() {
    local label="${1:-}" default="${2:-}" reply=''
    printf '> %s%s: ' "$label" "${default:+ [$default]}" >&2
    if [[ -r /dev/tty ]]; then read -r reply </dev/tty; else read -r reply; fi
    printf '%s\n' "${reply:-$default}"
  }
fi
if ! declare -f uk_confirm >/dev/null 2>&1; then
  uk_confirm() {
    local reply=''
    printf '> %s [y/N]: ' "${1:-Confirm?}" >&2
    if [[ -r /dev/tty ]]; then read -r reply </dev/tty; else read -r reply; fi
    [[ "$reply" =~ ^[Yy] ]]
  }
fi
if ! declare -f uk_platform >/dev/null 2>&1; then
  uk_platform() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then
      echo termux
    elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then
      echo macos
    else echo linux; fi
  }
fi
# --------------------------

tc_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s _tool_name.sh %s<subcommand> [VALUE] [OPTIONS]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Subcommands" \
    "epoch [TS]" "Convert epoch (seconds) to ISO 8601 / RFC 3339 / human." \
    "parse TIMESTAMP" "Parse a timestamp string to all formats." \
    "now" "Show current time in all formats." \
    "cron EXPR" "Show next N fire times for a cron expression." \
    "tz [ZONE]" "Show timezone info (list zones or diff against another)." \
    "diff TS1 TS2" "Show duration between two timestamps."
  printf '\n'
  uk_help_section "$w" "Options" \
    "--format FORMAT" "Output format: iso, rfc3339, rfc2822, unix, human (default all)." \
    "--tz TIMEZONE" "Interpret/display in given timezone." \
    "--count N" "Number of future cron fires (default 5)." \
    "--json" "Machine-readable JSON output." \
    "--no-color" "Disable ANSI (also respects NO_COLOR=1)." \
    "-h, --help" "Show this help."
  printf '\n'
  uk_help_section "$w" "Examples" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_time_convert.sh${UK_C_RESET:-} ${UK_C_DIM:-}now${UK_C_RESET:-}" "Show current time in all formats." \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_time_convert.sh${UK_C_RESET:-} ${UK_C_DIM:-}epoch 1700000000${UK_C_RESET:-}" "Convert epoch timestamp." \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_time_convert.sh${UK_C_RESET:-} ${UK_C_DIM:-}parse '2024-01-15T10:30:00Z'${UK_C_RESET:-}" "Parse a timestamp string." \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_time_convert.sh${UK_C_RESET:-} ${UK_C_DIM:-}cron '*/15 * * * *' --count 3${UK_C_RESET:-}" "Show next cron fire times." \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_time_convert.sh${UK_C_RESET:-} ${UK_C_DIM:-}tz Asia/Tokyo${UK_C_RESET:-}" "Show timezone info." \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_time_convert.sh${UK_C_RESET:-} ${UK_C_DIM:-}diff '2024-01-01' '2024-12-31'${UK_C_RESET:-}" "Show duration between two timestamps."
}

# ---- Helpers ---------------------------------------------------------------

tc_hr() {
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}

tc_section() {
  local title="${1:-}"
  printf '\n%s%s%s%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$title" "${UK_C_RESET:-}"
  tc_hr
}

tc_json_escape() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

# Detect GNU date vs BSD date
tc_date_is_gnu() {
  date --version 2>/dev/null | grep -qi gnu
}

# Convert epoch to various formats
tc_epoch_to_formats() {
  local epoch="$1" tz="${2:-}"
  local -a tz_env=()
  if [[ -n "$tz" ]]; then
    [[ "$tz" =~ ^[A-Za-z0-9_+:/.-]+$ ]] || { uk_error "Invalid timezone: $tz"; return 1; }
    tz_env=("TZ=$tz")
  fi

  local iso='' rfc3339='' rfc2822='' human=''
  if tc_date_is_gnu; then
    iso="$(env "${tz_env[@]}" date -d "@$epoch" --iso-8601=seconds || return 1)"
    rfc3339="$(env "${tz_env[@]}" date -d "@$epoch" --rfc-3339=seconds || return 1)"
    rfc2822="$(env "${tz_env[@]}" date -d "@$epoch" -R || return 1)"
    human="$(env "${tz_env[@]}" date -d "@$epoch" '+%A, %B %d, %Y at %H:%M:%S %Z' || return 1)"
  elif date -r "$epoch" '+%s' >/dev/null 2>&1; then
    local f
    f="$(env "${tz_env[@]}" date -r "$epoch" '+%Y-%m-%dT%H:%M:%S%z' || return 1)"
    iso="$f"
    rfc3339="${f%+*}+${f##*+}"
    rfc2822="$(env "${tz_env[@]}" date -r "$epoch" -R || return 1)"
    human="$(env "${tz_env[@]}" date -r "$epoch" '+%A, %B %d, %Y at %H:%M:%S %Z' || return 1)"
  elif uk_has_cmd python3; then
    iso="$(python3 -c "
from datetime import datetime, timezone
dt = datetime.fromtimestamp($epoch, tz=timezone.utc)
print(dt.isoformat())
" || return 1)"
    rfc3339="$iso"
    rfc2822="$(python3 -c "
from datetime import datetime, timezone
dt = datetime.fromtimestamp($epoch, tz=timezone.utc)
print(dt.strftime('%a, %d %b %Y %H:%M:%S %z'))
" || return 1)"
    human="$(python3 -c "
from datetime import datetime, timezone
dt = datetime.fromtimestamp($epoch, tz=timezone.utc)
print(dt.strftime('%A, %B %d, %Y at %H:%M:%S %Z'))
" || return 1)"
  fi
  printf '%s\n%s\n%s\n%s\n' "$iso" "$rfc3339" "$rfc2822" "$human"
}

# Parse a timestamp to epoch
tc_parse_to_epoch() {
  local ts="$1" tz="${2:-}"
  if uk_has_cmd python3; then
    python3 -c '
import sys, os
from datetime import datetime
ts = sys.argv[1]
tz_name = sys.argv[2] if len(sys.argv) > 2 else ""
try:
    dt = None
    formats = [
        "%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%dT%H:%M:%SZ",
        "%Y-%m-%d %H:%M:%S", "%Y-%m-%d",
        "%a, %d %b %Y %H:%M:%S %z", "%a %b %d %H:%M:%S %Y",
        "%d/%m/%Y %H:%M:%S", "%m/%d/%Y %H:%M:%S",
        "%Y%m%dT%H%M%S", "%Y%m%d",
    ]
    for fmt in formats:
        try:
            dt = datetime.strptime(ts, fmt)
            break
        except ValueError:
            continue
    if dt is None:
        # Try isoformat parser
        from datetime import datetime as dt2
        try:
            dt = dt2.fromisoformat(ts)
        except Exception:
            pass
    if dt is None:
        print("error=unable to parse timestamp")
        sys.exit(0)
    if tz_name:
        import zoneinfo
        target = zoneinfo.ZoneInfo(tz_name)
        dt = dt.replace(tzinfo=target)
    epoch = int(dt.timestamp())
    print(epoch)
    print(dt.isoformat())
except Exception as e:
    print(f"error={e}")
' "$ts" "$tz" 2>/dev/null || printf 'error=parse failed\n'
  else
    # Fallback: try date command
    local epoch=''
    if tc_date_is_gnu; then
      epoch="$(date -d "$ts" +%s 2>/dev/null || true)"
    else
      epoch="$(date -j -f '%Y-%m-%dT%H:%M:%S' "$ts" +%s 2>/dev/null || true)"
    fi
    if [[ -n "$epoch" ]]; then
      printf '%s\n' "$epoch"
    else
      printf 'error=cannot parse (install python3 for full support)\n'
    fi
  fi
}

# ---- Epoch subcommand ------------------------------------------------------

tc_cmd_epoch() {
  local val="$1" tz="$2" fmt="$3" as_json="$4"

  if [[ -z "$val" ]]; then
    val="$(date +%s 2>/dev/null || printf '0')"
  fi
  [[ "$val" =~ ^[0-9]+$ ]] || {
    uk_error "Epoch value must be numeric: $val"
    return 2
  }

  local formats
  formats="$(tc_epoch_to_formats "$val" "$tz")"
  local -a lines=()
  mapfile -t lines < <(printf '%s\n' "$formats")
  local iso="${lines[0]:-}" rfc3339="${lines[1]:-}" rfc2822="${lines[2]:-}" human="${lines[3]:-}"

  if ((as_json)); then
    printf '{"epoch":%s,"iso":%s,"rfc3339":%s,"rfc2822":%s,"human":%s}\n' \
      "$val" \
      "$(tc_json_escape "$iso")" \
      "$(tc_json_escape "$rfc3339")" \
      "$(tc_json_escape "$rfc2822")" \
      "$(tc_json_escape "$human")"
    return 0
  fi

  case "$fmt" in
  all | '') ;;
  iso | iso8601)
    printf '%s\n' "$iso"
    return 0
    ;;
  rfc3339)
    printf '%s\n' "$rfc3339"
    return 0
    ;;
  rfc2822)
    printf '%s\n' "$rfc2822"
    return 0
    ;;
  unix | epoch)
    printf '%s\n' "$val"
    return 0
    ;;
  human)
    printf '%s\n' "$human"
    return 0
    ;;
  *)
    uk_error "Unknown --format: $fmt"
    return 2
    ;;
  esac

  tc_section "Epoch $val"
  local labels=("ISO 8601" "RFC 3339" "RFC 2822" "Human")
  local values=("$iso" "$rfc3339" "$rfc2822" "$human")
  local idx
  for idx in "${!labels[@]}"; do
    if [[ -n "${values[$idx]}" ]]; then
      printf '  %s%-12s%s  %s\n' "${UK_C_DIM:-}" "${labels[$idx]}" "${UK_C_RESET:-}" "${values[$idx]}"
    fi
  done
}

# ---- Parse subcommand ------------------------------------------------------

tc_cmd_parse() {
  local ts="$1" tz="$2" as_json="$3"
  local result
  result="$(tc_parse_to_epoch "$ts" "$tz")"

  if printf '%s' "$result" | grep -q '^error='; then
    uk_error "${result#error=}"
    return 2
  fi

  local -a lines=()
  mapfile -t lines < <(printf '%s\n' "$result")
  local epoch="${lines[0]:-}" iso="${lines[1]:-}"

  if ((as_json)); then
    printf '{"epoch":%s,"iso":%s}\n' "$epoch" "$(tc_json_escape "$iso")"
    return 0
  fi

  tc_section "Parse: $ts"
  printf '  %s%-12s%s  %s\n' "${UK_C_DIM:-}" "Epoch" "${UK_C_RESET:-}" "$epoch"
  printf '  %s%-12s%s  %s\n' "${UK_C_DIM:-}" "ISO 8601" "${UK_C_RESET:-}" "$iso"
}

# ---- Now subcommand --------------------------------------------------------

tc_cmd_now() {
  local tz="$1" as_json="$2"
  local epoch
  epoch="$(date +%s 2>/dev/null || printf '0')"
  tc_cmd_epoch "$epoch" "$tz" "all" "$as_json"
}

# ---- Cron subcommand -------------------------------------------------------

tc_cmd_cron() {
  local expr="$1" count="$2" as_json="$3"
  [[ "$count" =~ ^[0-9]+$ ]] || count=5

  if uk_has_cmd python3; then
    local result
    result="$(python3 -c '
import sys
from datetime import datetime, timedelta

expr = sys.argv[1]
n = int(sys.argv[2])

try:
    from croniter import croniter
except ImportError:
    print("error=croniter not installed (pip install croniter)")
    sys.exit(0)

try:
    base = datetime.now().replace(second=0, microsecond=0) + timedelta(minutes=1)
    cron = croniter(expr, base)
    for i in range(n):
        next_dt = cron.get_next(datetime)
        print(f"{i+1}\t{next_dt.isoformat()}")
except Exception as e:
    print(f"error={e}")
' "$expr" "$count" 2>/dev/null)"

    if printf '%s' "$result" | grep -q '^error='; then
      uk_error "${result#error=}"
      return 2
    fi

    if ((as_json)); then
      printf '['
      local first=1 line
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local idx="${line%%$'\t'*}"
        local dt="${line#*$'\t'}"
        ((first)) || printf ','
        printf '{"index":%s,"datetime":"%s"}' "$idx" "$dt"
        first=0
      done <<<"$result"
      printf ']\n'
      return 0
    fi

    tc_section "Cron: $expr"
    printf '  %s%-6s  %s%s\n' "${UK_C_DIM:-}" "Next" "${UK_C_RESET:-}" "${count} fire(s)"
    tc_hr
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      printf '  %s%3s%s   %s\n' \
        "${UK_C_BRIGHT_CYAN:-}" "${line%%$'\t'*}" \
        "${UK_C_RESET:-}" "${line#*$'\t'}"
    done <<<"$result"
  else
    uk_error "Cron parsing requires python3 + croniter (pip install croniter)."
    return 2
  fi
}

# ---- TZ subcommand ---------------------------------------------------------

tc_cmd_tz() {
  local zone="$1" as_json="$2"
  if [[ -z "$zone" ]]; then
    # List timezones
    if ((as_json)); then
      if uk_has_cmd python3; then
        python3 -c '
import zoneinfo, json
zones = sorted(zoneinfo.available_timezones())
print(json.dumps(zones, ensure_ascii=False))
' 2>/dev/null || printf '[]\n'
      else
        printf '["UTC","local"]\n'
      fi
    else
      tc_section "Available timezones"
      if uk_has_cmd python3; then
        python3 -c '
import zoneinfo
zones = sorted(zoneinfo.available_timezones())
for z in zones:
    print(f"  {z}")
' 2>/dev/null || printf '  (python3 needed)\n'
      else
        printf '  (install python3 for full timezone list)\n'
      fi
    fi
    return 0
  fi

  # Show timezone info
  if ((as_json)); then
    if uk_has_cmd python3; then
      python3 -c '
import sys, zoneinfo, json
from datetime import datetime
try:
    tz = zoneinfo.ZoneInfo(sys.argv[1])
    now = datetime.now(tz)
    utc = datetime.now(zoneinfo.ZoneInfo("UTC"))
    offset = now.utcoffset()
    print(json.dumps({
        "zone": sys.argv[1],
        "now": now.isoformat(),
        "offset_hours": round(offset.total_seconds() / 3600, 2) if offset else None,
        "dst": bool(now.dst()),
    }, ensure_ascii=False))
except Exception as e:
    print(json.dumps({"error": str(e)}))
' "$zone" 2>/dev/null || printf '{"error":"unknown"}\n'
    else
      printf '{"zone":"%s"}\n' "$zone"
    fi
    return 0
  fi

  tc_section "Timezone: $zone"
  if uk_has_cmd python3; then
    python3 -c '
import sys, zoneinfo
from datetime import datetime
try:
    tz = zoneinfo.ZoneInfo(sys.argv[1])
    now = datetime.now(tz)
    utc = datetime.now(zoneinfo.ZoneInfo("UTC"))
    offset = now.utcoffset()
    print(f"  Current time:  {now.isoformat()}")
    if offset:
        print(f"  UTC offset:    {offset}")
        print(f"  Offset hours:  {offset.total_seconds()/3600:+.2f}")
    print(f"  DST active:    {'yes' if now.dst() else 'no'}")
except Exception as e:
    print(f"  Error: {e}")
' "$zone" 2>/dev/null
  else
    env TZ="$zone" date '+  Current time: %Y-%m-%dT%H:%M:%S%z'
  fi
}

# ---- Diff subcommand -------------------------------------------------------

tc_cmd_diff() {
  local ts1="$1" ts2="$2" as_json="$3"
  [[ -n "$ts1" && -n "$ts2" ]] || {
    uk_error "diff requires two timestamps."
    return 2
  }
  if ! uk_has_cmd python3; then
    uk_error "Diff requires python3."
    return 2
  fi
  local output rc
  if output="$(
    python3 - "$ts1" "$ts2" "$as_json" <<'PYDIFF' 2>&1
import json, sys
from datetime import datetime

ts1, ts2 = sys.argv[1], sys.argv[2]
as_json = sys.argv[3] == '1'

def parse_ts(ts):
    formats = [
        "%Y-%m-%dT%H:%M:%S%z", "%Y-%m-%dT%H:%M:%SZ",
        "%Y-%m-%d %H:%M:%S", "%Y-%m-%d",
        "%a, %d %b %Y %H:%M:%S %z",
        "%d/%m/%Y %H:%M:%S", "%m/%d/%Y %H:%M:%S",
    ]
    if ts.isdigit():
        return datetime.fromtimestamp(int(ts))
    for fmt in formats:
        try:
            return datetime.strptime(ts, fmt)
        except ValueError:
            pass
    try:
        return datetime.fromisoformat(ts.replace('Z', '+00:00'))
    except Exception:
        return None

d1, d2 = parse_ts(ts1), parse_ts(ts2)
if not d1 or not d2:
    msg = "unable to parse one or both timestamps"
    if as_json:
        print(json.dumps({"ok": False, "error": msg}))
    else:
        print(msg, file=sys.stderr)
    sys.exit(2)

diff = abs((d2 - d1).total_seconds())
days = int(diff // 86400)
hours = int((diff % 86400) // 3600)
minutes = int((diff % 3600) // 60)
seconds = int(diff % 60)
obj = {
    "ok": True,
    "seconds": int(diff),
    "minutes": round(diff / 60, 1),
    "hours": round(diff / 3600, 1),
    "days": round(diff / 86400, 2),
    "weeks": round(diff / 86400 / 7, 1),
    "human": f"{days}d {hours}h {minutes}m {seconds}s",
}
if as_json:
    print(json.dumps(obj, ensure_ascii=False))
else:
    for k in ["seconds", "minutes", "hours", "days", "weeks", "human"]:
        print(f"{k}={obj[k]}")
PYDIFF
  )"; then
    rc=0
  else
    rc=$?
  fi
  if ((rc != 0)); then
    if ((as_json)); then printf '%s\n' "$output"; else uk_error "$output"; fi
    return "$rc"
  fi
  if ((as_json)); then
    printf '%s\n' "$output"
  else
    tc_section "Diff"
    printf '%s\n' "$output"
  fi
}

# ---- Main ------------------------------------------------------------------

tc_main() {
  uk_banner "time-convert" "Epoch ↔ ISO 8601 ↔ human; cron schedule analyzer" "" "$@"

  local sub=""
  local val="" tz="" fmt="all" count=5 as_json=0

  # Subcommand
  if [[ $# -gt 0 ]]; then
    case "${1:-}" in
    epoch | parse | now | cron | tz | diff)
      sub="$1"
      shift
      ;;
    -h | --help)
      tc_usage
      return 0
      ;;
    esac
  fi

  [[ -z "$sub" ]] && sub="now"

  # Flags
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --format)
      shift
      fmt="${1:-all}"
      ;;
    --tz)
      shift
      tz="${1:-}"
      ;;
    --count)
      shift
      count="${1:-5}"
      ;;
    --json) as_json=1 ;;
    --no-color)
      UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
      UK_C_YELLOW='' UK_C_BRIGHT_CYAN=''
      ;;
    -h | --help)
      tc_usage
      return 0
      ;;
    -*)
      uk_error "Unknown option: ${1:-}"
      tc_usage
      return 2
      ;;
    *)
      if [[ -z "$val" ]]; then
        val="$1"
      else
        if [[ -z "${ts2:-}" ]]; then
          ts2="$1"
        else
          uk_error "Too many arguments"
          return 2
        fi
      fi
      ;;
    esac
    shift || true
  done

  case "$sub" in
  now) tc_cmd_now "$tz" "$as_json" ;;
  epoch) tc_cmd_epoch "$val" "$tz" "$fmt" "$as_json" ;;
  parse)
    [[ -z "$val" ]] && {
      uk_error "parse requires a timestamp."
      return 2
    }
    tc_cmd_parse "$val" "$tz" "$as_json"
    ;;
  cron)
    [[ -z "$val" ]] && {
      uk_error "cron requires an expression."
      return 2
    }
    tc_cmd_cron "$val" "$count" "$as_json"
    ;;
  tz) tc_cmd_tz "$val" "$as_json" ;;
  diff) tc_cmd_diff "$val" "${ts2:-}" "$as_json" ;;
  *)
    tc_usage
    return 2
    ;;
  esac
}

tc_wizard() {
  uk_banner "time-convert" "Epoch ↔ ISO 8601 ↔ human; cron schedule analyzer" ""
  local sub tz jsonf count
  sub="$(uk_prompt 'Action: now, epoch, parse, cron, tz, diff' 'now' \
    'now | epoch | parse | cron | tz | diff' \
    'now = current time. epoch = convert epoch. parse = string to epoch.')"

  case "$sub" in
  now)
    if uk_confirm 'Specify timezone?' 'N'; then
      tz="$(uk_prompt 'Timezone' 'UTC' 'America/New_York' 'e.g. UTC, Asia/Tokyo')"
    fi
    if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
    local -a a=(now)
    [[ -n "${tz:-}" ]] && a+=(--tz "$tz")
    [[ -n "$jsonf" ]] && a+=("$jsonf")
    tc_main "${a[@]}"
    ;;
  epoch)
    val="$(uk_prompt 'Unix epoch seconds (blank = current)' '' '1700000000' 'Numeric seconds since 1970-01-01.')"
    if uk_confirm 'Specify timezone?' 'N'; then
      tz="$(uk_prompt 'Timezone' 'UTC' 'America/New_York' '')"
    fi
    if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
    local -a a=(epoch "${val:-}")
    [[ -n "$tz" ]] && a+=(--tz "$tz")
    [[ -n "$jsonf" ]] && a+=("$jsonf")
    tc_main "${a[@]}"
    ;;
  parse)
    val="$(uk_prompt 'Timestamp string' '2024-01-15T10:30:00Z' \
      'Mon, 15 Jan 2024 10:30:00 +0000' 'Parses most common formats.')"
    if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
    local -a a=(parse "$val")
    [[ -n "$jsonf" ]] && a+=("$jsonf")
    tc_main "${a[@]}"
    ;;
  cron)
    val="$(uk_prompt 'Cron expression' '*/15 * * * *' '0 9 * * 1-5' 'Standard 5-field cron syntax.')"
    count="$(uk_prompt 'How many future fires?' '5' '3' '')"
    if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
    local -a a=(cron "$val" --count "$count")
    [[ -n "$jsonf" ]] && a+=("$jsonf")
    tc_main "${a[@]}"
    ;;
  tz)
    val="$(uk_prompt 'Timezone name (blank = list available)' '' 'Asia/Tokyo' 'Leave blank to list all timezones.')"
    if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
    local -a a=(tz)
    [[ -n "$val" ]] && a+=("$val")
    [[ -n "$jsonf" ]] && a+=("$jsonf")
    tc_main "${a[@]}"
    ;;
  diff)
    val="$(uk_prompt 'First timestamp' '2024-01-01' '1700000000' 'Any supported format.')"
    local ts2
    ts2="$(uk_prompt 'Second timestamp' '2024-12-31' '1735689599' 'Any supported format.')"
    if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
    local -a a=(diff "$val" "$ts2")
    [[ -n "$jsonf" ]] && a+=("$jsonf")
    tc_main "${a[@]}"
    ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    tc_wizard
  else
    tc_main "$@"
  fi
fi
