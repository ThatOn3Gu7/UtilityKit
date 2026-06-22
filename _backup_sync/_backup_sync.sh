#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
bs_usage(){ echo 'Usage: _backup_sync.sh --source DIR --dest DIR [--apply] [--delete] [--exclude PATTERN]...'; }
bs_main(){ local src='' dst='' apply=0 delete=0 excludes=(); while [[ $# -gt 0 ]]; do case "$1" in --source|-s) shift; src="${1:-}";; --dest|-d) shift; dst="${1:-}";; --apply) apply=1;; --delete) delete=1;; --exclude) shift; excludes+=("${1:-}");; -h|--help) bs_usage; return 0;; esac; shift; done; [[ -d "$src" && -n "$dst" ]] || { bs_usage; return 1; }; mkdir -p "$dst"; uk_header 'UtilityKit Backup Sync' "$src -> $dst"; if uk_has_cmd rsync; then local args=(-a --itemize-changes --human-readable --exclude node_modules --exclude .git); (( delete==1 )) && args+=(--delete); for e in "${excludes[@]}"; do args+=(--exclude "$e"); done; (( apply==0 )) && args+=(--dry-run); rsync "${args[@]}" "$src"/ "$dst"/; else uk_warn 'rsync unavailable; using cp fallback without delete support.'; (( apply==1 )) && cp -a "$src"/. "$dst"/ || find "$src" -type f | sed 's/^/  would copy: /'; fi; (( apply==0 )) && uk_note 'Dry-run only. Re-run with --apply.'; return 0; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" backup
  else
    bs_main "$@"
  fi
fi
