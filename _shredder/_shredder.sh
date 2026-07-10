#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

SD_APPLY=0
SD_PASSES=3
declare -a SD_FILES=()

# sd_usage prints the command usage and warns that secure deletion may not remove retained copies.
sd_usage() {
  cat <<'USAGE'
Usage:
  _shredder.sh [--passes N] [--apply] FILE...

Warning:
  Secure deletion is best-effort only. SSDs, journaling filesystems, snapshots,
  cloud sync, and backups may retain previous copies outside this tool's reach.
USAGE
}
# sd_secure_delete securely overwrites and removes a regular file using the available deletion method; missing files are skipped, and unavailable overwrite resources cause failure.
sd_secure_delete() {
  local file="${1:-}" size pass
  [[ -f "$file" ]] || {
    uk_warn "Skipping missing file: $file"
    return 0
  }
  if uk_has_cmd shred; then
    shred -n "$SD_PASSES" -z -u "$file"
    return 0
  fi
  [[ -r /dev/urandom ]] || { uk_error "/dev/urandom is unavailable; cannot overwrite safely."; return 1; }
  size=$(wc -c <"$file")
  for ((pass = 1; pass <= SD_PASSES; pass++)); do
    head -c "$size" /dev/urandom >"$file"
  done
  : >"$file"
  rm -f "$file"
}
# sd_main parses options, optionally prompts for a file and overwrite settings, and previews or performs best-effort secure deletion.
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
  local f
  for f in "${SD_FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
      uk_warn "Skipping — file not found: $f"
      continue
    fi
    if ((SD_APPLY == 1)); then
      printf '  %s%sShredding:%s %s%s%s\n' \
        "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET" \
        "$UK_C_DIM" "$f" "$UK_C_RESET"
      printf '  %s(%d overwrite pass(es) then unlink)%s\n' \
        "$UK_C_DIM" "$SD_PASSES" "$UK_C_RESET"
      sd_secure_delete "$f"
      uk_success "Securely erased: $f"
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
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  sd_main "$@"
fi
