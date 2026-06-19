#!/usr/bin/env bash
set -euo pipefail
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
  for ((i=0; i<PG_WORDS; i++)); do
    idx=$(( RANDOM % count ))
    out+="${PG_WORDLIST[$idx]}"
    (( i + 1 < PG_WORDS )) && out+="$PG_SEPARATOR"
  done
  printf '%s\n' "$out"
}

pg_string() {
  tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' </dev/urandom | head -c "$PG_LENGTH"; printf '\n'
}

pg_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode) shift; PG_MODE="${1:-passphrase}" ;;
      --words) shift; PG_WORDS="${1:-4}" ;;
      --length) shift; PG_LENGTH="${1:-20}" ;;
      --separator) shift; PG_SEPARATOR="${1:--}" ;;
      --copy) PG_COPY=1 ;;
      -h|--help) pg_usage; return 0 ;;
      *) uk_error "Unknown option: $1"; return 1 ;;
    esac
    shift
  done
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
    *) uk_error "Unsupported mode: $PG_MODE"; return 1 ;;
  esac
  uk_header 'UtilityKit Password Generator' "$PG_MODE"
  printf '%s\nEntropy: ~%s bits\n' "$generated" "$entropy"
  if (( PG_COPY == 1 )); then
    if uk_copy_to_clipboard "$generated"; then
      uk_success 'Copied password to clipboard.'
    else
      uk_warn 'No supported clipboard tool found.'
    fi
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  pg_main "$@"
fi
