#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

PG_MODE='passphrase'
PG_WORDS=4
PG_LENGTH=20
PG_COPY=0
PG_SEPARATOR='-'
PG_WORDLIST=(amber anchor aurora bamboo beacon cedar comet copper cosmos delta ember falcon fern glacier harbor ivy lantern marble meadow meteor neon orchard pebble phoenix pine prism quartz river shadow signal solar sparrow summit thunder velvet willow zenith)

pg_usage() {
  cat <<'USAGE'
Usage:
  _password_gen.sh [--mode passphrase|string] [--words N] [--length N] [--copy]
USAGE
}
pg_entropy_words() {
  awk -v n="${1:-}" -v k="${2:-}" 'BEGIN { printf "%.2f", n*(log(k)/log(2)) }'
}
pg_entropy_string() {
  awk -v n="${1:-}" 'BEGIN { printf "%.2f", n*(log(72)/log(2)) }'
}
pg_random_index() {
  local count="${1:-}" value limit
  [[ "$count" =~ ^[1-9][0-9]*$ && "$count" -le 256 ]] || return 1
  [[ -r /dev/urandom ]] || { uk_error '/dev/urandom is required for secure generation.'; return 1; }
  limit=$((256 - (256 % count)))
  while :; do
    value="$(od -An -N1 -tu1 /dev/urandom)" || return 1
    value="${value//[[:space:]]/}"
    [[ "$value" =~ ^[0-9]+$ ]] || return 1
    ((value < limit)) && { printf '%s\n' "$((value % count))"; return 0; }
  done
}
pg_passphrase() {
  local out='' idx i count=${#PG_WORDLIST[@]}
  for ((i = 0; i < PG_WORDS; i++)); do
    idx="$(pg_random_index "$count")" || return 1
    out+="${PG_WORDLIST[$idx]}"
    ((i + 1 < PG_WORDS)) && out+="$PG_SEPARATOR"
  done
  printf '%s\n' "$out"
}
pg_string() {
  local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+=-'
  local out='' idx
  while ((${#out} < PG_LENGTH)); do
    idx="$(pg_random_index "${#alphabet}")" || return 1
    out+="${alphabet:$idx:1}"
  done
  printf '%s\n' "$out"
}
pg_main() {
  uk_banner "password-gen" "XKCD-style passphrases or random strings with entropy" "" "$@"
  PG_MODE='passphrase'
  PG_WORDS=4
  PG_LENGTH=20
  PG_COPY=0
  PG_SEPARATOR='-'
  local seen_args=0
  while [[ $# -gt 0 ]]; do
    seen_args=1
    case "${1:-}" in
    --mode)
      shift
      PG_MODE="${1:-passphrase}"
      ;;
    --words)
      shift
      PG_WORDS="${1:-4}"
      ;;
    --length)
      shift
      PG_LENGTH="${1:-20}"
      ;;
    --separator)
      shift
      PG_SEPARATOR="${1:--}"
      ;;
    --copy) PG_COPY=1 ;;
    -h | --help)
      pg_usage
      return 0
      ;;
    *)
      uk_error "Unknown option: ${1:-}"
      return 1
      ;;
    esac
    shift
  done

  if ((seen_args == 0)) && [[ -t 0 && -t 1 ]]; then

    PG_MODE="$(uk_prompt \
      'Choose generator mode' \
      'passphrase' \
      'passphrase  →  human-readable words  |  string  →  random characters' \
      'Passphrases are easier to remember. Strings are denser and harder to type.')"

    if [[ "$PG_MODE" == 'string' ]]; then
      PG_LENGTH="$(uk_prompt \
        'Enter string length' \
        '20' \
        '20  →  good default  |  32  →  high entropy  |  64  →  very high entropy' \
        'Longer strings give more theoretical entropy against brute-force attacks.')"
    else
      PG_WORDS="$(uk_prompt \
        'Enter number of words' \
        '4' \
        '4  →  classic XKCD  |  5  →  more entropy  |  6  →  maximum comfort' \
        'More words increase both entropy and memorability.')"

      PG_SEPARATOR="$(uk_prompt \
        'Enter word separator character' \
        '-' \
        '-  →  readable  |  .  →  compact  |  _  →  no spaces' \
        'The separator is placed between each word in the passphrase.')"
    fi

    if uk_confirm 'Copy generated result to clipboard?' 'N'; then
      PG_COPY=1
    fi
  fi
  uk_has_cmd od || { uk_error 'od is required for secure random generation.'; return 1; }
  [[ "$PG_WORDS" =~ ^[1-9][0-9]*$ ]] && ((PG_WORDS <= 64)) || { uk_error '--words must be an integer from 1 to 64.'; return 1; }
  [[ "$PG_LENGTH" =~ ^[1-9][0-9]*$ ]] && ((PG_LENGTH <= 4096)) || { uk_error '--length must be an integer from 1 to 4096.'; return 1; }
  [[ "$PG_SEPARATOR" != *$'\n'* && "$PG_SEPARATOR" != *$'\r'* && ${#PG_SEPARATOR} -le 8 ]] || { uk_error '--separator must be at most 8 characters with no line breaks.'; return 1; }
  local generated entropy
  case "$PG_MODE" in
  passphrase)
    generated=$(pg_passphrase) || { uk_error 'Passphrase generation failed.'; return 1; }
    entropy=$(pg_entropy_words "$PG_WORDS" "${#PG_WORDLIST[@]}") || return 1
    ;;
  string)
    generated=$(pg_string) || { uk_error 'Random-string generation failed.'; return 1; }
    entropy=$(pg_entropy_string "$PG_LENGTH") || return 1
    ;;
  *)
    uk_error "Unsupported mode: $PG_MODE"
    return 1
    ;;
  esac

  # ── Output box ───
  local div
  div="$(printf '%*s' 52 '' | tr ' ' '-')"

  printf '\n  %s%s%s\n' "$UK_C_DIM" "$div" "$UK_C_RESET"
  printf '  %s✦ Generated%s\n' "$UK_C_BOLD$UK_C_BRIGHT_CYAN" "$UK_C_RESET"
  printf '  %s%s%s\n' "$UK_C_DIM" "$div" "$UK_C_RESET"
  printf '\n'
  printf '  %s%s%s\n' "$UK_C_GREEN$UK_C_BOLD" "$generated" "$UK_C_RESET"
  printf '\n'
  printf ' + %s%s%s\n' "$UK_C_DIM" "$div" "$UK_C_RESET"
  printf ' | %s◆ Entropy :%s  %s~%s bits%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_YELLOW" "$entropy" "$UK_C_RESET"
  printf ' | %s◆ Mode    :%s  %s%s%s\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$PG_MODE" "$UK_C_RESET"
  if [[ "$PG_MODE" == 'passphrase' ]]; then
    printf ' | %s◆ Words   :%s  %s%s%s  %s(separator: %s)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" \
      "$UK_C_WHITE" "$PG_WORDS" "$UK_C_RESET" \
      "$UK_C_DIM" "$PG_SEPARATOR" "$UK_C_RESET"
  else
    printf '  %s◆ Length  :%s  %s%s characters%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_WHITE" "$PG_LENGTH" "$UK_C_RESET"
  fi
  printf ' + %s%s%s\n\n' "$UK_C_DIM" "$div" "$UK_C_RESET"

  # ── Clipboard ────
  if ((PG_COPY == 1)); then
    if uk_copy_to_clipboard "$generated"; then
      uk_success 'Copied to clipboard.'
    else
      uk_warn 'No clipboard tool found (tried wl-copy, xclip, pbcopy, termux-clipboard-set).'
    fi
  fi

  # ── Save to file ────
  if [[ -t 0 && -t 1 ]]; then
    local save_dir save_path data_dir
    data_dir="$(uk_data_dir)" || return 1
    save_dir="$data_dir/passwords"
    printf ' ◆ %sSave to file?%s %s[Y/n]%s %s>%s ' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    local save_reply
    read -r save_reply </dev/tty || { uk_error 'Unable to read save confirmation.'; return 1; }
    if [[ ! "$save_reply" =~ ^[Nn]$ ]]; then
      mkdir -p -m 700 "$save_dir" || { uk_error "Unable to create password directory: $save_dir"; return 1; }
      chmod 700 "$save_dir" || { uk_error "Unable to secure password directory: $save_dir"; return 1; }
      save_path="$(mktemp "$save_dir/$(date '+%Y%m%d_%H%M%S')_${PG_MODE}.XXXXXX")" || { uk_error 'Unable to create password file.'; return 1; }
      chmod 600 "$save_path" || { rm -f "$save_path"; uk_error 'Unable to secure password file.'; return 1; }
      printf '%s\n' "$generated" >"$save_path" || { rm -f "$save_path"; uk_error 'Unable to write password file.'; return 1; }
      uk_success "Saved to $save_path"
    fi
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  pg_main "$@"
fi
