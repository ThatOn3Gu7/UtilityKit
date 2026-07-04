#!/usr/bin/env bash
# _http_bench — lightweight HTTP benchmark: N requests, C concurrency;
#               reports p50/p95/p99, RPS, error rate.
# Prefix: hb_
# Backends: curl + bash coprocs (built-in); hey/wrk if installed

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
# --------------------------

hb_usage() {
  cat <<'USAGE'
Usage:
  _http_bench.sh URL [OPTIONS]

Options:
  -n, --requests N     Total number of requests (default 50).
  -c, --concurrency N  Concurrent workers (default 5).
  -m, --method M       HTTP method: GET, POST, PUT, DELETE (default GET).
  -H, --header H       Custom header (repeatable).
  -d, --data DATA      Request body (for POST/PUT).
  --timeout SEC        Per-request timeout (default 10).
  --keep-alive         Use HTTP keep-alive (default: off).
  --json               Machine-readable JSON output.
  --no-color           Disable ANSI (also respects NO_COLOR=1).
  -h, --help           Show this help.

External backends: hey, wrk (used automatically if installed).
  Install hey:  https://github.com/rakyll/hey
  Install wrk:  https://github.com/wg/wrk

Examples:
  _http_bench.sh https://example.com
  _http_bench.sh https://api.example.com -n 200 -c 10
  _http_bench.sh https://httpbin.org/post -m POST -d '{"key":"value"}' -H 'Content-Type: application/json'
  _http_bench.sh https://example.com -n 1000 -c 50 --json
USAGE
}

# ---- Helpers ---------------------------------------------------------------

hb_hr() {
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}

hb_section() {
  local title="${1:-}"
  printf '\n%s%s%s%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$title" "${UK_C_RESET:-}"
  hb_hr
}

hb_json_escape() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

# ---- Native curl bench (built-in) -----------------------------------------

hb_run_native() {
  local url="$1" requests="$2" concurrency="$3" method="$4" timeout="$5"
  local -a headers=()
  local body="$6" keep_alive="$7"

  if ! uk_has_cmd curl; then
    uk_error "curl is required for the built-in benchmark."
    return 2
  fi

  # Build curl args
  local -a curl_args=(-s -o /dev/null -w '%{http_code}\t%{time_total}\t%{size_download}\n')
  curl_args+=(-m "$timeout" -X "$method")
  local h
  for h in "${headers[@]}"; do curl_args+=(-H "$h"); done
  [[ -n "$body" ]] && curl_args+=(-d "$body")
  [[ "$keep_alive" == "1" ]] || curl_args+=(--no-keepalive)

  # We'll spawn workers via background coprocesses, collect results in a temp file
  local tmp_results
  tmp_results="$(mktemp)" || { uk_error "Failed to create temp file."; return 1; }
  local completed=0 errors=0
  local -a pids=()
  local total_req=$((requests < concurrency ? requests : requests))
  local batch_size=$((requests / concurrency))
  local remainder=$((requests % concurrency))

  hb_section "Benchmarking: $url"
  printf '  %s%-14s%s  %s\n' "${UK_C_DIM:-}" "requests" "${UK_C_RESET:-}" "$requests"
  printf '  %s%-14s%s  %s\n' "${UK_C_DIM:-}" "concurrency" "${UK_C_RESET:-}" "$concurrency"
  printf '  %s%-14s%s  %s\n' "${UK_C_DIM:-}" "method" "${UK_C_RESET:-}" "$method"
  printf '  %s%-14s%s  %s\n' "${UK_C_DIM:-}" "backend" "${UK_C_RESET:-}" "curl (built-in)"
  hb_hr
  printf '\n  Running benchmark...\n\n'

  local start_time end_time
  start_time="$(date +%s%N 2>/dev/null || date +%s 2>/dev/null || printf '0')"

  local worker worker_count i
  for ((worker=0; worker<concurrency; worker++)); do
    worker_count=$batch_size
    (( worker < remainder )) && worker_count=$((worker_count + 1))

    (
      local j
      for ((j=0; j<worker_count; j++)); do
        local result
        result="$(curl "${curl_args[@]}" "$url" 2>/dev/null || printf 'ERR\t0\t0')"
        printf '%s\n' "$result" >> "$tmp_results"
      done
    ) &
    pids+=($!)
  done

  # Wait for all workers
  local pid
  for pid in "${pids[@]}"; do wait "$pid" 2>/dev/null || true; done

  end_time="$(date +%s%N 2>/dev/null || date +%s 2>/dev/null || printf '0')"

  # Parse results
  local -a times=() codes=()
  local line code time size
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    completed=$((completed + 1))
    IFS=$'\t' read -r code time size <<<"$line"
    if [[ "$code" == "ERR" ]]; then
      errors=$((errors + 1))
      continue
    fi
    codes+=("$code")
    times+=("$time")
  done <"$tmp_results"
  rm -f "$tmp_results"

  local elapsed_ms
  if [[ "$start_time" =~ ^[0-9]+$ && "$end_time" =~ ^[0-9]+$ ]]; then
    elapsed_ms=$(( (end_time - start_time) / 1000000 ))
  else
    elapsed_ms=0
  fi
  [[ "$elapsed_ms" -le 0 ]] && elapsed_ms=1

  # Sort times for percentile calculation
  local sorted
  sorted="$(printf '%s\n' "${times[@]}" | sort -n)"

  hb_report "$url" "$requests" "$completed" "$errors" "$elapsed_ms" "$sorted" "curl"
}

# ---- Report generator ------------------------------------------------------

hb_report() {
  local url="$1" requests="$2" completed="$3" errors="$4" elapsed_ms="$5" sorted="$6" backend="$7"

  local ok=$((completed - errors))
  local rps=0
  (( elapsed_ms > 0 )) && rps="$((completed * 1000 / elapsed_ms))"
  local avg=0
  (( completed > 0 )) && avg="$((elapsed_ms / completed))"

  if [[ "$SEC_JSON" == "1" ]]; then
    printf '{"url":%s,"requests":%s,"completed":%s,"errors":%s,"elapsed_ms":%s,"rps":%s,"backend":%s}\n' \
      "$(hb_json_escape "$url")" "$requests" "$completed" "$errors" "$elapsed_ms" "$rps" \
      "$(hb_json_escape "$backend")"
    return 0
  fi

  hb_section "Results"
  printf '  %s%-14s%s  %d\n' "${UK_C_DIM:-}" "completed" "${UK_C_RESET:-}" "$completed"
  printf '  %s%-14s%s  %d\n' "${UK_C_DIM:-}" "errors" "${UK_C_RESET:-}" "$errors"
  printf '  %s%-14s%s  %d ms\n' "${UK_C_DIM:-}" "total time" "${UK_C_RESET:-}" "$elapsed_ms"
  printf '  %s%-14s%s  %d req/s\n' "${UK_C_DIM:-}" "RPS" "${UK_C_RESET:-}" "$rps"

  # Percentile calculation using python3 or awk
  local times_count
  times_count="$(printf '%s\n' "$sorted" | grep -c . || true)"
  if uk_has_cmd python3 && (( times_count > 0 )); then
    local p50 p95 p99 min max
    read -r p50 p95 p99 min max <<<"$(printf '%s\n' "${sorted}" | python3 -c '
import sys
vals = sorted([float(l) for l in sys.stdin if l.strip()])
n = len(vals)
if n == 0:
    print("0 0 0 0 0"); sys.exit(0)
def pct(p):
    idx = max(0, min(n-1, int(n * p / 100)))
    return vals[idx]
print(f"{pct(50)*1000:.1f} {pct(95)*1000:.1f} {pct(99)*1000:.1f} {vals[0]*1000:.1f} {vals[-1]*1000:.1f}")
' 2>/dev/null)"

    if [[ -n "$p50" ]]; then
      printf '  %s%-14s%s  %s ms\n' "${UK_C_DIM:-}" "p50" "${UK_C_RESET:-}" "$p50"
      printf '  %s%-14s%s  %s ms\n' "${UK_C_DIM:-}" "p95" "${UK_C_RESET:-}" "$p95"
      printf '  %s%-14s%s  %s ms\n' "${UK_C_DIM:-}" "p99" "${UK_C_RESET:-}" "$p99"
      printf '  %s%-14s%s  %s ms\n' "${UK_C_DIM:-}" "min" "${UK_C_RESET:-}" "$min"
      printf '  %s%-14s%s  %s ms\n' "${UK_C_DIM:-}" "max" "${UK_C_RESET:-}" "$max"
    fi
  fi

  printf '  %s%-14s%s  %s\n\n' "${UK_C_DIM:-}" "backend" "${UK_C_RESET:-}" "$backend"
}

# ---- External backends (hey / wrk) -----------------------------------------

hb_run_hey() {
  local url="$1" requests="$2" concurrency="$3" method="$4" timeout="$5" json="$6"
  local -a headers=()
  local body="$7" keep_alive="$8"

  if ! uk_has_cmd hey; then
    uk_error "hey is not installed."
    return 2
  fi

  local -a args=(-n "$requests" -c "$concurrency" -m "$method" -t "$timeout")
  local h
  for h in "${headers[@]}"; do args+=(-H "$h"); done
  [[ -n "$body" ]] && args+=(-d "$body")
  [[ "$keep_alive" == "1" ]] || args+=(-disable-keepalive)

  if (( json )); then
    # Pipe through our own JSON schema
    local raw
    raw="$(hey "${args[@]}" "$url" 2>/dev/null || true)"
    local rps errors
    rps="$(printf '%s\n' "$raw" | grep 'Requests/sec' | grep -oP '[\d.]+' | head -n1)"
    errors="$(printf '%s\n' "$raw" | grep '\[error\]' | grep -oP '\d+' | head -n1)"
    printf '{"url":%s,"requests":%s,"rps":%s,"errors":%s,"backend":"hey"}\n' \
      "$(hb_json_escape "$url")" "$requests" "${rps:-0}" "${errors:-0}"
  else
    hey "${args[@]}" "$url"
  fi
}

hb_run_wrk() {
  local url="$1" requests="$2" concurrency="$3" timeout="$4" json="$5"
  local keep_alive="$6"

  if ! uk_has_cmd wrk; then
    uk_error "wrk is not installed."
    return 2
  fi

  local -a args=(-t "$concurrency" -c "$concurrency" -d "${timeout}s" -L)
  if (( json )); then
    local raw
    raw="$(wrk "${args[@]}" "$url" 2>/dev/null || true)"
    local rps errors
    rps="$(printf '%s\n' "$raw" | grep 'Requests/sec' | awk '{print $2}')"
    printf '{"url":%s,"requests":-1,"rps":%s,"backend":"wrk","note":"wrk does dynamic duration, not fixed count"}\n' \
      "$(hb_json_escape "$url")" "${rps:-0}"
  else
    wrk "${args[@]}" "$url"
  fi
}

# ---- Main ------------------------------------------------------------------

hb_main() {
  uk_banner "http-bench" "HTTP benchmark with percentile stats" "" "$@"

  local url="" requests=50 concurrency=5 method="GET" timeout=10
  local -a headers=()
  local body="" keep_alive=0 as_json=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -n|--requests)    shift; requests="${1:-50}" ;;
      -c|--concurrency) shift; concurrency="${1:-5}" ;;
      -m|--method)      shift; method="${1:-GET}" ;;
      -H|--header)      shift; headers+=("${1:-}") ;;
      -d|--data)        shift; body="${1:-}" ;;
      --timeout)        shift; timeout="${1:-10}" ;;
      --keep-alive)     keep_alive=1 ;;
      --json)           as_json=1 ;;
      --no-color)       UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                        UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help)        hb_usage; return 0 ;;
      -*)               uk_error "Unknown option: ${1:-}"; hb_usage; return 2 ;;
      *)                url="${1:-}" ;;
    esac
    shift || true
  done

  [[ -z "$url" ]] && { uk_error "URL required."; hb_usage; return 2; }

  # Validate numeric params
  [[ "$requests"    =~ ^[0-9]+$ ]] || requests=50
  [[ "$concurrency" =~ ^[0-9]+$ ]] || concurrency=5
  [[ "$timeout"     =~ ^[0-9]+$ ]] || timeout=10
  (( requests < 1 )) && requests=50
  (( concurrency < 1 )) && concurrency=1

  method="${method^^}"

  # External backend preference: hey > wrk > built-in curl
  if uk_has_cmd hey; then
    hb_run_hey "$url" "$requests" "$concurrency" "$method" "$timeout" "$as_json" "$body" "$keep_alive"
  elif uk_has_cmd wrk; then
    hb_run_wrk "$url" "$requests" "$concurrency" "$timeout" "$as_json" "$keep_alive"
  else
    hb_run_native "$url" "$requests" "$concurrency" "$method" "$timeout" "$body" "$keep_alive"
  fi
}

hb_wizard() {
  uk_banner "http-bench" "HTTP benchmark with percentile stats" ""
  local url requests concurrency method body jsonf

  url="$(uk_prompt 'URL to benchmark' 'https://example.com' \
    'https://httpbin.org/get' 'The full URL with protocol.')"
  requests="$(uk_prompt 'Total requests' '50' '200' 'Higher = more accurate stats.')"
  concurrency="$(uk_prompt 'Concurrency (parallel requests)' '5' '10' 'Match expected real-world load.')"
  method="$(uk_prompt 'HTTP method' 'GET' 'POST' 'GET, POST, PUT, DELETE')"
  if [[ "$method" != "GET" ]]; then
    body="$(uk_prompt 'Request body' '' '{"key":"value"}' 'Payload for the request.')"
  fi
  if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi

  local -a a=("$url" -n "$requests" -c "$concurrency" -m "$method")
  [[ -n "$body" ]] && a+=(-d "$body")
  [[ -n "$jsonf" ]] && a+=("$jsonf")
  hb_main "${a[@]}"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    hb_wizard
  else
    hb_main "$@"
  fi
fi
