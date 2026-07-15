#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

dv_usage() {
  cat <<'USAGE'
Usage:
  _dotenv_vault.sh --file .env --encrypt KEY [--apply]
  _dotenv_vault.sh --file .env --decrypt [--output FILE]

Encrypts a single KEY=value in a dotenv file using gpg symmetric encryption.
Dry-run by default for --encrypt; use --apply to write the changed file.
USAGE
}
dv_need_crypto() {
  uk_has_cmd gpg || {
    uk_error 'gpg is required. On Termux: pkg install gnupg'
    return 1
  }
  uk_has_cmd base64 || {
    uk_error 'base64 is required but was not found.'
    return 1
  }
}
dv_b64_encode() { base64 | tr -d '\n'; }
dv_b64_decode() { base64 -d 2>/dev/null || base64 -D; }
dv_encrypt_value() {
  local value="${1:-}" tmp out
  tmp=$(mktemp)
  out=$(mktemp)
  printf '%s' "$value" >"$tmp"
  if ! gpg --quiet --symmetric --armor --output "$out" "$tmp"; then
    rm -f "$tmp" "$out"
    uk_error 'gpg encryption failed or was cancelled.'
    return 1
  fi
  dv_b64_encode <"$out"
  rm -f "$tmp" "$out"
}
dv_decrypt_token() {
  local token="${1:-}" tmp rc=0
  tmp=$(mktemp) || return 1
  if ! printf '%s' "$token" | dv_b64_decode >"$tmp"; then
    rm -f "$tmp" || uk_warn "Unable to remove failed decrypt temporary file."
    uk_error 'Invalid encrypted token encoding.'
    return 1
  fi
  gpg --quiet --decrypt "$tmp" || rc=$?
  rm -f "$tmp" || { uk_error 'Unable to remove decrypt temporary file.'; return 1; }
  return "$rc"
}
dv_main() {
  uk_banner "dotenv-vault" "Encrypt .env values to ENC:: tokens with gpg" "" "$@"
  local file='.env' key='' decrypt=0 apply=0 output=''
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --file)
      shift
      file="${1:-.env}"
      ;;
    --encrypt)
      shift
      key="${1:-}"
      ;;
    --decrypt) decrypt=1 ;;
    --output)
      shift
      output="${1:-}"
      ;;
    --apply) apply=1 ;;
    -h | --help)
      dv_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  [[ -f "$file" ]] || {
    uk_error "Missing env file: $file"
    return 1
  }
  dv_need_crypto || return 1

  if ((decrypt == 1)); then
    local tmp line name token value
    tmp=$(mktemp)
    while IFS= read -r line || [[ -n "$line" ]]; do
      # FIX: no quotes in the regex – match KEY=ENC::TOKEN (without quotes)
      if [[ "$line" =~ ^([^=#[:space:]]+)=ENC::(.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        token="${BASH_REMATCH[2]}"
        if value="$(dv_decrypt_token "$token")"; then
          printf '%s=%s\n' "$name" "$value" >>"$tmp"
        else
          rm -f "$tmp"
          uk_error "Failed to decrypt $name"
          return 1
        fi
      else
        printf '%s\n' "$line" >>"$tmp"
      fi
    done <"$file"
    if [[ -n "$output" ]]; then
      mv "$tmp" "$output"
      uk_success "Decrypted dotenv written to $output"
    else
      cat "$tmp"
      rm -f "$tmp"
    fi
    return 0
  fi

  [[ -n "$key" ]] || {
    dv_usage
    return 1
  }
  local tmp found=0 line name value token
  tmp=$(mktemp)
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "$key="* ]]; then
      found=1
      name="${line%%=*}"
      value="${line#*=}"
      if [[ "$value" == ENC::* ]]; then
        uk_warn "$key is already encrypted; leaving it unchanged."
        printf '%s\n' "$line" >>"$tmp"
      else
        uk_note "Encrypting value for $key with gpg. You may be prompted for a passphrase."
        token="$(dv_encrypt_value "$value")" || {
          rm -f "$tmp"
          return 1
        }
        # Write without quotes (consistent with decryption regex)
        printf '%s=ENC::%s\n' "$name" "$token" >>"$tmp"
      fi
    else
      printf '%s\n' "$line" >>"$tmp"
    fi
  done <"$file"

  ((found == 1)) || {
    rm -f "$tmp"
    uk_error "Key not found: $key"
    return 1
  }

  if ((apply == 1)); then
    # Check writability
    if [[ ! -w "$file" ]]; then
      uk_error "File '$file' is not writable."
      rm -f "$tmp"
      return 1
    fi
    local stamp
    stamp="$(date '+%Y%m%d_%H%M%S')"
    cp "$file" "$file.bak.$stamp"
    mv "$tmp" "$file"
    uk_success "Encrypted $key in $file (backup created at $file.bak.$stamp)."
  else
    uk_note 'Dry-run preview. Use --apply to write changes.'
    cat "$tmp"
    rm -f "$tmp"
  fi
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  dv_main "$@"
fi

