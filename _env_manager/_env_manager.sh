#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely source external library
if [[ -f "$SCRIPT_DIR/../lib/uk_common.sh" ]]; then
  # shellcheck source=../lib/uk_common.sh
  source "$SCRIPT_DIR/../lib/uk_common.sh"
fi

EM_DIR='.'
EM_PROFILE=''
EM_APPLY=0
EM_COMPARE=0
EM_VALIDATE=''
EM_ENCRYPT=''
EM_DECRYPT=''
EM_ACTIVE='.env'
EM_EXAMPLE='.env.example'

# --- Fallback Functions & Variables ---
UK_C_BOLD=${UK_C_BOLD:-}
UK_C_CYAN=${UK_C_CYAN:-}
UK_C_RESET=${UK_C_RESET:-}
UK_C_DIM=${UK_C_DIM:-}
UK_I_ARROW=${UK_I_ARROW:-'>'}

if ! declare -f uk_error >/dev/null 2>&1; then uk_error() { printf "Error: %s\n" "$*"; }; fi
if ! declare -f uk_warn >/dev/null 2>&1; then uk_warn() { printf "Warning: %s\n" "$*"; }; fi
if ! declare -f uk_note >/dev/null 2>&1; then uk_note() { printf "Note: %s\n" "$*"; }; fi
if ! declare -f uk_success >/dev/null 2>&1; then uk_success() { printf "Success: %s\n" "$*"; }; fi
if ! declare -f uk_header >/dev/null 2>&1; then uk_header() { printf "\n=== %s ===\n%s\n" "${1:-}" "${2:-}"; }; fi
if ! declare -f uk_prompt >/dev/null 2>&1; then
  uk_prompt() {
    printf "%s\n%s\n[Default: %s] > " "${1:-}" "${4:-}" "${2:-}" >&2
    local ans
    read -r ans </dev/tty
    echo "${ans:-${2:-}}"
  }
fi
em_usage() {
  cat <<USAGE
Usage:
  _env_manager.sh [OPTIONS]

Options:
  --dir DIR           Project directory containing .env profiles.
  --profile NAME      Profile name to inspect/swap (e.g. local, staging, production).
  --apply             Copy .env.<profile> to .env.
  --compare           Compare active .env against .env.example.
  --validate [FILE]   Validate syntax of FILE (default: .env in --dir).
  --encrypt FILE      Encrypt a file using gpg -c or openssl.
  --decrypt FILE      Decrypt a .gpg/.enc file.
  --active FILE       Active env file name (default: .env).
  --example FILE      Example env file name (default: .env.example).
  -h, --help          Show this help.
USAGE
}
em_keys() {
  local file="${1:-}"
  [[ -f "$file" ]] || return 0
  grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$file" | sed 's/=.*$//' | sort -u
}
em_validate_file() {
  local file="${1:-}" invalid=0 line_no=0 line
  [[ -f "$file" ]] || {
    uk_error "Missing file: $file"
    return 1
  }
  uk_section_title "Env syntax validation: $file"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))

    # Skip entirely empty lines, lines with only whitespace, and comments
    if [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    if [[ ! "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=.*$ ]]; then
      uk_warn "Invalid line $line_no: $line"
      invalid=$((invalid + 1))
    fi
  done <"$file"

  if ((invalid == 0)); then
    uk_success "No syntax issues detected."
  else
    uk_error "Found $invalid invalid line(s)."
    return 1
  fi
}
em_compare_files() {
  local active="${1:-}" example="${2:-}"
  [[ -f "$active" ]] || { uk_error "Missing active env file: $active"; return 1; }
  [[ -f "$example" ]] || { uk_error "Missing example env file: $example"; return 1; }

  local tmp1 tmp2
  tmp1=$(mktemp) || return 1
  tmp2=$(mktemp) || { rm -f "$tmp1"; return 1; }

  em_keys "$active" >"$tmp1"
  em_keys "$example" >"$tmp2"

  uk_section_title "Key comparison: active=$active example=$example"
  uk_note "Missing from active .env:"
  comm -13 "$tmp1" "$tmp2" | sed 's/^/  - /' || true

  uk_note "Extra keys in active .env:"
  comm -23 "$tmp1" "$tmp2" | sed 's/^/  - /' || true
  rm -f "$tmp1" "$tmp2"
}

em_list_profiles() {
  local dir="${1:-}"
  find "$dir" -maxdepth 1 -type f -name '.env.*' ! -name '*.enc' ! -name '*.gpg' ! -name '.env.example' -exec basename {} \; 2>/dev/null | sed 's/^\.env\.//' | sort
}
em_swap_profile() {
  local profile="${1:-}"
  local src="$EM_DIR/.env.$profile"
  local dst="$EM_DIR/$EM_ACTIVE"

  [[ -f "$src" ]] || {
    uk_error "Profile not found: $src"
    return 1
  }
  uk_section_title "Profile switch: $src -> $dst"

  if ((EM_APPLY == 1)); then
    cp "$src" "$dst"
    uk_success "Activated profile '$profile'."
  else
    uk_note "Dry-run only. Re-run with --apply to activate profile '$profile'."
  fi
}
em_encrypt_file() {
  local file="${1:-}"
  [[ -f "$file" ]] || {
    uk_error "Missing file: $file"
    return 1
  }

  if command -v gpg >/dev/null 2>&1; then
    gpg -c --output "$file.gpg" "$file"
    uk_success "Encrypted to $file.gpg"
  elif command -v openssl >/dev/null 2>&1; then
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$file" -out "$file.enc"
    uk_success "Encrypted to $file.enc"
  else
    uk_error "Neither gpg nor openssl is available."
    return 1
  fi
}
em_decrypt_file() {
  local file="${1:-}"
  [[ -f "$file" ]] || {
    uk_error "Missing file: $file"
    return 1
  }
  case "$file" in
  *.gpg)
    command -v gpg >/dev/null 2>&1 || {
      uk_error "gpg is required to decrypt $file"
      return 1
    }
    gpg -d "$file"
    ;;
  *.enc)
    command -v openssl >/dev/null 2>&1 || {
      uk_error "openssl is required to decrypt $file"
      return 1
    }
    openssl enc -d -aes-256-cbc -pbkdf2 -in "$file"
    ;;
  *)
    uk_error "Expected a .gpg or .enc file."
    return 1
    ;;
  esac
}
em_interactive() {
  local profiles profile

  profiles="$(em_list_profiles "$EM_DIR" || true)"
  uk_note "Scanning profiles in: $EM_DIR"

  if [[ -n "$profiles" ]]; then
    printf '%s\n' "$profiles" | sed 's/^/  - /'
  else
    printf '  %s(no .env.<profile> files found in this directory)%s\n' "$UK_C_DIM" "$UK_C_RESET"
  fi

  printf '\n'
  printf '  %s1)%s Compare %s.env%s against %s.env.example%s  %s(find missing or extra keys)%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$UK_C_RESET" "$UK_C_CYAN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '  %s2)%s Validate syntax of %s.env%s             %s(check for malformed key=value lines)%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '  %s3)%s Activate a profile                    %s(copy .env.<name> to .env)%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '  %s4)%s Encrypt a secret file                 %s(uses gpg or openssl)%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '  %s5)%s Decrypt a .gpg or .enc file           %s(output printed to terminal)%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '\n'

  printf ' %s Choose an action [1-5]: ' "$UK_I_ARROW"
  read -r choice </dev/tty

  case "$choice" in
  1) em_compare_files "$EM_DIR/$EM_ACTIVE" "$EM_DIR/$EM_EXAMPLE" ;;
  2) em_validate_file "$EM_DIR/$EM_ACTIVE" ;;
  3)
    profile="$(uk_prompt \
      'Enter profile name to activate (without the .env. prefix)' \
      '' \
      'local   →  loads .env.local | staging  →  loads .env.staging' \
      'The selected profile file will be copied over your active .env.')"
    EM_APPLY=1
    em_swap_profile "$profile"
    ;;
  4)
    profile="$(uk_prompt \
      'Enter path of the file to encrypt' \
      "$EM_DIR/.env" \
      "$EM_DIR/.env.production" \
      'gpg is used if available, otherwise openssl aes-256-cbc. Output gets a .gpg or .enc suffix.')"
    em_encrypt_file "$profile"
    ;;
  5)
    profile="$(uk_prompt \
      'Enter path of the .gpg or .enc file to decrypt' \
      '' \
      "$EM_DIR/.env.production.gpg" \
      'The decrypted content is printed to stdout. Pipe it or redirect as needed.')"
    em_decrypt_file "$profile"
    ;;
  *) uk_warn 'No action selected.' ;;
  esac
}
em_main() {
  uk_banner "env-manager" ".env profile switching, validation, and encryption" "" "$@"
  EM_DIR='.'
  EM_PROFILE=''
  EM_APPLY=0
  EM_COMPARE=0
  EM_VALIDATE=''
  EM_ENCRYPT=''
  EM_DECRYPT=''
  EM_ACTIVE='.env'
  EM_EXAMPLE='.env.example'
  local positional=()

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --dir)
      shift
      EM_DIR="${1:-}"
      ;;
    --profile)
      shift
      EM_PROFILE="${1:-}"
      ;;
    --apply) EM_APPLY=1 ;;
    --compare) EM_COMPARE=1 ;;
    --validate)
      if [[ ${2:-} == --* || $# -eq 1 ]]; then
        EM_VALIDATE='DEFAULT'
      else
        shift
        EM_VALIDATE="${1:-}"
      fi
      ;;
    --encrypt)
      shift
      EM_ENCRYPT="${1:-}"
      ;;
    --decrypt)
      shift
      EM_DECRYPT="${1:-}"
      ;;
    --active)
      shift
      EM_ACTIVE="${1:-}"
      ;;
    --example)
      shift
      EM_EXAMPLE="${1:-}"
      ;;
    -h | --help)
      em_usage
      return 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        positional+=("${1:-}")
        shift
      done
      break
      ;;
    *) positional+=("${1:-}") ;;
    esac
    shift || true
  done

  [[ -n "$EM_ENCRYPT" ]] && {
    em_encrypt_file "$EM_ENCRYPT"
    return $?
  }
  [[ -n "$EM_DECRYPT" ]] && {
    em_decrypt_file "$EM_DECRYPT"
    return $?
  }
  [[ -n "$EM_PROFILE" ]] && {
    em_swap_profile "$EM_PROFILE"
    return $?
  }
  if ((EM_COMPARE == 1)); then
    em_compare_files "$EM_DIR/$EM_ACTIVE" "$EM_DIR/$EM_EXAMPLE" || return $?
  fi

  if [[ -n "$EM_VALIDATE" ]]; then
    if [[ "$EM_VALIDATE" == 'DEFAULT' ]]; then
      em_validate_file "$EM_DIR/$EM_ACTIVE"
    else
      em_validate_file "$EM_VALIDATE"
    fi
    return 0
  fi

  if ((EM_COMPARE == 1)); then
    return 0
  fi

  em_interactive
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  em_main "$@"
fi
