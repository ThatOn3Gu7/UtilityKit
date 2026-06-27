#!/usr/bin/env bash
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
    [[ "$line" == '```'* ]] && {
      ((in_code = 1 - in_code))
      continue
    }
    ((in_code == 1)) && continue
    if [[ "$line" =~ ^(#{1,6})[[:space:]]+(.+) ]]; then
      level=${#BASH_REMATCH[1]}
      title="${BASH_REMATCH[2]}"
      anchor=$(mt_anchor "$title")
      indent=$(printf '%*s' $(((level - 1) * 2)) '')
      printf '%s- [%s](#%s)\n' "$indent" "$title" "$anchor"
    fi
  done <"$MT_FILE"
}
mt_insert_toc() {
  local toc_lines tmp
  toc_lines=$(mt_generate_toc)
  MT_TOC_COUNT=$(printf '%s\n' "$toc_lines" | grep -c . || true)

  if ((MT_TOC_COUNT == 0)); then
    uk_warn 'No markdown headings were found; TOC would be empty.'
    return 0
  fi

  tmp=$(mktemp)

  python3 - "$MT_FILE" "$tmp" "$MT_START" "$MT_END" <<PYEOF
import sys

src_path  = sys.argv[1]
dst_path  = sys.argv[2]
start_tag = sys.argv[3]
end_tag   = sys.argv[4]

toc_block = """$toc_lines"""
toc_lines = toc_block.splitlines()

with open(src_path, 'r', encoding='utf-8') as f:
    lines = f.read().splitlines()

out = []
in_block    = False
has_markers = False
inserted    = False

for i, line in enumerate(lines):
    stripped = line.rstrip('\r')
    if stripped == start_tag:
        has_markers = True
        in_block = True
        out.append(line)
        for t in toc_lines:
            out.append(t)
        continue
    if stripped == end_tag:
        in_block = False
        out.append(line)
        continue
    if in_block:
        continue
    out.append(line)
    if not has_markers and not inserted and stripped.startswith('# '):
        out.append('')
        out.append(start_tag)
        for t in toc_lines:
            out.append(t)
        out.append(end_tag)
        out.append('')
        inserted = True

if not has_markers and not inserted:
    out.append('')
    out.append(start_tag)
    for t in toc_lines:
        out.append(t)
    out.append(end_tag)

with open(dst_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(out) + '\n')
PYEOF

  local py_status=$?
  if ((py_status != 0)); then
    rm -f "$tmp"
    uk_error 'TOC insertion failed.'
    return 1
  fi

  if ((MT_APPLY == 1)); then
    mv "$tmp" "$MT_FILE"
    uk_success "TOC updated with $MT_TOC_COUNT entr$( ((MT_TOC_COUNT == 1)) && printf 'y' || printf 'ies')."
  else
    uk_note "Preview with $MT_TOC_COUNT entr$( ((MT_TOC_COUNT == 1)) && printf 'y' || printf 'ies'):"
    cat "$tmp"
    rm -f "$tmp"
  fi
}
mt_check_links() {
  printf '\n  %s%sRelative link validation%s\n' "$UK_C_BOLD" "$UK_C_CYAN" "$UK_C_RESET"
  printf '  %s\n' "$(printf '%*s' 48 '' | tr ' ' '-')"
  python3 - "$MT_FILE" <<'PY2'
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
  python3 - "$MT_FILE" "$tmp" <<'PY2'
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
  if ((MT_APPLY == 1)); then
    mv "$tmp" "$MT_FILE"
    uk_success 'Aligned markdown tables.'
  else
    cat "$tmp"
  fi
}
mt_main() {
  uk_banner "markdown-toc" "Insert or refresh markdown TOC with link validation" "" "$@"
  MT_FILE=''
  MT_APPLY=0
  MT_CHECK_LINKS=0
  MT_ALIGN_TABLES=0
  MT_TOC_COUNT=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --apply) MT_APPLY=1 ;;
    --check-links) MT_CHECK_LINKS=1 ;;
    --align-tables) MT_ALIGN_TABLES=1 ;;
    -h | --help)
      mt_usage
      return 0
      ;;
    *) MT_FILE="$1" ;;
    esac
    shift
  done
  if [[ -z "$MT_FILE" ]] && [[ -t 0 && -t 1 ]]; then

    MT_FILE="$(uk_prompt \
      'Enter the markdown file to process' \
      '' \
      'README.md  |  docs/guide.md  |  ./CONTRIBUTING.md' \
      'A table of contents will be inserted or refreshed based on headings found in the file.')"
    [[ -n "$MT_FILE" ]] || {
      uk_warn 'No file entered. Exiting.'
      return 0
    }

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

  uk_section_title "File: $MT_FILE"
  mt_insert_toc
  ((MT_CHECK_LINKS == 1)) && {
    printf '\n'
    mt_check_links
  }
  ((MT_ALIGN_TABLES == 1)) && {
    printf '\n'
    mt_align_tables
  }
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  mt_main "$@"
fi
