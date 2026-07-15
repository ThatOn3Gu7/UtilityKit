#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/uk_common.sh"

SD_APPLY=0
SD_PASSES=3
declare -a SD_FILES=()

sd_usage() {
  cat <<'USAGE'
Usage:
  _shredder.sh [--passes N] [--apply] FILE...

Warning:
  Secure deletion is best-effort only. SSDs, journaling filesystems, snapshots,
  cloud sync, and backups may retain previous copies outside this tool's reach.
USAGE
}
sd_secure_delete() {
  local file="${1:-}" size pass
  [[ -f "$file" ]] || { uk_error "File not found: $file"; return 1; }
  [[ ! -L "$file" ]] || { uk_error "Refusing to shred a symbolic link: $file"; return 1; }
  if uk_has_cmd shred; then
    shred -n "$SD_PASSES" -z -u -- "$file" || return 1
  else
    [[ -r /dev/urandom ]] || { uk_error "/dev/urandom is unavailable; cannot overwrite safely."; return 1; }
    size=$(wc -c <"$file") || return 1
    [[ "$size" =~ ^[0-9]+$ ]] || { uk_error "Unable to determine file size: $file"; return 1; }
    for ((pass = 1; pass <= SD_PASSES; pass++)); do
      head -c "$size" /dev/urandom >"$file" || return 1
    done
    : >"$file" || return 1
    rm -f -- "$file" || return 1
  fi
  [[ ! -e "$file" && ! -L "$file" ]] || { uk_error "Secure erase did not remove: $file"; return 1; }
}
sd_main() {
  uk_banner "shredder" "Multi-pass overwrite using shred or /dev/urandom fallback" "" "$@"
  SD_APPLY=0
  SD_PASSES=3
  SD_FILES=()
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
    --passes)
      shift
      SD_PASSES="${1:-3}"
      ;;
    --apply) SD_APPLY=1 ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do SD_FILES+=("${1:-}"); shift; done
      break
      ;;
    -h | --help)
      sd_usage
      return 0
      ;;
    *) SD_FILES+=("${1:-}") ;;
    esac
    shift
  done
  if ((${#SD_FILES[@]} == 0)) && [[ -t 0 && -t 1 ]]; then

    local input_file
    input_file="$(uk_prompt \
      'Enter path of the file to securely erase' \
      '' \
      '~/secret.txt  |  ./credentials.env  |  /tmp/private.key' \
      'The file will be overwritten multiple times before being deleted.')"
    [[ -n "$input_file" ]] || {
      uk_warn 'No file entered. Exiting.'
      return 0
    }
    SD_FILES+=("$input_file")

    SD_PASSES="$(uk_prompt \
      'How many overwrite passes?' \
      '3' \
      '3  →  good default  |  7  →  DoD standard  |  1  →  fast, less thorough' \
      'More passes take longer but overwrite the file contents more thoroughly.')"

    if uk_confirm \
      'Apply secure erase now? (this permanently destroys the file and cannot be undone)' \
      'N'; then
      SD_APPLY=1
    fi
  elif ((${#SD_FILES[@]} == 0)); then
    sd_usage
    return 1
  fi

  [[ "$SD_PASSES" =~ ^[1-9][0-9]*$ ]] || { uk_error "--passes must be a positive integer."; return 2; }
  (( SD_PASSES <= 35 )) || { uk_error "--passes is too high (max 35)."; return 2; }
  if (( SD_APPLY == 1 )); then
    uk_warn "Best-effort deletion only: SSDs/snapshots/backups may retain copies."
  fi
  uk_section_title "Passes: $SD_PASSES"
  local f failed=0
  for f in "${SD_FILES[@]}"; do
    if [[ ! -f "$f" || -L "$f" ]]; then
      uk_error "Refusing invalid or missing regular file: $f"
      failed=$((failed + 1))
      continue
    fi
    if ((SD_APPLY == 1)); then
      printf '  %s%sShredding:%s %s%s%s\n' \
        "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET" \
        "$UK_C_DIM" "$f" "$UK_C_RESET"
      printf '  %s(%d overwrite pass(es) then unlink)%s\n' \
        "$UK_C_DIM" "$SD_PASSES" "$UK_C_RESET"
      if sd_secure_delete "$f"; then
        uk_success "Securely erased: $f"
      else
        failed=$((failed + 1))
      fi
    else
      printf '\n  %s%sDry-run preview%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
      printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
      printf '  %sFile:%s    %s\n' "$UK_C_BOLD" "$UK_C_RESET" "$f"
      printf '  %sMethod:%s  %s\n' "$UK_C_BOLD" "$UK_C_RESET" \
        "$(uk_has_cmd shred && printf 'shred -n %d -z -u' "$SD_PASSES" || printf 'urandom overwrite x%d then rm' "$SD_PASSES")"
      printf '  %sPasses:%s  %d\n' "$UK_C_BOLD" "$UK_C_RESET" "$SD_PASSES"
      printf '  %s(re-run with --apply to permanently erase this file)%s\n' \
        "$UK_C_DIM" "$UK_C_RESET"
    fi
  done
  ((failed == 0))
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sd_main "$@"
fi
