#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

AT_ACTION='run'
AT_NAME=''
AT_METHOD='GET'
AT_URL=''
AT_BODY=''
AT_BODY_FILE=''
declare -a AT_HEADERS=()

at_profiles_dir() {
  local dir="$(uk_data_dir)/api_profiles"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

at_usage() {
  cat <<'USAGE'
Usage:
  _api_tester.sh [--method METHOD --url URL] [--header 'K: V'] [--body TEXT|--body-file FILE]
  _api_tester.sh --save NAME --method METHOD --url URL [--header 'K: V'] [--body TEXT|--body-file FILE]
  _api_tester.sh --run NAME | --show NAME | --list
USAGE
}

at_save_profile() {
  local file="$(at_profiles_dir)/$AT_NAME.conf" hdr
  {
    printf 'API_METHOD=%q\n' "$AT_METHOD"
    printf 'API_URL=%q\n' "$AT_URL"
    printf 'API_BODY=%q\n' "$AT_BODY"
    printf 'API_BODY_FILE=%q\n' "$AT_BODY_FILE"
    printf 'API_HEADERS=(\n'
    for hdr in "${AT_HEADERS[@]}"; do
      printf '  %q\n' "$hdr"
    done
    printf ')\n'
  } > "$file"
  uk_success "Saved API profile: $file"
}

at_load_profile() {
  local file="$(at_profiles_dir)/$AT_NAME.conf"
  [[ -f "$file" ]] || { uk_error "Profile not found: $AT_NAME"; return 1; }
  # shellcheck disable=SC1090
  source "$file"
  AT_METHOD="$API_METHOD"
  AT_URL="$API_URL"
  AT_BODY="$API_BODY"
  AT_BODY_FILE="$API_BODY_FILE"
  AT_HEADERS=("${API_HEADERS[@]:-}")
}

at_list_profiles() {
  find "$(at_profiles_dir)" -maxdepth 1 -type f -name '*.conf' -exec basename {} .conf \; | sort
}

at_show_profile() {
  local file="$(at_profiles_dir)/$AT_NAME.conf"
  [[ -f "$file" ]] || { uk_error "Profile not found: $AT_NAME"; return 1; }
  cat "$file"
}

at_run_request() {
  uk_has_cmd curl || { uk_error 'curl is required.'; return 1; }
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

  curl "${curl_args[@]}" 2>"$tmp_meta" > "$tmp_timing" || true

  printf '\n  %s%sRequest%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  printf '  %sMethod:%s  %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$AT_METHOD" "$UK_C_RESET"
  printf '  %sURL:%s     %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$AT_URL" "$UK_C_RESET"
  for hdr in "${AT_HEADERS[@]}"; do
    printf '  %sHeader:%s  %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$hdr" "$UK_C_RESET"
  done
  [[ -n "$AT_BODY" ]] && printf '  %sBody:%s    %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$AT_BODY" "$UK_C_RESET"

  printf '\n  %s%sTiming%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
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

  printf '\n  %s%sResponse body%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  if uk_has_cmd jq && jq . "$tmp_body" >/dev/null 2>&1; then
    jq . "$tmp_body" | sed 's/^/  /'
  else
    cat "$tmp_body" | sed 's/^/  /'
  fi

  if [[ -s "$tmp_meta" ]]; then
    printf '\n  %s%sCurl warnings%s\n' "$UK_C_BOLD" "$UK_C_YELLOW" "$UK_C_RESET"
    printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
    cat "$tmp_meta" | sed 's/^/  /'
  fi
}

at_main() {
  AT_ACTION='run'; AT_NAME=''; AT_METHOD='GET'; AT_URL=''; AT_BODY=''; AT_BODY_FILE=''; AT_HEADERS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --save) shift; AT_ACTION='save'; AT_NAME="${1:-}" ;;
      --run) shift; AT_ACTION='run-profile'; AT_NAME="${1:-}" ;;
      --show) shift; AT_ACTION='show'; AT_NAME="${1:-}" ;;
      --list) AT_ACTION='list' ;;
      --method) shift; AT_METHOD="${1:-GET}" ;;
      --url) shift; AT_URL="${1:-}" ;;
      --header) shift; AT_HEADERS+=("${1:-}") ;;
      --body) shift; AT_BODY="${1:-}" ;;
      --body-file) shift; AT_BODY_FILE="${1:-}" ;;
      -h|--help) at_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done
  case "$AT_ACTION" in
    list) at_list_profiles ;;
    show) at_show_profile ;;
    save)
      [[ -n "$AT_NAME" && -n "$AT_URL" ]] || { at_usage; return 1; }
      at_save_profile
      ;;
    run-profile)
      [[ -n "$AT_NAME" ]] || { at_usage; return 1; }
      at_load_profile
      at_run_request
      ;;
    run)
      if [[ -z "$AT_URL" && -t 0 && -t 1 ]]; then
        uk_header 'UtilityKit API Tester' 'One-off HTTP request'
        AT_METHOD="$(uk_prompt \
          'Enter HTTP method' \
          'GET' \
          'GET  |  POST  |  PUT  |  PATCH  |  DELETE' \
          'GET fetches data, POST creates, PUT replaces, PATCH updates, DELETE removes.')"
        AT_URL="$(uk_prompt \
          'Enter request URL' \
          '' \
          'https://api.example.com/items  |  http://127.0.0.1:8000/health' \
          'Must include the protocol. Use http:// for local servers.')"
        local hdr
        hdr="$(uk_prompt \
          'Optional header in Key: Value format (leave blank to skip)' \
          '' \
          'Authorization: Bearer TOKEN  |  Content-Type: application/json' \
          'Only one header can be added here. Use --header for multiple.')"
        [[ -n "$hdr" ]] && AT_HEADERS+=("$hdr")
        AT_BODY="$(uk_prompt \
          'Optional request body (leave blank to skip)' \
          '' \
          '{"name":"demo"}  |  id=1&active=true' \
          'For JSON bodies also add a Content-Type: application/json header above.')"
      fi
      [[ -n "$AT_URL" ]] || { at_usage; return 1; }
      at_run_request
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  at_main "$@"
fi
