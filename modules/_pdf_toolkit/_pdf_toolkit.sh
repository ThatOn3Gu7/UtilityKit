#!/usr/bin/env bash
# _pdf_toolkit — merge, split, extract text, page count, compress PDFs.
# Prefix: pt_
# Backends: qpdf, pdftotext (poppler-utils), pdfimages, gs (ghostscript)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

if ! declare -f uk_has_cmd  >/dev/null 2>&1; then uk_has_cmd()  { command -v "${1:-}" >/dev/null 2>&1; }; fi
if ! declare -f uk_error    >/dev/null 2>&1; then uk_error()    { printf "[ERR] %s\n" "$*" >&2; }; fi
if ! declare -f uk_warn     >/dev/null 2>&1; then uk_warn()     { printf "[WRN] %s\n" "$*" >&2; }; fi
if ! declare -f uk_info     >/dev/null 2>&1; then uk_info()     { printf "[INF] %s\n" "$*"; }; fi
if ! declare -f uk_success  >/dev/null 2>&1; then uk_success()  { printf "[OK]  %s\n" "$*"; }; fi
if ! declare -f uk_note     >/dev/null 2>&1; then uk_note()     { printf "-> %s\n" "$*"; }; fi
if ! declare -f uk_banner   >/dev/null 2>&1; then uk_banner()   { :; }; fi
if ! declare -f uk_prompt   >/dev/null 2>&1; then
  uk_prompt() {
    local label="${1:-}" default="${2:-}" reply=''
    printf '> %s%s: ' "$label" "${default:+ [$default]}" >&2
    if [[ -r /dev/tty ]]; then read -r reply </dev/tty; else read -r reply; fi
    printf '%s\n' "${reply:-$default}"
  }
fi
if ! declare -f uk_confirm  >/dev/null 2>&1; then
  uk_confirm() {
    local reply=''
    printf '> %s [y/N]: ' "${1:-Confirm?}" >&2
    if [[ -r /dev/tty ]]; then read -r reply </dev/tty; else read -r reply; fi
    [[ "$reply" =~ ^[Yy] ]]
  }
fi
if ! declare -f uk_platform >/dev/null 2>&1; then
  uk_platform() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then echo termux
    elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then echo macos
    else echo linux; fi
  }
fi
if ! declare -f uk_expand_path >/dev/null 2>&1; then
  uk_expand_path() { local i="${1:-}"; printf '%s\n' "${i/#\~/$HOME}"; }
fi

# Dry-run by default: writing subcommands only create output when PT_APPLY=1.
PT_APPLY=0

pt_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s %s_pdf_toolkit.sh <subcommand> FILE [OPTIONS]%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Subcommands" \
    "info FILE" "Show page count, PDF version, encryption, metadata" \
    "count FILE" "Print page count only" \
    "merge FILE1 FILE2..." "Merge PDFs into one" \
    "split FILE" "Split each page into separate PDFs" \
    "text FILE" "Extract text content" \
    "compress FILE" "Compress/optimize PDF (requires ghostscript)" \
    "rotate FILE DEG" "Rotate pages (90, 180, 270)"
  printf '\n'
  uk_help_section "$w" "Options" \
    "--output FILE" "Output path (merge, split, compress, rotate)" \
    "--pages RANGE" "Page range for split (e.g. 1-3,5)" \
    "--apply" "Actually write output files (default is dry-run)" \
    "--json" "Machine-readable output (info, count, text)" \
    "--no-color" "Disable ANSI (also respects NO_COLOR=1)" \
    "-h, --help" "Show this help"
  printf '\n'
  printf  '%s Safety:%s\n %s Merge, split, compress, and rotate preview only by default and do not write any file. Re-run with --apply to create the output file(s).%s\n' "${UK_C_BOLD:-}${UK_C_YELLOW:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  printf '\n'
  uk_help_section "$w" "Dependencies" \
    "qpdf" "Recommended – PDF manipulation" \
    "pdftotext" "From poppler-utils – text extraction" \
    "pdfimages" "From poppler-utils – image extraction" \
    "gs" "Ghostscript – PostScript/PDF conversion" \
    "${UK_C_DIM:-}---------------------------------------------------------------"${UK_C_RESET:-} "" \
    "Install deps:" "apt install qpdf poppler-utils ghostscript"
  printf '\n'
  uk_help_section "$w" "Examples" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_pdf_toolkit.sh${UK_C_RESET:-} ${UK_C_DIM:-}info document.pdf${UK_C_RESET:-}" "Show document info" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_pdf_toolkit.sh${UK_C_RESET:-} ${UK_C_DIM:-}count document.pdf${UK_C_RESET:-}" "Print page count" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_pdf_toolkit.sh${UK_C_RESET:-} ${UK_C_DIM:-}merge a.pdf b.pdf --output merged.pdf${UK_C_RESET:-}" "Merge PDFs" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_pdf_toolkit.sh${UK_C_RESET:-} ${UK_C_DIM:-}split document.pdf --output ./pages/${UK_C_RESET:-}" "Split into pages" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_pdf_toolkit.sh${UK_C_RESET:-} ${UK_C_DIM:-}text document.pdf${UK_C_RESET:-}" "Extract text" \
    "${UK_C_GREEN:-}bash${UK_C_RESET:-} ${UK_C_WHITE:-}_pdf_toolkit.sh${UK_C_RESET:-} ${UK_C_DIM:-}compress document.pdf --output compressed.pdf${UK_C_RESET:-}" "Compress PDF"
}

pt_hr() {
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}
pt_section() {
  local title="${1:-}"
  printf '\n%s%s%s%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$title" "${UK_C_RESET:-}"
  pt_hr
}

pt_json_escape() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

pt_cmd_info() {
  local file="$1" as_json="$2"
  [[ ! -f "$file" ]] && { uk_error "File not found: $file"; return 2; }

  if (( as_json )); then
    if uk_has_cmd python3 && uk_has_cmd qpdf; then
      python3 -c '
import sys, json, subprocess
file = sys.argv[1]
info = {"file": file, "pages": 0, "version": "unknown", "encrypted": False}
try:
    r = subprocess.run(["qpdf", "--show-info", file], capture_output=True, text=True, timeout=10)
    for line in r.stdout.splitlines():
        if "Page" in line:
            info["pages"] = int(line.split(":")[-1].strip())
        if "PDF version" in line:
            info["version"] = line.split(":")[-1].strip()
        if "Encrypted" in line:
            info["encrypted"] = "yes" in line.lower()
except: pass
print(json.dumps(info, ensure_ascii=False))
' "$file" 2>/dev/null || printf '{"file":"%s","error":"qpdf failed"}\n' "$file"
    else
      local pages
      pages="$(pt_cmd_count "$file" 0 2>/dev/null || echo 0)"
      printf '{"file":%s,"pages":%d}\n' "$(pt_json_escape "$file")" "$pages"
    fi
    return 0
  fi

  pt_section "PDF Info: $(basename "$file")"
  printf '  %s%-16s%s  %s\n' "${UK_C_DIM:-}" "File" "${UK_C_RESET:-}" "$file"

  if uk_has_cmd qpdf; then
    local raw
    raw="$(qpdf --show-info "$file" 2>/dev/null || true)"
    local pages version encrypted
    pages="$(printf '%s\n' "$raw" | grep -i 'Page' | head -n1 | awk -F: '{print $2}' | xargs)"
    version="$(printf '%s\n' "$raw" | grep -i 'PDF version' | head -n1 | awk -F: '{print $2}' | xargs)"
    encrypted="$(printf '%s\n' "$raw" | grep -i 'Encrypted' | head -n1 | awk -F: '{print $2}' | xargs)"
    printf '  %s%-16s%s  %s\n' "${UK_C_DIM:-}" "Pages" "${UK_C_RESET:-}" "${pages:-?}"
    printf '  %s%-16s%s  %s\n' "${UK_C_DIM:-}" "Version" "${UK_C_RESET:-}" "${version:-?}"
    printf '  %s%-16s%s  %s\n' "${UK_C_DIM:-}" "Encrypted" "${UK_C_RESET:-}" "${encrypted:-?}"
  else
    local count
    count="$(pt_cmd_count "$file" 0 2>/dev/null || echo 0)"
    printf '  %s%-16s%s  %s\n' "${UK_C_DIM:-}" "Pages" "${UK_C_RESET:-}" "$count"
    printf '  %s%-16s%s  %s\n' "${UK_C_DIM:-}" "(install qpdf for more info)" "${UK_C_RESET:-}" ""
  fi
}

pt_cmd_count() {
  local file="$1" as_json="$2"
  [[ ! -f "$file" ]] && { uk_error "File not found: $file"; return 2; }
  local count=0

  if uk_has_cmd qpdf; then
    count="$(qpdf --show-info "$file" 2>/dev/null | grep -i 'Page' | awk -F: '{print $2}' | xargs || echo 0)"
  elif uk_has_cmd pdfinfo; then
    count="$(pdfinfo "$file" 2>/dev/null | grep -i Pages | awk '{print $2}' || echo 0)"
  elif uk_has_cmd python3; then
    count="$(python3 -c "
import sys
try:
    from PyPDF2 import PdfReader
    r = PdfReader(sys.argv[1])
    print(len(r.pages))
except Exception:
    try:
        import pikepdf
        pdf = pikepdf.open(sys.argv[1])
        print(len(pdf.pages))
    except Exception:
        print(0)
" "$file" 2>/dev/null || echo 0)"
  else
    uk_error "No PDF tool found. Install qpdf or poppler-utils."
    return 2
  fi

  if (( as_json )); then
    printf '{"file":%s,"pages":%d}\n' "$(pt_json_escape "$file")" "$count"
  else
    printf '%d\n' "$count"
  fi
}

pt_cmd_merge() {
  local -a files=()
  local out=""
  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --output)
        shift
        out="${1:-}"
        ;;
      *) files+=("${1:-}") ;;
    esac
    shift || true
  done
  [[ ${#files[@]} -ge 2 ]] || { uk_error "merge requires at least 2 input PDFs."; return 2; }
  [[ -n "$out" ]] || { uk_error "merge requires --output FILE"; return 2; }
  local f
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || { uk_error "Input PDF not found: $f"; return 2; }
  done
  mkdir -p "$(dirname -- "$out")" 2>/dev/null || true

  if (( PT_APPLY == 0 )); then
    uk_note "Dry-run preview. Would merge ${#files[@]} PDF(s) into: $out"
    uk_note "Re-run with --apply to write the merged file."
    return 0
  fi

  if uk_has_cmd qpdf; then
    qpdf --empty --pages "${files[@]}" -- "$out" 2>/dev/null || {
      uk_error "Merge failed."
      return 1
    }
    uk_success "Merged ${#files[@]} PDFs into $out"
  elif uk_has_cmd python3; then
    python3 -c "
import sys
try:
    from PyPDF2 import PdfMerger
except ImportError:
    try:
        from pypdf import PdfMerger
    except ImportError:
        print('ERR: install PyPDF2 or pypdf')
        sys.exit(1)
merger = PdfMerger()
for f in sys.argv[1:-1]:
    merger.append(f)
merger.write(sys.argv[-1])
merger.close()
print('OK')
" "${files[@]}" "$out" 2>/dev/null | grep -q 'OK' || {
      uk_error "Python merge failed (install PyPDF2 or pypdf)."
      return 1
    }
    uk_success "Merged ${#files[@]} PDFs into $out"
  else
    uk_error "No merge backend. Install qpdf or PyPDF2."
    return 2
  fi
}

pt_expand_pages() {
  local range="$1" max="$2" part a b i
  if [[ -z "$range" ]]; then
    seq 1 "$max"
    return 0
  fi
  IFS=',' read -r -a _parts <<<"$range"
  for part in "${_parts[@]}"; do
    part="${part//[[:space:]]/}"
    if [[ "$part" =~ ^[0-9]+$ ]]; then
      (( part >= 1 && part <= max )) && printf '%s\n' "$part"
    elif [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
      a="${part%-*}"; b="${part#*-}"
      (( a > b )) && { i="$a"; a="$b"; b="$i"; }
      for ((i=a; i<=b; i++)); do (( i >= 1 && i <= max )) && printf '%s\n' "$i"; done
    else
      uk_error "Invalid page range part: $part"
      return 2
    fi
  done | awk '!seen[$0]++'
}

pt_cmd_split() {
  local file="$1" outdir="$2" pages="${3:-}"
  [[ ! -f "$file" ]] && { uk_error "File not found: $file"; return 2; }

  if (( PT_APPLY == 0 )); then
    local count
    count="$(pt_cmd_count "$file" 0 2>/dev/null || echo 0)"
    uk_note "Dry-run preview. Would split ${file##*/} into $count page file(s) under: $outdir"
    uk_note "Re-run with --apply to write the split files."
    return 0
  fi

  mkdir -p "$outdir"

  local count
  count="$(pt_cmd_count "$file" 0 2>/dev/null || echo 0)"
  [[ "$count" -eq 0 ]] && { uk_error "No pages found."; return 1; }

  local -a selected_pages=()
  local expanded
  expanded="$(pt_expand_pages "$pages" "$count")" || return $?
  [[ -n "$expanded" ]] && mapfile -t selected_pages <<<"$expanded"
  ((${#selected_pages[@]} > 0)) || { uk_error 'No valid pages selected.'; return 1; }
  if uk_has_cmd qpdf; then
    local i failed=0
    for i in "${selected_pages[@]}"; do
      local outfile="$outdir/$(basename "$file" .pdf)-p$i.pdf"
      if ! qpdf --pages "$file" "$i" -- "$file" "$outfile"; then
        rm -f "$outfile"
        failed=$((failed + 1))
      fi
    done
    ((failed == 0)) || { uk_error "$failed page split(s) failed."; return 1; }
    uk_success "Split ${#selected_pages[@]} page(s) into $outdir"
  elif uk_has_cmd python3; then
    python3 -c "
import sys, os
try:
    from PyPDF2 import PdfWriter, PdfReader
except ImportError:
    try:
        from pypdf import PdfWriter, PdfReader
    except ImportError:
        sys.exit(1)
file, outdir = sys.argv[1], sys.argv[2]
reader = PdfReader(file)
base = os.path.splitext(os.path.basename(file))[0]
for i, page in enumerate(reader.pages):
    writer = PdfWriter()
    writer.add_page(page)
    out = os.path.join(outdir, f'{base}-p{i+1}.pdf')
    with open(out, 'wb') as f:
        writer.write(f)
print(f'Split {len(reader.pages)} pages')
" "$file" "$outdir" 2>/dev/null || {
      uk_error "Split failed. Install PyPDF2 or pypdf."
      return 1
    }
    uk_success "Split $count pages into $outdir"
  else
    uk_error "No split backend. Install qpdf or PyPDF2."
    return 2
  fi
}

pt_cmd_text() {
  local file="$1" as_json="$2"
  [[ ! -f "$file" ]] && { uk_error "File not found: $file"; return 2; }

  if uk_has_cmd pdftotext; then
    if (( as_json )); then
      local text
      text="$(pdftotext "$file" - 2>/dev/null || true)"
      printf '{"file":%s,"text":%s}\n' "$(pt_json_escape "$file")" "$(printf '%s' "$text" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read(), ensure_ascii=False))' 2>/dev/null || pt_json_escape "$text")"
    else
      pdftotext "$file" - 2>/dev/null || {
        uk_error "Text extraction failed."
        return 1
      }
    fi
  elif uk_has_cmd python3; then
    python3 -c "
import sys
try:
    from PyPDF2 import PdfReader
except ImportError:
    try:
        from pypdf import PdfReader
    except ImportError:
        print('ERR: install PyPDF2 or pypdf', file=sys.stderr)
        sys.exit(1)
file = sys.argv[1]
reader = PdfReader(file)
for page in reader.pages:
    print(page.extract_text() or '')
" "$file" 2>/dev/null || {
      uk_error "Python text extraction failed."
      return 1
    }
  else
    uk_error "No text extraction backend. Install poppler-utils or PyPDF2."
    return 2
  fi
}

pt_cmd_compress() {
  local file="$1" output="$2"
  [[ ! -f "$file" ]] && { uk_error "File not found: $file"; return 2; }
  [[ -z "$output" ]] && output="${file%.pdf}-compressed.pdf"

  if (( PT_APPLY == 0 )); then
    uk_note "Dry-run preview. Would compress to: $output"
    uk_note "Re-run with --apply to write the compressed file."
    return 0
  fi

  if uk_has_cmd gs; then
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
      -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH \
      -sOutputFile="$output" "$file" 2>/dev/null || {
      uk_error "Compression failed."
      return 1
    }
    local orig_size comp_size
    orig_size="$(wc -c <"$file" | tr -d ' ')"
    comp_size="$(wc -c <"$output" | tr -d ' ')"
    local pct=0
    (( orig_size > 0 )) && pct=$(( (comp_size * 100) / orig_size ))
    uk_success "Compressed to ${pct}% of original: $output"
  else
    uk_error "Compression requires ghostscript (gs)."
    return 2
  fi
}

pt_cmd_rotate() {
  local file="$1" deg="$2" output="$3"
  [[ ! -f "$file" ]] && { uk_error "File not found: $file"; return 2; }
  [[ -z "$output" ]] && output="${file%.pdf}-rotated.pdf"
  [[ "$deg" =~ ^(90|180|270)$ ]] || { uk_error "Degrees must be 90, 180, or 270."; return 2; }

  if (( PT_APPLY == 0 )); then
    uk_note "Dry-run preview. Would rotate $deg degrees into: $output"
    uk_note "Re-run with --apply to write the rotated file."
    return 0
  fi

  if uk_has_cmd qpdf; then
    qpdf --rotate="$deg" -- "$file" "$output" 2>/dev/null || {
      uk_error "Rotation failed."
      return 1
    }
    uk_success "Rotated $deg degrees: $output"
  else
    uk_error "Rotation requires qpdf."
    return 2
  fi
}

pt_main() {
  uk_banner "pdf-toolkit" "Merge, split, extract, compress PDFs" "" "$@"

  local sub="" file="" output="" deg="" pages=""
  local -a args=()
  local as_json=0
  PT_APPLY=0

  if [[ $# -gt 0 ]]; then
    case "${1:-}" in
      info|count|merge|split|text|compress|rotate) sub="$1"; shift ;;
      -h|--help) pt_usage; return 0 ;;
    esac
  fi

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --output) shift; output="${1:-}" ;;
      --pages)  shift; pages="${1:-}" ;;
      --apply)  PT_APPLY=1 ;;
      --json)   as_json=1 ;;
      --no-color) UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                  UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help) pt_usage; return 0 ;;
      -*)       uk_error "Unknown option: ${1:-}"; pt_usage; return 2 ;;
      *)        args+=("$1") ;;
    esac
    shift || true
  done

  [[ -z "$sub" ]] && { uk_error "Subcommand required."; pt_usage; return 2; }

  case "$sub" in
    info)  file="${args[0]:-}"; [[ -z "$file" ]] && { uk_error "FILE required."; return 2; }
           pt_cmd_info "$file" "$as_json" ;;
    count) file="${args[0]:-}"; [[ -z "$file" ]] && { uk_error "FILE required."; return 2; }
           pt_cmd_count "$file" "$as_json" ;;
    merge) [[ ${#args[@]} -lt 2 ]] && { uk_error "At least 2 input PDFs required."; return 2; }
           pt_cmd_merge "${args[@]}" --output "$output" ;;
    split) file="${args[0]:-}"; [[ -z "$file" ]] && { uk_error "FILE required."; return 2; }
           [[ -z "$output" ]] && output="./pages"
           pt_cmd_split "$file" "$output" "$pages" ;;
    text)  file="${args[0]:-}"; [[ -z "$file" ]] && { uk_error "FILE required."; return 2; }
           pt_cmd_text "$file" "$as_json" ;;
    compress) file="${args[0]:-}"; [[ -z "$file" ]] && { uk_error "FILE required."; return 2; }
              pt_cmd_compress "$file" "$output" ;;
    rotate) file="${args[0]:-}"; deg="${args[1]:-}"
            [[ -z "$file" ]] && { uk_error "FILE required."; return 2; }
            [[ -z "$deg" ]] && { uk_error "rotate requires DEGREES (90/180/270)."; return 2; }
            pt_cmd_rotate "$file" "$deg" "$output" ;;
    *) pt_usage; return 2 ;;
  esac
}

pt_wizard() {
  uk_banner "pdf-toolkit" "Merge, split, extract, compress PDFs" ""
  local sub file output deg jsonf
  sub="$(uk_prompt 'Action: info, count, merge, split, text, compress, rotate' 'info' \
    'info | count | merge | split | text | compress | rotate' \
    'info = metadata. merge = combine PDFs. split = one per page.')"
  file="$(uk_prompt 'PDF file' './document.pdf' './report.pdf' 'Required for most commands.')"
  file="$(uk_expand_path "$file" 2>/dev/null || printf '%s' "$file")"

  case "$sub" in
    merge)
      local extra
      extra="$(uk_prompt 'Additional PDFs (space-separated)' '' './b.pdf ./c.pdf' 'First file already specified.')"
      if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
      local -a a=(merge "$file" $extra --output "$output")
      [[ -n "$jsonf" ]] && a+=("$jsonf")
      uk_confirm 'Write the merged PDF now?' 'N' && a+=(--apply)
      pt_main "${a[@]}"
      ;;
    split)
      output="$(uk_prompt 'Output directory' './pages' './split' 'Each page becomes a file.')"
      local -a a=(split "$file" --output "$(uk_expand_path "$output" 2>/dev/null || printf '%s' "$output")")
      uk_confirm 'Write the split PDFs now?' 'N' && a+=(--apply)
      pt_main "${a[@]}"
      ;;
    compress)
      output="$(uk_prompt 'Output file (blank = in-place)' '' './compressed.pdf' 'Leave blank to auto-name.')"
      local -a a=(compress "$file")
      [[ -n "$output" ]] && a+=(--output "$output")
      uk_confirm 'Write the compressed PDF now?' 'N' && a+=(--apply)
      pt_main "${a[@]}"
      ;;
    rotate)
      deg="$(uk_prompt 'Degrees: 90, 180, or 270' '90' '180' 'Clockwise rotation.')"
      local -a a=(rotate "$file" "$deg")
      uk_confirm 'Write the rotated PDF now?' 'N' && a+=(--apply)
      pt_main "${a[@]}"
      ;;
    info|count|text)
      if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
      local -a a=("$sub" "$file")
      [[ -n "$jsonf" ]] && a+=("$jsonf")
      pt_main "${a[@]}"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    pt_wizard
  else
    pt_main "$@"
  fi
fi
