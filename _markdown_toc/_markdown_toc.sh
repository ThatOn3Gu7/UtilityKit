#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/uk_common.sh"

MT_FILE=''
MT_APPLY=0
MT_CHECK_LINKS=0
MT_ALIGN_TABLES=0
MT_START='<!-- utilitykit:toc:start -->'
MT_END='<!-- utilitykit:toc:end -->'
MT_TOC_COUNT=0

mt_usage() {
  cat <<'USAGE'
Usage:
  _markdown_toc.sh FILE [--apply] [--check-links] [--align-tables]
USAGE
}

mt_anchor() {
  local text="$1"
  text=$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')
  text=$(printf '%s' "$text" | sed 's/[^a-z0-9 _-]//g; s/[[:space:]]\+/-/g; s/--\+/-/g; s/^-//; s/-$//')
  printf '%s\n' "$text"
}

mt_generate_toc() {
  local in_code=0 line level title indent anchor
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == '```'* ]] && { (( in_code = 1 - in_code )); continue; }
    (( in_code == 1 )) && continue
    if [[ "$line" =~ ^(#{1,6})[[:space:]]+(.+) ]]; then
      level=${#BASH_REMATCH[1]}
      title="${BASH_REMATCH[2]}"
      anchor=$(mt_anchor "$title")
      indent=$(printf '%*s' $(((level-1)*2)) '')
      printf '%s- [%s](#%s)\n' "$indent" "$title" "$anchor"
    fi
  done < "$MT_FILE"
}

mt_insert_toc() {
  local toc tmp
  toc=$(mktemp)
  tmp=$(mktemp)
  trap "rm -f '$toc' '$tmp'" RETURN
  mt_generate_toc > "$toc"
  MT_TOC_COUNT=$(wc -l < "$toc" | tr -d ' ')

  if (( MT_TOC_COUNT == 0 )); then
    uk_warn 'No markdown headings were found; TOC would be empty.'
  fi

  awk -v start="$MT_START" -v end="$MT_END" -v tocfile="$toc" '
    BEGIN {inblock=0; has_markers=0; inserted=0}
    $0==start {
      has_markers=1
      print
      while ((getline line < tocfile) > 0) print line
      inblock=1
      next
    }
    $0==end {inblock=0; print; next}
    inblock {next}
    {
      print
      if (!has_markers && !inserted && $0 ~ /^# /) {
        print ""
        print start
        while ((getline line < tocfile) > 0) print line
        print end
        print ""
        inserted=1
      }
    }
    END {
      if (!has_markers && !inserted) {
        print ""
        print start
        while ((getline line < tocfile) > 0) print line
        print end
      }
    }
  ' "$MT_FILE" > "$tmp"

  if (( MT_APPLY == 1 )); then
    mv "$tmp" "$MT_FILE"
    uk_success "TOC updated with $MT_TOC_COUNT entr$( (( MT_TOC_COUNT == 1 )) && printf 'y' || printf 'ies' )."
  else
    uk_note "Preview with $MT_TOC_COUNT entr$( (( MT_TOC_COUNT == 1 )) && printf 'y' || printf 'ies' ):"
    cat "$tmp"
  fi
}

mt_check_links() {
  printf '\n  %s%sRelative link validation%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  python3 - <<'PY2' "$MT_FILE"
import re,sys,os
path=sys.argv[1]
base=os.path.dirname(os.path.abspath(path))
text=open(path,'r',encoding='utf-8').read()
found=False
for link in re.findall(r'\]\(([^)]+)\)', text):
    if link.startswith(('http://','https://','mailto:','#')):
        continue
    found=True
    target=os.path.join(base, link.split('#',1)[0])
    status='OK  ' if os.path.exists(target) else 'MISS'
    color='\033[32m' if os.path.exists(target) else '\033[31m'
    print(f'  {color}{status}\033[0m  {link}')
if not found:
    print('  \033[2m(no relative links found in this file)\033[0m')
PY2
}

mt_align_tables() {
  local tmp
  tmp=$(mktemp)
  trap "rm -f '$tmp'" RETURN
  python3 - <<'PY2' "$MT_FILE" "$tmp"
import sys,re
src,dst=sys.argv[1],sys.argv[2]
lines=open(src,'r',encoding='utf-8').read().splitlines()
out=[]
i=0
while i < len(lines):
    if '|' in lines[i] and i+1 < len(lines) and re.match(r'^\s*\|?\s*[:\-]+', lines[i+1]):
        block=[]
        while i < len(lines) and '|' in lines[i]:
            block.append(lines[i])
            i+=1
        rows=[[c.strip() for c in row.strip().strip('|').split('|')] for row in block]
        width=[0]*max(len(r) for r in rows)
        for r in rows:
            for idx,c in enumerate(r): width[idx]=max(width[idx],len(c))
        for ridx,r in enumerate(rows):
            padded=[' '+(r[idx] if idx < len(r) else '').ljust(width[idx])+' ' for idx in range(len(width))]
            if ridx==1:
                padded=[' '+('-'*width[idx])+' ' for idx in range(len(width))]
            out.append('|'+'|'.join(padded)+'|')
    else:
        out.append(lines[i])
        i+=1
open(dst,'w',encoding='utf-8').write('\n'.join(out)+'\n')
PY2
  if (( MT_APPLY == 1 )); then
    mv "$tmp" "$MT_FILE"
    uk_success 'Aligned markdown tables.'
  else
    cat "$tmp"
  fi
}

mt_main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply) MT_APPLY=1 ;;
      --check-links) MT_CHECK_LINKS=1 ;;
      --align-tables) MT_ALIGN_TABLES=1 ;;
      -h|--help) mt_usage; return 0 ;;
      *) MT_FILE="$1" ;;
    esac
    shift
  done
if [[ -z "$MT_FILE" ]] && [[ -t 0 && -t 1 ]]; then
    uk_header 'UtilityKit Markdown TOC' 'TOC generation, link checking and table alignment'

    MT_FILE="$(uk_prompt \
      'Enter the markdown file to process' \
      '' \
      'README.md  |  docs/guide.md  |  ./CONTRIBUTING.md' \
      'A table of contents will be inserted or refreshed based on headings found in the file.')"
    [[ -n "$MT_FILE" ]] || { uk_warn 'No file entered. Exiting.'; return 0; }

    if uk_confirm 'Apply TOC changes to the file? (dry-run preview if you say no)' 'N'; then
      MT_APPLY=1
    fi

    if uk_confirm 'Check relative links inside the file?' 'Y'; then
      MT_CHECK_LINKS=1
    fi

    if uk_confirm 'Align markdown pipe tables?' 'Y'; then
      MT_ALIGN_TABLES=1
    fi
  elif [[ -z "$MT_FILE" ]]; then
    mt_usage
    return 1
  fi

  uk_header 'UtilityKit Markdown TOC' "$MT_FILE"
  mt_insert_toc
  (( MT_CHECK_LINKS == 1 )) && { printf '\n'; mt_check_links; }
  (( MT_ALIGN_TABLES == 1 )) && { printf '\n'; mt_align_tables; }
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  mt_main "$@"
fi
