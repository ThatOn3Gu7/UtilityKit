#!/usr/bin/env bash
# _clipboard_history — persistent clipboard history with fuzzy search + pin support.
# Prefix: ch_
# Storage: ${XDG_DATA_HOME:-~/.local/share}/utilitykit/clipboard.jsonl
# Format:  one JSON object per line: {"t":<epoch>,"pin":<0|1>,"data":"<text>"}
# Backends: uk_common's uk_copy_to_clipboard / uk_pick_clipboard_cmd (already
#           wraps wl-copy, xclip, pbcopy, termux-clipboard-set, clip.exe).
# Read-side uses a symmetric list: wl-paste, xclip -o, pbpaste,
# termux-clipboard-get, powershell Get-Clipboard.

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
if ! declare -f uk_data_dir >/dev/null 2>&1; then
  uk_data_dir() {
    local d="${XDG_DATA_HOME:-$HOME/.local/share}/utilitykit"
    mkdir -p "$d"
    printf '%s\n' "$d"
  }
fi
# --------------------------

CH_STORE=""
CH_MAX_DEFAULT=200
CH_MAX_PREVIEW=80

ch_usage() {
  cat <<'USAGE'
Usage:
  _clipboard_history.sh <subcommand> [OPTIONS]

Subcommands:
  add [TEXT]              Add TEXT (or piped stdin, or current clipboard) to history.
  list                    List entries (newest first).
  get N|--last            Copy entry N (1-indexed) back to the clipboard.
  show N|--last           Print entry N without touching the clipboard.
  find PATTERN            Case-insensitive substring/regex search.
  pin N                   Pin entry so trimming won't drop it.
  unpin N                 Unpin entry.
  remove N                Remove entry.
  clear [--force]         Remove ALL entries (asks confirmation without --force).
  path                    Print the on-disk store path.

Options:
  --max N          Cap history to N entries (default 200). Pins are never dropped.
  --no-clip        Skip actually writing to the OS clipboard (add/get).
  --json           Machine-readable output (list, find, show).
  --quiet          Suppress info output.
  -h, --help       Show this help.

Examples:
  echo "hello" | _clipboard_history.sh add
  _clipboard_history.sh add "quick note"
  _clipboard_history.sh add                # capture whatever's on the clipboard
  _clipboard_history.sh list --json
  _clipboard_history.sh find TODO
  _clipboard_history.sh get 1              # copy most recent
  _clipboard_history.sh pin 3
USAGE
}

# ---- Storage helpers -------------------------------------------------------

ch_init_store() {
  local data_dir
  data_dir="$(uk_data_dir)" || return 1
  CH_STORE="$data_dir/clipboard.jsonl"
  if [[ ! -f "$CH_STORE" ]]; then
    (umask 077; : > "$CH_STORE") || { uk_error "Cannot create store: $CH_STORE"; return 1; }
  fi
  chmod 600 "$CH_STORE" || { uk_error "Cannot secure clipboard store: $CH_STORE"; return 1; }
}

# JSON-escape a string using Python if available (handles UTF-8 + control chars
# correctly), otherwise a hand-rolled escaper that covers the four required
# JSON escapes plus newlines/tabs.
ch_json_esc() {
  local s="${1:-}"
  if uk_has_cmd python3; then
    python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1], ensure_ascii=False))' "$s"
  else
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '"%s"' "$s"
  fi
}

# JSON-decode the "data" field of a jsonl line.
ch_json_get_data() {
  local line="$1"
  if uk_has_cmd python3; then
    python3 -c '
import json, sys
try:
    print(json.loads(sys.argv[1])["data"], end="")
except Exception as e:
    print(f"invalid clipboard record: {e}", file=sys.stderr)
    sys.exit(1)
' "$line"
  else
    # Fallback: strip prefix + suffix around "data":"..." — best-effort only.
    local data="${line#*\"data\":}"
    data="${data#\"}"
    data="${data%\"*}"
    data="${data//\\n/$'\n'}"
    data="${data//\\t/$'\t'}"
    data="${data//\\\"/\"}"
    data="${data//\\\\/\\}"
    printf '%s' "$data"
  fi
}

ch_json_get_field() {
  # $1 = jsonl line, $2 = field name (numeric or boolean)
  local line="$1" field="$2"
  if uk_has_cmd python3; then
    python3 -c '
import json, sys
try:
    print(json.loads(sys.argv[1]).get(sys.argv[2], ""), end="")
except Exception as e:
    print(f"invalid clipboard record: {e}", file=sys.stderr)
    sys.exit(1)
' "$line" "$field"
  else
    # naive: look for "field":<value>
    local rest="${line#*\"$field\":}"
    rest="${rest%%,*}"
    rest="${rest%%\}*}"
    printf '%s' "$rest"
  fi
}

ch_line_count() { [[ -f "$CH_STORE" ]] && wc -l <"$CH_STORE" | tr -d ' ' || printf '0\n'; }

ch_trim_to_max() {
  local max="${1:-$CH_MAX_DEFAULT}"
  [[ -f "$CH_STORE" ]] || return 0
  local total
  total="$(ch_line_count)"
  (( total <= max )) && return 0

  local tmp
  tmp="$(mktemp "${CH_STORE}.trim.XXXXXX")" || return 1
  # Keep: all pinned lines, plus most recent (max - pinned) unpinned lines.
  # File is append-only, so newest lines are at the bottom.
  if uk_has_cmd python3; then
    local rc=0
    python3 - "$CH_STORE" "$max" "$tmp" <<'PY' || rc=$?
import json, sys
store, max_keep, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
lines = []
with open(store, encoding='utf-8', errors='replace') as f:
    for l in f:
        l = l.rstrip('\n')
        if not l: continue
        try: obj = json.loads(l)
        except Exception as e:
            raise SystemExit(f"invalid clipboard record: {e}")
        lines.append((obj, l))
pinned   = [l for o, l in lines if o.get('pin')]
unpinned = [l for o, l in lines if not o.get('pin')]
budget   = max(0, max_keep - len(pinned))
unpinned = unpinned[-budget:] if budget > 0 else []
kept = []
kept.extend(pinned)
kept.extend(unpinned)
# Preserve original insertion order for kept lines.
order = {l:i for i,(_,l) in enumerate(lines)}
kept.sort(key=lambda l: order.get(l, 0))
with open(out, 'w', encoding='utf-8') as f:
    for l in kept:
        f.write(l + '\n')
PY
    if ((rc != 0)); then
      rm -f "$tmp"
      uk_error 'Clipboard store contains a malformed record; trim aborted without rewriting it.'
      return 1
    fi
    mv "$tmp" "$CH_STORE" || { rm -f "$tmp"; return 1; }
  else
    # awk fallback — keeps last $max lines including pins.
    tail -n "$max" "$CH_STORE" >"$tmp" || { rm -f "$tmp"; return 1; }
    mv "$tmp" "$CH_STORE" || { rm -f "$tmp"; return 1; }
  fi
  chmod 600 "$CH_STORE" || { uk_error "Cannot secure clipboard store: $CH_STORE"; return 1; }
}

# ---- Clipboard read/write (system) -----------------------------------------

ch_read_clipboard() {
  if uk_has_cmd wl-paste;              then wl-paste 2>/dev/null;              return
  elif uk_has_cmd xclip;               then xclip -selection clipboard -o 2>/dev/null; return
  elif uk_has_cmd pbpaste;             then pbpaste 2>/dev/null;               return
  elif uk_has_cmd termux-clipboard-get; then termux-clipboard-get 2>/dev/null; return
  elif uk_has_cmd powershell.exe;      then powershell.exe -NoProfile -Command Get-Clipboard 2>/dev/null; return
  fi
  return 1
}

ch_write_clipboard() {
  if declare -f uk_copy_to_clipboard >/dev/null 2>&1; then
    uk_copy_to_clipboard "$1"
    return $?
  fi
  local text="$1"
  if   uk_has_cmd wl-copy;              then printf '%s' "$text" | wl-copy
  elif uk_has_cmd xclip;                then printf '%s' "$text" | xclip -selection clipboard
  elif uk_has_cmd pbcopy;               then printf '%s' "$text" | pbcopy
  elif uk_has_cmd termux-clipboard-set; then printf '%s' "$text" | termux-clipboard-set
  elif uk_has_cmd clip.exe;             then printf '%s' "$text" | clip.exe
  else
    return 1
  fi
}

# ---- Subcommands -----------------------------------------------------------

ch_add() {
  local text="$1" quiet="$2"
  # Priority: explicit arg → stdin (if piped) → clipboard.
  if [[ -z "$text" ]]; then
    if [[ ! -t 0 ]]; then
      text="$(cat)"
    else
      text="$(ch_read_clipboard || printf '')"
      [[ -z "$text" ]] && { uk_error "Nothing to add. Provide TEXT, pipe stdin, or copy something first."; return 1; }
    fi
  fi
  # Dedupe against the most recent entry.
  local last
  last="$(tail -n1 "$CH_STORE" 2>/dev/null || true)"
  local last_data=""
  # A corrupt trailing record must not block new adds; treat a parse failure
  # as "not a duplicate" rather than aborting the whole add.
  [[ -n "$last" ]] && last_data="$(ch_json_get_data "$last" 2>/dev/null || true)"
  if [[ "$text" == "$last_data" ]]; then
    [[ "$quiet" == "1" ]] || uk_note "Duplicate of most recent entry — not added."
    return 0
  fi

  local esc t
  esc="$(ch_json_esc "$text")" || return 1
  t="$(date +%s)" || { uk_error 'Unable to read current time.'; return 1; }
  printf '{"t":%s,"pin":0,"data":%s}\n' "$t" "$esc" >>"$CH_STORE" || return 1
  chmod 600 "$CH_STORE" || { uk_error "Cannot secure clipboard store: $CH_STORE"; return 1; }
  [[ "$quiet" == "1" ]] || uk_success "Added ${#text}-byte entry."
}

ch_list() {
  local as_json="$1"
  local total; total="$(ch_line_count)"
  if [[ "$total" -eq 0 ]]; then
    [[ "$as_json" == "1" ]] && printf '[]\n' || uk_info "History is empty."
    return 0
  fi

  if [[ "$as_json" == "1" ]]; then
    if uk_has_cmd python3; then
      python3 - "$CH_STORE" <<'PY'
import json, sys
out = []
with open(sys.argv[1], encoding='utf-8', errors='replace') as f:
    for l in f:
        l = l.rstrip('\n')
        if not l: continue
        try: out.append(json.loads(l))
        except Exception as e:
            raise SystemExit(f"invalid clipboard record: {e}")
out.reverse()
print(json.dumps(out, ensure_ascii=False))
PY
    else
      # Best-effort: emit the raw lines wrapped in an array.
      printf '['
      local first=1 line
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ $first -eq 1 ]] || printf ','
        printf '%s' "$line"
        first=0
      done < <(tac "$CH_STORE" 2>/dev/null || tail -r "$CH_STORE" 2>/dev/null || nl -ba "$CH_STORE" | sort -rn | cut -f2-)
      printf ']\n'
    fi
    return 0
  fi

  printf '\n%s%sClipboard history%s %s(%s entries)%s\n' \
    "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "${UK_C_RESET:-}" \
    "${UK_C_DIM:-}" "$total" "${UK_C_RESET:-}"
  printf '%s%s%s\n\n' "${UK_C_DIM:-}" "$(printf '%*s' 68 '' | tr ' ' '-')" "${UK_C_RESET:-}"

  # Print newest-first — build an index and iterate down.
  local idx="$total" line pin data preview when
  # Read whole file into an array so we can iterate in reverse safely.
  local -a rows=()
  while IFS= read -r line; do rows+=("$line"); done <"$CH_STORE"
  for (( i=${#rows[@]}-1; i>=0; i-- )); do
    line="${rows[$i]}"
    [[ -z "$line" ]] && continue
    pin="$(ch_json_get_field "$line" pin)"
    data="$(ch_json_get_data "$line")"
    when="$(ch_json_get_field "$line" t)"

    # Preview: strip newlines, truncate.
    preview="${data//$'\n'/ ↵ }"
    preview="${preview//$'\t'/ }"
    if (( ${#preview} > CH_MAX_PREVIEW )); then
      preview="${preview:0:CH_MAX_PREVIEW}…"
    fi

    local mark=' '
    [[ "$pin" == "1" ]] && mark="${UK_C_YELLOW:-}${UK_I_STAR:-*}${UK_C_RESET:-}"

    local age=''
    if [[ "$when" =~ ^[0-9]+$ ]]; then
      age="$(ch_relative_age "$when")"
    fi

    printf ' %s%3d%s %s  %s%s%s  %s%s%s\n' \
      "${UK_C_BRIGHT_CYAN:-}" "$idx" "${UK_C_RESET:-}" \
      "$mark" \
      "${UK_C_BOLD:-}" "$preview" "${UK_C_RESET:-}" \
      "${UK_C_DIM:-}" "$age" "${UK_C_RESET:-}"

    idx=$((idx - 1))
  done
  printf '\n'
}

ch_relative_age() {
  local ts="$1" now diff
  now="$(date +%s 2>/dev/null || printf 0)"
  diff=$(( now - ts ))
  (( diff < 0 )) && diff=0
  if   (( diff < 60 ));     then printf '%ds ago'  "$diff"
  elif (( diff < 3600 ));   then printf '%dm ago'  "$(( diff / 60 ))"
  elif (( diff < 86400 ));  then printf '%dh ago'  "$(( diff / 3600 ))"
  else                            printf '%dd ago' "$(( diff / 86400 ))"; fi
}

# Resolve display-N or --last to a 1-indexed line inside the file.
# File is append-only, so display-N == file line N. Highest N = newest.
# --last is sugar for N = total (== newest).
ch_resolve_line_number() {
  local sel="$1" total
  total="$(ch_line_count)"
  [[ "$total" -eq 0 ]] && { uk_error "History is empty."; return 1; }
  if [[ "$sel" == "--last" ]]; then
    sel="$total"
  fi
  [[ "$sel" =~ ^[0-9]+$ ]] || { uk_error "Selector must be a positive integer or --last."; return 1; }
  (( sel < 1 || sel > total )) && { uk_error "Out of range: $sel (have $total entries)."; return 1; }
  printf '%s\n' "$sel"
}

ch_read_line() {
  local n="$1"
  sed -n "${n}p" "$CH_STORE"
}

ch_get() {
  local sel="$1" no_clip="$2" quiet="$3"
  local lineno line data
  lineno="$(ch_resolve_line_number "$sel")" || return 1
  line="$(ch_read_line "$lineno")"
  data="$(ch_json_get_data "$line")"
  if [[ "$no_clip" == "1" ]]; then
    printf '%s\n' "$data"
    return 0
  fi
  if ch_write_clipboard "$data"; then
    [[ "$quiet" == "1" ]] || uk_success "Copied entry #$sel to clipboard (${#data} bytes)."
  else
    uk_warn "No clipboard command available — printing instead."
    printf '%s\n' "$data"
  fi
}

ch_show() {
  local sel="$1"
  local lineno line
  lineno="$(ch_resolve_line_number "$sel")" || return 1
  line="$(ch_read_line "$lineno")"
  ch_json_get_data "$line"
  printf '\n'
}

ch_find() {
  local pattern="$1" as_json="$2"
  [[ -f "$CH_STORE" ]] || { uk_info "History is empty."; return 0; }
  local -a rows=(); local line
  while IFS= read -r line; do rows+=("$line"); done <"$CH_STORE"

  local matches=() total=${#rows[@]} i data
  for (( i=total-1; i>=0; i-- )); do
    line="${rows[$i]}"
    data="$(ch_json_get_data "$line")"
    if printf '%s' "$data" | grep -Eiq -- "$pattern"; then
      matches+=( "$(( total - i ))|$line" )
    fi
  done

  if [[ ${#matches[@]} -eq 0 ]]; then
    [[ "$as_json" == "1" ]] && printf '[]\n' || uk_note "No matches for /$pattern/i."
    return 0
  fi

  if [[ "$as_json" == "1" ]]; then
    printf '['
    local first=1 m raw
    for m in "${matches[@]}"; do
      raw="${m#*|}"
      [[ $first -eq 1 ]] || printf ','
      printf '%s' "$raw"
      first=0
    done
    printf ']\n'
    return 0
  fi

  printf '\n%s%sMatches for /%s/i%s\n' "${UK_C_BOLD:-}" "${UK_C_BRIGHT_CYAN:-}" "$pattern" "${UK_C_RESET:-}"
  printf '%s%s%s\n\n' "${UK_C_DIM:-}" "$(printf '%*s' 68 '' | tr ' ' '-')" "${UK_C_RESET:-}"

  local n preview m
  for m in "${matches[@]}"; do
    n="${m%%|*}"
    line="${m#*|}"
    data="$(ch_json_get_data "$line")"
    preview="${data//$'\n'/ ↵ }"
    (( ${#preview} > CH_MAX_PREVIEW )) && preview="${preview:0:CH_MAX_PREVIEW}…"
    printf ' %s%3d%s  %s\n' "${UK_C_BRIGHT_CYAN:-}" "$n" "${UK_C_RESET:-}" "$preview"
  done
  printf '\n'
}

ch_set_pin() {
  local sel="$1" val="$2"
  local lineno
  lineno="$(ch_resolve_line_number "$sel")" || return 1
  if uk_has_cmd python3; then
    python3 - "$CH_STORE" "$lineno" "$val" <<'PY'
import json, sys
path, ln, val = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
with open(path, encoding='utf-8', errors='replace') as f:
    lines = f.readlines()
try:
    obj = json.loads(lines[ln-1])
except Exception:
    sys.exit(1)
obj['pin'] = val
lines[ln-1] = json.dumps(obj, ensure_ascii=False) + '\n'
with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
PY
    local rc=$?
    (( rc == 0 )) || { uk_error "Failed to update pin state."; return 1; }
  else
    # sed fallback — swap "pin":0 <-> "pin":1 on the target line only.
    local tmp; tmp="$(mktemp)" || return 1
    awk -v ln="$lineno" -v v="$val" '
      NR == ln {
        sub(/"pin":[01]/, "\"pin\":" v)
      }
      { print }
    ' "$CH_STORE" >"$tmp" && mv "$tmp" "$CH_STORE" || { rm -f "$tmp"; return 1; }
  fi
  chmod 600 "$CH_STORE" || { uk_error "Cannot secure clipboard store: $CH_STORE"; return 1; }
  if [[ "$val" == "1" ]]; then uk_success "Pinned entry #$sel."; else uk_success "Unpinned entry #$sel."; fi
}

ch_remove() {
  local sel="$1"
  local lineno
  lineno="$(ch_resolve_line_number "$sel")" || return 1
  local tmp; tmp="$(mktemp)" || return 1
  sed "${lineno}d" "$CH_STORE" >"$tmp" && mv "$tmp" "$CH_STORE" || { rm -f "$tmp"; return 1; }
  chmod 600 "$CH_STORE" || { uk_error "Cannot secure clipboard store: $CH_STORE"; return 1; }
  uk_success "Removed entry #$sel."
}

ch_clear() {
  local force="$1"
  if [[ "$force" != "1" ]]; then
    if declare -f uk_confirm >/dev/null 2>&1; then
      uk_confirm "Delete ALL clipboard history entries?" "N" || { uk_note "Aborted."; return 0; }
    else
      printf 'Delete ALL history? [y/N] ' >&2
      local reply=''
      read -r reply
      [[ "$reply" =~ ^[Yy]$ ]] || { uk_note "Aborted."; return 0; }
    fi
  fi
  : > "$CH_STORE"
  chmod 600 "$CH_STORE" || { uk_error "Cannot secure clipboard store: $CH_STORE"; return 1; }
  uk_success "History cleared."
}

# ---- Main ------------------------------------------------------------------

ch_main() {
  uk_banner "clipboard-history" "Persistent clipboard history with pins & search" "" "$@"

  local sub=""
  local text_arg=""
  local sel=""
  local pattern=""
  local max="$CH_MAX_DEFAULT"
  local no_clip=0
  local as_json=0
  local quiet=0
  local force=0

  if [[ $# -gt 0 ]]; then
    case "${1:-}" in
      add|list|get|show|find|pin|unpin|remove|clear|path) sub="$1"; shift ;;
      -h|--help) ch_usage; return 0 ;;
    esac
  fi

  # Positional args differ per subcommand. Peel them off before flag parsing.
  case "$sub" in
    add|show|get|pin|unpin|remove|find)
      if [[ $# -gt 0 && ! "${1:-}" =~ ^- ]]; then
        case "$sub" in
          add)                        text_arg="$1" ;;
          find)                       pattern="$1"  ;;
          show|get|pin|unpin|remove)  sel="$1"      ;;
        esac
        shift
      elif [[ "$sub" == "get" || "$sub" == "show" ]] && [[ "${1:-}" == "--last" ]]; then
        sel="--last"; shift
      fi
      ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "${1:-}" in
      --max)     shift; max="${1:-$CH_MAX_DEFAULT}" ;;
      --no-clip) no_clip=1 ;;
      --json)    as_json=1 ;;
      --quiet)   quiet=1 ;;
      --force)   force=1 ;;
      --last)    sel="--last" ;;
      -h|--help) ch_usage; return 0 ;;
      *) uk_error "Unknown option: ${1:-}"; ch_usage; return 1 ;;
    esac
    shift || true
  done

  ch_init_store || return 1

  case "$sub" in
    ''|help) ch_usage ;;
    add)     ch_add "$text_arg" "$quiet" && ch_trim_to_max "$max" ;;
    list)    ch_list "$as_json" ;;
    get)     [[ -z "$sel" ]] && { uk_error "get requires N or --last."; return 1; }
             ch_get "$sel" "$no_clip" "$quiet" ;;
    show)    [[ -z "$sel" ]] && { uk_error "show requires N or --last."; return 1; }
             ch_show "$sel" ;;
    find)    [[ -z "$pattern" ]] && { uk_error "find requires PATTERN."; return 1; }
             ch_find "$pattern" "$as_json" ;;
    pin)     [[ -z "$sel" ]] && { uk_error "pin requires N."; return 1; }
             ch_set_pin "$sel" 1 ;;
    unpin)   [[ -z "$sel" ]] && { uk_error "unpin requires N."; return 1; }
             ch_set_pin "$sel" 0 ;;
    remove)  [[ -z "$sel" ]] && { uk_error "remove requires N."; return 1; }
             ch_remove "$sel" ;;
    clear)   ch_clear "$force" ;;
    path)    printf '%s\n' "$CH_STORE" ;;
    *)       ch_usage; return 1 ;;
  esac
}

ch_wizard() {
  uk_banner "clipboard-history" "Persistent clipboard history with pins & search" ""
  local action
  action="$(uk_prompt 'Action: list, add, get, show, find, pin, unpin, remove, clear' 'list' \
    'list | add | find TODO | get 1' \
    'list = newest-first table. get N copies entry N back to clipboard.')"
  case "$action" in
    list)   ch_main list ;;
    add)
      local txt
      txt="$(uk_prompt 'Text to add (blank = pull current clipboard)' '' 'quick note' '')"
      if [[ -n "$txt" ]]; then ch_main add "$txt"; else ch_main add; fi
      ;;
    get)
      local n; n="$(uk_prompt 'Entry number (or --last)' '--last' '1' '')"
      ch_main get "$n"
      ;;
    show)
      local n; n="$(uk_prompt 'Entry number (or --last)' '--last' '1' '')"
      ch_main show "$n"
      ;;
    find)
      local p; p="$(uk_prompt 'Search pattern (regex)' 'TODO' 'https?://' 'Case-insensitive.')"
      ch_main find "$p"
      ;;
    pin|unpin|remove)
      local n; n="$(uk_prompt 'Entry number' '1' '3' 'Use list first if unsure.')"
      ch_main "$action" "$n"
      ;;
    clear)
      if uk_confirm 'Delete ALL history entries?' 'N'; then ch_main clear --force; fi
      ;;
    *) uk_warn "Unknown action: $action"; ch_usage; return 1 ;;
  esac
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  set -euo pipefail
  if [[ $# -eq 0 ]] && [[ -t 0 && -t 1 ]]; then
    ch_wizard
  else
    ch_main "$@"
  fi
fi
