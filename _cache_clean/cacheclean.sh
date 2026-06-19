#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_cache_clean.sh
source "$SCRIPT_DIR/_cache_clean.sh"
cc_main "$@"
