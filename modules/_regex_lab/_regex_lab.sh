#!/usr/bin/env bash
# _regex_lab — live regex tester: pattern + sample text, prints matches,
#              named captures, and substitution preview.
# Prefix: rl_
# Backends: perl (preferred) → grep -P → python3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  source "$SCRIPT_DIR/../../lib/uk_common.sh"
fi

# --- Fallback Functions ---
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
# --------------------------

rl_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf 'Usage: _regex_lab.sh PATTERN [TEXT] [OPTIONS]\n'
  printf '       _regex_lab.sh [-f FILE | -i] PATTERN\n\n'
  uk_help_section "$w" "Options" \
    "-p, --pattern PAT" "Regex pattern to test" \
    "-t, --text TEXT" "Sample text to match against" \
    "-f, --file FILE" "Read sample text from FILE" \
    "-i, --stdin" "Read sample text from stdin" \
    "-s, --sub SUB" "Substitution expression (e.g. s/foo/bar/g)" \
    "-m, --multiline" "Treat input as multiline (^/$ match line boundaries)" \
    "-x, --extended" "Extended regex mode (perl-compatible by default)" \
    "-c, --case-insensitive" "Case-insensitive matching" \
    "--color" "Colorize matches in output" \
    "--json" "Machine-readable output" \
    "--no-color" "Disable ANSI (also respects NO_COLOR=1)" \
    "-h, --help" "Show this help"
  printf '\n'
  printf 'Backends tried: perl → grep -P → python3.\n'
  printf '\n'
  printf 'Exit codes:\n'
  printf '  0   matches found (or substitution applied)\n'
  printf '  1   no matches\n'
  printf '  2   argument / dependency error\n'
  printf '\n'
  printf 'Examples:\n'
  printf "  _regex_lab.sh '\\\d+' 'hello 42 world 99'\n"
  printf "  _regex_lab.sh -p '\\\w+' -f /var/log/syslog\n"
  printf "  _regex_lab.sh -p 'foo(bar)' -s 's/foo(bar)/baz\$1/' -t 'foobar qux'\n"
  printf "  echo 'abc123' | _regex_lab.sh -p '[a-z]+' -i\n"
}

# ---- Helpers ---------------------------------------------------------------

rl_hr() {
  printf '%s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
}

rl_section() {
  local title="${1:-}"
  printf '\n%s%s%s%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$title" "${UK_C_RESET:-}"
  rl_hr
}

rl_json_escape() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

rl_detect_backend() {
  if uk_has_cmd perl; then
    printf 'perl\n'; return 0
  fi
  if grep -P '' /dev/null 2>/dev/null; then
    printf 'grep-p\n'; return 0
  fi
  if uk_has_cmd python3; then
    printf 'python3\n'; return 0
  fi
  return 1
}

# ---- Match using perl backend ---------------------------------------------

rl_match_perl() {
  local pattern="$1" text="$2" multiline="$3" case_insensitive="$4" colorize="$5"
  local flags=()
  [[ "$multiline" == "1" ]] && flags+=('-m')
  [[ "$case_insensitive" == "1" ]] && flags+=('-i')
  local color_flag=''
  [[ "$colorize" == "1" ]] && color_flag='--'

  printf '%s' "$text" | perl -w "${flags[@]}" -e '
    my $pat = shift;
    my $color = shift;
    my $ok = 0;
    while (<>) {
      if (/$pat/) {
        $ok = 1;
        if ($color) {
          s/($pat)/\e[31m$1\e[0m/g;
        }
        print;
      }
    }
    exit($ok ? 0 : 1);
  ' -- "$pattern" "$color_flag" 2>/dev/null || true
}

rl_match_perl_json() {
  local pattern="$1" text="$2" multiline="$3" case_insensitive="$4"
  local flags=()
  [[ "$multiline" == "1" ]] && flags+=('-m')
  [[ "$case_insensitive" == "1" ]] && flags+=('-i')

  printf '%s' "$text" | perl "${flags[@]}" -e '
    use strict; use warnings;
    my $pat = shift;
    my @results;
    my $line_no = 0;
    while (my $line = <>) {
      $line_no++;
      while ($line =~ /$pat/g) {
        my $match = $&;
        my $start = pos($line) - length($match);
        my %captures;
        my $i = 1;
        while (exists($-[$i])) {
          $captures{$i} = defined($1) ? $1 : "undef";
          $i++;
        }
        push @results, {
          line     => $line_no,
          match    => $match,
          start    => $start,
          end      => pos($line),
          captures => \%captures,
        };
      }
    }
    print @results ? "ok" : "empty";
    print "\t";
    require JSON; print JSON::to_json(\@results, {utf8 => 1, pretty => 0});
  ' -- "$pattern" 2>/dev/null || printf 'empty\t[]\n'
}

# ---- Match using grep -P backend ------------------------------------------

rl_match_grep_p() {
  local pattern="$1" text="$2" case_insensitive="$3"
  local flags=(-oP)
  [[ "$case_insensitive" == "1" ]] && flags+=('-i')
  printf '%s' "$text" | grep "${flags[@]}" -- "$pattern" 2>/dev/null || true
}

# ---- Match using python3 backend ------------------------------------------

rl_match_python() {
  local pattern="$1" text="$2" multiline="$3" case_insensitive="$4" colorize="$5"
  python3 -c '
import sys, re
pat = sys.argv[1]
text = sys.argv[2]
multiline = sys.argv[3] == "1"
ci = sys.argv[4] == "1"
colorize = sys.argv[5] == "1"
flags = re.MULTILINE if multiline else 0
if ci: flags |= re.IGNORECASE
try:
    rx = re.compile(pat, flags)
except re.error as e:
    print(f"Regex error: {e}", file=sys.stderr)
    sys.exit(2)
found = False
for m in rx.finditer(text):
    found = True
    s = m.group(0)
    if colorize:
        start = m.start()
        end = m.end()
        print(f"{text[:start]}\033[31m{s}\033[0m{text[end:]}")
        break
    else:
        print(s)
sys.exit(0 if found else 1)
' "$pattern" "$text" "$multiline" "$case_insensitive" "$colorize" 2>/dev/null || true
}

rl_match_python_json() {
  local pattern="$1" text="$2" multiline="$3" case_insensitive="$4"
  python3 -c '
import sys, json, re
pat = sys.argv[1]
text = sys.argv[2]
multiline = sys.argv[3] == "1"
ci = sys.argv[4] == "1"
flags = re.MULTILINE if multiline else 0
if ci: flags |= re.IGNORECASE
try:
    rx = re.compile(pat, flags)
except re.error as e:
    print(json.dumps({"ok": False, "error": str(e)}))
    sys.exit(0)
results = []
for m in rx.finditer(text):
    captures = {}
    for i in range(1, len(m.groups()) + 1):
        captures[str(i)] = m.group(i)
    results.append({
        "match": m.group(0),
        "start": m.start(),
        "end": m.end(),
        "captures": captures,
    })
print(json.dumps({"ok": True, "matches": results}, ensure_ascii=False))
' "$pattern" "$text" "$multiline" "$case_insensitive"
}

# ---- Substitution preview --------------------------------------------------

rl_sub_perl() {
  local pattern="$1" sub="$2" text="$3" multiline="$4" case_insensitive="$5"
  local flags=('-pe')
  [[ "$multiline" == "1" ]] && flags+=('-m')
  [[ "$case_insensitive" == "1" ]] && flags+=('-i')

  # Extract the delimiter and build the substitution from the s/// form
  printf '%s' "$text" | perl "${flags[@]}" -e "
    my \$pat = shift;
    my \$sub = shift;
    eval qq{ \$sub = \$sub };
    s/\$pat/\$sub/gr;
  " -- "$pattern" "$sub" 2>/dev/null || printf '%s' "$text"
}

rl_sub_python() {
  local pattern="$1" sub="$2" text="$3" multiline="$4" case_insensitive="$5"
  python3 -c '
import sys, re
pat = sys.argv[1]
sub = sys.argv[2]
text = sys.argv[3]
multiline = sys.argv[4] == "1"
ci = sys.argv[5] == "1"
flags = re.MULTILINE if multiline else 0
if ci: flags |= re.IGNORECASE
try:
    rx = re.compile(pat, flags)
except re.error as e:
    print(f"Regex error: {e}", file=sys.stderr)
    sys.exit(2)
result = rx.sub(sub, text)
print(result)
' "$pattern" "$sub" "$text" "$multiline" "$case_insensitive" 2>/dev/null || printf '%s' "$text"
}

# ---- Main match driver ----------------------------------------------------

rl_run_match() {
  local pattern="$1" text="$2" multiline="$3" case_insensitive="$4" colorize="$5" as_json="$6"

  if ! uk_has_cmd python3; then
    uk_error "regex-lab requires python3 for reliable matching and JSON output."
    return 2
  fi

  local output rc
  if output="$(python3 - "$pattern" "$text" "$multiline" "$case_insensitive" "$colorize" "$as_json" <<'PYREGEX' 2>&1
import json, re, sys
pattern, text = sys.argv[1], sys.argv[2]
multiline = sys.argv[3] == "1"
case_insensitive = sys.argv[4] == "1"
colorize = sys.argv[5] == "1"
as_json = sys.argv[6] == "1"
flags = 0
if multiline:
    flags |= re.MULTILINE
if case_insensitive:
    flags |= re.IGNORECASE
try:
    rx = re.compile(pattern, flags)
except re.error as e:
    if as_json:
        print(json.dumps({"ok": False, "error": str(e), "matches": []}, ensure_ascii=False))
    else:
        print(f"Regex error: {e}", file=sys.stderr)
    sys.exit(2)

matches = []
for line_no, line in enumerate(text.splitlines() or [text], 1):
    for m in rx.finditer(line):
        captures = {str(i): m.group(i) for i in range(1, len(m.groups()) + 1)}
        captures.update({k: v for k, v in m.groupdict().items()})
        matches.append({
            "line": line_no,
            "match": m.group(0),
            "start": m.start(),
            "end": m.end(),
            "captures": captures,
        })

if as_json:
    print(json.dumps({"ok": True, "matches": matches}, ensure_ascii=False))
else:
    if not matches:
        sys.exit(1)
    for i, m in enumerate(matches, 1):
        val = m["match"]
        if colorize:
            val = "\033[31m" + val + "\033[0m"
        cap = ""
        if m["captures"]:
            cap = " captures=" + json.dumps(m["captures"], ensure_ascii=False)
        print(f"[{i}] line {m['line']} span {m['start']}-{m['end']}: {val}{cap}")
sys.exit(0 if matches else 1)
PYREGEX
)"; then
    rc=0
  else
    rc=$?
  fi

  if (( as_json )); then
    printf '%s\n' "$output"
    return "$rc"
  fi

  if (( rc == 2 )); then
    uk_error "$output"
    return 2
  fi

  rl_section "Match results"
  printf '  %spattern:%s %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$pattern"
  printf '  %sbackend:%s python3\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  printf '  %sflags:%s  %s%s%s\n\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" \
    "${UK_C_BOLD:-}" \
    "$([[ "$multiline" == "1" ]] && printf ' multiline')$([[ "$case_insensitive" == "1" ]] && printf ' case-insensitive')" \
    "${UK_C_RESET:-}"

  if (( rc == 1 )); then
    printf '  %s(no matches)%s\n\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"
    return 1
  fi

  local count
  count="$(printf '%s\n' "$output" | grep -c '^\[' || true)"
  printf '  %s%d match(es):%s\n\n' "${UK_C_BOLD:-}${UK_C_GREEN:-}" "$count" "${UK_C_RESET:-}"
  printf '%s\n\n' "$output"
  return 0
}

rl_run_sub() {
  local pattern="$1" sub="$2" text="$3" multiline="$4" case_insensitive="$5" as_json="$6"

  if ! uk_has_cmd python3; then
    uk_error "regex substitution requires python3."
    return 2
  fi

  local output rc
  if output="$(python3 - "$pattern" "$sub" "$text" "$multiline" "$case_insensitive" "$as_json" <<'PYSUB' 2>&1
import json, re, sys
pattern, sub, text = sys.argv[1], sys.argv[2], sys.argv[3]
multiline = sys.argv[4] == "1"
case_insensitive = sys.argv[5] == "1"
as_json = sys.argv[6] == "1"
flags = 0
if multiline:
    flags |= re.MULTILINE
if case_insensitive:
    flags |= re.IGNORECASE

def parse_s_expr(expr):
    if not expr.startswith('s') or len(expr) < 3:
        return None
    delim = expr[1]
    parts = []
    cur = []
    esc = False
    for ch in expr[2:]:
        if esc:
            cur.append(ch); esc = False; continue
        if ch == '\\':
            cur.append(ch); esc = True; continue
        if ch == delim and len(parts) < 2:
            parts.append(''.join(cur)); cur = []; continue
        cur.append(ch)
    if len(parts) != 2:
        return None
    flags_part = ''.join(cur)
    return parts[0], parts[1], flags_part

expr = parse_s_expr(sub)
if expr:
    pattern, replacement, flag_text = expr
    if 'i' in flag_text:
        flags |= re.IGNORECASE
    count = 0 if 'g' in flag_text else 1
else:
    replacement = sub
    count = 0
try:
    rx = re.compile(pattern, flags)
except re.error as e:
    if as_json:
        print(json.dumps({"ok": False, "error": str(e)}))
    else:
        print(f"Regex error: {e}", file=sys.stderr)
    sys.exit(2)
try:
    result, n = rx.subn(replacement, text, count=count)
except re.error as e:
    if as_json:
        print(json.dumps({"ok": False, "error": str(e)}))
    else:
        print(f"Substitution error: {e}", file=sys.stderr)
    sys.exit(2)
if as_json:
    print(json.dumps({"ok": True, "input": text, "pattern": pattern, "substitution": sub, "replacements": n, "result": result}, ensure_ascii=False))
else:
    print(result)
sys.exit(0)
PYSUB
)"; then
    rc=0
  else
    rc=$?
  fi

  if (( as_json )); then
    printf '%s\n' "$output"
    return "$rc"
  fi
  if (( rc != 0 )); then
    uk_error "$output"
    return "$rc"
  fi

  rl_section "Substitution preview"
  printf '  %spattern:%s      %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$pattern"
  printf '  %ssubstitution:%s  %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$sub"
  printf '  %sbackend:%s       python3\n\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}"

  printf '  %sBefore:%s  %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$text"
  printf '  %sAfter:%s   %s%s%s\n\n' \
    "${UK_C_BOLD:-}${UK_C_GREEN:-}" "${UK_C_RESET:-}" \
    "${UK_C_BOLD:-}" "$output" "${UK_C_RESET:-}"
}

# ---- Main ------------------------------------------------------------------

rl_main() {
  uk_banner "regex-lab" "Live regex tester with match + substitution preview" "" "$@"

  local pattern="" text="" text_file=""
  local use_stdin=0 multiline=0 case_insensitive=0 colorize=0 as_json=0
  local sub=""

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      -p|--pattern)  shift; pattern="${1:-}" ;;
      -t|--text)     shift; text="${1:-}" ;;
      -f|--file)     shift; text_file="${1:-}" ;;
      -i|--stdin)    use_stdin=1 ;;
      -s|--sub)      shift; sub="${1:-}" ;;
      -m|--multiline) multiline=1 ;;
      -x|--extended) ;;
      -c|--case-insensitive) case_insensitive=1 ;;
      --color)       colorize=1 ;;
      --json)        as_json=1 ;;
      --no-color)    UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                     UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help)     rl_usage; return 0 ;;
      -*)            uk_error "Unknown option: ${1:-}"; rl_usage; return 2 ;;
      *)
        if [[ -z "$pattern" ]]; then
          pattern="${1:-}"
        elif [[ -z "$text" ]]; then
          text="${1:-}"
        fi
        ;;
    esac
    shift || true
  done

  # Read text from file or stdin
  if [[ -n "$text_file" ]]; then
    if [[ ! -f "$text_file" ]]; then
      uk_error "File not found: $text_file"
      return 2
    fi
    text="$(cat "$text_file")"
  elif (( use_stdin )); then
    if [[ ! -t 0 ]]; then
      text="$(cat)"
    else
      uk_error "No stdin data. Pipe input or use -t/--text."
      return 2
    fi
  fi

  [[ -z "$pattern" ]] && { uk_error "Pattern required."; rl_usage; return 2; }
  [[ -z "$text" && -z "$sub" ]] && { uk_error "Text required. Use -t, -f, -i, or positional arg."; rl_usage; return 2; }

  if [[ -n "$sub" ]]; then
    rl_run_sub "$pattern" "$sub" "$text" "$multiline" "$case_insensitive" "$as_json"
    return $?
  fi

  rl_run_match "$pattern" "$text" "$multiline" "$case_insensitive" "$colorize" "$as_json"
}

rl_wizard() {
  uk_banner "regex-lab" "Live regex tester with match + substitution preview" ""
  local mode pattern text file multiline ci sub jsonf

  mode="$(uk_prompt 'Mode: match, substitute, or file' 'match' \
    'match | substitute | file' \
    'match prints matches. substitute transforms text. file reads from a file.')"

  pattern="$(uk_prompt 'Regex pattern' '\d+' '[a-z]+' 'Perl-compatible syntax.')"

  if [[ "$mode" == "file" ]]; then
    file="$(uk_prompt 'File path' '/var/log/syslog' './test.txt' 'Will read entire file into memory.')"
    file="$(uk_expand_path "$file" 2>/dev/null || printf '%s' "$file")"
    text_flag="-f"
    text_val="$file"
  else
    text="$(uk_prompt 'Sample text' 'hello 42 world 99' 'The quick brown fox' 'Text to test the pattern against.')"
    text_flag="-t"
    text_val="$text"
  fi

  if [[ "$mode" == "substitute" ]]; then
    sub="$(uk_prompt 'Substitution (e.g. s/foo/bar/g)' 's/\d+/[N]/g' 's/(\w+)/\U$1/' 'Perl s/// syntax.')"
  else
    sub=""
  fi

  if uk_confirm 'Multiline mode?' 'N'; then multiline="-m"; else multiline=""; fi
  if uk_confirm 'Case-insensitive?' 'N'; then ci="-c"; else ci=""; fi
  if uk_confirm 'Colorize output?' 'N'; then colorize="--color"; else colorize=""; fi
  if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi

  local -a a=(-p "$pattern" "$text_flag" "$text_val")
  [[ -n "$sub"      ]] && a+=(-s "$sub")
  [[ -n "$multiline" ]] && a+=("$multiline")
  [[ -n "$ci"       ]] && a+=("$ci")
  [[ -n "$colorize" ]] && a+=("$colorize")
  [[ -n "$jsonf"    ]] && a+=("$jsonf")
  rl_main "${a[@]}"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    rl_wizard
  else
    rl_main "$@"
  fi
fi
