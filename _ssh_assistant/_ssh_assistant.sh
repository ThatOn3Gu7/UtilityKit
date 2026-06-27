#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

SA_CONFIG="$HOME/.ssh/config"
SA_CONNECT=''
SA_COPY_ID=''
SA_ADD_HOST=''

sa_usage() {
  cat <<'USAGE'
Usage:
  _ssh_assistant.sh [--connect HOST] [--copy-id HOST] [--add [HOST]] [--config FILE]
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

# ----- Add new host -------------------------------------------------
sa_add_host() {
  local hostname="$1"
  local config_dir
  config_dir="$(dirname "$SA_CONFIG")"
  mkdir -p "$config_dir"
  touch "$SA_CONFIG"

  # If hostname not provided, prompt for it
  if [[ -z "$hostname" ]]; then
    printf '\n  %sEnter the Host alias (e.g., myserver): %s' "$UK_I_ARROW" "$UK_C_RESET"
    read -r hostname </dev/tty
    [[ -n "$hostname" ]] || {
      uk_warn 'No hostname given. Aborting.'
      return 1
    }
  fi

  # Check if host already exists
  if grep -q "^Host[[:space:]]\+$hostname\([[:space:]]\|$\)" "$SA_CONFIG"; then
    uk_warn "Host '$hostname' already exists in $SA_CONFIG."
    if ! uk_confirm 'Do you want to edit/overwrite it?' 'N'; then
      return 0
    fi
    # Remove existing block (naive: remove from line "Host $hostname" to next "Host" or EOF)
    # We'll use sed to delete lines from that Host line until next Host line or end.
    # This is a bit tricky; we'll use awk to remove the block.
    local tmp_file
    tmp_file="$(mktemp)"
    awk -v h="$hostname" '
      BEGIN { skip=0 }
      /^Host[[:space:]]+/ {
        # Check if this Host line contains our hostname as a separate word
        if ($0 ~ "Host[[:space:]]+" h "([[:space:]]|$)") {
          skip=1
          next
        }
      }
      skip && /^Host[[:space:]]+/ { skip=0 }
      !skip { print }
    ' "$SA_CONFIG" >"$tmp_file"
    mv "$tmp_file" "$SA_CONFIG"
  fi

  # Prompt for details
  printf '\n  %sEnter HostName (IP or domain): %s' "$UK_I_ARROW" "$UK_C_RESET"
  read -r hostname_val </dev/tty
  [[ -n "$hostname_val" ]] || {
    uk_warn 'HostName required.'
    return 1
  }

  printf '  %sEnter User (default: current user): %s' "$UK_I_ARROW" "$UK_C_RESET"
  read -r user_val </dev/tty
  [[ -z "$user_val" ]] && user_val="$USER"

  printf '  %sEnter Port (default: 22): %s' "$UK_I_ARROW" "$UK_C_RESET"
  read -r port_val </dev/tty
  [[ -z "$port_val" ]] && port_val=22

  printf '  %sEnter IdentityFile path (optional, leave blank to skip): %s' "$UK_I_ARROW" "$UK_C_RESET"
  read -r identity_val </dev/tty

  # Build the block
  {
    echo ""
    echo "Host $hostname"
    echo "  HostName $hostname_val"
    echo "  User $user_val"
    echo "  Port $port_val"
    [[ -n "$identity_val" ]] && echo "  IdentityFile $identity_val"
  } >>"$SA_CONFIG"

  uk_success "Added host '$hostname' to $SA_CONFIG"
}

# ----- Main ---------------------------------------------------------
sa_main() {
  uk_banner "ssh-assistant" "Parse ~/.ssh/config and connect to named hosts" "" "$@"
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
    --add)
      shift
      SA_ADD_HOST="${1:-}" # may be empty
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

  # Handle direct actions first
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
  if [[ -n "$SA_ADD_HOST" ]] || [[ "$SA_ADD_HOST" == "" && "${1:-}" == "--add" ]]; then
    # --add was given with optional hostname
    sa_add_host "$SA_ADD_HOST"
    return 0
  fi

  # Interactive mode
  uk_section_title "Config: $SA_CONFIG"

  mapfile -t hosts < <(sa_hosts)

  if ((${#hosts[@]} == 0)); then
    uk_warn 'No named SSH hosts found in ~/.ssh/config.'
    printf '  %sAdd Host entries to %s to use this tool.%s\n' \
      "$UK_C_DIM" "$SA_CONFIG" "$UK_C_RESET"
    printf '\n  %sExample:%s\n' "$UK_C_BOLD" "$UK_C_RESET"
    printf '  %sHost myserver%s\n' "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s  HostName 192.168.1.10%s\n' "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s  User deploy%s\n\n' "$UK_C_DIM" "$UK_C_RESET"
    if uk_confirm 'Would you like to add a new host now?' 'Y'; then
      sa_add_host ''
    fi
    return 0
  fi

  # ── Host list ────────────────────────────────────────────────────
  printf '\n  %s%s Named hosts in %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_BRIGHT_CYAN" "$SA_CONFIG" "$UK_C_RESET" ""
  printf '  %s%s%s\n\n' "$UK_C_DIM" "$(printf '%*s' 52 '' | tr ' ' '-')" "$UK_C_RESET"

  local i
  for i in "${!hosts[@]}"; do
    printf '  %s%2d)%s  %s%-22s%s %s→  ssh %s%s\n' \
      "$UK_C_BOLD" "$((i + 1))" "$UK_C_RESET" \
      "$UK_C_CYAN" "${hosts[$i]}" "$UK_C_RESET" \
      "$UK_C_DIM" "${hosts[$i]}" "$UK_C_RESET"
  done

  # Add an extra option for adding a new host
  local add_option_num=$((${#hosts[@]} + 1))
  printf '  %s%2d)%s  %s%-22s%s %s→  %sAdd new host%s\n' \
    "$UK_C_BOLD" "$add_option_num" "$UK_C_RESET" \
    "$UK_C_GREEN" "Add new host" "$UK_C_RESET" \
    "$UK_C_DIM" "$UK_C_RESET" ""

  # ── Info notes ───────────────────────────────────────────────────
  printf '\n  %s%s Tip:%s Select a number to open an SSH session in this terminal.%s\n' \
    "$UK_C_DIM" "$UK_I_INFO" "$UK_C_RESET" "$UK_C_RESET"
  printf '  %s%s Note:%s GitHub · GitLab · Bitbucket hosts close immediately after auth — that is normal.%s\n' \
    "$UK_C_DIM" "$UK_I_WARN" "$UK_C_RESET" "$UK_C_RESET"
  printf '  %s%s Copy-ID:%s Run with %s--copy-id user@host%s to push your public key.%s\n\n' \
    "$UK_C_DIM" "$UK_I_INFO" "$UK_C_RESET" \
    "$UK_C_CYAN" "$UK_C_RESET" "$UK_C_RESET"

  if uk_is_interactive; then
    printf '  %s Enter host number (or press Enter to quit): %s' \
      "$UK_I_ARROW" "$UK_C_RESET"
    read -r i </dev/tty
    [[ -n "$i" ]] || return 0
    if ! [[ "$i" =~ ^[0-9]+$ ]] || ((i < 1 || i > add_option_num)); then
      uk_warn "Invalid selection: '$i'. Enter a number between 1 and $add_option_num."
      return 1
    fi
    if ((i == add_option_num)); then
      sa_add_host ''
    else
      sa_run_ssh "${hosts[$((i - 1))]}"
    fi
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sa_main "$@"
fi
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
  uk_banner "ssh-assistant" "Parse ~/.ssh/config and connect to named hosts" "" "$@"
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

  uk_section_title "Config: $SA_CONFIG"

  mapfile -t hosts < <(sa_hosts)

  if ((${#hosts[@]} == 0)); then
    uk_warn 'No named SSH hosts found in ~/.ssh/config.'
    printf '  %sAdd Host entries to %s to use this tool.%s\n' \
      "$UK_C_DIM" "$SA_CONFIG" "$UK_C_RESET"
    printf '\n  %sExample:%s\n' "$UK_C_BOLD" "$UK_C_RESET"
    printf '  %sHost myserver%s\n' "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s  HostName 192.168.1.10%s\n' "$UK_C_DIM" "$UK_C_RESET"
    printf '  %s  User deploy%s\n\n' "$UK_C_DIM" "$UK_C_RESET"
    return 0
  fi

  # ── Host list ────────────────────────────────────────────────────
  printf '\n  %s%s Named hosts in %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_BRIGHT_CYAN" "$SA_CONFIG" "$UK_C_RESET" ""
  printf '  %s%s%s\n\n' "$UK_C_DIM" "$(printf '%*s' 52 '' | tr ' ' '-')" "$UK_C_RESET"

  local i
  for i in "${!hosts[@]}"; do
    printf '  %s%2d)%s  %s%-22s%s %s→  ssh %s%s\n' \
      "$UK_C_BOLD" "$((i + 1))" "$UK_C_RESET" \
      "$UK_C_CYAN" "${hosts[$i]}" "$UK_C_RESET" \
      "$UK_C_DIM" "${hosts[$i]}" "$UK_C_RESET"
  done

  # ── Info notes ───────────────────────────────────────────────────
  printf '\n  %s%s Tip:%s Select a number to open an SSH session in this terminal.%s\n' \
    "$UK_C_DIM" "$UK_I_INFO" "$UK_C_RESET" "$UK_C_RESET"
  printf '  %s%s Note:%s GitHub · GitLab · Bitbucket hosts close immediately after auth — that is normal.%s\n' \
    "$UK_C_DIM" "$UK_I_WARN" "$UK_C_RESET" "$UK_C_RESET"
  printf '  %s%s Copy-ID:%s Run with %s--copy-id user@host%s to push your public key.%s\n\n' \
    "$UK_C_DIM" "$UK_I_INFO" "$UK_C_RESET" \
    "$UK_C_CYAN" "$UK_C_RESET" "$UK_C_RESET"

  if uk_is_interactive; then
    printf '  %s Enter host number (or press Enter to quit): %s' \
      "$UK_I_ARROW" "$UK_C_RESET"
    read -r i </dev/tty
    [[ -n "$i" ]] || return 0
    if ! [[ "$i" =~ ^[0-9]+$ ]] || ((i < 1 || i > ${#hosts[@]})); then
      uk_warn "Invalid selection: '$i'. Enter a number between 1 and ${#hosts[@]}."
      return 1
    fi
    sa_run_ssh "${hosts[$((i - 1))]}"
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sa_main "$@"
fi
