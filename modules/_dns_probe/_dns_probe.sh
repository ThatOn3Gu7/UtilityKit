#!/usr/bin/env bash
# _dns_probe — query DNS records across multiple resolvers in parallel;
#              includes a propagation-check mode (authoritative vs public).
# Prefix: dp_
# Backends: dig (bind-utils) → drill (ldns) → host → getent (last resort).
# Termux notes: `pkg install dnsutils` provides dig.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
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

DP_DEFAULT_TYPES=(A AAAA MX TXT NS CAA SOA)
DP_DEFAULT_RESOLVERS=(
  "cloudflare|1.1.1.1"
  "google|8.8.8.8"
  "quad9|9.9.9.9"
  "opendns|208.67.222.222"
  "system|"
)

dp_usage() {
  cat <<'USAGE'
Usage:
  _dns_probe.sh DOMAIN [OPTIONS]

Options:
  --type T[,T,...]     Record types to query. Default: A,AAAA,MX,TXT,NS,CAA,SOA.
                       ANY expands to the default set (real ANY is often blocked).
  --resolver HOST      Query only HOST (IP or hostname). Repeatable.
  --system             Also include the system resolver.
  --propagation        Propagation mode: ask every default resolver + system,
                       diff answers, and flag any resolver that disagrees.
  --timeout SEC        Per-query timeout (default 3).
  --tries N            Retry count per query (default 2).
  --json               Emit results as a single JSON document.
  --no-color           Disable ANSI (also respects NO_COLOR=1).
  -h, --help           Show this help.

Backends tried in order: dig > drill > host.
Examples:
  _dns_probe.sh example.com
  _dns_probe.sh example.com --type A,AAAA,MX
  _dns_probe.sh example.com --propagation
  _dns_probe.sh example.com --resolver 1.1.1.1 --resolver 8.8.4.4
USAGE
}

# ---- Backend selection ------------------------------------------------------

dp_pick_backend() {
  if   uk_has_cmd dig;   then printf 'dig\n'
  elif uk_has_cmd drill; then printf 'drill\n'
  elif uk_has_cmd host;  then printf 'host\n'
  else return 1
  fi
}

# Perform ONE query. Prints one answer per line (record data only).
# Args: backend, domain, type, resolver ('' = system), timeout, tries
dp_query() {
  local backend="$1" domain="$2" rtype="$3" resolver="$4" timeout="$5" tries="$6" output
  case "$backend" in
    dig)
      local -a args=(+short +time="$timeout" +tries="$tries" +noall +answer)
      [[ -n "$resolver" ]] && args=("@$resolver" "${args[@]}")
      output="$(dig "${args[@]}" "$domain" "$rtype" 2>&1)" || { uk_error "dig query failed: $output"; return 1; }
      printf '%s\n' "$output" | sed 's/[[:space:]]*$//' | awk 'NF {if (NF>=5) {for(i=5;i<=NF;i++) printf "%s%s",$i,(i==NF?"\n":" ")} else print}'
      ;;
    drill)
      if [[ -n "$resolver" ]]; then
        output="$(drill -Q "$domain" "$rtype" "@$resolver" 2>&1)" || { uk_error "drill query failed: $output"; return 1; }
      else
        output="$(drill -Q "$domain" "$rtype" 2>&1)" || { uk_error "drill query failed: $output"; return 1; }
      fi
      awk 'NF' <<<"$output"
      ;;
    host)
      if [[ -n "$resolver" ]]; then
        output="$(host -W "$timeout" -t "$rtype" "$domain" "$resolver" 2>&1)" || { uk_error "host query failed: $output"; return 1; }
      else
        output="$(host -W "$timeout" -t "$rtype" "$domain" 2>&1)" || { uk_error "host query failed: $output"; return 1; }
      fi
      sed -n 's/.* has address //p; s/.* has IPv6 address //p; s/.* mail is handled by //p; s/.* descriptive text //p; s/.* name server //p' <<<"$output"
      ;;
    *) uk_error "Unknown DNS backend: $backend"; return 1 ;;
  esac
}

# ---- Formatters -------------------------------------------------------------

dp_hr() {
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 72 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}

dp_print_section() {
  local title="$1"
  printf '\n%s%s%s%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$title" "${UK_C_RESET:-}"
  dp_hr
}

dp_print_records() {
  local rtype="$1"; shift
  local -a records=("$@")
  if (( ${#records[@]} == 0 )); then
    printf '  %s%-6s%s  %s(no answer)%s\n' \
      "${UK_C_DIM:-}" "$rtype" "${UK_C_RESET:-}" \
      "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    return
  fi
  local first=1 r
  for r in "${records[@]}"; do
    if (( first )); then
      printf '  %s%-6s%s  %s\n' \
        "${UK_C_BOLD:-}${UK_C_GREEN:-}" "$rtype" "${UK_C_RESET:-}" "$r"
      first=0
    else
      printf '  %-6s  %s\n' '' "$r"
    fi
  done
}

# ---- Standard mode (query each type once against first resolver) ------------

dp_run_standard() {
  local backend="$1" domain="$2" timeout="$3" tries="$4"
  local -n types_ref=$5
  local -n resolvers_ref=$6

  # If multiple resolvers are supplied, print one section per resolver.
  local r rlabel rip rtype answer
  local -a answers
  for r in "${resolvers_ref[@]}"; do
    rlabel="${r%%|*}"; rip="${r#*|}"
    [[ "$rlabel" == "$r" ]] && { rlabel="$r"; rip="$r"; }
    if [[ -z "$rip" ]]; then
      dp_print_section "$rlabel  (system resolver)"
    else
      dp_print_section "$rlabel  ($rip)"
    fi

    for rtype in "${types_ref[@]}"; do
      answers=()
      local query_output
      query_output="$(dp_query "$backend" "$domain" "$rtype" "$rip" "$timeout" "$tries")" || return 1
      while IFS= read -r answer; do [[ -n "$answer" ]] && answers+=("$answer"); done <<<"$query_output"
      dp_print_records "$rtype" "${answers[@]}"
    done
  done
}

# ---- JSON mode --------------------------------------------------------------

dp_json_escape() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

dp_run_json() {
  local backend="$1" domain="$2" timeout="$3" tries="$4"
  local -n types_ref=$5
  local -n resolvers_ref=$6

  printf '{'
  printf '"domain":%s,' "$(dp_json_escape "$domain")"
  printf '"backend":%s,' "$(dp_json_escape "$backend")"
  printf '"resolvers":['
  local first_r=1 r rlabel rip
  for r in "${resolvers_ref[@]}"; do
    rlabel="${r%%|*}"; rip="${r#*|}"
    [[ "$rlabel" == "$r" ]] && { rlabel="$r"; rip="$r"; }
    (( first_r )) || printf ','
    first_r=0
    printf '{"name":%s,"ip":%s,"records":{' \
      "$(dp_json_escape "$rlabel")" "$(dp_json_escape "$rip")"
    local first_t=1 rtype answer
    for rtype in "${types_ref[@]}"; do
      (( first_t )) || printf ','
      first_t=0
      printf '%s:[' "$(dp_json_escape "$rtype")"
      local first_a=1 query_output
      query_output="$(dp_query "$backend" "$domain" "$rtype" "$rip" "$timeout" "$tries")" || return 1
      while IFS= read -r answer; do
        [[ -z "$answer" ]] && continue
        (( first_a )) || printf ','
        first_a=0
        printf '%s' "$(dp_json_escape "$answer")"
      done <<<"$query_output"
      printf ']'
    done
    printf '}}'
  done
  printf ']}\n'
}

# ---- Propagation mode -------------------------------------------------------
# For each type, collect answers from every default resolver + system.
# Normalize (sort + join) each set, group resolvers by identical answer, and
# flag disagreement.

dp_run_propagation() {
  local backend="$1" domain="$2" timeout="$3" tries="$4"
  local -n types_ref=$5

  local -a resolvers=("${DP_DEFAULT_RESOLVERS[@]}")

  dp_print_section "Propagation report — $domain"
  local rtype r rlabel rip
  local disagreements=0

  for rtype in "${types_ref[@]}"; do
    printf '\n  %s%s%s\n' "${UK_C_BOLD:-}" "$rtype" "${UK_C_RESET:-}"

    # Collect: fingerprint -> "label1,label2,..."; keep first raw answer set
    # (as multi-line string) per fingerprint for display.
    local -A groups=() displays=()
    local first_fp=''
    for r in "${resolvers[@]}"; do
      rlabel="${r%%|*}"; rip="${r#*|}"
      local raw sorted fp
      raw="$(dp_query "$backend" "$domain" "$rtype" "$rip" "$timeout" "$tries")" || return 1
      # Normalize: sort, strip whitespace on each line, drop blanks.
      sorted="$(printf '%s\n' "$raw" | awk 'NF' | sort -u | paste -sd$'\n' -)"
      fp="$(printf '%s' "$sorted" | md5sum 2>/dev/null | cut -d' ' -f1)"
      [[ -z "$fp" ]] && fp="$(printf '%s' "$sorted" | shasum 2>/dev/null | cut -d' ' -f1)"
      [[ -z "$fp" ]] && fp="$(printf '%s' "$sorted" | wc -c | tr -d ' ')-$(printf '%s' "$sorted" | head -c 40 | tr -c 'A-Za-z0-9._:-' '_')"

      groups[$fp]="${groups[$fp]:+${groups[$fp]},}$rlabel"
      displays[$fp]="$sorted"
      [[ -z "$first_fp" ]] && first_fp="$fp"
    done

    local group_count=${#groups[@]}
    if (( group_count > 1 )); then
      disagreements=$((disagreements + 1))
      printf '  %s%s%s  disagreement across %d resolver groups\n' \
        "${UK_C_YELLOW:-}${UK_I_WARN:-!}" "" "${UK_C_RESET:-}" "$group_count"
    else
      printf '  %s%s%s  consensus across %d resolvers\n' \
        "${UK_C_GREEN:-}${UK_I_OK:-OK}" "" "${UK_C_RESET:-}" "${#resolvers[@]}"
    fi

    local fp
    for fp in "${!groups[@]}"; do
      local labels="${groups[$fp]}"
      local disp="${displays[$fp]}"
      printf '    %s[%s]%s\n' "${UK_C_DIM:-}" "$labels" "${UK_C_RESET:-}"
      if [[ -z "$disp" ]]; then
        printf '      %s(no answer)%s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
      else
        local line
        while IFS= read -r line; do
          [[ -n "$line" ]] && printf '      %s\n' "$line"
        done <<<"$disp"
      fi
    done
  done

  printf '\n'
  dp_hr
  if (( disagreements > 0 )); then
    printf '  %s%s%s propagation issues across %d record type(s)\n\n' \
      "${UK_C_YELLOW:-}${UK_I_WARN:-!}" "" "${UK_C_RESET:-}" "$disagreements"
    return 1
  else
    printf '  %s%s%s full consensus across all record types\n\n' \
      "${UK_C_GREEN:-}${UK_I_OK:-OK}" "" "${UK_C_RESET:-}"
    return 0
  fi
}

# ---- Main -------------------------------------------------------------------

dp_main() {
  uk_banner "dns-probe" "Multi-resolver DNS query & propagation checker" "" "$@"

  local domain=""
  local -a types=()
  local -a user_resolvers=()
  local system=0 propagation=0 timeout=3 tries=2
  local as_json=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --type)         shift
                      IFS=',' read -r -a types <<<"${1:-}"
                      ;;
      --resolver)     shift; user_resolvers+=("${1:-}") ;;
      --system)       system=1 ;;
      --propagation)  propagation=1 ;;
      --timeout)      shift; timeout="${1:-3}" ;;
      --tries)        shift; tries="${1:-2}" ;;
      --json)         as_json=1 ;;
      --no-color)     UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                      UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help)      dp_usage; return 0 ;;
      -*)             uk_error "Unknown option: ${1:-}"; dp_usage; return 2 ;;
      *)              domain="${1:-}" ;;
    esac
    shift || true
  done

  [[ -z "$domain" ]] && { uk_error "Domain required."; dp_usage; return 2; }

  # Validate numeric flags.
  [[ "$timeout" =~ ^[0-9]+$ ]] || { uk_error "Invalid --timeout"; return 2; }
  [[ "$tries"   =~ ^[0-9]+$ ]] || { uk_error "Invalid --tries";   return 2; }

  # Default types.
  if (( ${#types[@]} == 0 )); then
    types=("${DP_DEFAULT_TYPES[@]}")
  else
    # Normalize case; expand ANY.
    local -a expanded=() t
    for t in "${types[@]}"; do
      t="${t^^}"
      if [[ "$t" == "ANY" ]]; then
        expanded+=("${DP_DEFAULT_TYPES[@]}")
      else
        expanded+=("$t")
      fi
    done
    types=("${expanded[@]}")
  fi

  # Pick a backend.
  local backend
  backend="$(dp_pick_backend 2>/dev/null || true)"
  if [[ -z "$backend" ]]; then
    uk_error "No DNS backend found. Install one of: dig (bind-utils), drill (ldns), or host."
    case "$(uk_platform 2>/dev/null || echo unknown)" in
      termux) uk_info "Termux: pkg install dnsutils" ;;
      macos)  uk_info "macOS is expected to ship 'host' and 'dig' by default." ;;
      linux)  uk_info "Linux: apt install dnsutils  |  dnf install bind-utils" ;;
    esac
    return 2
  fi

  # Build resolver list.
  local -a resolvers=()
  if (( ${#user_resolvers[@]} > 0 )); then
    local u
    for u in "${user_resolvers[@]}"; do
      resolvers+=("$u|$u")
    done
    (( system )) && resolvers+=("system|")
  else
    resolvers=("${DP_DEFAULT_RESOLVERS[0]}")   # cloudflare by default
    (( system )) && resolvers+=("system|")
  fi

  if (( propagation )); then
    dp_run_propagation "$backend" "$domain" "$timeout" "$tries" types
    return $?
  fi

  if (( as_json )); then
    dp_run_json "$backend" "$domain" "$timeout" "$tries" types resolvers
    return $?
  fi

  dp_run_standard "$backend" "$domain" "$timeout" "$tries" types resolvers || return 1
  printf '\n'
  dp_hr
  printf '  backend: %s   timeout: %ss   tries: %s\n\n' "$backend" "$timeout" "$tries"
}

dp_wizard() {
  uk_banner "dns-probe" "Multi-resolver DNS query & propagation checker" ""
  local domain types resolver system prop jsonf timeout
  domain="$(uk_prompt 'Domain to query' 'example.com' 'github.com' 'Required.')"
  types="$(uk_prompt 'Record types (comma-separated, or ANY)' 'A,AAAA,MX,TXT,NS,CAA,SOA' \
    'A,MX,TXT' 'ANY expands to the default set.')"
  if uk_confirm 'Propagation mode? (query all public resolvers)' 'N'; then prop=1; else prop=0; fi
  resolver=""
  system=""
  if (( ! prop )); then
    resolver="$(uk_prompt 'Custom resolver IP (blank = cloudflare)' '' '1.1.1.1' 'Repeat via CLI --resolver.')"
    if uk_confirm 'Include system resolver?' 'N'; then system="--system"; fi
  fi
  timeout="$(uk_prompt 'Per-query timeout (seconds)' '3' '5' '')"
  if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi

  local -a a=("$domain" --type "$types" --timeout "$timeout")
  (( prop )) && a+=(--propagation)
  [[ -n "$resolver" ]] && a+=(--resolver "$resolver")
  [[ -n "$system"   ]] && a+=("$system")
  [[ -n "$jsonf"    ]] && a+=("$jsonf")
  dp_main "${a[@]}"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    dp_wizard
  else
    dp_main "$@"
  fi
fi
