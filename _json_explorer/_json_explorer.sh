#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
jx_usage(){ echo 'Usage: _json_explorer.sh [FILE|-] [--path a.b.0] [--keys] [--summary]'; }
jx_main(){ local file='-' path='' keys=0 summary=0; while [[ $# -gt 0 ]]; do case "$1" in --path) shift; path="${1:-}";; --keys) keys=1;; --summary) summary=1;; -h|--help) jx_usage; return 0;; *) file="$1";; esac; shift; done; uk_has_cmd python3 || { uk_error 'python3 is required for portable JSON parsing.'; return 1; }; python3 - "$file" "$path" "$keys" "$summary" <<'PY'
import json,sys
file,path,keys,summary=sys.argv[1],sys.argv[2],sys.argv[3]=='1',sys.argv[4]=='1'
try: data=json.loads(sys.stdin.read() if file=='-' else open(file,encoding='utf-8').read())
except Exception as e: print(f'[ERR] Invalid JSON: {e}',file=sys.stderr); sys.exit(1)
def get(o,p):
    for part in [x for x in p.split('.') if x]: o=o[int(part)] if isinstance(o,list) and part.isdigit() else o[part]
    return o
try: obj=get(data,path) if path else data
except Exception as e: print(f'[ERR] Path not found: {e}',file=sys.stderr); sys.exit(1)
if keys:
    print('\n'.join(map(str, obj.keys() if isinstance(obj,dict) else range(len(obj)) if isinstance(obj,list) else [])))
elif summary:
    def walk(o,p='$'):
        print(f'{p}: {type(o).__name__}' + (f' ({len(o)})' if isinstance(o,(dict,list)) else ''))
        if isinstance(o,dict):
            for k,v in list(o.items())[:20]: walk(v,p+'.'+k)
    walk(obj)
else: print(json.dumps(obj,indent=2,ensure_ascii=False))
PY
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" json
  else
    jx_main "$@"
  fi
fi
