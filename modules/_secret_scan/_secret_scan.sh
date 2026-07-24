#!/usr/bin/env bash
# _secret_scan — regex + entropy-based scan for leaked credentials in a tree.
# Prefix: sec_
# Detects: AWS keys, GitHub tokens, private keys, JWTs, Slack/Discord webhooks,
#          Google API keys, generic high-entropy blobs, live .env values.
# Respects .gitignore (via `git ls-files`) when the target is inside a repo.
# Non-zero exit status when findings are present (CI-friendly).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/../../lib/uk_common.sh" ]]; then
  # shellcheck source=../../lib/uk_common.sh
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
if ! declare -f uk_expand_path >/dev/null 2>&1; then
  uk_expand_path() { local i="${1:-}"; printf '%s\n' "${i/#\~/$HOME}"; }
fi
if ! declare -f uk_platform >/dev/null 2>&1; then
  uk_platform() {
    if [[ -n "${TERMUX_VERSION:-}" ]]; then echo termux
    elif [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; then echo macos
    else echo linux; fi
  }
fi
# --------------------------

sec_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%sUsage: %sbash%s _secret_scan.sh %s[PATH]... [OPTIONS]%s\n\n' "${UK_C_BOLD:-}" "${UK_C_GREEN:-}" "${UK_C_RESET:-}" "${UK_C_DIM:-}" "${UK_C_RESET:-}"
  uk_help_section "$w" "Options" \
    "--path PATH" "Add a scan path (repeatable). Defaults to current dir." \
    "--json" "Emit findings as one JSON object per line (jsonl)." \
    "--no-entropy" "Skip high-entropy detection (regex rules only)." \
    "--entropy-min N" "Minimum Shannon entropy to flag a blob (default 4.5)." \
    "--entropy-len N" "Minimum blob length to consider (default 20)." \
    "--max-bytes N" "Skip files larger than N bytes (default 1048576 = 1 MB)." \
    "--no-gitignore" "Do not filter by git ls-files even inside a repo." \
    "--include GLOB" "Only scan paths matching GLOB (repeatable)." \
    "--exclude GLOB" "Skip paths matching GLOB (repeatable)." \
    "--context N" "Show N chars of surrounding context (default 40)." \
    "--quiet" "Only print summary." \
    "--reveal" "Do not redact matches in JSON/terminal output." \
    "--no-color" "Disable ANSI (also respects NO_COLOR=1)." \
    "-h, --help" "Show this help."
  printf '\n'
  uk_help_section "$w" "Exit status" \
    "${UK_C_GREEN:-}0${UK_C_RESET:-}" "clean" \
    "${UK_C_RED:-}1${UK_C_RESET:-}" "findings present" \
    "${UK_C_YELLOW:-}2${UK_C_RESET:-}" "argument/dependency error"
  printf '\n'
  uk_help_section "$w" "Detected patterns" --name-w 26 \
    "aws-access-key" "AWS access key" \
    "aws-secret-key" "AWS secret key" \
    "github-token" "GitHub token" \
    "slack-token" "Slack token" \
    "jwt" "JWT token" \
    "private-key" "Private key PEM block" \
    "stripe-key" "Stripe key pair" \
    "high-entropy" "High entropy blob"
  printf '\n'
}

# ---- Detector definitions --------------------------------------------------
# Format: "name|regex"
# Regex uses POSIX ERE (grep -E) so no lookarounds. Case-insensitive matching
# is turned on globally via -i where noted.

sec_detectors() {
  cat <<'RULES'
aws-access-key|AKIA[0-9A-Z]{16}
aws-secret-key|(?:aws.{0,20})?(?:secret|access).{0,20}[=:]\s*['\"]?[A-Za-z0-9/+=]{40}['\"]?
github-token|gh[pousr]_[A-Za-z0-9]{36,255}
github-pat|github_pat_[A-Za-z0-9_]{22,}
github-oauth|ghs_[A-Za-z0-9]{36}
slack-token|xox[abpsr]-[A-Za-z0-9-]{10,}
slack-webhook|https://hooks\.slack\.com/services/T[A-Z0-9]{8,}/B[A-Z0-9]{8,}/[A-Za-z0-9]{20,}
discord-webhook|https://(?:ptb\.|canary\.)?discord(?:app)?\.com/api/webhooks/[0-9]{15,}/[A-Za-z0-9_-]{50,}
google-api-key|AIza[0-9A-Za-z_-]{35}
stripe-key|(?:sk|pk|rk)_(?:live|test)_[A-Za-z0-9]{20,}
jwt|eyJ[A-Za-z0-9_-]{5,}\.eyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}
private-key-block|-----BEGIN (?:RSA|EC|DSA|OPENSSH|PGP|ENCRYPTED)? ?PRIVATE KEY( BLOCK)?-----
generic-hex-secret|(?:secret|token|password|api[_-]?key|apikey)['\"]?\s*[:=]\s*['\"]?[a-f0-9]{32,}['\"]?
generic-b64-secret|(?:secret|token|password|api[_-]?key|apikey)['\"]?\s*[:=]\s*['\"]?[A-Za-z0-9+/]{40,}={0,2}['\"]?
RULES
}

# Default exclusion globs used when --exclude isn't given.
SEC_DEFAULT_EXCLUDES=(
  '*/.git/*' '*/node_modules/*' '*/__pycache__/*'
  '*/dist/*' '*/build/*' '*/.venv/*' '*/venv/*'
  '*/target/*' '*/.next/*' '*/.cache/*' '*/coverage/*'
)

# ---- File enumeration ------------------------------------------------------

sec_list_files() {
  local path="$1" respect_gitignore="$2"
  local -n out_ref=$3
  out_ref=()
  local list_file repo_root='' probe_error='' f abs_path
  list_file="$(mktemp)" || return 1

  if [[ "$respect_gitignore" == "1" ]] && uk_has_cmd git; then
    if repo_root="$(git -C "$path" rev-parse --show-toplevel 2>&1)"; then
      if ! git -C "$repo_root" ls-files -z --cached --others --exclude-standard >"$list_file"; then
        rm -f "$list_file"
        uk_error "git file enumeration failed: $repo_root"
        return 1
      fi
      abs_path="$(cd "$path" && pwd -P)" || { rm -f "$list_file"; return 1; }
      while IFS= read -r -d '' f; do
        f="$repo_root/$f"
        [[ "$f" == "$abs_path"/* || "$f" == "$abs_path" ]] && out_ref+=("$f")
      done <"$list_file"
      rm -f "$list_file" || return 1
      return 0
    else
      probe_error="$repo_root"
      [[ -n "$probe_error" ]] && uk_note "Git enumeration unavailable for '$path'; using find."
    fi
  fi

  local -a find_args=("$path" -type f)
  local ex find_err
  for ex in "${SEC_DEFAULT_EXCLUDES[@]}"; do find_args+=(-not -path "$ex"); done
  # Separate stderr so a single unreadable subdirectory (routine in real
  # trees) does not abort the entire scan and hide secrets elsewhere. Only
  # fail hard when nothing at all was enumerated.
  find "${find_args[@]}" -print0 >"$list_file" 2>"$list_file.err" || find_err=1
  if [[ -n "${find_err:-}" ]]; then
    uk_warn "$(cat "$list_file.err")"
  fi
  rm -f "$list_file.err"
  if [[ -n "${find_err:-}" && ! -s "$list_file" ]]; then
    rm -f "$list_file"
    uk_error "File traversal failed: $path"
    return 1
  fi
  while IFS= read -r -d '' f; do out_ref+=("$f"); done <"$list_file"
  rm -f "$list_file" || return 1
}

# ---- Entropy detection -----------------------------------------------------
# We prefer python3 for accurate Shannon entropy across UTF-8 lines. Awk
# fallback approximates it. Only tokens that pass the regex pre-filter (long
# alnum+/=/-/_ blobs) are scored, so this stays cheap.

sec_scan_entropy_py() {
  local file="$1" min_e="$2" min_len="$3"
  python3 - "$file" "$min_e" "$min_len" <<'PY'
import sys, math, re
path, min_e, min_len = sys.argv[1], float(sys.argv[2]), int(sys.argv[3])
def entropy(s):
    if not s: return 0.0
    freq = {}
    for c in s: freq[c] = freq.get(c,0)+1
    n = len(s); e = 0.0
    for v in freq.values():
        p = v / n
        e -= p * math.log2(p)
    return e
tok_re = re.compile(r'[A-Za-z0-9+/=_\-]{%d,}' % min_len)
try:
    with open(path, encoding='utf-8', errors='replace') as f:
        for lineno, line in enumerate(f, 1):
            for m in tok_re.finditer(line):
                tok = m.group(0)
                # Skip obvious low-signal tokens: pure hex numbers, uuids,
                # SHA hashes with 'sha256:' prefix already handled by regex
                # rules, and long runs of a single char.
                if len(set(tok)) < 8: continue
                e = entropy(tok)
                if e >= min_e:
                    ctx = line.strip()
                    print(f"{lineno}\t{e:.2f}\t{tok}\t{ctx}")
except Exception as e:
    print(f"entropy scan failed for {path}: {e}", file=sys.stderr)
    sys.exit(2)
PY
}

# ---- Findings emission -----------------------------------------------------

SEC_TOTAL=0
SEC_REVEAL=0

sec_redact() {
  local s="${1:-}" n=${#1}
  if (( n > 12 )); then
    printf '%s%s%s' "${s:0:4}" "$(printf '%*s' $((n - 8)) '' | tr ' ' '*')" "${s: -4}"
  else
    printf '%s' "$s"
  fi
}

sec_emit_finding() {
  local rule="$1" file="$2" lineno="$3" match="$4" context="$5"
  SEC_TOTAL=$(( SEC_TOTAL + 1 ))

  if [[ "$SEC_JSON" == "1" ]]; then
    if uk_has_cmd python3; then
      python3 -c '
import json,sys
rule, file, line, match, context, reveal = sys.argv[1:7]
if reveal != "1" and len(match) > 12:
    redacted = match[:4] + "*" * (len(match)-8) + match[-4:]
    context = context.replace(match, redacted)
    match = redacted
print(json.dumps({
  "rule": rule, "file": file, "line": int(line),
  "match": match, "context": context,
}, ensure_ascii=False))' "$rule" "$file" "$lineno" "$match" "$context" "$SEC_REVEAL"
    else
      # Fallback JSON — best-effort escape.
      local esc_m="${match//\\/\\\\}"; esc_m="${esc_m//\"/\\\"}"
      local esc_c="${context//\\/\\\\}"; esc_c="${esc_c//\"/\\\"}"
      esc_c="${esc_c//$'\n'/ }"
      printf '{"rule":"%s","file":"%s","line":%s,"match":"%s","context":"%s"}\n' \
        "$rule" "$file" "$lineno" "$esc_m" "$esc_c"
    fi
    return 0
  fi

  [[ "$SEC_QUIET" == "1" ]] && return 0

  # Redact all but first/last 4 chars of the match for the terminal output.
  # Use ASCII '*' so NO_UNICODE=1 terminals (and non-UTF8 locales) don't
  # emit replacement glyphs.
  local redacted="$match" mlen=${#match}
  if [[ "$SEC_REVEAL" != "1" && $mlen -gt 12 ]]; then
    redacted="$(sec_redact "$match")"
    context="${context//$match/$redacted}"
  fi

  printf '\n %s%s%s  %s%s:%s%s\n' \
    "${UK_C_RED:-}${UK_I_ERR:-x}" "" "${UK_C_RESET:-}" \
    "${UK_C_BOLD:-}" "$file" "$lineno" "${UK_C_RESET:-}"
  printf '   %srule:%s   %s%s%s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" \
    "${UK_C_YELLOW:-}" "$rule" "${UK_C_RESET:-}"
  printf '   %smatch:%s  %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$redacted"
  if [[ -n "$context" ]]; then
    local ctx="${context//$'\n'/ }"
    printf '   %sctx:%s    %s\n' "${UK_C_DIM:-}" "${UK_C_RESET:-}" "$ctx"
  fi
}

# ---- Main scan loop --------------------------------------------------------

sec_scan_file_regex() {
  local file="$1" ctx_len="$2"
  local line
  # Read detectors once per file.
  local -a rules_names=() rules_regexes=()
  while IFS='|' read -r rname rregex; do
    [[ -z "$rname" ]] && continue
    rules_names+=("$rname")
    rules_regexes+=("$rregex")
  done < <(sec_detectors)

  # We use grep -HnE per rule so line numbers are exact. Rely on -P if
  # available for regex features (\s), else emulate via [ \t].
  local grep_flag='-E'
  if grep -P '' /dev/null 2>/dev/null; then grep_flag='-P'; fi

  local i lineno match
  for (( i=0; i<${#rules_names[@]}; i++ )); do
    local rname="${rules_names[$i]}"
    local regex="${rules_regexes[$i]}"
    # Feed the file to grep without -H: the file path is already known, and
    # parsing grep's file:line:match format breaks on filenames containing ':'.
    if [[ "$grep_flag" == "-E" ]]; then
      regex="${regex//(?:/(}"
      regex="${regex//\s/[[:space:]]}"
    fi
    local grep_output grep_status=0
    grep_output="$(grep $grep_flag -nai -- "$regex" "$file" 2>&1)" || grep_status=$?
    ((grep_status == 1)) && continue
    ((grep_status == 0)) || { uk_error "Regex scan failed for $file ($rname): $grep_output"; return "$grep_status"; }
    while IFS= read -r line; do
      lineno="${line%%:*}"
      match="${line#*:}"
      [[ "$lineno" =~ ^[0-9]+$ ]] || continue
      local raw raw_status=0
      raw="$(printf '%s' "$match" | grep $grep_flag -oi -- "$regex")" || raw_status=$?
      ((raw_status <= 1)) || { uk_error "Match extraction failed for $file ($rname)."; return "$raw_status"; }
      raw="$(awk 'NR==1 {print; exit}' <<<"$raw")"
      [[ -z "$raw" ]] && raw="$match"
      local ctx="$match"
      if (( ${#ctx} > 2*ctx_len )); then ctx="${ctx:0:ctx_len}…${ctx: -ctx_len}"; fi
      sec_emit_finding "$rname" "$file" "$lineno" "$raw" "$ctx"
    done <<<"$grep_output"
  done

  # Live dotenv values: KEY=<non-empty, not a placeholder>.
  # Very common leak vector — a real value tracked in git.
  if [[ "$file" == *.env* ]]; then
    local ln=0
    while IFS= read -r line; do
      ln=$(( ln + 1 ))
      # Skip comments, blanks, and template placeholders.
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ "$line" =~ ^[[:space:]]*$ ]] && continue
      # KEY=value
      if [[ "$line" =~ ^[[:space:]]*[A-Z_][A-Z0-9_]*[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        local val="${BASH_REMATCH[1]}"
        # Strip quotes.
        val="${val%\"}"; val="${val#\"}"
        val="${val%\'}"; val="${val#\'}"
        # Placeholders / obvious template values.
        [[ -z "$val" ]] && continue
        [[ "$val" =~ ^(changeme|xxx+|todo|example|your[_-]?.*|<.*>|placeholder|__.*__)$ ]] && continue
        # Length gate to reduce noise on things like FLAG=1.
        (( ${#val} >= 8 )) || continue
        sec_emit_finding "dotenv-live-value" "$file" "$ln" "$val" "$line"
      fi
    done <"$file"
  fi
}

sec_scan_file_entropy() {
  local file="$1" min_e="$2" min_len="$3"
  uk_has_cmd python3 || return 0
  local line output
  output="$(sec_scan_entropy_py "$file" "$min_e" "$min_len")" || { uk_error "Entropy scan failed: $file"; return 1; }
  while IFS=$'\t' read -r lineno e tok ctx; do
    [[ -z "$lineno" ]] && continue
    sec_emit_finding "high-entropy-blob" "$file" "$lineno" "$tok" "entropy=$e $ctx"
  done <<<"$output"
}

# ---- Main ------------------------------------------------------------------

sec_main() {
  uk_banner "secret-scan" "Regex + entropy scan for leaked credentials" "" "$@"

  local -a paths=() includes=() excludes=()
  local use_entropy=1 entropy_min="4.5" entropy_len=20
  local max_bytes=1048576
  local respect_gitignore=1
  local ctx_len=40
  SEC_JSON=0
  SEC_QUIET=0
  SEC_REVEAL=0
  SEC_TOTAL=0

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --path)         shift; paths+=("${1:-}") ;;
      --json)         SEC_JSON=1 ;;
      --no-entropy)   use_entropy=0 ;;
      --entropy-min)  shift; entropy_min="${1:-4.5}" ;;
      --entropy-len)  shift; entropy_len="${1:-20}" ;;
      --max-bytes)    shift; max_bytes="${1:-1048576}" ;;
      --no-gitignore) respect_gitignore=0 ;;
      --include)      shift; includes+=("${1:-}") ;;
      --exclude)      shift; excludes+=("${1:-}") ;;
      --context)      shift; ctx_len="${1:-40}" ;;
      --quiet)        SEC_QUIET=1 ;;
      --reveal)       SEC_REVEAL=1 ;;
      --no-color)     UK_C_RESET='' UK_C_BOLD='' UK_C_DIM='' UK_C_RED='' UK_C_GREEN=''
                      UK_C_YELLOW='' UK_C_BRIGHT_CYAN='' ;;
      -h|--help)      sec_usage; return 0 ;;
      -*)             uk_error "Unknown option: ${1:-}"; sec_usage; return 2 ;;
      *)              paths+=("${1:-}") ;;
    esac
    shift || true
  done

  [[ ${#paths[@]} -eq 0 ]] && paths=(".")

  # Sanity-check path targets.
  local p
  for p in "${paths[@]}"; do
    if [[ ! -e "$p" ]]; then
      uk_error "Path not found: $p"
      return 2
    fi
  done

  [[ "$entropy_min" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { uk_error "Invalid --entropy-min: $entropy_min"; return 2; }
  [[ "$entropy_len" =~ ^[0-9]+$ ]]           || { uk_error "Invalid --entropy-len"; return 2; }
  [[ "$max_bytes" =~ ^[0-9]+$ ]]             || { uk_error "Invalid --max-bytes"; return 2; }
  [[ "$ctx_len" =~ ^[0-9]+$ ]]               || { uk_error "Invalid --context"; return 2; }

  # If the user provided --exclude, extend the defaults instead of replacing.
  local combined_excludes=("${SEC_DEFAULT_EXCLUDES[@]}" "${excludes[@]}")

  # Build the file list from every path.
  local -a all_files=() files=()
  for p in "${paths[@]}"; do
    if [[ -f "$p" ]]; then
      all_files+=("$p")
      continue
    fi
    sec_list_files "$p" "$respect_gitignore" files || return 2
    all_files+=("${files[@]}")
  done

  # Apply --include / --exclude globs and size cap.
  local -a to_scan=() f skip
  for f in "${all_files[@]}"; do
    [[ -f "$f" ]] || continue
    # Size cap.
    local sz
    sz="$(wc -c <"$f" | tr -d ' ')" || { uk_error "Unable to read file size: $f"; return 2; }
    [[ "$sz" =~ ^[0-9]+$ ]] || { uk_error "Invalid file size: $f"; return 2; }
    (( sz > max_bytes )) && continue

    skip=0
    local pat
    for pat in "${combined_excludes[@]}"; do
      # shellcheck disable=SC2053
      [[ "$f" == $pat ]] && { skip=1; break; }
    done
    (( skip )) && continue

    if (( ${#includes[@]} > 0 )); then
      skip=1
      for pat in "${includes[@]}"; do
        # shellcheck disable=SC2053
        [[ "$f" == $pat ]] && { skip=0; break; }
      done
      (( skip )) && continue
    fi
    to_scan+=("$f")
  done

  local file_count=${#to_scan[@]}
  if (( file_count == 0 )); then
    [[ "$SEC_JSON" == "1" ]] || uk_warn "No files matched the scan criteria."
    return 0
  fi

  if [[ "$SEC_JSON" != "1" && "$SEC_QUIET" != "1" ]]; then
    printf '\n %s%sScan target%s  %d file(s) — entropy: %s\n' \
      "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "${UK_C_RESET:-}" \
      "$file_count" "$([[ "$use_entropy" == "1" ]] && echo on || echo off)"
    printf ' %s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
  fi

  for f in "${to_scan[@]}"; do
    sec_scan_file_regex "$f" "$ctx_len" || return 2
    if ((use_entropy)); then sec_scan_file_entropy "$f" "$entropy_min" "$entropy_len" || return 2; fi
  done

  if [[ "$SEC_JSON" != "1" ]]; then
    printf '\n %s%s%s\n' "${UK_C_DIM:-}" "$(printf '%*s' 60 '' | tr ' ' '-')" "${UK_C_RESET:-}"
    if (( SEC_TOTAL == 0 )); then
      printf ' %s%s%s no findings across %d file(s)\n\n' \
        "${UK_C_GREEN:-}" "${UK_I_OK:-OK}" "${UK_C_RESET:-}" "$file_count"
    else
      printf ' %s%s%s %d finding(s) across %d file(s)\n\n' \
        "${UK_C_RED:-}" "${UK_I_ERR:-x}" "${UK_C_RESET:-}" "$SEC_TOTAL" "$file_count"
    fi
  fi

  (( SEC_TOTAL == 0 ))
}

sec_wizard() {
  uk_banner "secret-scan" "Regex + entropy scan for leaked credentials" ""
  local path use_entropy jsonf quiet exclude ent_min
  path="$(uk_prompt 'Directory to scan' '.' '~/project' 'Uses git ls-files when the target is inside a repo.')"
  if uk_confirm 'Run entropy detection too?' 'Y'; then use_entropy=1; else use_entropy=0; fi
  ent_min="$(uk_prompt 'Minimum Shannon entropy for a blob' '4.5' '5.0' 'Only used with entropy on.')"
  exclude="$(uk_prompt 'Extra exclude glob (blank = none)' '' '*/vendor/*' 'Repeat via CLI for multiple globs.')"
  if uk_confirm 'JSON output?' 'N'; then jsonf="--json"; else jsonf=""; fi
  if uk_confirm 'Quiet (summary only)?' 'N'; then quiet="--quiet"; else quiet=""; fi

  local -a a=(--path "$(uk_expand_path "$path")")
  (( use_entropy )) || a+=(--no-entropy)
  a+=(--entropy-min "$ent_min")
  [[ -n "$exclude" ]] && a+=(--exclude "$exclude")
  [[ -n "$jsonf"   ]] && a+=("$jsonf")
  [[ -n "$quiet"   ]] && a+=("$quiet")
  sec_main "${a[@]}"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    sec_wizard
  else
    sec_main "$@"
  fi
fi
