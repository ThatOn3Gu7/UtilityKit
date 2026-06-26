#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

SA_CONFIG="$HOME/.ssh/config"
SA_CONNECT=''
SA_COPY_ID=''

sa_usage() {
  cat <<'USAGE'
Usage:
  _ssh_assistant.sh [--connect HOST] [--copy-id HOST] [--config FILE]
USAGE
}
sa_hosts() {
  [[ -f "$SA_CONFIG" ]] || return 0
  awk '/^Host[[:space:]]+/ {for (i=2; i<=NF; i++) if ($i !~ /[*?]/) print $i}' "$SA_CONFIG" | sort -u
}
sa_maybe_explain_host_auth() {
  local host="$1" code="$2"
  case "$host" in
  *gitlab* | *github* | *bitbucket*)
    if [[ "$code" -ne 0 ]]; then
      uk_note 'Some Git hosting SSH endpoints intentionally close after a successful auth-only handshake.'
      uk_note 'If you saw a welcome/auth message before the close, that may be expected behavior.'
    fi
    ;;
  esac
}
sa_run_ssh() {
  local host="$1" code=0
  ssh "$host" || code=$?
  sa_maybe_explain_host_auth "$host" "$code"
  return 0
}
sa_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --connect)
      shift
      SA_CONNECT="${1:-}"
      ;;
    --copy-id)
      shift
      SA_COPY_ID="${1:-}"
      ;;
    --config)
      shift
      SA_CONFIG="${1:-}"
      ;;
    -h | --help)
      sa_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: $1"
      return 1
      ;;
    esac
    shift
  done

  if [[ -n "$SA_CONNECT" ]]; then
    sa_run_ssh "$SA_CONNECT"
    return 0
  fi
  if [[ -n "$SA_COPY_ID" ]]; then
    uk_has_cmd ssh-copy-id || {
      uk_error 'ssh-copy-id not installed.'
      return 1
    }
    ssh-copy-id "$SA_COPY_ID"
    return 0
  fi

  uk_header 'UtilityKit SSH Assistant' "Config: $SA_CONFIG"
  mapfile -t hosts < <(sa_hosts)
  if ((${#hosts[@]} == 0)); then
    uk_warn 'No named SSH hosts found in ~/.ssh/config.'
    printf '  %sAdd entries like "Host myserver" to ~/.ssh/config to use this tool.%s\n' \
      "$UK_C_DIM" "$UK_C_RESET"
    return 0
  fi

  printf '  %sNamed hosts found in %s:%s\n\n' "$UK_C_DIM" "$SA_CONFIG" "$UK_C_RESET"
  local i
  for i in "${!hosts[@]}"; do
    printf '  %s%2d)%s %s%s%s  %s(ssh %s)%s\n' \
      "$UK_C_BOLD" "$((i + 1))" "$UK_C_RESET" \
      "$UK_C_CYAN" "${hosts[$i]}" "$UK_C_RESET" \
      "$UK_C_DIM" "${hosts[$i]}" "$UK_C_RESET"
  done
  printf '\n'

  if uk_is_interactive; then
    printf '  %s Enter a host number to connect, or press Enter to quit: %s' \
      "$UK_I_ARROW" "$UK_C_RESET"
    read -r i </dev/tty
    [[ -n "$i" ]] || return 0
    if ! [[ "$i" =~ ^[0-9]+$ ]] || ((i < 1 || i > ${#hosts[@]})); then
      uk_warn "Invalid selection: '$i'. Please enter a number between 1 and ${#hosts[@]}."
      return 1
    fi
    sa_run_ssh "${hosts[$((i - 1))]}"
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sa_main "$@"
fi
