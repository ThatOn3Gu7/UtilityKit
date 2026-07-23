#!/usr/bin/env bash

set -uo pipefail
IFS=$' \t\n'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../lib/uk_common.sh"

SCRIPT_NAME="${0##*/}"

# Modes & Flags
IC_DO_PACKAGES=0
IC_DO_COMMANDS=0
IC_COUNT_ONLY=0
IC_JSON=0
IC_EXPORT=""
IC_ONLY_MANAGERS=""
IC_ONLY_CATEGORIES=""
IC_PLAIN=0

# Spinner state (set by ic_spinner_start, consumed by ic_spinner_stop).
IC_SPIN_PID=""

# Manager Registry
# Bash-3 safe parallel arrays (no associative arrays). Each PM_LIST command is
# expected to emit "name version" lines; ic_parse turns raw output into
# "name<TAB>version" (version may be empty). Versions are best-effort.
PM_ID=()
PM_CAT=()
PM_DETECT=()
PM_LIST=()
PM_PARSE=()
PM_NOTES=()

ic_register() {
  PM_ID[${#PM_ID[@]}]="${1:-}"
  PM_CAT[${#PM_CAT[@]}]="${2:-}"
  PM_DETECT[${#PM_DETECT[@]}]="${3:-}"
  PM_LIST[${#PM_LIST[@]}]="${4:-}"
  PM_PARSE[${#PM_PARSE[@]}]="${5:-}"
  PM_NOTES[${#PM_NOTES[@]}]="${6:-}"
}

ic_register_managers() {
  # NATIVE SYSTEM PACKAGE MANAGERS
  ic_register "apt" "system" \
    'command -v apt-get >/dev/null 2>&1 || command -v dpkg-query >/dev/null 2>&1' \
    "dpkg-query -W -f='\${Package} \${Version}\n' 2>/dev/null" \
    "aptv" "Debian / Ubuntu family"
  ic_register "dnf" "system" \
    'command -v dnf >/dev/null 2>&1' \
    "dnf list installed 2>/dev/null" \
    "rpmpv" "Fedora / RHEL (dnf)"
  ic_register "yum" "system" \
    'command -v yum >/dev/null 2>&1 && ! command -v dnf >/dev/null 2>&1' \
    "yum list installed 2>/dev/null" \
    "rpmpv" "Legacy RHEL / CentOS (yum)"
  ic_register "zypper" "system" \
    'command -v zypper >/dev/null 2>&1' \
    "zypper --no-color se --installed-only 2>/dev/null" \
    "zypperpv" "openSUSE / SLES"
  ic_register "pacman" "system" \
    'command -v pacman >/dev/null 2>&1' \
    "pacman -Q 2>/dev/null" \
    "pacmanpv" "Arch Linux"
  ic_register "apk" "system" \
    'command -v apk >/dev/null 2>&1' \
    "apk info -v 2>/dev/null" \
    "apkpv" "Alpine Linux"
  ic_register "xbps" "system" \
    'command -v xbps-query >/dev/null 2>&1' \
    "xbps-query -l 2>/dev/null" \
    "xbpspv" "Void Linux"
  ic_register "eopkg" "system" \
    'command -v eopkg >/dev/null 2>&1' \
    "eopkg list-installed 2>/dev/null" \
    "eopkgpv" "Solus"
  ic_register "emerge" "system" \
    'command -v emerge >/dev/null 2>&1' \
    "qlist -I 2>/dev/null" \
    "nonepv" "Gentoo"
  ic_register "brew" "system" \
    'command -v brew >/dev/null 2>&1' \
    "brew list --versions 2>/dev/null" \
    "brewpv" "Homebrew (Mac / Linux)"
  ic_register "macports" "system" \
    'command -v port >/dev/null 2>&1' \
    "port installed 2>/dev/null" \
    "macportspv" "MacPorts"
  ic_register "nix" "system" \
    'command -v nix-env >/dev/null 2>&1 || command -v nix >/dev/null 2>&1' \
    "nix-env -q --versions 2>/dev/null" \
    "nixpv" "Nix packages / profiles"
  ic_register "guix" "system" \
    'command -v guix >/dev/null 2>&1' \
    "guix package -I 2>/dev/null" \
    "guixpv" "GNU Guix"

  # APP STORES & BINARIES
  ic_register "snap" "apps" \
    'command -v snap >/dev/null 2>&1' \
    "snap list 2>/dev/null" \
    "snappv" "Canonical Snap"
  ic_register "flatpak" "apps" \
    'command -v flatpak >/dev/null 2>&1' \
    "flatpak list 2>/dev/null" \
    "snappv" "Flatpak"
  ic_register "choco" "apps" \
    'command -v choco >/dev/null 2>&1' \
    "choco list -lo 2>/dev/null" \
    "snappv" "Chocolatey (Windows)"
  ic_register "scoop" "apps" \
    'command -v scoop >/dev/null 2>&1' \
    "scoop list 2>/dev/null" \
    "snappv" "Scoop (Windows)"
  ic_register "winget" "apps" \
    'command -v winget >/dev/null 2>&1' \
    "winget list 2>/dev/null" \
    "snappv" "Windows Package Manager"

  # LANGUAGE ECOSYSTEMS
  ic_register "pip" "language" \
    'command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1 || command -v pip >/dev/null 2>&1' \
    "python3 -m pip list 2>/dev/null || pip list 2>/dev/null" \
    "pippv" "Python pip"
  ic_register "pipx" "language" \
    'command -v pipx >/dev/null 2>&1' \
    "pipx list 2>/dev/null" \
    "pipxpv" "Python isolated apps"
  ic_register "npm" "language" \
    'command -v npm >/dev/null 2>&1' \
    "npm ls -g --depth=0 2>/dev/null" \
    "npmpv" "Node npm (global)"
  ic_register "pnpm" "language" \
    'command -v pnpm >/dev/null 2>&1' \
    "pnpm -g list 2>/dev/null" \
    "npmpv" "pnpm (global)"
  ic_register "yarn" "language" \
    'command -v yarn >/dev/null 2>&1' \
    "yarn global list 2>/dev/null" \
    "npmpv" "Yarn (global)"
  ic_register "bun" "language" \
    'command -v bun >/dev/null 2>&1' \
    "bun pm ls -g 2>/dev/null" \
    "bunpv" "Bun (global)"
  ic_register "gem" "language" \
    'command -v gem >/dev/null 2>&1' \
    "gem list 2>/dev/null" \
    "gempv" "RubyGems"
  ic_register "cargo" "language" \
    'command -v cargo >/dev/null 2>&1' \
    "cargo install --list 2>/dev/null" \
    "cargopv" "Cargo binaries"
  ic_register "rustup" "language" \
    'command -v rustup >/dev/null 2>&1' \
    "rustup toolchain list 2>/dev/null" \
    "nonepv" "Rust toolchains"
  ic_register "go" "language" \
    'command -v go >/dev/null 2>&1' \
    "gobin=\"\${GOPATH:-\$(go env GOPATH 2>/dev/null)}/bin\"; ls \"\$gobin\" 2>/dev/null" \
    "nonepv" "Go global binaries"
  ic_register "composer" "language" \
    'command -v composer >/dev/null 2>&1' \
    "composer global show 2>/dev/null" \
    "compv" "PHP Composer (global)"
  ic_register "conda" "language" \
    'command -v conda >/dev/null 2>&1' \
    "conda list 2>/dev/null" \
    "condapv" "Conda environment"
  ic_register "uv" "language" \
    'command -v uv >/dev/null 2>&1' \
    "uv tool list 2>/dev/null" \
    "uvpv" "Astral uv tools"
  ic_register "dotnet" "language" \
    'command -v dotnet >/dev/null 2>&1' \
    "dotnet tool list -g 2>/dev/null" \
    "dotnetpv" ".NET global tools"
  ic_register "luarocks" "language" \
    'command -v luarocks >/dev/null 2>&1' \
    "luarocks list 2>/dev/null" \
    "luarockspv" "LuaRocks"
  ic_register "opam" "language" \
    'command -v opam >/dev/null 2>&1' \
    "opam list installed 2>/dev/null" \
    "opampv" "OCaml opam"
  ic_register "tlmgr" "language" \
    'command -v tlmgr >/dev/null 2>&1' \
    "tlmgr list --only-installed 2>/dev/null" \
    "tlmgrpv" "TeX Live Manager"

  # TOOLS & PLUGINS
  ic_register "asdf" "tools" \
    'command -v asdf >/dev/null 2>&1' \
    "asdf plugin list 2>/dev/null" \
    "nonepv" "asdf plugins"
  ic_register "gh" "tools" \
    'command -v gh >/dev/null 2>&1' \
    "gh extension list 2>/dev/null" \
    "nonepv" "GitHub CLI extensions"
  ic_register "krew" "tools" \
    'command -v kubectl >/dev/null 2>&1 && kubectl krew version >/dev/null 2>&1' \
    "kubectl krew list 2>/dev/null" \
    "nonepv" "kubectl krew plugins"
}

# Helpers
ic_has_cmd() { command -v "${1:-}" >/dev/null 2>&1; }

ic_usage() {
  local w
  w=$(uk_fh_cols)
  ((w > 80)) && w=80
  ((w < 40)) && w=40
  printf '%s v%s\n\n' "${SCRIPT_NAME}" "${UK_VERSION:-Unknown}"
  printf 'List installed packages (native + language package managers) and every\n'
  printf "executable command discoverable on your \$PATH. Versions are shown per package\n"
  printf 'when the manager reports them, as: [ - name \342\206\222 v1.2.3 ].\n\n'
  printf 'Usage:\n  %s [options]\n\n' "${SCRIPT_NAME}"
  uk_help_section "$w" "Modes" \
    "--packages" "Only list packages per detected package manager" \
    "--commands" "Only list executable commands found in \$PATH" \
    "--all" "List both (default)"
  printf '\n'
  uk_help_section "$w" "Filtering" \
    "--category c1,c2" "Limit to: system, apps, language, tools" \
    "--manager id1,id2" "Only these package-manager ids (e.g. apt,brew,npm)"
  printf '\n'
  uk_help_section "$w" "Output" \
    "--count" "Show a per-manager / total count instead of names" \
    "--json" "Emit a machine-readable JSON summary" \
    "--export FILE" "Write a plain-text report to FILE" \
    "--no-color" "Disable ANSI colors" \
    "-h, --help" "Show this help"
  printf '\nExamples:\n'
  printf '  %s --packages --category language\n' "${SCRIPT_NAME}"
  printf '  %s --commands --count\n' "${SCRIPT_NAME}"
  printf '  %s --manager apt,brew --json\n' "${SCRIPT_NAME}"
}

# Spinner
# Animated progress shown while a (possibly slow / network-blocked) manager's
# list command runs. Gated to interactive TTYs and disabled for --json / --export
# so machine output stays clean. Uses a background rotating loop that is killed
# on stop; the line is erased so the result can be printed in its place.
ic_should_spin() {
  [ "$IC_JSON" -eq 0 ] || return 1
  [ -z "${IC_EXPORT:-}" ] || return 1
  [ -t 1 ] || return 1
  return 0
}

ic_spinner_start() {
  IC_SPIN_PID=""
  [ -t 1 ] || return 0
  local label="${1:-}"
  local frames flen loc
  loc="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
  # Use Geometric-Shapes frames (same block as ◆/✔ already rendered fine) only
  # when the locale is UTF-8; otherwise fall back to an ASCII spinner. Braille
  # frames were dropped because many terminals lack those glyphs (shown as "?").
  if [ -z "${NO_UNICODE:-}" ] && printf '%s' "$loc" | grep -Eiq 'utf-?8'; then
    frames="◐◓◑◒"
    flen=4
  else
    frames="|/-\\"
    flen=4
  fi
  (
    local i=0 f
    while true; do
      f="${frames:$((i % flen)):1}"
      printf '\r\033[K %s %s' "$f" "$label"
      i=$((i + 1))
      sleep 0.1
    done
  ) &
  IC_SPIN_PID=$!
}

ic_spinner_stop() {
  if [ -n "${IC_SPIN_PID:-}" ]; then
    kill "${IC_SPIN_PID}" 2>/dev/null
    wait "${IC_SPIN_PID}" 2>/dev/null
    printf '\r\033[K'
  fi
}

# Run a manager's list command to a file, with a hard time budget so a slow /
# network-blocked package manager (e.g. `npm ls -g` probing the registry) can
# never hang the whole inventory. Uses GNU/BSD `timeout` when available.
ic_run_to_file() {
  local cmd="${1:-}" file="${2:-}" rc=0 err="${file}.err"
  if ic_has_cmd timeout; then
    timeout 25 sh -c "$cmd" >"$file" 2>/dev/null
    local rc=$?
    if [ $rc -eq 124 ]; then
      echo "Warning: command timed out after 25s" >&2
    fi
    return $rc
  else
    sh -c "$cmd" >"$file" 2>"$err" || rc=$?
  fi
  if [ -s "$err" ]; then cat "$err" >&2; fi
  rm -f "$err" || return 1
  return "$rc"
}

# Run a manager's query, animating a spinner while it executes.
ic_query_manager() {
  local idx="${1:-}" outfile="${2:-}" cmd="${PM_LIST[$idx]:-}" id="${PM_ID[$idx]:-}"
  local rc=0
  if ic_should_spin; then
    ic_spinner_start "Querying ${id}"
    ic_run_to_file "$cmd" "$outfile" || rc=$?
    ic_spinner_stop
  else
    ic_run_to_file "$cmd" "$outfile" || rc=$?
  fi
  return "$rc"
}

# Normalize a manager's raw list output into "name<TAB>version" lines. Reads
# stdin, writes stdout. Pipelines are written inline (not stored in a variable)
# so awk's \$1 is literal here and never expanded by bash.
ic_parse() {
  case "${1:-lines}" in
  aptv) awk 'NF{print $1"\t"$2}' ;;
  rpmpv) awk 'NR>1{gsub(/\.[a-z0-9_]+$/,"",$1); print $1"\t"$2}' ;;
  zypperpv) awk -F'|' '/^i \|/{gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$3); print $2"\t"$3}' ;;
  pacmanpv) awk 'NF{print $1"\t"$2}' ;;
  apkpv) awk '{p=$1; sub(/.*\//,"",p); if(match(p,/-[0-9]/)){v=substr(p,RSTART+1); p=substr(p,1,RSTART-1); print p"\t"v} else print p"\t"}' ;;
  xbpspv) awk '{p=$2; sub(/^ii/,"",p); if(match(p,/-[0-9]/)){v=substr(p,RSTART+1); p=substr(p,1,RSTART-1); print p"\t"v} else print p"\t"}' ;;
  eopkgpv) awk 'NR>1{print $1"\t"$2}' ;;
  nonepv) awk 'NF{print $1"\t"}' ;;
  brewpv) awk 'NF{print $1"\t"$2}' ;;
  macportspv) awk '{v=$2; sub(/@/,"",v); sub(/\(.*/,"",v); print $1"\t"v}' ;;
  nixpv) awk '{p=$1; if(match(p,/-[0-9]/)){v=substr(p,RSTART+1); p=substr(p,1,RSTART-1); print p"\t"v} else print p"\t"}' ;;
  guixpv) awk 'NF{print $1"\t"$2}' ;;
  snappv) awk 'NR>1{print $1"\t"$2}' ;;
  pippv) awk 'NR>2 && $1 !~ /^--+/{print $1"\t"$2}' ;;
  pipxpv) grep -i '^package' | awk 'NF>=3{print $2"\t"$3}' ;;
  npmpv) grep '──' | sed 's/.*── //; s/@/\t/' ;;
  bunpv) sed 's/^[│├└─ ]*//; s/@/\t/' | awk 'NF{print $1"\t"$2}' ;;
  gempv) awk '{v=$0; sub(/.*\(/,"",v); sub(/\).*/,"",v); print $1"\t"v}' ;;
  cargopv) awk -F'[: ]' '/v[0-9]/{print $1"\t"$2}' ;;
  condapv) awk 'NR>3{print $1"\t"$2}' ;;
  uvpv) awk 'NF{ v=$2; sub(/^v/,"",v); sub(/ .*/,"",v); print $1"\t"v }' ;;
  dotnetpv) awk 'NR>2{print $1"\t"$2}' ;;
  compv) awk 'NF>=2{print $1"\t"$2}' ;;
  luarockspv) awk 'NR>1 && NF{print $1"\t"$2}' ;;
  opampv) awk 'NR>2{print $1"\t"$2}' ;;
  tlmgrpv) awk -F'[: ]' '/^i /{print $2"\t"$3}' ;;
  *) cat ;;
  esac
}

# Render one package as "[ - name → vX ]" (version forced to a v-prefix) or
# "[ - name ]" when no version is available.
ic_format_pkg() {
  local name="${1:-}" ver="${2:-}"
  if [ -n "$ver" ]; then
    # Strip one leading v if present, then force exactly one v
    printf '[ - %s → v%s ]' "$name" "${ver#v}"
  else
    printf '[ - %s ]' "$name"
  fi
}

ic_csv_contains() {
  local csv=",$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]'),"
  local want
  want="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  # FIX: If the user didn't specify a filter, don't match anything
  [[ "$csv" == ",," ]] && return 1
  case "$csv" in *",$want,"*) return 0 ;; *) return 1 ;; esac
}

# Detect which registered managers are present; echoes space-separated indices.
ic_detect() {
  local i=0 idxs="" detect
  while [ $i -lt ${#PM_ID[@]} ]; do
    detect="${PM_DETECT[$i]}"
    if eval "$detect" >/dev/null 2>&1; then
      idxs="$idxs $i"
    fi
    i=$((i + 1))
  done
  printf '%s\n' "$idxs"
}

# Collect every executable basename found in $PATH, de-duplicated, sorted.
# Uses builtins / parameter expansion only (no per-file `basename` fork) so it
# stays fast even on systems where process creation is expensive.
ic_path_commands() {
  local dir f base oldifs
  oldifs="$IFS"
  IFS=':'
  for dir in $PATH; do
    IFS="$oldifs"
    [ -n "$dir" ] || continue
    [ -d "$dir" ] || continue
    for f in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
      [ -e "$f" ] || [ -L "$f" ] || continue
      [ -f "$f" ] || continue
      [ -x "$f" ] || continue
      base="${f##*/}"
      [ -n "$base" ] && printf '%s\n' "$base"
    done
  done | sort -u
}

ic_json_array() {
  local items="${1:-}" first=1 line out=''
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    line="${line//\\/\\\\}"
    line="${line//\"/\\\"}"
    if [ "$first" -eq 1 ]; then
      first=0
      out="\"$line\""
    else out="$out, \"$line\""; fi
  done <<<"$items"
  printf '[%s]' "$out"
}

# Emit a JSON array of {"name","version"} objects from "name<TAB>version" input.
ic_json_pkg_array() {
  local items="${1:-}" first=1 name ver out=''
  while IFS=$'\t' read -r name ver; do
    [ -z "$name" ] && continue
    # Escape backslash first, then quotes, then control chars
    name="${name//\\/\\\\}"
    name="${name//\"/\\\"}"
    name="${name//$'\n'/\\n}"
    name="${name//$'\t'/\\t}"
    name="${name//$'\r'/\\r}"
    ver="${ver//\\/\\\\}"
    ver="${ver//\"/\\\"}"
    ver="${ver//$'\n'/\\n}"
    ver="${ver//$'\t'/\\t}"
    ver="${ver//$'\r'/\\r}"
    if [ "$first" -eq 1 ]; then
      first=0
      out="{\"name\": \"$name\", \"version\": \"$ver\"}"
    else out="$out, {\"name\": \"$name\", \"version\": \"$ver\"}"; fi
  done <<<"$items"
  printf '[%s]' "$out"
}

# ----------------------------- Main Flow --------------------------------
ic_main() {
  # Relax errexit for the duration of this run. ic_main is always invoked
  # inside a subshell by main.sh, so this never affects the caller.
  set +e

  local tmpfiles=()
  cleanup() {
    rm -f "${tmpfiles[@]}" 2>/dev/null
  }
  trap cleanup EXIT

  # Local color aliases — respect tty / NO_COLOR / --export => plain.
  local C_B C_D C_G C_Y C_C C_R C_M C_W C_RESET
  if [ "$IC_PLAIN" -eq 0 ] && [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_B="$UK_C_BOLD" C_D="$UK_C_DIM" C_G="$UK_C_GREEN" C_Y="$UK_C_YELLOW"
    C_C="$UK_C_CYAN" C_R="$UK_C_RED" C_M="$UK_C_MAGENTA" C_W="$UK_C_WHITE"
    C_RESET="$UK_C_RESET"
  else
    C_B='' C_D='' C_G='' C_Y='' C_C='' C_R='' C_M='' C_W='' C_RESET=''
  fi

  # ---- parse args ----
  while [ $# -gt 0 ]; do
    case "${1:-}" in
    --packages) IC_DO_PACKAGES=1 ;;
    --commands) IC_DO_COMMANDS=1 ;;
    --all)
      IC_DO_PACKAGES=1
      IC_DO_COMMANDS=1
      ;;
    --count) IC_COUNT_ONLY=1 ;;
    --json) IC_JSON=1 ;;
    --no-color) IC_PLAIN=1 ;;
    --export)
      shift
      if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
        echo "Error: --export requires a file path." >&2
        return 2
      fi
      IC_EXPORT="${1:-}"
      IC_PLAIN=1
      ;;
    --export=*)
      IC_EXPORT="${1#*=}"
      IC_PLAIN=1
      ;;
    --category)
      shift
      if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
        echo "Error: --category requires a comma list." >&2
        return 2
      fi
      IC_ONLY_CATEGORIES="${1:-}"
      ;;
    --category=*) IC_ONLY_CATEGORIES="${1#*=}" ;;
    --manager)
      shift
      if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
        echo "Error: --manager requires a comma list." >&2
        return 2
      fi
      IC_ONLY_MANAGERS="${1:-}"
      ;;
    --manager=*) IC_ONLY_MANAGERS="${1#*=}" ;;
    -h | --help)
      ic_usage
      return 0
      ;;
    *)
      echo "Unknown argument: ${1:-}" >&2
      ic_usage >&2
      return 2
      ;;
    esac
    shift
  done

  # Default behaviour: list both.
  if [ "$IC_DO_PACKAGES" -eq 0 ] && [ "$IC_DO_COMMANDS" -eq 0 ]; then
    IC_DO_PACKAGES=1
    IC_DO_COMMANDS=1
  fi

  ic_register_managers

  local report="" line="" idxs idx id cat notes parse pkgs count tmpfile query_failed=0
  local cmds="" cmd_count=0
  local json_managers="" json_cmds=""

  if [ "$IC_DO_PACKAGES" -eq 1 ]; then
    idxs="$(ic_detect)"
    local cats="system apps language tools" c i idx found
    for c in $cats; do
      found=0
      for idx in $idxs; do
        [ "${PM_CAT[$idx]}" = "$c" ] && {
          found=1
          break
        }
      done
      [ "$found" -eq 0 ] && continue

      report="${report}${C_B}${C_C}◆ ${c}${C_RESET}${C_D} package managers${C_RESET}"$'\n'

      for idx in $idxs; do
        [ "${PM_CAT[$idx]}" = "$c" ] || continue
        id="${PM_ID[$idx]}"
        notes="${PM_NOTES[$idx]}"
        [ -n "$IC_ONLY_MANAGERS" ] && ! ic_csv_contains "$id" "$IC_ONLY_MANAGERS" && continue
        [ -n "$IC_ONLY_CATEGORIES" ] && ! ic_csv_contains "$c" "$IC_ONLY_CATEGORIES" && continue

        parse="${PM_PARSE[$idx]}"
        tmpfile="$(mktemp "${TMPDIR:-/tmp}/ic.XXXXXX")"
        tmpfiles+=("$tmpfile")
        ic_query_manager "$idx" "$tmpfile"
        # Normalize to "name<TAB>version", drop empties, dedupe by name.
        # A parser producing zero rows (e.g. empty global npm / newer pipx
        # output) is not a query failure; only the manager rc drives
        # query_failed, so tolerate an empty parse here.
        pkgs="$(ic_parse "$parse" <"$tmpfile" | awk -F'\t' 'NF>=1 && $1!="" && !seen[$1]++' || true)"
        rm -f "$tmpfile" || return 1
        count="$(printf '%s\n' "$pkgs" | grep -c . || true)"

        if [ "$IC_JSON" -eq 1 ]; then
          json_managers="${json_managers}${json_managers:+, }\"${id}\": $(ic_json_pkg_array "$pkgs")"
        fi

        if [ "$IC_COUNT_ONLY" -eq 1 ]; then
          report="${report}  ${C_G}${UK_I_OK}${C_RESET} ${C_G}${id}${C_RESET}${C_D} — ${count} package(s)${C_RESET}"$'\n'
        else
          report="${report}  ${C_G}${UK_I_OK}${C_RESET} ${C_G}${id}${C_RESET}${C_D} (${notes}) — ${count} package(s)${C_RESET}"$'\n'
          if [ "$count" -gt 0 ]; then
            local pname pver pline
            while IFS=$'\t' read -r pname pver; do
              [ -z "$pname" ] && continue
              pline="$(ic_format_pkg "$pname" "$pver")"
              report="${report}    ${C_D}- ${C_RESET}${pline}"$'\n'
            done <<<"$pkgs"
          fi
        fi
      done
      report="${report}"$'\n'
    done
  fi

  if [ "$IC_DO_COMMANDS" -eq 1 ]; then
    cmds="$(ic_path_commands)"
    cmd_count="$(printf '%s\n' "$cmds" | grep -c . || true)"
    if [ "$IC_JSON" -eq 1 ]; then
      json_cmds="$(ic_json_array "$cmds")"
    fi
    report="${report}${C_B}${C_C}▸ PATH executables${C_RESET}${C_D} — ${cmd_count} unique command(s)${C_RESET}"$'\n'
    if [ "$IC_COUNT_ONLY" -eq 0 ] && [ "$IC_JSON" -eq 0 ]; then
      local cc
      while IFS= read -r cc; do
        [ -z "$cc" ] && continue
        report="${report}  ${cc}"$'\n'
      done <<<"$cmds"
    fi
  fi
  # ---- render ----
  if [ "$IC_JSON" -eq 1 ]; then
    printf '{\n'
    printf '  "managers": {%s},\n' "$json_managers"
    printf '  "commands": %s,\n' "$json_cmds"
    printf '  "counts": { "commands": %s }\n' "$cmd_count"
    printf '}\n'
  else
    printf '%s' "$report"
  fi

  if [ -n "$IC_EXPORT" ]; then
    if [ "$IC_JSON" -eq 1 ]; then
      printf '{\n  "managers": {%s},\n  "commands": %s,\n  "counts": { "commands": %s }\n}\n' \
        "$json_managers" "$json_cmds" "$cmd_count" >"$IC_EXPORT" 2>/dev/null || {
        echo "Cannot write report file: $IC_EXPORT" >&2
        return 2
      }
    else
      printf '%s' "$report" >"$IC_EXPORT" 2>/dev/null || {
        echo "Cannot write report file: $IC_EXPORT" >&2
        return 2
      }
    fi
    [ "$IC_PLAIN" -eq 0 ] && printf '  %s report written to %s%s\n' "$C_G" "$IC_EXPORT" "$C_RESET"
  fi
}

# Entry point (standalone-safe). When executed directly we run ic_main; when
# sourced by main.sh the BASH_SOURCE guard is skipped and main.sh calls ic_main.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -uo pipefail
  IFS=$' \t\n'
  ic_main "$@"
fi
