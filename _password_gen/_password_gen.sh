#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

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
  awk -v n="$1" -v k="$2" 'BEGIN { printf "%.2f", n*(log(k)/log(2)) }'
}
pg_entropy_string() {
  awk -v n="$1" 'BEGIN { printf "%.2f", n*(log(72)/log(2)) }'
}
pg_passphrase() {
  local out='' idx i count=${#PG_WORDLIST[@]}
  for ((i = 0; i < PG_WORDS; i++)); do
    idx=$((RANDOM % count))
    out+="${PG_WORDLIST[$idx]}"
    ((i + 1 < PG_WORDS)) && out+="$PG_SEPARATOR"
  done
  printf '%s\n' "$out"
}
pg_string() {
  tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' </dev/urandom | head -c "$PG_LENGTH"
  printf '\n'
}
pg_main() {
  PG_MODE='passphrase'
  PG_WORDS=4
  PG_LENGTH=20
  PG_COPY=0
  PG_SEPARATOR='-'
  local seen_args=0
  while [[ $# -gt 0 ]]; do
    seen_args=1
    case "$1" in
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
      uk_error "Unknown option: $1"
      return 1
      ;;
    esac
    shift
  done

  if ((seen_args == 0)) && [[ -t 0 && -t 1 ]]; then
    uk_header 'UtilityKit Password Generator' 'Passphrases and random strings'

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
  local generated entropy
  case "$PG_MODE" in
  passphrase)
    generated=$(pg_passphrase)
    entropy=$(pg_entropy_words "$PG_WORDS" "${#PG_WORDLIST[@]}")
    ;;
  string)
    generated=$(pg_string)
    entropy=$(pg_entropy_string "$PG_LENGTH")
    ;;
  *)
    uk_error "Unsupported mode: $PG_MODE"
    return 1
    ;;
  esac

  uk_header 'UtilityKit Password Generator' "$PG_MODE"

  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  printf '  %s%sGenerated%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '\n  %s%s%s\n\n' "$UK_C_GREEN$UK_C_BOLD" "$generated" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  printf '  %sEntropy :%s ~%s bits\n' "$UK_C_BOLD" "$UK_C_RESET" "$entropy"
  printf '  %sMode    :%s %s\n' "$UK_C_BOLD" "$UK_C_RESET" "$PG_MODE"
  if [[ "$PG_MODE" == 'passphrase' ]]; then
    printf '  %sWords   :%s %s  %s(separator: %s)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$PG_WORDS" "$UK_C_DIM" "$PG_SEPARATOR" "$UK_C_RESET"
  else
    printf '  %sLength  :%s %s characters\n' "$UK_C_BOLD" "$UK_C_RESET" "$PG_LENGTH"
  fi
  printf '  %s\n\n' "$(printf '%*s' 48 '' | tr ' ' '-')"

  if ((PG_COPY == 1)); then
    if uk_copy_to_clipboard "$generated"; then
      uk_success 'Copied to clipboard.'
    else
      uk_warn 'No supported clipboard tool found (tried wl-copy, xclip, pbcopy, termux-clipboard-set).'
    fi
  fi
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  pg_main "$@"
fi
