#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
sw_usage() {
  cat <<'USAGE'
Usage: _service_watcher.sh URL... [--expect CODES] [--interval SECONDS] [--profile NAME] [--save NAME]
USAGE
}
sw_dir() {
  local d="$(uk_data_dir)/service_watcher"
  mkdir -p "$d"
  printf '%s\n' "$d"
}
sw_check() {
  local url="$1" expect="$2" out code time ok=1
  uk_has_cmd curl || {
    uk_error 'curl is required.'
    return 1
  }
  out=$(curl -L -k -sS -o /dev/null --max-time 10 -w '%{http_code} %{time_total}' "$url" 2>/dev/null || printf '000 0')
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
  local expect='2xx,3xx' interval=0 save='' profile='' urls=()
  while [[ $# -gt 0 ]]; do
    case "$1" in --expect)
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
    -h | --help)
      sw_usage
      return 0
      ;;
    *) urls+=("$1") ;; esac
    shift
  done
  if [[ -n "$profile" ]]; then
    local f="$(sw_dir)/$profile.urls"
    [[ -f "$f" ]] || {
      uk_error "Profile not found: $profile"
      return 1
    }
    mapfile -t urls <"$f"
  fi
  if [[ -n "$save" ]]; then
    printf '%s\n' "${urls[@]}" >"$(sw_dir)/$save.urls"
    uk_success "Saved profile: $save"
    return 0
  fi
  [[ ${#urls[@]} -gt 0 ]] || {
    sw_usage
    return 1
  }
  while true; do
    uk_header 'UtilityKit Service Watcher' "expect: $expect"
    local fail=0 u
    for u in "${urls[@]}"; do sw_check "$u" "$expect" || fail=1; done
    ((interval > 0)) || return "$fail"
    sleep "$interval"
  done
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  sw_main "$@"
fi
