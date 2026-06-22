#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
ht_usage(){ echo 'Usage: _hash_tools.sh FILE...'; }
ht_main(){ [[ ${1:-} == -h || ${1:-} == --help ]] && { ht_usage; return 0; }; local cmd=sha256sum; uk_has_cmd sha256sum || cmd='shasum -a 256'; [[ $# -gt 0 ]] || { ht_usage; return 1; }; for f in "$@"; do [[ -d "$f" ]] && find "$f" -type f -print0 | xargs -0 $cmd || $cmd "$f"; done; }
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" hash
  else
    ht_main "$@"
  fi
fi
