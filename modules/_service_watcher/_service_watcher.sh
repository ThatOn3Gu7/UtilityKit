#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"
sw_usage() {
  cat <<'USAGE'
Usage: _service_watcher.sh URL... [--expect CODES] [--interval SECONDS] [--profile NAME] [--save NAME]
USAGE
}
sw_dir() {
  local d
  d="$(uk_data_dir)" || return 1
  d="$d/service_watcher"
  mkdir -p "$d" || return 1
  printf '%s\n' "$d"
}
sw_valid_profile() { [[ "${1:-}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]]; }
sw_check() {
  local url="${1:-}" expect="${2:-}" insecure="${3:-0}" out code time ok=1
  [[ "$url" =~ ^https?:// ]] || { uk_error "Invalid service URL: $url"; return 1; }
  uk_has_cmd curl || {
    uk_error 'curl is required.'
    return 1
  }
  local -a curl_args=(-L -sS -o /dev/null --max-time 10 -w '%{http_code} %{time_total}')
  ((insecure == 1)) && curl_args+=(-k)
  out="$(curl "${curl_args[@]}" --url "$url" 2>&1)" || { uk_error "Service check failed for $url: $out"; return 1; }
  code=${out%% *}
  time=${out#* }
  IFS=',' read -r -a codes <<<"$expect"
  for c in "${codes[@]}"; do [[ "$code" == "$c" || ("$c" == "2xx" && "$code" =~ ^2) || ("$c" == "3xx" && "$code" =~ ^3) ]] && ok=0; done
  ((ok == 0)) && printf '  %s %s code=%s time=%ss\n' "$UK_I_OK" "$url" "$code" "$time" || {
    printf '  %s %s code=%s time=%ss\n' "$UK_I_ERR" "$url" "$code" "$time"
    printf '\a'
  }
  return "$ok"
}
sw_main() {
  uk_banner "service-watcher" "HTTP endpoint status and response-time checks" "" "$@"
  local expect='2xx,3xx' interval=0 save='' profile='' insecure=0 urls=()
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in --expect)
      shift
      expect="${1:-$expect}"
      ;;
    --interval)
      shift
      interval="${1:-0}"
      ;;
    --save)
      shift
      save="${1:-}"
      ;;
    --profile)
      shift
      profile="${1:-}"
      ;;
    --insecure) insecure=1 ;;
    -h | --help)
      sw_usage
      return 0
      ;;
    *) urls+=("${1:-}") ;; esac
    shift
  done
  [[ "$interval" =~ ^[0-9]+$ ]] && ((interval <= 86400)) || { uk_error '--interval must be an integer from 0 to 86400.'; return 1; }
  [[ -z "$profile" ]] || sw_valid_profile "$profile" || { uk_error "Invalid profile name: $profile"; return 1; }
  [[ -z "$save" ]] || sw_valid_profile "$save" || { uk_error "Invalid profile name: $save"; return 1; }
  local data_dir
  data_dir="$(sw_dir)" || return 1
  if [[ -n "$profile" ]]; then
    local f="$data_dir/$profile.urls"
    [[ -f "$f" ]] || {
      uk_error "Profile not found: $profile"
      return 1
    }
    mapfile -t urls <"$f"
  fi
  if [[ -n "$save" ]]; then
    printf '%s\n' "${urls[@]}" >"$data_dir/$save.urls" || { uk_error "Unable to save profile: $save"; return 1; }
    uk_success "Saved profile: $save"
    return 0
  fi
  [[ ${#urls[@]} -gt 0 ]] || {
    sw_usage
    return 1
  }
  while true; do
    uk_section_title "expect: $expect"
    local fail=0 u
    for u in "${urls[@]}"; do sw_check "$u" "$expect" "$insecure" || fail=1; done
    ((interval > 0)) || return "$fail"
    sleep "$interval"
  done
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  sw_main "$@"
fi
