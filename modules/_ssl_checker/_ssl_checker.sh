#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

SC_HOST=''
SC_PORT=443
SC_DNS=1
SC_TLS=1

sc_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf 'Usage:\n  _ssl_checker.sh HOST [OPTIONS]\n\n'
  uk_help_section "$w" "Options" \
    "--port PORT" "Port to connect on (default: 443)." \
    "--no-dns" "Skip DNS record lookup." \
    "--no-tls" "Skip legacy TLS protocol probe." \
    "-h, --help" "Show this help."
}
sc_days_left() {
  python3 - "${1:-}" <<'PY2'
import sys,datetime,email.utils
expiry = email.utils.parsedate_to_datetime(sys.argv[1])
now = datetime.datetime.now(expiry.tzinfo)
print((expiry-now).days)
PY2
}
sc_endpoint() {
  if [[ "$SC_HOST" == *:* && "$SC_HOST" != \[*\] ]]; then
    printf '[%s]:%s\n' "$SC_HOST" "$SC_PORT"
  else
    printf '%s:%s\n' "$SC_HOST" "$SC_PORT"
  fi
}
sc_dns() {
  printf '\n  %s%sDNS records for %s%s\n' \
    "$UK_C_BOLD" "$UK_C_CYAN" "$SC_HOST" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  if uk_has_cmd dig; then
    local result output
    for t in A AAAA MX TXT; do
      output="$(dig +short "$SC_HOST" "$t" 2>&1)" || {
        uk_error "DNS query failed for $t: $output"
        return 1
      }
      result="$(printf '%s\n' "$output" | paste -sd '; ' -)" || return 1
      if [[ -n "$result" ]]; then
        printf '  %s%-6s%s %s\n' "$UK_C_BOLD" "$t" "$UK_C_RESET" "$result"
      else
        printf '  %s%-6s%s %s(no record)%s\n' "$UK_C_BOLD" "$t" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
      fi
    done
  elif uk_has_cmd nslookup; then
    local output
    output="$(nslookup "$SC_HOST" 2>&1)" || {
      uk_error "DNS lookup failed: $output"
      return 1
    }
    printf '%s\n' "$output" | sed 's/^/  /'
  else
    printf '  %s(dig and nslookup unavailable — skipping DNS checks)%s\n' "$UK_C_DIM" "$UK_C_RESET"
  fi
}
sc_tls_probe() {
  local flag="$1" label="$2" output endpoint
  endpoint="$(sc_endpoint)" || return 1
  if output="$(openssl s_client -connect "$endpoint" -servername "$SC_HOST" "$flag" </dev/null 2>&1)"; then
    uk_warn "Server still accepts $label."
    return 0
  fi
  if grep -Eqi 'alert protocol version|wrong version number|unsupported protocol' <<<"$output"; then
    uk_success "$label rejected by the server."
    return 0
  fi
  uk_error "$label probe failed for a non-protocol reason: ${output##*$'\n'}"
  return 1
}
sc_tls_checks() {
  uk_note 'Legacy TLS support probe:'
  sc_tls_probe -tls1 'TLS 1.0' || return 1
  sc_tls_probe -tls1_1 'TLS 1.1' || return 1
}
sc_main() {
  uk_banner "ssl-checker" "Certificate expiry, DNS records, legacy TLS probe" "" "$@"
  SC_HOST=''
  SC_PORT=443
  SC_DNS=1
  SC_TLS=1
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --port)
      shift
      SC_PORT="${1:-443}"
      ;;
    --no-dns) SC_DNS=0 ;;
    --no-tls) SC_TLS=0 ;;
    -h | --help)
      sc_usage
      return 0
      ;;
    *) SC_HOST="${1:-}" ;;
    esac
    shift
  done
  if [[ -z "$SC_HOST" ]]; then
    if [[ -t 0 && -t 1 ]]; then
      SC_HOST="$(uk_prompt \
        'Enter the domain or host to inspect' \
        '' \
        'example.com  |  api.myservice.io  |  mail.company.org' \
        'The tool will connect on the specified port and fetch the certificate.')"
      SC_PORT="$(uk_prompt \
        'Enter the port to connect on' \
        '443' \
        '443  →  standard HTTPS  |  8443  →  alternate HTTPS  |  465  →  SMTPS' \
        'Most HTTPS services use 443. Leave blank to use the default.')"
      [[ -n "$SC_HOST" ]] || {
        uk_warn 'No host entered. Exiting.'
        return 0
      }
    else
      sc_usage
      return 1
    fi
  fi
  [[ "$SC_PORT" =~ ^[0-9]+$ ]] && ((SC_PORT >= 1 && SC_PORT <= 65535)) || {
    uk_error "Port must be in 1..65535: $SC_PORT"
    return 1
  }
  [[ "$SC_HOST" != -* && "$SC_HOST" != *$'\n'* && "$SC_HOST" != *$'\r'* && "$SC_HOST" != *[[:space:]]* ]] || {
    uk_error "Invalid host: $SC_HOST"
    return 1
  }
  uk_has_cmd openssl || {
    uk_error 'openssl is required.'
    return 1
  }
  local endpoint
  endpoint="$(sc_endpoint)" || return 1
  uk_section_title "$endpoint"
  local handshake cert_info expiry issuer subject days health_status=0
  handshake="$(openssl s_client -connect "$endpoint" -servername "$SC_HOST" </dev/null 2>&1)" || {
    uk_error "Failed to establish TLS connection: ${handshake##*$'\n'}"
    return 1
  }
  cert_info="$(printf '%s\n' "$handshake" | openssl x509 -noout -dates -issuer -subject 2>&1)" || {
    uk_error "Failed to parse certificate: $cert_info"
    return 1
  }
  printf '%s\n' "$cert_info" | sed 's/^/  /'
  expiry=$(printf '%s\n' "$cert_info" | awk -F= '/notAfter/ {print $2}') || return 1
  subject=$(printf '%s\n' "$cert_info" | awk -F= '/subject=/ {$1=""; sub(/^ /,""); print}') || return 1
  issuer=$(printf '%s\n' "$cert_info" | awk -F= '/issuer=/ {$1=""; sub(/^ /,""); print}') || return 1
  days=$(sc_days_left "$expiry") || {
    uk_error "Unable to parse certificate expiry."
    return 1
  }
  [[ "$days" =~ ^-?[0-9]+$ ]] || {
    uk_error "Invalid certificate lifetime: $days"
    return 1
  }
  printf '\nSubject: %s\nIssuer : %s\nDays left: %s\n' "$subject" "$issuer" "$days"
  if ((days < 0)); then
    uk_error 'Certificate is expired.'
    health_status=1
  elif ((days < 30)); then
    uk_warn 'Certificate expires in less than 30 days.'
  else
    uk_success 'Certificate lifetime looks healthy.'
  fi
  if ((SC_DNS == 1)); then
    printf '\n'
    sc_dns || return 1
  fi
  if ((SC_TLS == 1)); then
    printf '\n'
    sc_tls_checks || return 1
  fi
  return "$health_status"
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sc_main "$@"
fi
