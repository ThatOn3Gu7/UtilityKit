#!/usr/bin/env bash
set -euo pipefail
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
  find "$(at_profiles_dir)" -maxdepth 1 -type f -name '*.conf' -printf '%f\n' | sed 's/\.conf$//' | sort
}

at_show_profile() {
  local file="$(at_profiles_dir)/$AT_NAME.conf"
  [[ -f "$file" ]] || { uk_error "Profile not found: $AT_NAME"; return 1; }
  cat "$file"
}

at_run_request() {
  uk_has_cmd curl || { uk_error 'curl is required.'; return 1; }
  local tmp_body tmp_meta curl_args=() hdr
  tmp_body=$(mktemp)
  tmp_meta=$(mktemp)
  trap "rm -f '$tmp_body' '$tmp_meta'" RETURN
  curl_args=(-sS -X "$AT_METHOD" "$AT_URL" -o "$tmp_body" -w 'dns=%{time_namelookup} tcp=%{time_connect} ttfb=%{time_starttransfer} total=%{time_total} code=%{http_code}\n')
  for hdr in "${AT_HEADERS[@]}"; do
    curl_args+=(-H "$hdr")
  done
  if [[ -n "$AT_BODY_FILE" ]]; then
    curl_args+=(--data-binary "@$AT_BODY_FILE")
  elif [[ -n "$AT_BODY" ]]; then
    curl_args+=(--data "$AT_BODY")
  fi
  printf '%s\n' "$(curl "${curl_args[@]}" 2>"$tmp_meta")"
  printf '\nResponse body:\n'
  if uk_has_cmd jq && jq . "$tmp_body" >/dev/null 2>&1; then
    jq . "$tmp_body"
  else
    cat "$tmp_body"
  fi
  [[ -s "$tmp_meta" ]] && { printf '\nCurl stderr:\n'; cat "$tmp_meta"; }
}

at_main() {
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
      if [[ -z "$AT_URL" && -t 0 ]]; then
        printf 'Method [GET]: '; read -r AT_METHOD; AT_METHOD=${AT_METHOD:-GET}
        printf 'URL: '; read -r AT_URL
      fi
      [[ -n "$AT_URL" ]] || { at_usage; return 1; }
      at_run_request
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  at_main "$@"
fi
