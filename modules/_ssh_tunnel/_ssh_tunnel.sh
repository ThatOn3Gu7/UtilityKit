#!/usr/bin/env bash
# _ssh_tunnel — create, list, kill, restart SSH port-forwards.
# Prefix: st_
# Config: ${XDG_CONFIG_HOME:-~/.config}/utilitykit/tunnels.conf

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

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
    [[ -r /dev/tty ]] && read -r reply </dev/tty || read -r reply; printf '%s\n' "${reply:-$default}"
  }
fi
if ! declare -f uk_confirm  >/dev/null 2>&1; then
  uk_confirm() {
    local reply=''; printf '> %s [y/N]: ' "${1:-Confirm?}" >&2
    [[ -r /dev/tty ]] && read -r reply </dev/tty || read -r reply; [[ "$reply" =~ ^[Yy] ]]
  }
fi
# --------------------------

ST_CONFIG=""

st_usage() {
  cat <<'USAGE'
Usage: _ssh_tunnel.sh <create|list|kill|restart> [OPTIONS]

create HOST:PORT  Create tunnel (local forward). Options: --local LPORT, --user U, --key F, --autossh, --name N
list              List saved tunnels with status.
kill ID|NAME      Kill tunnel by index or name.
restart ID|NAME   Restart tunnel.

--json     Machine-readable list output.
--no-color Disable ANSI.
-h, --help Show this help.
USAGE
}

st_cfg() {
  local d="${XDG_CONFIG_HOME:-$HOME/.config}/utilitykit"
  mkdir -p "$d" || { uk_error "Unable to create tunnel config directory: $d"; return 1; }
  ST_CONFIG="$d/tunnels.conf"
  [[ -f "$ST_CONFIG" ]] || (umask 077; : >"$ST_CONFIG") || return 1
  chmod 600 "$ST_CONFIG" || { uk_error "Unable to secure tunnel config: $ST_CONFIG"; return 1; }
}
st_valid_name() { [[ "${1:-}" =~ ^[A-Za-z0-9._-]+$ ]]; }
st_valid_field() { [[ "${1:-}" != *'|'* && "${1:-}" != *$'\n'* && "${1:-}" != *$'\r'* ]]; }
st_pid_matches() {
  local pid="$1" lp="$2" rh="$3" rp="$4" args
  [[ "$pid" =~ ^[1-9][0-9]*$ ]] || return 1
  args="$(ps -p "$pid" -o args= 2>&1)" || return 1
  [[ "$args" == *ssh* && "$args" == *"-L ${lp}:${rh}:${rp}"* ]]
}
st_port_in_use() {
  local port="${1:-}"
  if uk_has_cmd lsof; then lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && return 0; fi
  if uk_has_cmd ss; then ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]${port}$" && return 0; fi
  return 1
}

st_create() {
  local remote="$1" lp="$2" user="$3" key="$4" autossh="$5" name="$6"
  uk_has_cmd ssh || { uk_error "ssh not found"; return 2; }
  local rh="${remote%:*}" rp="${remote#*:}"
  [[ "$rh" == "$rp" ]] && rp="$lp"
  [[ -z "$lp" ]] && lp="$rp"
  [[ -z "$name" ]] && name="${rh}-${lp}"
  st_valid_name "$name" || { uk_error "Tunnel name must contain only letters, numbers, dot, underscore, dash: $name"; return 2; }
  [[ "$rh" =~ ^[A-Za-z0-9][A-Za-z0-9._:-]*$ ]] || { uk_error "Invalid remote host: $rh"; return 2; }
  [[ -z "$user" || "$user" =~ ^[A-Za-z0-9._-]+$ ]] || { uk_error "Invalid SSH user: $user"; return 2; }
  st_valid_field "$key" || { uk_error "Invalid key path."; return 2; }
  [[ "$lp" =~ ^[0-9]+$ && "$rp" =~ ^[0-9]+$ ]] || { uk_error "Ports must be numeric."; return 2; }
  (( lp >= 1 && lp <= 65535 && rp >= 1 && rp <= 65535 )) || { uk_error "Ports must be in 1..65535."; return 2; }
  st_port_in_use "$lp" && { uk_error "Local port already appears to be in use: $lp"; return 1; }
  local ssh_cmd="ssh"
  local -a args=(-N -L "${lp}:${rh}:${rp}")
  [[ -n "$user" ]] && args+=("-l" "$user")
  [[ -n "$key" ]] && args+=("-i" "$key")
  args+=("-o" "ServerAliveInterval=30" "-o" "ServerAliveCountMax=3")
  (( autossh )) && uk_has_cmd autossh && ssh_cmd="autossh" && args=("-M" "0" "${args[@]}")
  local error_log pid rc=0
  error_log="$(mktemp)" || return 1
  $ssh_cmd "${args[@]}" "$rh" >/dev/null 2>"$error_log" &
  pid=$!
  sleep 0.4 || { kill "$pid" 2>/dev/null || true; rm -f "$error_log"; return 1; }
  if ! kill -0 "$pid" 2>/dev/null; then
    wait "$pid" || rc=$?
    [[ -s "$error_log" ]] && cat "$error_log" >&2
    rm -f "$error_log"
    uk_error "Tunnel failed to start (exit $rc)."
    return 1
  fi
  rm -f "$error_log" || return 1
  disown "$pid" 2>/dev/null || uk_note "Tunnel process remains managed by the current shell."
  printf '%s|%s|%s|%s|%s|%s|%s|%s\n' "$name" "$lp" "$rh" "$rp" "$user" "$key" "$autossh" "$pid" >>"$ST_CONFIG" || return 1
  uk_success "Tunnel '$name' (PID $pid): :$lp → $rh:$rp"
}

st_list() {
  st_cfg; [[ ! -f "$ST_CONFIG" ]] && { [[ "$1" != "1" ]] && uk_note "No tunnels."; return 0; }
  local -a names=() lps=() rhs=() rps=() users=() keys=() autosshs=() pids=()
  while IFS='|' read -r n lp rh rp u k a p; do
    [[ -z "$n" ]] && continue; names+=("$n"); lps+=("$lp"); rhs+=("$rh"); rps+=("$rp")
    users+=("$u"); keys+=("$k"); autosshs+=("$a"); pids+=("$p")
  done <"$ST_CONFIG"
  if (( $1 )); then
    printf '['; local i=0
    for ((i=0; i<${#names[@]}; i++)); do
      (( i > 0 )) && printf ','; local rn=0; st_pid_matches "${pids[$i]}" "${lps[$i]}" "${rhs[$i]}" "${rps[$i]}" && rn=1
      printf '{"name":"%s","local":"%s","remote":"%s:%s","pid":"%s","running":%d}' "${names[$i]}" "${lps[$i]}" "${rhs[$i]}" "${rps[$i]}" "${pids[$i]}" "$rn"
    done; printf ']\n'
  else
    printf '\n  %sTunnels%s\n' "${UK_C_BOLD:-}" "${UK_C_RESET:-}"
    for ((i=0; i<${#names[@]}; i++)); do
      local s; if st_pid_matches "${pids[$i]}" "${lps[$i]}" "${rhs[$i]}" "${rps[$i]}"; then s="${UK_C_GREEN:-}RUN${UK_C_RESET:-}"; else s="${UK_C_RED:-}STOP${UK_C_RESET:-}"; fi
      printf '  %s%3d%s %s %s :%s → %s:%s (PID %s)\n' "${UK_C_BRIGHT_CYAN:-}" "$((i+1))" "${UK_C_RESET:-}" "$s" "${names[$i]}" "${lps[$i]}" "${rhs[$i]}" "${rps[$i]}" "${pids[$i]}"
    done
  fi
}

st_kill() {
  local id="$1"; st_cfg || return 1
  local line
  if [[ "$id" =~ ^[0-9]+$ ]]; then line="$(sed -n "${id}p" "$ST_CONFIG")" || return 1
  else line="$(awk -F'|' -v n="$id" '$1==n{print; exit}' "$ST_CONFIG")" || return 1; fi
  [[ -z "$line" ]] && { uk_error "No tunnel: $id"; return 1; }
  local name lp rh rp user key autossh pid
  IFS='|' read -r name lp rh rp user key autossh pid <<<"$line"
  if kill -0 "$pid" 2>/dev/null; then
    # Process is alive: only signal it after confirming it is our tunnel.
    st_pid_matches "$pid" "$lp" "$rh" "$rp" || { uk_error "Refusing to signal stale or unrelated PID $pid for tunnel '$name'."; return 1; }
    kill "$pid" || { uk_error "Could not kill PID $pid"; return 1; }
    local n=0
    while kill -0 "$pid" 2>/dev/null; do
      n=$((n+1)); ((n < 20)) || { uk_error "PID $pid did not exit."; return 1; }; sleep 0.1
    done
  fi
  # Config removal proceeds whether the process was alive or already gone,
  # so a stopped tunnel can still be killed or restarted.
  local tmp; tmp="$(mktemp)" || return 1
  awk -F'|' -v n="$name" '$1 != n' "$ST_CONFIG" >"$tmp" || { rm -f "$tmp"; return 1; }
  chmod 600 "$tmp" || { rm -f "$tmp"; return 1; }
  mv "$tmp" "$ST_CONFIG" || { rm -f "$tmp"; return 1; }
  uk_success "Killed tunnel '$name'"
}

st_restart() {
  local id="$1"; st_cfg
  local line; [[ "$id" =~ ^[0-9]+$ ]] && line="$(sed -n "${id}p" "$ST_CONFIG" 2>/dev/null)" || line="$(grep -F "${id}|" "$ST_CONFIG" 2>/dev/null | awk -F'|' -v n="$id" '$1==n{print; exit}')"
  [[ -z "$line" ]] && { uk_error "No tunnel: $id"; return 1; }
  IFS='|' read -r n lp rh rp u k a p <<<"$line"
  st_kill "$id" || return 1
  sleep 1 || return 1
  st_create "${rh}:${rp}" "$lp" "$u" "$k" "$a" "$n"
}

st_main() {
  uk_banner "ssh-tunnel" "Manage SSH port-forwards" "" "$@"
  local sub="" remote="" lp="" user="" key="" name="" as_json=0 autossh=0; st_cfg
  [[ $# -gt 0 ]] && { case "${1:-}" in create|list|kill|restart) sub="$1"; shift;; -h|--help) st_usage; return 0;; esac; }
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --local) shift; lp="${1:-}" ;; --user) shift; user="${1:-}" ;; --key) shift; key="${1:-}" ;;
      --autossh) autossh=1 ;; --name) shift; name="${1:-}" ;; --json) as_json=1 ;;
      --no-color) UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN='' UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help) st_usage; return 0 ;; -*) uk_error "Unknown: ${1:-}"; st_usage; return 2 ;;
      *) [[ -z "$remote" ]] && remote="$1" || remote="$1" ;;
    esac; shift || true
  done
  case "$sub" in
    create) [[ -z "$remote" ]] && { uk_error "create HOST:PORT required"; return 2; }
      local h="${remote%:*}"; [[ -z "$lp" ]] && lp="${remote#*:}"; [[ -z "$name" ]] && name="${h}-${lp}"
      st_create "$remote" "$lp" "$user" "$key" "$autossh" "$name" ;;
    list) st_list "$as_json" ;;
    kill|restart) [[ -z "${remote:-}" ]] && { uk_error "$sub requires ID or name"; return 2; }; "st_$sub" "$remote" ;;
    *) st_list "$as_json" ;;
  esac
}

st_wizard() {
  uk_banner "ssh-tunnel" "Manage SSH port-forwards" ""
  local a; a="$(uk_prompt 'Action: create, list, kill, restart' 'list' '' '')"
  case "$a" in
    create)
      local r lp u n
      r="$(uk_prompt 'Remote host:port' 'server.com:3000' 'db.internal:5432' '')"
      lp="$(uk_prompt 'Local port' "${r##*:}" '8080' '')"
      u="$(uk_prompt 'SSH user (optional)' '' 'deploy' '')"
      n="$(uk_prompt 'Name' "${r%:*}-${lp}" 'my-tunnel' '')"
      local -a aa=(create "$r" --local "$lp" --name "$n")
      [[ -n "$u" ]] && aa+=(--user "$u")
      uk_confirm 'Use autossh?' 'N' && aa+=(--autossh)
      st_main "${aa[@]}" ;;
    list) st_main list ${1:+--json} ;;
    kill) st_main list; local n; n="$(uk_prompt 'Name or index' '1' '' '')"; st_main kill "$n" ;;
    restart) st_main list; local n; n="$(uk_prompt 'Name or index' '1' '' '')"; st_main restart "$n" ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then set -euo pipefail; if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then st_wizard; else st_main "$@"; fi; fi
