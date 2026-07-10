#!/usr/bin/env bash
# _ip_info — local + public IP, reverse DNS, ASN, GeoIP, WHOIS, IPv6 status.
# Prefix: ii_
# Data sources (opt-out via --no-network): ipinfo.io, ifconfig.co (fallback),
#                                          ipv6.icanhazip.com, ip-api.com.
# Local IP detection: `ip addr` → `ifconfig` → `hostname -I`.
# WHOIS: `whois` binary, degrades gracefully if absent.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
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

ii_usage() {
  cat <<'USAGE'
Usage:
  _ip_info.sh [TARGET] [OPTIONS]

  TARGET may be an IPv4/IPv6 address or hostname. Without a TARGET, the tool
  reports on the local machine's public IP.

Options:
  --local            Show local interfaces (IPv4/IPv6, MAC, gateway).
  --public           Look up public IPv4 (and IPv6 if available).
  --whois            Include WHOIS registrar/org summary.
  --geo              Include GeoIP/ASN lookup (default when public/target).
  --no-network       Skip every network call (local-only report).
  --timeout SEC      HTTP timeout per request (default 5).
  --json             Emit results as a single JSON document.
  --no-color         Disable ANSI.
  -h, --help         Show this help.

Examples:
  _ip_info.sh                    # local + public IP report
  _ip_info.sh 1.1.1.1            # inspect a remote IP
  _ip_info.sh github.com --whois
  _ip_info.sh --local --no-network
  _ip_info.sh --json
USAGE
}

# ---- Helpers ---------------------------------------------------------------

ii_hr() {
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 72 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}
ii_section() {
  printf '\n%s%s%s%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$1" "${UK_C_RESET:-}"
  ii_hr
}
ii_kv() {
  local key="$1" val="${2:-}"
  [[ -z "$val" ]] && val="${UK_C_DIM:-}—${UK_C_RESET:-}"
  printf '  %s%-14s%s  %s\n' "${UK_C_DIM:-}" "$key" "${UK_C_RESET:-}" "$val"
}

ii_curl() {
  local url="$1" timeout="$2"
  uk_has_cmd curl || return 1
  curl -sS -m "$timeout" -A "utilitykit-ip-info/1.0" "$url" 2>/dev/null
}

ii_json_escape() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

ii_is_ipv4() { [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }
ii_is_ipv6() { [[ "$1" =~ : ]] && [[ "$1" =~ ^[0-9a-fA-F:]+$ ]]; }

# Resolve a hostname to a single IP (A record) using getent → dig → host.
ii_resolve_host() {
  local host="$1"
  local ip=''
  if uk_has_cmd getent; then
    ip="$(getent ahosts "$host" 2>/dev/null | awk '/STREAM|RAW/ {print $1; exit}')"
  fi
  if [[ -z "$ip" ]] && uk_has_cmd dig; then
    ip="$(dig +short "$host" A 2>/dev/null | head -n1)"
  fi
  if [[ -z "$ip" ]] && uk_has_cmd host; then
    ip="$(host "$host" 2>/dev/null | awk '/has address/ {print $NF; exit}')"
  fi
  if [[ -z "$ip" ]] && uk_has_cmd python3; then
    ip="$(python3 -c 'import socket,sys
try: print(socket.gethostbyname(sys.argv[1]))
except Exception: pass' "$host" 2>/dev/null)"
  fi
  printf '%s' "$ip"
}

# Reverse DNS lookup (PTR).
ii_reverse_dns() {
  local ip="$1"
  if uk_has_cmd dig; then
    dig +short -x "$ip" 2>/dev/null | sed 's/\.$//' | head -n1
  elif uk_has_cmd host; then
    host "$ip" 2>/dev/null | awk '/domain name pointer/ {print $NF; exit}' | sed 's/\.$//'
  elif uk_has_cmd python3; then
    python3 -c 'import socket,sys
try: print(socket.gethostbyaddr(sys.argv[1])[0])
except Exception: pass' "$ip" 2>/dev/null
  fi
}

# ---- Local interfaces ------------------------------------------------------

ii_local_report() {
  ii_section 'Local network'

  local hn plat gw
  hn="$(hostname 2>/dev/null || printf 'unknown')"
  plat="$(uk_platform)"
  ii_kv 'hostname' "$hn"
  ii_kv 'platform' "$plat"

  # Default gateway. Every backend can fail on locked-down systems (e.g.
  # Termux without proc/net/route access) so we always tack `|| true` on so
  # the outer `set -e` does not see a pipefail bubble up.
  gw=""
  if uk_has_cmd ip; then
    gw="$(ip route 2>/dev/null | awk '/^default/ {print $3; exit}' || true)"
  fi
  if [[ -z "$gw" ]] && uk_has_cmd route; then
    gw="$({ route -n 2>/dev/null || true; } | awk '/^0\.0\.0\.0/ {print $2; exit}' || true)"
  fi
  if [[ -z "$gw" ]] && uk_has_cmd netstat; then
    gw="$({ netstat -rn 2>/dev/null || true; } | awk '/^default/ {print $2; exit}' || true)"
  fi
  ii_kv 'gateway' "$gw"

  # Interface list.
  local -a rows=()
  if uk_has_cmd ip; then
    while IFS= read -r line; do rows+=("$line"); done < <(
      { ip -o addr show 2>/dev/null || true; } | awk '
        $3 == "inet"  {printf "%s|IPv4|%s\n", $2, $4}
        $3 == "inet6" && $4 !~ /^fe80/ {printf "%s|IPv6|%s\n", $2, $4}
      ' || true
    )
  fi
  if [[ ${#rows[@]} -eq 0 ]] && uk_has_cmd ifconfig; then
    while IFS= read -r line; do rows+=("$line"); done < <(
      { ifconfig 2>/dev/null || true; } | awk '
        /^[a-z0-9]/ {iface=$1; sub(":","",iface); next}
        /inet /       {for(i=1;i<=NF;i++) if($i=="inet")  printf "%s|IPv4|%s\n", iface, $(i+1)}
        /inet6 /      {for(i=1;i<=NF;i++) if($i=="inet6") if($(i+1) !~ /^fe80/) printf "%s|IPv6|%s\n", iface, $(i+1)}
      ' || true
    )
  fi

  if [[ ${#rows[@]} -eq 0 ]]; then
    printf '  %s(no interface info available — install iproute2 or net-tools)%s\n' \
      "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    return 0
  fi

  printf '\n  %s%-14s  %-6s  %s%s\n' "${UK_C_BOLD:-}" 'interface' 'family' 'address' "${UK_C_RESET:-}"
  local row iface fam addr
  for row in "${rows[@]}"; do
    IFS='|' read -r iface fam addr <<<"$row"
    printf '  %-14s  %-6s  %s\n' "$iface" "$fam" "$addr"
  done
}

# ---- Public IP + geo -------------------------------------------------------

# Fetch public IPv4. First tries ipinfo.io/ip (bare IP response), falls back
# to ifconfig.co and ifconfig.me.
ii_get_public_v4() {
  local timeout="$1" ip
  for url in "https://ipinfo.io/ip" "https://ifconfig.co" "https://ifconfig.me" "https://api.ipify.org"; do
    ip="$(ii_curl "$url" "$timeout" | tr -d ' \t\r\n')"
    if ii_is_ipv4 "$ip"; then
      printf '%s' "$ip"
      return 0
    fi
  done
  return 1
}

# Fetch public IPv6.
ii_get_public_v6() {
  local timeout="$1" ip
  for url in "https://ipv6.icanhazip.com" "https://api64.ipify.org" "https://ifconfig.co"; do
    ip="$(ii_curl "$url" "$timeout" | tr -d ' \t\r\n')"
    if ii_is_ipv6 "$ip"; then
      printf '%s' "$ip"
      return 0
    fi
  done
  return 1
}

# Enrich an IP via ip-api.com (JSON, no key required for ~45 rpm).
# Returns key=value lines (one per field) to stdout.
ii_enrich() {
  local ip="$1" timeout="$2" body
  body="$(ii_curl "http://ip-api.com/json/${ip}?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query,reverse" "$timeout")"
  [[ -z "$body" ]] && return 1

  if uk_has_cmd python3; then
    printf '%s' "$body" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception as e:
    print(f"error={e}"); sys.exit(0)
if d.get("status") != "success":
    print("error={}".format(d.get("message", "unknown"))); sys.exit(0)
order = ["query","reverse","country","countryCode","regionName","city","zip",
         "lat","lon","timezone","isp","org","as"]
for k in order:
    v = d.get(k)
    if v is None or v == "": continue
    print(f"{k}={v}")
'
  else
    # Minimal grep-based fallback.
    printf '%s' "$body" | tr ',' '\n' | sed 's/[{}"]//g; s/:/=/'
  fi
}

# ---- WHOIS -----------------------------------------------------------------

ii_whois_summary() {
  local target="$1"
  uk_has_cmd whois || { printf 'error=whois binary not installed\n'; return 1; }
  # Cap at 6-second lookup so a slow WHOIS server never wedges the tool.
  local raw
  raw="$(timeout 6 whois "$target" 2>/dev/null)"
  [[ -z "$raw" ]] && { printf 'error=empty whois response\n'; return 1; }

  # Extract common fields case-insensitively; keep the first non-empty match.
  local field val
  for field in 'OrgName' 'org-name' 'organization' 'Organization' 'descr' 'netname' \
               'NetName' 'Country' 'country' 'CIDR' 'inetnum' 'route' \
               'Registrar' 'RegDate' 'created' 'Updated' 'updated' 'NameServer' \
               'name servers'; do
    val="$(printf '%s\n' "$raw" | grep -i "^[[:space:]]*${field}:" | head -n1 | \
           sed 's/^[[:space:]]*[^:]*:[[:space:]]*//; s/[[:space:]]*$//')"
    if [[ -n "$val" ]]; then
      # Normalize the key we emit so the printer can align nicely.
      local ekey
      case "${field,,}" in
        orgname|org-name|organization) ekey='org' ;;
        descr|netname)                 ekey='netname' ;;
        country)                       ekey='country' ;;
        cidr|inetnum|route)            ekey='range' ;;
        registrar)                     ekey='registrar' ;;
        regdate|created)               ekey='created' ;;
        updated)                       ekey='updated' ;;
        'nameserver'|'name servers')   ekey='nameserver' ;;
        *)                             ekey="$field" ;;
      esac
      printf '%s=%s\n' "$ekey" "$val"
    fi
  done
}

# ---- Report drivers --------------------------------------------------------

ii_report_public() {
  local timeout="$1"
  ii_section 'Public IP'

  local v4 v6 ptr4
  v4="$(ii_get_public_v4 "$timeout" || true)"
  v6="$(ii_get_public_v6 "$timeout" || true)"

  if [[ -n "$v4" ]]; then
    ptr4="$(ii_reverse_dns "$v4" 2>/dev/null)"
    ii_kv 'IPv4' "$v4"
    [[ -n "$ptr4" ]] && ii_kv 'PTR' "$ptr4"
  else
    ii_kv 'IPv4' 'lookup failed'
  fi
  if [[ -n "$v6" ]]; then
    ii_kv 'IPv6' "$v6"
  else
    ii_kv 'IPv6' 'no route / not detected'
  fi

  # Emit the primary IP so the caller can enrich it.
  printf '%s\n' "$v4"
}

ii_report_geo() {
  local ip="$1" timeout="$2"
  [[ -z "$ip" ]] && return 0
  ii_section "GeoIP & ASN — $ip"

  local out kv key val
  out="$(ii_enrich "$ip" "$timeout" || true)"
  if [[ -z "$out" ]]; then
    printf '  %s(no geo data — is curl installed / network reachable?)%s\n' \
      "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    return 0
  fi

  while IFS='=' read -r key val; do
    [[ -z "$key" ]] && continue
    ii_kv "$key" "$val"
  done <<<"$out"
}

ii_report_whois() {
  local target="$1"
  ii_section "WHOIS — $target"

  local out key val
  out="$(ii_whois_summary "$target")"
  if [[ -z "$out" ]] || printf '%s' "$out" | grep -q '^error='; then
    local err
    err="$(printf '%s' "$out" | grep '^error=' | head -n1 | cut -d= -f2-)"
    printf '  %s(%s)%s\n' "${UK_C_DIM:-}" "${err:-no data}" "${UK_C_RESET:-}"
    return 0
  fi
  while IFS='=' read -r key val; do
    [[ -z "$key" ]] && continue
    ii_kv "$key" "$val"
  done <<<"$out"
}

ii_valid_json_or_null() {
  if uk_has_cmd python3; then
    python3 -c 'import json,sys
try:
    data=json.load(sys.stdin); print(json.dumps(data, ensure_ascii=False))
except Exception:
    print("null")'
  else
    printf 'null\n'
  fi
}

# ---- JSON mode -------------------------------------------------------------

ii_report_json() {
  local target="$1" want_local="$2" want_public="$3" want_geo="$4" \
        want_whois="$5" no_network="$6" timeout="$7"

  local -a parts=()
  parts+=("$(printf '"target":%s' "$(ii_json_escape "$target")")")
  if (( no_network )); then
    parts+=("\"network_disabled\":true")
  fi

  if (( want_local )); then
    local hn plat gw
    hn="$(hostname 2>/dev/null || printf 'unknown')"
    plat="$(uk_platform)"
    if uk_has_cmd ip; then gw="$(ip route 2>/dev/null | awk '/^default/ {print $3; exit}')"
    elif uk_has_cmd route; then gw="$(route -n 2>/dev/null | awk '/^0\.0\.0\.0/ {print $2; exit}')"; fi
    parts+=("$(printf '"local":{"hostname":%s,"platform":%s,"gateway":%s}' \
      "$(ii_json_escape "$hn")" "$(ii_json_escape "$plat")" "$(ii_json_escape "${gw:-}")")")
  fi

  local ip_for_geo="$target"
  if (( want_public )) && (( ! no_network )); then
    local v4 v6
    v4="$(ii_get_public_v4 "$timeout" || true)"
    v6="$(ii_get_public_v6 "$timeout" || true)"
    parts+=("$(printf '"public":{"v4":%s,"v6":%s}' \
      "$(ii_json_escape "$v4")" "$(ii_json_escape "$v6")")")
    [[ -z "$ip_for_geo" ]] && ip_for_geo="$v4"
  fi

  if (( want_geo )) && (( ! no_network )) && [[ -n "$ip_for_geo" ]]; then
    # Resolve hostname → IP first.
    if ! ii_is_ipv4 "$ip_for_geo" && ! ii_is_ipv6 "$ip_for_geo"; then
      ip_for_geo="$(ii_resolve_host "$ip_for_geo")"
    fi
    local body
    body="$(ii_curl "http://ip-api.com/json/${ip_for_geo}?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query,reverse" "$timeout")"
    body="$(printf '%s' "$body" | ii_valid_json_or_null)"
    parts+=("$(printf '"geo":%s' "${body:-null}")")
  fi

  if (( want_whois )); then
    local wout esc
    wout="$(ii_whois_summary "$target")"
    esc="$(ii_json_escape "$wout")"
    parts+=("$(printf '"whois":%s' "$esc")")
  fi

  printf '{'
  local i=0
  for p in "${parts[@]}"; do
    (( i > 0 )) && printf ','
    printf '%s' "$p"
    i=$(( i + 1 ))
  done
  printf '}\n'
}

# ---- Main ------------------------------------------------------------------

ii_main() {
  uk_banner "ip-info" "Public/local IP, reverse DNS, ASN, GeoIP, WHOIS" "" "$@"

  local target=""
  local want_local=0 want_public=0 want_whois=0 want_geo=0
  local no_network=0 timeout=5 as_json=0
  local explicit_sections=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --local)      want_local=1;   explicit_sections=1 ;;
      --public)     want_public=1;  explicit_sections=1 ;;
      --whois)      want_whois=1;   explicit_sections=1 ;;
      --geo)        want_geo=1;     explicit_sections=1 ;;
      --no-network) no_network=1 ;;
      --timeout)    shift; timeout="${1:-5}" ;;
      --json)       as_json=1 ;;
      --no-color)   UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                    UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help)    ii_usage; return 0 ;;
      -*)           uk_error "Unknown option: ${1:-}"; ii_usage; return 2 ;;
      *)            target="${1:-}" ;;
    esac
    shift || true
  done

  [[ "$timeout" =~ ^[0-9]+$ ]] || { uk_error "Invalid --timeout"; return 2; }

  # Defaults if the user gave no --local/--public/--whois/--geo:
  #   - No target      → local + public + geo
  #   - Target given   → geo (+ whois if requested)
  if (( ! explicit_sections )); then
    if [[ -z "$target" ]]; then
      want_local=1; want_public=1; want_geo=1
    else
      want_geo=1
    fi
  fi

  # Force-disable everything network-dependent when --no-network is set.
  if (( no_network )); then
    want_public=0
    want_geo=0
    want_whois=0
  fi
  if (( no_network )) && (( ! want_local && ! as_json )); then
    uk_warn "--no-network disabled all requested sections; use --local for an offline report."
    return 0
  fi

  # If a target hostname was given, resolve it once so geo/reverse work.
  local target_ip="$target"
  if [[ -n "$target" ]] && ! ii_is_ipv4 "$target" && ! ii_is_ipv6 "$target"; then
    target_ip="$(ii_resolve_host "$target")"
    [[ -z "$target_ip" ]] && uk_warn "Could not resolve $target — skipping geo/reverse."
  fi

  if (( as_json )); then
    ii_report_json "$target" "$want_local" "$want_public" "$want_geo" \
      "$want_whois" "$no_network" "$timeout"
    return 0
  fi

  # Pretty report.
  (( want_local )) && ii_local_report

  local resolved_public=""
  if (( want_public )); then
    resolved_public="$(ii_report_public "$timeout" | tail -n1)"
  fi

  if (( want_geo )); then
    local ip_for_geo="$target_ip"
    [[ -z "$ip_for_geo" ]] && ip_for_geo="$resolved_public"
    if [[ -n "$ip_for_geo" ]]; then
      ii_report_geo "$ip_for_geo" "$timeout"
    fi
  fi

  if (( want_whois )) && [[ -n "$target" ]]; then
    ii_report_whois "$target"
  fi

  printf '\n'
}

ii_wizard() {
  uk_banner "ip-info" "Public/local IP, reverse DNS, ASN, GeoIP, WHOIS" ""
  local target want_local want_public want_geo want_whois jsonf
  target="$(uk_prompt 'Target IP/hostname (blank = report on local)' '' '1.1.1.1' '')"
  if uk_confirm 'Include local interfaces?' 'Y'; then want_local="--local"; else want_local=""; fi
  if [[ -z "$target" ]]; then
    if uk_confirm 'Look up my public IP?' 'Y'; then want_public="--public"; else want_public=""; fi
  else
    want_public=""
  fi
  if uk_confirm 'GeoIP & ASN lookup?' 'Y'; then want_geo="--geo"; else want_geo=""; fi
  if uk_confirm 'WHOIS lookup?' 'N'; then want_whois="--whois"; else want_whois=""; fi
  if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi

  local -a a=()
  [[ -n "$target"      ]] && a+=("$target")
  [[ -n "$want_local"  ]] && a+=("$want_local")
  [[ -n "$want_public" ]] && a+=("$want_public")
  [[ -n "$want_geo"    ]] && a+=("$want_geo")
  [[ -n "$want_whois"  ]] && a+=("$want_whois")
  [[ -n "$jsonf"       ]] && a+=("$jsonf")
  ii_main "${a[@]}"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    ii_wizard
  else
    ii_main "$@"
  fi
fi
