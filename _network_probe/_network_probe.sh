#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

np_usage() {
  cat <<'USAGE'
Usage: _network_probe.sh [HOST] [--count N] [--dns DOMAIN] [--no-public-ip] [--no-trace]

Options:
  HOST              Target host for ping and traceroute (default: example.com)
  --count N         Number of ping packets (default: 4)
  --dns DOMAIN      Domain to resolve (default: same as HOST)
  --no-public-ip    Skip public IP lookup
  --no-trace        Skip route tracing
  -h, --help        Show this help
USAGE
}
np_section() {
  local title="$1" icon="${2:-$UK_I_INFO}"
  printf '\n  %s%s%s %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_BRIGHT_CYAN" "$icon" "$title" "$UK_C_RESET" ""
  printf '  %s%s%s\n' "$UK_C_DIM" "$(printf '%*s' 52 '' | tr ' ' '-')" "$UK_C_RESET"
}
np_ping() {
  local host="$1" count="$2"
  np_section 'Ping' '◉'

  if ! uk_has_cmd ping; then
    uk_warn 'ping unavailable — skipping.'
    return 0
  fi

  local output
  output=$(ping -c "$count" "$host" 2>&1 || true)

  if [[ -z "$output" ]]; then
    uk_warn "No ping response from $host"
    return 0
  fi

  # Print each hop/line with indentation and dim color, highlight summary line
  while IFS= read -r line; do
    if [[ "$line" == *'packet loss'* ]]; then
      local color="$UK_C_GREEN"
      [[ "$line" == *'100% packet loss'* ]] && color="$UK_C_RED"
      [[ "$line" == *[1-9][0-9]'% packet loss'* ]] && color="$UK_C_YELLOW"
      printf '  %s%s%s\n' "$color" "$line" "$UK_C_RESET"
    elif [[ "$line" == *'min/avg/max'* || "$line" == *'round-trip'* ]]; then
      printf '  %s%s%s\n' "$UK_C_CYAN" "$line" "$UK_C_RESET"
    else
      printf '  %s%s%s\n' "$UK_C_DIM" "$line" "$UK_C_RESET"
    fi
  done <<<"$output"
}
np_dns() {
  local domain="$1"
  np_section 'DNS Resolution' '◈'

  if uk_has_cmd dig; then
    local results
    results=$(dig +short "$domain" 2>/dev/null | head -5 || true)
    if [[ -n "$results" ]]; then
      printf '  %s%-8s%s ' "$UK_C_BOLD" "A/AAAA" "$UK_C_RESET"
      while IFS= read -r ip; do
        printf '%s%s%s  ' "$UK_C_GREEN" "$ip" "$UK_C_RESET"
      done <<<"$results"
      printf '\n'
    else
      uk_warn "No DNS records found for $domain"
    fi
    # MX records
    local mx
    mx=$(dig +short MX "$domain" 2>/dev/null | head -3 || true)
    [[ -n "$mx" ]] && printf '  %s%-8s%s %s%s%s\n' \
      "$UK_C_BOLD" "MX" "$UK_C_RESET" "$UK_C_DIM" "$mx" "$UK_C_RESET"

  elif uk_has_cmd nslookup; then
    local results
    results=$(nslookup "$domain" 2>/dev/null | grep -E 'Address|Name' | grep -v '#' || true)
    printf '  %s%s%s\n' "$UK_C_DIM" "$results" "$UK_C_RESET"

  elif uk_has_cmd python3; then
    local ip
    ip=$(python3 -c 'import socket,sys; print(socket.gethostbyname(sys.argv[1]))' "$domain" 2>/dev/null || true)
    if [[ -n "$ip" ]]; then
      printf '  %s%-8s%s %s%s%s\n' "$UK_C_BOLD" "A" "$UK_C_RESET" "$UK_C_GREEN" "$ip" "$UK_C_RESET"
    else
      uk_warn "Could not resolve $domain"
    fi
  else
    uk_warn 'No DNS tool available (dig, nslookup, or python3 required).'
  fi
}
np_public_ip() {
  np_section 'Public IP' '◎'

  if ! uk_has_cmd curl; then
    uk_warn 'curl unavailable — skipping.'
    return 0
  fi

  local ip
  ip=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)
  if [[ -n "$ip" ]]; then
    printf '  %sIPv4:%s  %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_GREEN" "$ip" "$UK_C_RESET"
  else
    # Try IPv6 fallback
    ip=$(curl -fsS --max-time 5 https://api6.ipify.org 2>/dev/null || true)
    if [[ -n "$ip" ]]; then
      printf '  %sIPv6:%s  %s%s%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$ip" "$UK_C_RESET"
    else
      uk_warn 'Public IP lookup failed (no connectivity or timeout).'
    fi
  fi
}
np_trace() {
  local host="$1"
  np_section 'Route Trace' '⇢'

  local cmd=''
  uk_has_cmd traceroute && cmd='traceroute'
  uk_has_cmd tracepath && [[ -z "$cmd" ]] && cmd='tracepath'

  if [[ -z "$cmd" ]]; then
    uk_warn 'No traceroute or tracepath available — skipping.'
    return 0
  fi

  local output
  output=$($cmd "$host" 2>/dev/null | head -20 || true)

  if [[ -z "$output" ]]; then
    uk_warn "Route trace returned no output for $host"
    return 0
  fi

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*[0-9]+ ]]; then
      # Highlight hop lines that have IPs
      if [[ "$line" == *'ms'* ]]; then
        printf '  %s%s%s\n' "$UK_C_CYAN" "$line" "$UK_C_RESET"
      else
        printf '  %s%s%s\n' "$UK_C_DIM" "$line" "$UK_C_RESET"
      fi
    else
      printf '  %s%s%s\n' "$UK_C_DIM" "$line" "$UK_C_RESET"
    fi
  done <<<"$output"
}
np_main() {
  uk_banner "network-probe" "Ping, DNS lookup, public IP, and route tracing" "" "$@"
  local host='example.com' count=4 dns='' public=1 trace=1

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --count)
      shift
      count="${1:-4}"
      ;;
    --dns)
      shift
      dns="${1:-}"
      ;;
    --no-public-ip) public=0 ;;
    --no-trace) trace=0 ;;
    -h | --help)
      np_usage
      return 0
      ;;
    *) host="$1" ;;
    esac
    shift
  done

  # Default DNS target to host if not set separately
  [[ -z "$dns" ]] && dns="$host"

  uk_section_title "target: $host"

  np_ping "$host" "$count"
  np_dns "$dns"
  ((public == 1)) && np_public_ip
  ((trace == 1)) && np_trace "$host"

  printf '\n'
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  np_main "$@"
fi
