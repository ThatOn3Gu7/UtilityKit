#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"
lc_usage(){ echo 'Usage: _link_checker.sh FILE... [--http] [--timeout N]'; }
lc_main(){ local http=0 timeout=8 files=(); while [[ $# -gt 0 ]]; do case "$1" in --http) http=1;; --timeout) shift; timeout="${1:-8}";; -h|--help) lc_usage; return 0;; *) files+=("$1");; esac; shift; done; [[ ${#files[@]} -gt 0 ]] || { lc_usage; return 1; }; python3 - "$http" "$timeout" "${files[@]}" <<'PY'
import os,re,sys,urllib.request
http=sys.argv[1]=='1'; timeout=int(sys.argv[2]); bad=0
for f in sys.argv[3:]:
  base=os.path.dirname(os.path.abspath(f)); print('\n'+f)
  try: text=open(f,encoding='utf-8').read()
  except Exception as e: print('  ERR',e); bad+=1; continue
  for link in re.findall(r'\[[^\]]*\]\(([^)\s]+)', text):
    t=link.split('#',1)[0]
    if not t or t.startswith(('mailto:','#')): continue
    if t.startswith(('http://','https://')):
      if http:
        try: print('  OK HTTP', urllib.request.urlopen(urllib.request.Request(t,method='HEAD'),timeout=timeout).status, t)
        except Exception as e: print('  MISS HTTP',t,e); bad+=1
    elif os.path.exists(os.path.join(base,t)): print('  OK',link)
    else: print('  MISS',link); bad+=1
sys.exit(1 if bad else 0)
PY
}
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 && -t 0 && -t 1 && -f "$SCRIPT_DIR/../main.sh" ]]; then
    bash "$SCRIPT_DIR/../main.sh" links
  else
    lc_main "$@"
  fi
fi
