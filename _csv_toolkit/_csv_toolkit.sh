#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
csvt_usage(){ echo 'Usage: _csv_toolkit.sh FILE [--columns] [--head N]'; }
csvt_main(){ local file='' cols=0 headn=10; while [[ $# -gt 0 ]]; do case "$1" in --columns) cols=1;; --head) shift; headn="${1:-10}";; -h|--help) csvt_usage; return 0;; *) file="$1";; esac; shift; done; python3 - "$file" "$cols" "$headn" <<'PY'
import csv,sys
rows=list(csv.reader(open(sys.argv[1],newline='',encoding='utf-8')))
if sys.argv[2]=='1': print('\n'.join(rows[0] if rows else []))
else:
 for r in rows[:int(sys.argv[3])]: print(' | '.join(r))
 print(f'rows={max(len(rows)-1,0)}')
PY
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" csv
  else
    csvt_main "$@"
  fi
fi
