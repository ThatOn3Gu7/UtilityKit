#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

AT_ACTION='run'
AT_NAME=''
AT_METHOD='GET'
AT_URL=''
AT_BODY=''
AT_BODY_FILE=''
AT_EXPECT='2xx,3xx'
declare -a AT_HEADERS=()

at_profiles_dir() {
  local dir="$(uk_data_dir)/api_profiles"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}
at_usage() {
  cat <<'USAGE'
Usage:
  _api_tester.sh [--method METHOD --url URL] [--header 'K: V'] [--body TEXT|--body-file FILE] [--expect 2xx,3xx]
  _api_tester.sh --save NAME --method METHOD --url URL [--header 'K: V'] [--body TEXT|--body-file FILE]
  _api_tester.sh --run NAME | --show NAME | --list
USAGE
}
at_validate_profile_name() {
  [[ "${1:-}" =~ ^[A-Za-z0-9._-]+$ ]] || { uk_error "Invalid profile name: ${1:-}. Use letters, numbers, dot, underscore, dash."; return 1; }
}
at_profile_file() { printf '%s/%s.json\n' "$(at_profiles_dir)" "$AT_NAME"; }
at_save_profile() {
  at_validate_profile_name "$AT_NAME" || return 1
  uk_has_cmd python3 || { uk_error 'python3 is required for safe JSON profile storage.'; return 1; }
  local file="$(at_profile_file)"
  python3 - "$file" "$AT_METHOD" "$AT_URL" "$AT_BODY" "$AT_BODY_FILE" "$AT_EXPECT" "${AT_HEADERS[@]}" <<'PYAPI_SAVE'
import json, sys, os
file, method, url, body, body_file, expect = sys.argv[1:7]
headers = sys.argv[7:]
os.makedirs(os.path.dirname(file), exist_ok=True)
with open(file, 'w', encoding='utf-8') as f:
    json.dump({"method": method, "url": url, "body": body, "body_file": body_file,
               "expect": expect, "headers": headers}, f, ensure_ascii=False, indent=2)
    f.write('\n')
PYAPI_SAVE
  uk_success "Saved API profile: $file"
}
at_load_profile() {
  at_validate_profile_name "$AT_NAME" || return 1
  uk_has_cmd python3 || { uk_error 'python3 is required to load JSON profiles.'; return 1; }
  local file="$(at_profile_file)"
  [[ -f "$file" ]] || {
    uk_error "Profile not found: $AT_NAME"
    return 1
  }
  local -a loaded=()
  mapfile -t loaded < <(python3 - "$file" <<'PYAPI_LOAD'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    d=json.load(f)
print(d.get('method','GET'))
print(d.get('url',''))
print(d.get('body',''))
print(d.get('body_file',''))
print(d.get('expect','2xx,3xx'))
for h in d.get('headers',[]): print(h)
PYAPI_LOAD
)
  AT_METHOD="${loaded[0]:-GET}"
  AT_URL="${loaded[1]:-}"
  AT_BODY="${loaded[2]:-}"
  AT_BODY_FILE="${loaded[3]:-}"
  AT_EXPECT="${loaded[4]:-2xx,3xx}"
  AT_HEADERS=("${loaded[@]:5}")
}
at_list_profiles() {
  find "$(at_profiles_dir)" -maxdepth 1 -type f -name '*.json' -exec basename {} .json \; | sort
}
at_show_profile() {
  at_validate_profile_name "$AT_NAME" || return 1
  local file="$(at_profile_file)"
  [[ -f "$file" ]] || {
    uk_error "Profile not found: $AT_NAME"
    return 1
  }
  cat "$file"
}
at_redact_header() {
  local hdr="${1:-}"
  case "${hdr%%:*}" in
    [Aa]uthorization|[Cc]ookie|[Xx]-[Aa]pi-[Kk]ey|[Ss]et-[Cc]ookie) printf '%s: <redacted>\n' "${hdr%%:*}" ;;
    *) printf '%s\n' "$hdr" ;;
  esac
}
at_status_expected() {
  local code="$1" spec_csv="${2:-2xx,3xx}" spec start end
  [[ "$code" =~ ^[0-9][0-9][0-9]$ ]] || return 1
  local -a specs=()
  IFS=',' read -r -a specs <<<"$spec_csv"
  for spec in "${specs[@]}"; do
    spec="${spec//[[:space:]]/}"
    case "$spec" in
      [1-5]xx) [[ "${code:0:1}" == "${spec:0:1}" ]] && return 0 ;;
      [0-9][0-9][0-9]) [[ "$code" == "$spec" ]] && return 0 ;;
      [0-9][0-9][0-9]-[0-9][0-9][0-9])
        start="${spec%-*}"; end="${spec#*-}"
        (( code >= start && code <= end )) && return 0
        ;;
    esac
  done
  return 1
}
at_run_request() {
  uk_has_cmd curl || {
    uk_error 'curl is required.'
    return 1
  }
  local tmp_body tmp_meta tmp_timing curl_args=() hdr
  tmp_body=$(mktemp)
  tmp_meta=$(mktemp)
  tmp_timing=$(mktemp)
  trap "rm -f '$tmp_body' '$tmp_meta' '$tmp_timing'" RETURN

  curl_args=(-sS -X "$AT_METHOD" "$AT_URL"
    -o "$tmp_body"
    -w 'dns=%{time_namelookup}\ntcp=%{time_connect}\nttfb=%{time_starttransfer}\ntotal=%{time_total}\ncode=%{http_code}\n')
  for hdr in "${AT_HEADERS[@]}"; do
    curl_args+=(-H "$hdr")
  done
  if [[ -n "$AT_BODY_FILE" ]]; then
    curl_args+=(--data-binary "@$AT_BODY_FILE")
  elif [[ -n "$AT_BODY" ]]; then
    curl_args+=(--data "$AT_BODY")
  fi

  local curl_rc=0
  curl "${curl_args[@]}" 2>"$tmp_meta" >"$tmp_timing" || curl_rc=$?

  printf '\n  %s%s◆ Request%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  printf '  %sMethod:%s  %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$AT_METHOD" "$UK_C_RESET"
  printf '  %sURL:%s     %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$AT_URL" "$UK_C_RESET"
  for hdr in "${AT_HEADERS[@]}"; do
    printf '  %sHeader:%s  %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$(at_redact_header "$hdr")" "$UK_C_RESET"
  done
  [[ -n "$AT_BODY" ]] && printf '  %sBody:%s    %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$AT_BODY" "$UK_C_RESET"

  printf '\n  %s%s◆ Timing%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  local code dns tcp ttfb total
  code=$(grep '^code=' "$tmp_timing" | cut -d= -f2)
  dns=$(grep '^dns=' "$tmp_timing" | cut -d= -f2)
  tcp=$(grep '^tcp=' "$tmp_timing" | cut -d= -f2)
  ttfb=$(grep '^ttfb=' "$tmp_timing" | cut -d= -f2)
  total=$(grep '^total=' "$tmp_timing" | cut -d= -f2)
  local code_color="$UK_C_GREEN"
  [[ "$code" -ge 400 ]] 2>/dev/null && code_color="$UK_C_RED"
  [[ "$code" -ge 300 && "$code" -lt 400 ]] 2>/dev/null && code_color="$UK_C_YELLOW"
  printf '  %sStatus:%s  %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$code_color" "$code" "$UK_C_RESET"
  printf '  %sDNS:%s     %ss\n' "$UK_C_BOLD" "$UK_C_RESET" "$dns"
  printf '  %sTCP:%s     %ss\n' "$UK_C_BOLD" "$UK_C_RESET" "$tcp"
  printf '  %sTTFB:%s    %ss\n' "$UK_C_BOLD" "$UK_C_RESET" "$ttfb"
  printf '  %sTotal:%s   %ss\n' "$UK_C_BOLD" "$UK_C_RESET" "$total"

  printf '\n  %s%s◆ Response body%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"

  # --- Beautiful output: bat → jq -C → plain cat ---
  if uk_has_cmd bat; then
    # bat with syntax highlighting, no line numbers, force colour
    bat --language=json --style=plain --color=always "$tmp_body" 2>/dev/null | sed 's/^/  /'
  elif uk_has_cmd jq; then
    # Check if the response is valid JSON, then pretty‑print with colour
    if jq -e . "$tmp_body" >/dev/null 2>&1; then
      jq -C . "$tmp_body" 2>/dev/null | sed 's/^/  /'
    else
      # Not JSON – fall back to plain cat
      cat "$tmp_body" 2>/dev/null | sed 's/^/  /'
    fi
  else
    # No bat, no jq – plain cat
    cat "$tmp_body" 2>/dev/null | sed 's/^/  /'
  fi

  if [[ -s "$tmp_meta" ]]; then
    printf '\n  %s%sCurl warnings%s\n' "$UK_C_BOLD" "$UK_C_YELLOW" "$UK_C_RESET"
    printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
    cat "$tmp_meta" | sed 's/^/  /'
  fi

  if (( curl_rc != 0 )); then
    uk_error "curl failed with exit code $curl_rc"
    return "$curl_rc"
  fi
  if ! at_status_expected "${code:-000}" "$AT_EXPECT"; then
    uk_error "Unexpected HTTP status ${code:-000}; expected $AT_EXPECT"
    return 1
  fi
  return 0
}
at_main() {
  uk_banner "api-tester" "One-off HTTP requests or saved/replayable profiles" "" "$@"
  AT_ACTION='run'
  AT_NAME=''
  AT_METHOD='GET'
  AT_URL=''
  AT_BODY=''
  AT_BODY_FILE=''
  AT_EXPECT='2xx,3xx'
  AT_HEADERS=()
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --save)
      shift
      AT_ACTION='save'
      AT_NAME="${1:-}"
      ;;
    --run)
      shift
      AT_ACTION='run-profile'
      AT_NAME="${1:-}"
      ;;
    --show)
      shift
      AT_ACTION='show'
      AT_NAME="${1:-}"
      ;;
    --list) AT_ACTION='list' ;;
    --method)
      shift
      AT_METHOD="${1:-GET}"
      ;;
    --url)
      shift
      AT_URL="${1:-}"
      ;;
    --header)
      shift
      AT_HEADERS+=("${1:-}")
      ;;
    --body)
      shift
      AT_BODY="${1:-}"
      ;;
    --body-file)
      shift
      AT_BODY_FILE="${1:-}"
      ;;
    --expect)
      shift
      AT_EXPECT="${1:-2xx,3xx}"
      ;;
    -h | --help)
      at_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done
  case "$AT_ACTION" in
  list) at_list_profiles ;;
  show) at_show_profile ;;
  save)
    [[ -n "$AT_NAME" && -n "$AT_URL" ]] || {
      at_usage
      return 1
    }
    at_save_profile
    ;;
  run-profile)
    [[ -n "$AT_NAME" ]] || {
      at_usage
      return 1
    }
    at_load_profile || return $?
    at_run_request
    ;;
  run)
    if [[ -z "$AT_URL" && -t 0 && -t 1 ]]; then
      uk_section_title 'One-off HTTP request'

      printf '\n %s%s◆ Method%s\n' "$UK_C_BOLD" "$UK_C_BRIGHT_CYAN" "$UK_C_RESET"
      printf '  %sHTTP verb to use for the request%s\n' "$UK_C_DIM" "$UK_C_RESET"
      printf '  %sExamples:%s GET · POST · PUT · PATCH · DELETE\n' "$UK_C_DIM" "$UK_C_RESET"
      AT_METHOD="$(uk_prompt 'Method' 'GET' '' '')"

      printf '\n %s%s◆ URL%s\n' "$UK_C_BOLD" "$UK_C_BRIGHT_CYAN" "$UK_C_RESET"
      printf '  %sFull URL including protocol%s\n' "$UK_C_DIM" "$UK_C_RESET"
      printf '  %sExamples:%s https://api.example.com/users · http://127.0.0.1:3000/health\n' "$UK_C_DIM" "$UK_C_RESET"
      AT_URL="$(uk_prompt 'URL' '' '' '')"

      printf '\n %s%s◆ Header%s %s(optional — leave blank to skip)%s\n' \
        "$UK_C_BOLD" "$UK_C_BRIGHT_CYAN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
      printf '  %sFormat:%s  Key: Value\n' "$UK_C_DIM" "$UK_C_RESET"
      printf '  %sExamples:%s Authorization: Bearer TOKEN · Content-Type: application/json\n' "$UK_C_DIM" "$UK_C_RESET"
      local hdr
      hdr="$(uk_prompt 'Header' '' '' '')"
      [[ -n "$hdr" ]] && AT_HEADERS+=("$hdr")

      printf '\n %s%s◆ Body%s %s(optional — leave blank to skip)%s\n' \
        "$UK_C_BOLD" "$UK_C_BRIGHT_CYAN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
      printf '  %sFor JSON bodies also set Content-Type: application/json above%s\n' "$UK_C_DIM" "$UK_C_RESET"
      printf '  %sExamples:%s {"name":"demo"} · id=1&active=true\n' "$UK_C_DIM" "$UK_C_RESET"
      AT_BODY="$(uk_prompt 'Body' '' '' '')"

      printf '\n'
    fi
    [[ -n "$AT_URL" ]] || {
      at_usage
      return 1
    }
    at_run_request
    ;;
  esac
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  at_main "$@"
fi
