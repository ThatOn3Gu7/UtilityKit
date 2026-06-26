#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

SC_HOST=''
SC_PORT=443
SC_DNS=1
SC_TLS=1

sc_usage() {
  cat <<'USAGE'
Usage:
  _ssl_checker.sh HOST [--port 443] [--no-dns] [--no-tls]
USAGE
}
sc_days_left() {
  python3 - "$1" <<'PY2'
import sys,datetime,email.utils
expiry = email.utils.parsedate_to_datetime(sys.argv[1])
now = datetime.datetime.now(expiry.tzinfo)
print((expiry-now).days)
PY2
}
sc_dns() {
  printf '\n  %s%sDNS records for %s%s\n' \
    "$UK_C_BOLD" "$UK_C_CYAN" "$SC_HOST" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  if uk_has_cmd dig; then
    local result
    for t in A AAAA MX TXT; do
      result="$(dig +short "$SC_HOST" "$t" 2>/dev/null | paste -sd '; ' - || true)"
      if [[ -n "$result" ]]; then
        printf '  %s%-6s%s %s\n' "$UK_C_BOLD" "$t" "$UK_C_RESET" "$result"
      else
        printf '  %s%-6s%s %s(no record)%s\n' "$UK_C_BOLD" "$t" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
      fi
    done
  elif uk_has_cmd nslookup; then
    nslookup "$SC_HOST" 2>/dev/null | sed 's/^/  /' || true
  else
    printf '  %s(dig and nslookup unavailable — skipping DNS checks)%s\n' "$UK_C_DIM" "$UK_C_RESET"
  fi
}
sc_tls_checks() {
  uk_note 'Legacy TLS support probe:'
  if openssl s_client -connect "$SC_HOST:$SC_PORT" -servername "$SC_HOST" -tls1 </dev/null >/dev/null 2>&1; then
    uk_warn 'Server still accepts TLS 1.0.'
  else
    uk_success 'TLS 1.0 rejected.'
  fi
  if openssl s_client -connect "$SC_HOST:$SC_PORT" -servername "$SC_HOST" -tls1_1 </dev/null >/dev/null 2>&1; then
    uk_warn 'Server still accepts TLS 1.1.'
  else
    uk_success 'TLS 1.1 rejected.'
  fi
}
sc_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
    *) SC_HOST="$1" ;;
    esac
    shift
  done
  if [[ -z "$SC_HOST" ]]; then
    if [[ -t 0 && -t 1 ]]; then
      uk_header 'UtilityKit SSL Checker' 'Certificate expiry, DNS records and legacy TLS probe'
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
  uk_has_cmd openssl || {
    uk_error 'openssl is required.'
    return 1
  }
  uk_header 'UtilityKit SSL Checker' "$SC_HOST:$SC_PORT"
  local cert_info expiry issuer subject days
  cert_info=$(openssl s_client -connect "$SC_HOST:$SC_PORT" -servername "$SC_HOST" </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject 2>/dev/null) || {
    uk_error 'Failed to retrieve certificate.'
    return 1
  }
  printf '%s\n' "$cert_info" | sed 's/^/  /'
  expiry=$(printf '%s\n' "$cert_info" | awk -F= '/notAfter/ {print $2}')
  subject=$(printf '%s\n' "$cert_info" | awk -F= '/subject=/ {$1=""; sub(/^ /,""); print}')
  issuer=$(printf '%s\n' "$cert_info" | awk -F= '/issuer=/ {$1=""; sub(/^ /,""); print}')
  days=$(sc_days_left "$expiry")
  printf '\nSubject: %s\nIssuer : %s\nDays left: %s\n' "$subject" "$issuer" "$days"
  ((days < 0)) && uk_error 'Certificate is expired.' || ((days < 30)) && uk_warn 'Certificate expires in less than 30 days.' || uk_success 'Certificate lifetime looks healthy.'
  ((SC_DNS == 1)) && {
    printf '\n'
    sc_dns
  }
  ((SC_TLS == 1)) && {
    printf '\n'
    sc_tls_checks
  }
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sc_main "$@"
fi
