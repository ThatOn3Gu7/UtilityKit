#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
np_usage(){ cat <<'USAGE'
Usage: _network_probe.sh [HOST] [--count N] [--dns DOMAIN] [--no-public-ip] [--no-trace]
USAGE
}
np_main(){ local host='example.com' count=4 dns='example.com' public=1 trace=1; while [[ $# -gt 0 ]]; do case "$1" in --count) shift; count="${1:-4}";; --dns) shift; dns="${1:-example.com}";; --no-public-ip) public=0;; --no-trace) trace=0;; -h|--help) np_usage; return 0;; *) host="$1";; esac; shift; done; uk_header 'UtilityKit Network Probe' "target: $host"; uk_section_title 'Ping'; if uk_has_cmd ping; then ping -c "$count" "$host" 2>&1 | tail -n 8 || uk_warn "Ping failed for $host"; else uk_warn 'ping unavailable; skipping.'; fi; uk_section_title 'DNS'; if uk_has_cmd dig; then dig +short "$dns" | head -5; elif uk_has_cmd nslookup; then nslookup "$dns" 2>/dev/null | sed -n '1,8p'; elif uk_has_cmd python3; then python3 -c 'import socket,sys; print(socket.gethostbyname(sys.argv[1]))' "$dns" || true; else uk_warn 'No DNS helper available.'; fi; if (( public==1 )); then uk_section_title 'Public IP'; uk_has_cmd curl && (curl -fsS --max-time 5 https://api.ipify.org || true; echo) || uk_warn 'curl unavailable; skipping.'; fi; if (( trace==1 )); then uk_section_title 'Route trace'; if uk_has_cmd traceroute; then traceroute "$host" 2>/dev/null | head -20 || true; elif uk_has_cmd tracepath; then tracepath "$host" 2>/dev/null | head -20 || true; else uk_warn 'No traceroute/tracepath available.'; fi; fi; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" network
  else
    np_main "$@"
  fi
fi
