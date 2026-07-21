#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

SA_CONFIG="$HOME/.ssh/config"
SA_CONNECT=''
SA_COPY_ID=''
SA_ADD_HOST=''
SA_ADD_REQUESTED=0

sa_usage() {
  cat <<'USAGE'
Usage:
  _ssh_assistant.sh [--connect HOST] [--copy-id HOST] [--add [HOST]] [--config FILE]
USAGE
}

sa_valid_alias() { [[ "${1:-}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]]; }
sa_valid_destination() { [[ "${1:-}" =~ ^([A-Za-z0-9][A-Za-z0-9._-]*@)?[A-Za-z0-9][A-Za-z0-9._:-]*$ ]]; }
sa_valid_user() { [[ "${1:-}" =~ ^[A-Za-z0-9._-]+$ ]]; }
sa_single_line() { [[ "${1:-}" != *$'\n'* && "${1:-}" != *$'\r'* ]]; }

sa_hosts() {
  [[ -f "$SA_CONFIG" ]] || return 0
  awk '/^Host[[:space:]]+/ {for (i=2; i<=NF; i++) if ($i !~ /[*?]/) print $i}' "$SA_CONFIG" | sort -u
}

sa_maybe_explain_host_auth() {
  local host="${1:-}" code="${2:-}"
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
  local host="${1:-}" code=0
  sa_valid_destination "$host" || { uk_error "Invalid SSH destination: $host"; return 1; }
  ssh -- "$host" || code=$?
  sa_maybe_explain_host_auth "$host" "$code"
  return "$code"
}

# ----- Add new host -------------------------------------------------
sa_add_host() {
  local hostname="${1:-}"
  local config_dir
  config_dir="$(dirname "$SA_CONFIG")" || return 1
  mkdir -p "$config_dir" || { uk_error "Unable to create SSH config directory: $config_dir"; return 1; }
  touch "$SA_CONFIG" || { uk_error "Unable to create SSH config: $SA_CONFIG"; return 1; }
  chmod 600 "$SA_CONFIG" || { uk_error "Unable to secure SSH config: $SA_CONFIG"; return 1; }

  # If hostname not provided, prompt for it
  if [[ -z "$hostname" ]]; then
    printf '\n  %sEnter the Host alias (e.g., myserver): %s' "$UK_I_ARROW" "$UK_C_RESET"
    read -r hostname </dev/tty
    [[ -n "$hostname" ]] || {
      uk_warn 'No hostname given. Aborting.'
      return 1
    }
  fi

  sa_valid_alias "$hostname" || { uk_error "Invalid Host alias: $hostname"; return 1; }

  # Check if host already exists using exact token comparison.
  if awk -v h="$hostname" '/^Host[[:space:]]+/ {for (i=2; i<=NF; i++) if ($i==h) found=1} END{exit found?0:1}' "$SA_CONFIG"; then
    uk_warn "Host '$hostname' already exists in $SA_CONFIG."
    if ! uk_confirm 'Do you want to edit/overwrite it?' 'N'; then
      return 0
    fi
    # Remove existing block (naive: remove from line "Host $hostname" to next "Host" or EOF)
    # We'll use sed to delete lines from that Host line until next Host line or end.
    # This is a bit tricky; we'll use awk to remove the block.
    local tmp_file
    tmp_file="$(mktemp)" || { uk_error 'Unable to create SSH config temporary file.'; return 1; }
    if ! awk -v h="$hostname" '
      /^Host[[:space:]]+/ {
        out=""; keep=0
        for (i=2; i<=NF; i++) {
          if ($i==h) continue
          out=out (out=="" ? "Host " : " ") $i
          keep=1
        }
        if (keep) print out
        next
      }
      { print }
    ' "$SA_CONFIG" >"$tmp_file"; then
      rm -f "$tmp_file"
      uk_error "Unable to update SSH config."
      return 1
    fi
    chmod 600 "$tmp_file" || { rm -f "$tmp_file"; uk_error 'Unable to secure SSH config temporary file.'; return 1; }
    mv "$tmp_file" "$SA_CONFIG" || { rm -f "$tmp_file"; uk_error 'Unable to replace SSH config.'; return 1; }
  fi

  # Prompt for details
  printf '\n  %sEnter HostName (IP or domain): %s' "$UK_I_ARROW" "$UK_C_RESET"
  read -r hostname_val </dev/tty || { uk_error 'Unable to read HostName.'; return 1; }
  [[ "$hostname_val" =~ ^[A-Za-z0-9][A-Za-z0-9._:-]*$ ]] || {
    uk_error "Invalid HostName: $hostname_val"
    return 1
  }

  printf '  %sEnter User (default: current user): %s' "$UK_I_ARROW" "$UK_C_RESET"
  read -r user_val </dev/tty || { uk_error 'Unable to read SSH user.'; return 1; }
  [[ -z "$user_val" ]] && user_val="$USER"
  sa_valid_user "$user_val" || { uk_error "Invalid SSH user: $user_val"; return 1; }

  printf '  %sEnter Port (default: 22): %s' "$UK_I_ARROW" "$UK_C_RESET"
  read -r port_val </dev/tty || { uk_error 'Unable to read SSH port.'; return 1; }
  [[ -z "$port_val" ]] && port_val=22
  [[ "$port_val" =~ ^[0-9]+$ ]] && ((port_val >= 1 && port_val <= 65535)) || { uk_error "Invalid SSH port: $port_val"; return 1; }

  printf '  %sEnter IdentityFile path (optional, leave blank to skip): %s' "$UK_I_ARROW" "$UK_C_RESET"
  read -r identity_val </dev/tty || { uk_error 'Unable to read IdentityFile.'; return 1; }
  sa_single_line "$identity_val" || { uk_error 'IdentityFile must be a single line.'; return 1; }

  # Build the block
  if ! {
    printf '\nHost %s\n' "$hostname"
    printf '  HostName %s\n' "$hostname_val"
    printf '  User %s\n' "$user_val"
    printf '  Port %s\n' "$port_val"
    [[ -n "$identity_val" ]] && printf '  IdentityFile %s\n' "$identity_val"
  } >>"$SA_CONFIG"; then
    uk_error "Unable to write SSH config: $SA_CONFIG"
    return 1
  fi
  chmod 600 "$SA_CONFIG" || { uk_error "Unable to secure SSH config: $SA_CONFIG"; return 1; }

  uk_success "Added host '$hostname' to $SA_CONFIG"
}

# ----- Main ---------------------------------------------------------
sa_main() {
  uk_banner "ssh-assistant" "Parse ~/.ssh/config and connect to named hosts" "" "$@"
  SA_CONFIG="$HOME/.ssh/config"
  SA_CONNECT=''
  SA_COPY_ID=''
  SA_ADD_HOST=''
  SA_ADD_REQUESTED=0
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --connect)
      shift
      SA_CONNECT="${1:-}"
      ;;
    --copy-id)
      shift
      SA_COPY_ID="${1:-}"
      ;;
    --add)
      SA_ADD_REQUESTED=1
      if [[ $# -gt 1 && "${2:-}" != --* ]]; then
        shift
        SA_ADD_HOST="${1:-}"
      fi
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
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  sa_single_line "$SA_CONFIG" && [[ -n "$SA_CONFIG" ]] || { uk_error 'SSH config path must be a non-empty single line.'; return 1; }

  # Handle direct actions first
  if [[ -n "$SA_CONNECT" ]]; then
    sa_run_ssh "$SA_CONNECT"
    return $?
  fi
  if [[ -n "$SA_COPY_ID" ]]; then
    uk_has_cmd ssh-copy-id || {
      uk_error 'ssh-copy-id not installed.'
      return 1
    }
    sa_valid_destination "$SA_COPY_ID" || { uk_error "Invalid ssh-copy-id destination: $SA_COPY_ID"; return 1; }
    ssh-copy-id -- "$SA_COPY_ID"
    return $?
  fi
  if ((SA_ADD_REQUESTED == 1)); then
    # --add was given with optional hostname
    sa_add_host "$SA_ADD_HOST"
    return $?
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

  local -a menu_items=()
  local i
  for i in "${!hosts[@]}"; do
    menu_items+=("${hosts[$i]}|ssh ${hosts[$i]}")
  done
  menu_items+=("Add new host|add a new SSH config entry")

  printf '  %sGitHub/GitLab hosts close after auth — that is normal.%s\n' \
    "$UK_C_DIM" "$UK_C_RESET"
  printf '  %sRun with --copy-id user@host to push your public key.%s\n' \
    "$UK_C_DIM" "$UK_C_RESET"

  if uk_menu --prompt "SSH Hosts" "${menu_items[@]}"; then
    if ((UK_MENU_SELECTED == ${#hosts[@]})); then
      sa_add_host ''
    else
      sa_run_ssh "${hosts[$UK_MENU_SELECTED]}"
    fi
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sa_main "$@"
fi
