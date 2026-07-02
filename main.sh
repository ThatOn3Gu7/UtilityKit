#!/usr/bin/env bash
# UtilityKit central hub
set -euo pipefail
readonly UK_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UK_ROOT_DIR/lib/uk_common.sh"

# Fallback for color names not defined in uk_common.sh.
: "${UK_C_BRIGHT_GREEN:=$UK_C_GREEN}"

uk_source_tool() {
  local path="${1:-}"
  [[ -f "$path" ]] || {
    uk_warn "Missing tool: $path"
    return 0
  }
  # shellcheck disable=SC1090
  source "$path"
}
# =============================================================================
# UNIFIED TOOL REGISTRY  (single source of truth)
# -----------------------------------------------------------------------------
# Every tool is described ONCE here. The lazy-loader map (UK_TOOL_PATHS) and the
# interactive dashboard menu (M_* arrays) are both DERIVED from this list, so
# they can never drift out of sync again. `uk doctor` validates this registry
# against the files on disk and against the run_tool dispatch cases.
#
# Record format (pipe-delimited, exactly 7 fields):
#   key | action | icon | color | Display Name | description | menu
#     key    : registry key + directory stem (dir is _<key>, script _<key>.sh)
#     action : the command word passed to run_tool for this tool
#     icon   : dashboard glyph
#     color  : a UK_C_* color VARIABLE NAME (looked up indirectly)
#     name   : dashboard display name
#     desc   : one-line dashboard description
#     menu   : 1 = show in the interactive dashboard, 0 = CLI-only / hidden
# =============================================================================
UK_REGISTRY=(
  "apply_changes|apply|↻|UK_C_GREEN|Apply Changes|Robust Directory Synchronization|1"
  "rename_batch|rename|✎|UK_C_BRIGHT_BLUE|Batch Rename|Recursive File Renaming & Copying|1"
  "cache_clean|cacheclean|🗑|UK_C_BRIGHT_MAGENTA|Cache Cleaner|Intelligent System Cache Cleanup|1"
  "symlink_manager|symlink|►|UK_C_YELLOW|Symlink Manager|Dotfiles & System Config Management|1"
  "disk_analyzer|disk|◆|UK_C_BRIGHT_CYAN|Disk Analyzer|Storage Inspection & Quick Archiving|1"
  "env_manager|env|◎|UK_C_CYAN|Env Manager|compare, validate, and switch .env profiles|1"
  "git_sweep|git|⑂|UK_C_GREEN|Git Sweep|clean merged branches, stashes, and artifacts|1"
  "project_scaffold|scaffold|▣|UK_C_BRIGHT_BLUE|Project Scaffold|generate starter projects from guided templates|1"
  "duplicate_finder|dup|◆|UK_C_MAGENTA|Duplicate Finder|find exact duplicate files and reclaim space|1"
  "process_killer|proc|✖|UK_C_RED|Process Killer|inspect memory pressure and terminate processes|1"
  "port_inspector|port|◉|UK_C_BRIGHT_CYAN|Port Inspector|find which process owns a local port|1"
  "ssl_checker|ssl|🔒|UK_C_CYAN|SSL Checker|inspect certificate expiry, DNS, and TLS support|1"
  "api_tester|api|⇄|UK_C_GREEN|API Tester|send HTTP requests and save reusable profiles|1"
  "password_gen|pass|✦|UK_C_YELLOW|Password Gen|generate passphrases or random strings|1"
  "ssh_assistant|ssh|⇢|UK_C_BRIGHT_BLUE|SSH Assistant|list SSH hosts and run connection helpers|1"
  "shredder|shred|⌫|UK_C_RED|Shredder|securely erase sensitive files with fallbacks|1"
  "media_convert|media|▧|UK_C_MAGENTA|Media Convert|batch convert images/videos when tools exist|1"
  "markdown_toc|toc|☷|UK_C_CYAN|Markdown TOC|generate TOCs, check links, align tables|1"
  "pomodoro|pomodoro|◷|UK_C_GREEN|Pomodoro|run focused work/break cycles|1"
  "cheat_sheet|cheat|☰|UK_C_YELLOW|Cheat Sheet|store, search, and show command snippets|1"
  "move_in_batch|move|⇥|UK_C_BRIGHT_CYAN|Move in Batch|copy/move files safely with exclusions|1"
  "docker_janitor|docker|⬢|UK_C_BRIGHT_BLUE|Docker Janitor|clean containers, images, and volumes|1"
  "network_probe|network|⌁|UK_C_BRIGHT_CYAN|Network Probe|ping, DNS, public IP, and route diagnostics|1"
  "service_watcher|service|◍|UK_C_GREEN|Service Watcher|check HTTP services and response times|1"
  "git_stats|git-stats|⑂|UK_C_YELLOW|Git Stats|summarize authors, branches, and changed files|1"
  "json_explorer|json|{}|UK_C_MAGENTA|JSON Explorer|pretty-print, inspect, and extract JSON paths|1"
  "link_checker|links|🔗|UK_C_CYAN|Link Checker|validate Markdown local and HTTP links|1"
  "backup_sync|backup|⇄|UK_C_GREEN|Backup Sync|dry-run-first backup wrapper with fallbacks|1"
  "project_search|search|⌕|UK_C_BRIGHT_BLUE|Project Search|search files/text with rg/grep/find fallbacks|1"
  "log_inspector|log-inspect|≡|UK_C_YELLOW|Log Inspector|summarize warnings, errors, repeated lines|1"
  "csv_toolkit|csv|▤|UK_C_MAGENTA|CSV Toolkit|inspect CSV headers and preview rows|1"
  "cron_manager|cron|◷|UK_C_CYAN|Cron Manager|list/add/remove crontab entries safely|1"
  "dotenv_vault|dotenv|🔐|UK_C_GREEN|Dotenv Vault|encrypt selected .env values with gpg|1"
  "disk_health|disk-health|◆|UK_C_YELLOW|Disk Health|SMART health check when smartctl exists|1"
  "weather|weather|☁|UK_C_BRIGHT_CYAN|Weather|terminal forecast lookup with cache fallback|1"
  "tmux_session|tmux|▥|UK_C_GREEN|Tmux Session|list, create, attach, or kill tmux sessions|1"
  "font_inspector|font|A|UK_C_BRIGHT_BLUE|Font Inspector|check glyph support and list fonts|1"
  "toolbox_bootstrap|toolbox|⚙|UK_C_YELLOW|Toolbox Audit|detect recommended CLI tools|1"
  "github_helper|github|#|UK_C_CYAN|GitHub Helper|wrap common gh CLI tasks|1"
  "hash_tools|hash|▦|UK_C_GREEN|Hash Tools|create checksums for files and trees|1"
  "archive_manager|archive|◈|UK_C_YELLOW|Archive Manager|list, create, and safely extract archives|1"
  "system_snapshot|snapshot|◉|UK_C_MAGENTA|System Snapshot|collect a compact diagnostic summary|1"
  "open_files|open-files|▰|UK_C_CYAN|Open Files|find processes using paths or ports|1"
  "battery_doctor|battery|✦|UK_C_GREEN|Battery Doctor|show battery and power diagnostics|1"
  "release_helper|release|§|UK_C_YELLOW|Release Helper|run git release checks and optional tags|1"
  "license_helper|license|◆|UK_C_MAGENTA|License Helper|detect or generate simple license text|1"
  "todo_manager|todo|☑|UK_C_BRIGHT_CYAN|Todo Manager|plain-text tasks with tags and search|1"
  "update_managers|update|↥|UK_C_BRIGHT_GREEN|Update Managers|detect and update every package manager found|1"
)

# Derive the lazy-loader path map from the registry (never hand-maintained now).
declare -A UK_TOOL_PATHS=()
uk_registry_build_paths() {
  local rec key
  for rec in "${UK_REGISTRY[@]}"; do
    key="${rec%%|*}"
    UK_TOOL_PATHS["$key"]="$UK_ROOT_DIR/_${key}/_${key}.sh"
  done
}
uk_registry_build_paths

declare -A UK_TOOL_LOADED=()

uk_load() {
  local key="${1:-}"
  # Already sourced — do nothing.
  [[ -n "${UK_TOOL_LOADED[$key]:-}" ]] && return 0
  local path="${UK_TOOL_PATHS[$key]:-}"
  if [[ -z "$path" ]]; then
    uk_warn "uk_load: unknown tool key '$key'"
    return 1
  fi
  if [[ ! -f "$path" ]]; then
    uk_warn "uk_load: missing script: $path"
    return 1
  fi
  # shellcheck disable=SC1090
  source "$path"
  UK_TOOL_LOADED[$key]=1
}
uk_expand_path() {
  local input="${1:-}"
  if [[ "$input" == ~* ]]; then
    printf '%s\n' "${input/#\~/$HOME}"
  else
    printf '%s\n' "$input"
  fi
}
uk_main_banner() {
  clear 2>/dev/null || printf '\n'
  cat <<EOF
${UK_C_BRIGHT_CYAN}

    ██╗   ██╗████████╗██╗██╗     ██╗████████╗██╗   ██╗██╗  ██╗██╗████████╗
    ██║   ██║╚══██╔══╝██║██║     ██║╚══██╔══╝╚██╗ ██╔╝██║ ██╔╝██║╚══██╔══╝
    ██║   ██║   ██║   ██║██║     ██║   ██║    ╚████╔╝ █████╔╝ ██║   ██║   
    ██║   ██║   ██║   ██║██║     ██║   ██║     ╚██╔╝  ██╔═██╗ ██║   ██║   
    ╚██████╔╝   ██║   ██║███████╗██║   ██║      ██║   ██║  ██╗██║   ██║   
     ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝   ╚═╝${UK_C_RESET}

EOF
  printf '%s\n' "${UK_C_DIM}     ----------------------------------------------------------------------${UK_C_RESET}"
  printf "           %s %s READY%s   %s %s UtilityKit Central Hub %s Suite %sv%s%s\n" \
    "$UK_C_GREEN" "$UK_I_READY" "$UK_C_RESET" "$UK_C_DIM$UK_I_SEP$UK_C_RESET" \
    "$UK_C_BOLD$UK_C_WHITE" "$UK_C_RESET$UK_C_DIM$UK_I_SEP$UK_C_RESET" "$UK_C_BRIGHT_BLUE" "${UK_VERSION}" "$UK_C_RESET"
  printf '%s\n\n' "${UK_C_DIM}     ----------------------------------------------------------------------${UK_C_RESET}"
}

run_apply_wizard() {
  uk_banner "apply-changes" "Directory sync with dry-run preview, backup, and rollback" ""
  local src dst apply mirror force include_runtime custom
  src="$(uk_prompt 'Enter updated source directory to sync from' '.' '~/path/to/source' 'Use a directory that contains the newest version of your files.')"
  dst="$(uk_prompt 'Enter local target directory to update' '.' '~/path/to/target' 'The target directory will be compared against the source.')"
  if uk_confirm 'Apply changes now?' 'N'; then apply=y; else apply=n; fi
  if uk_confirm 'Mirror delete missing target files too?' 'N'; then mirror=y; else mirror=n; fi
  if uk_confirm 'Force past local git changes if needed?' 'N'; then force=y; else force=n; fi
  if uk_confirm 'Include runtime logs/tmp files?' 'N'; then include_runtime=y; else include_runtime=n; fi
  custom=""
  [[ "$apply" =~ ^[Yy]$ ]] && custom+=" --apply --yes"
  [[ "$mirror" =~ ^[Yy]$ ]] && custom+=" --mirror"
  [[ "$force" =~ ^[Yy]$ ]] && custom+=" --force"
  [[ "$include_runtime" =~ ^[Yy]$ ]] && custom+=" --include-runtime"
  local args=()
  [[ "$apply" =~ ^[Yy]$ ]] && args+=(--apply --yes) || args+=(--dry-run)
  [[ "$mirror" =~ ^[Yy]$ ]] && args+=(--mirror)
  [[ "$force" =~ ^[Yy]$ ]] && args+=(--force)
  [[ "$include_runtime" =~ ^[Yy]$ ]] && args+=(--include-runtime)
  (ac_main "${args[@]}" "$(uk_expand_path "$src")" "$(uk_expand_path "$dst")")
}
run_rename_wizard() {
  uk_banner "rename-batch" "Recursively rename or copy files to a new extension" ""
  local src ext out force
  src="$(uk_prompt 'Enter target directory to process' '.' '~/path/to/your/directory' 'Every non-hidden file in this folder tree will be considered.')"
  ext="$(uk_prompt 'Enter target new extension format (e.g. sh, py, txt)' '' '.md' 'Do not worry about the leading dot; both md and .md work.')"
  out="$(uk_prompt 'Enter output export directory (leave blank for in-place rename)' '' '~/path/to/export-folder' 'Leave blank to rename files where they already live.')"
  if uk_confirm 'Force protected files too (README, LICENSE, *.md, *.json)?' 'N'; then force=y; else force=n; fi
  if [[ "$force" =~ ^[Yy]$ ]]; then
    if [[ -n "$out" ]]; then
      (rb_main --force "$(uk_expand_path "$src")" "$ext" "$(uk_expand_path "$out")")
    else
      (rb_main --force "$(uk_expand_path "$src")" "$ext")
    fi
  else
    if [[ -n "$out" ]]; then
      (rb_main "$(uk_expand_path "$src")" "$ext" "$(uk_expand_path "$out")")
    else
      (rb_main "$(uk_expand_path "$src")" "$ext")
    fi
  fi
}
run_symlink_wizard() {
  uk_banner "symlink-manager" "Transactional symlink creator with backup of existing targets" ""
  local src dst apply
  src="$(uk_prompt 'Enter source file or directory to link from' '' '~/.dotfiles/.bashrc' 'This is the real file or folder that should back the symlink.')"
  dst="$(uk_prompt 'Enter target link path to create or replace' '' '~/.bashrc' 'If the target already exists, the tool can back it up first.')"
  if uk_confirm 'Apply the symlink change now?' 'Y'; then apply=y; else apply=n; fi
  if [[ "$apply" =~ ^[Nn]$ ]]; then
    (sm_main "$(uk_expand_path "$src")" "$(uk_expand_path "$dst")")
  else
    (sm_main --apply -y "$(uk_expand_path "$src")" "$(uk_expand_path "$dst")")
  fi
}
run_disk_wizard() {
  uk_banner "disk-analyzer" "Largest-items disk usage explorer with optional archiving" ""
  local dir count
  dir="$(uk_prompt 'Enter target directory to scan' '.' '~/projects' 'For large folders, the scan can take a little while.')"
  count="$(uk_prompt 'Enter how many top items to display' '10' '15' 'Smaller numbers render faster and are easier to read on mobile screens.')"
  (da_main --count "$count" "$(uk_expand_path "$dir")")
}
run_env_wizard() {
  uk_banner "env-manager" ".env profile switching, validation, and encryption" ""
  printf '  1) Compare .env with .env.example\n'
  printf '  2) Validate an env file\n'
  printf '  3) Activate a profile such as .env.local or .env.production\n'
  printf '  4) Encrypt a secret file\n'
  printf '  5) Decrypt a secret file\n'
  printf ' %s Choose an action: ' "$UK_I_ARROW" >&2
  local choice dir file profile
  read -r choice
  dir="$(uk_prompt 'Enter the project directory that contains your env files' '.' '~/project' 'This folder may contain .env, .env.example, and .env.<profile> files.')"
  dir="$(uk_expand_path "$dir")"
  case "$choice" in
  1) (em_main --dir "$dir" --compare) ;;
  2)
    file="$(uk_prompt 'Enter env file path to validate' "$dir/.env" "$dir/.env.production" 'The validator checks key=value syntax lines.')"
    (em_main --validate "$(uk_expand_path "$file")")
    ;;
  3)
    profile="$(uk_prompt 'Enter profile name without the .env. prefix' 'local' 'production' 'For example, profile=local means the tool will use .env.local.')"
    (em_main --dir "$dir" --profile "$profile" --apply)
    ;;
  4)
    file="$(uk_prompt 'Enter the file path to encrypt' "$dir/.env" "$dir/.env.production" 'The tool will use gpg first, or openssl as a fallback.')"
    (em_main --encrypt "$(uk_expand_path "$file")")
    ;;
  5)
    file="$(uk_prompt 'Enter the .gpg or .enc file path to decrypt' '' "$dir/.env.production.gpg" 'The decrypted content will be printed by the active backend tool.')"
    (em_main --decrypt "$(uk_expand_path "$file")")
    ;;
  *) uk_warn 'No env-manager action selected.' ;;
  esac
}
run_git_wizard() {
  uk_banner "git-sweep" "Merged-branch cleanup, stash purge, repo garbage collection" ""
  local repo
  repo="$(uk_prompt 'Enter the Git repository directory to inspect' '.' '~/project' 'The tool looks for merged branches, stashes, artifacts, and git gc opportunities.')"
  (gs_main --repo "$(uk_expand_path "$repo")")
}
run_scaffold_wizard() {
  uk_banner "project-scaffold" "Starter project generator for Bash, Python, Node, Go" ""
  local type name dest
  type="$(uk_prompt 'Enter scaffold type (bash, python-flask, node-cli, go-service)' 'bash' 'python-flask' 'A new project folder will be generated for the selected stack.')"
  name="$(uk_prompt 'Enter the new project folder name' '' 'demo-app' 'This becomes the generated project directory name.')"
  dest="$(uk_prompt 'Enter the parent destination directory' '.' '~/projects' 'The generated folder will be created inside this destination.')"
  (ps_main --type "$type" --name "$name" --dest "$(uk_expand_path "$dest")")
}
run_duplicate_wizard() {
  uk_banner "duplicate-finder" "Size-first, hash-second duplicate detection" ""
  local dir mode apply_args=()
  dir="$(uk_prompt 'Enter directory to scan for duplicate files' '.' '~/Downloads' 'The tool matches file sizes first, then hashes exact candidates.')"
  printf '  1) Report only\n  2) Delete duplicates and keep the first copy\n  3) Replace duplicates with hardlinks\n'
  printf ' %s Choose an action: ' "$UK_I_ARROW" >&2
  read -r mode
  case "$mode" in
  1) (df_main "$(uk_expand_path "$dir")") ;;
  2) (df_main "$(uk_expand_path "$dir")" --delete --apply) ;;
  3) (df_main "$(uk_expand_path "$dir")" --hardlink --apply) ;;
  *) uk_warn 'No duplicate-finder action selected.' ;;
  esac
}
run_process_wizard() {
  uk_banner "process-killer" "RAM/swap overview, top consumers, optional signal send" ""
  local pid sig
  printf '  The tool will show memory pressure and the top memory consumers first.\n'
  pid="$(uk_prompt 'Enter a PID to terminate (leave blank to only inspect processes)' '' '12345' 'If you leave this blank, no signal will be sent.')"
  if [[ -n "$pid" ]]; then
    sig="$(uk_prompt 'Enter signal type (TERM or KILL)' 'TERM' 'KILL' 'TERM is safer; KILL is more forceful.')"
    (pk_main --pid "$pid" --signal "$sig")
  else
    (pk_main)
  fi
}
run_port_wizard() {
  uk_banner "port-inspector" "Find which process owns a local TCP port" ""
  local port kill_flag
  port="$(uk_prompt 'Enter the local TCP port to inspect' '' '3000' 'The tool will search for whichever process is listening on this port.')"
  if uk_confirm 'Terminate the process if one is found?' 'N'; then kill_flag=y; else kill_flag=n; fi
  if [[ "$kill_flag" =~ ^[Yy]$ ]]; then
    (pi_main "$port" --kill)
  else
    (pi_main "$port")
  fi
}
run_ssl_wizard() {
  uk_banner "ssl-checker" "Certificate expiry, DNS records, legacy TLS probe" ""
  local host port
  host="$(uk_prompt 'Enter host or domain name to inspect' '' 'example.com' 'The tool will fetch certificate metadata and DNS information.')"
  port="$(uk_prompt 'Enter port number to check' '443' '443' 'Most HTTPS services use port 443.')"
  (sc_main "$host" --port "$port")
}
run_api_wizard() {
  uk_banner "api-tester" "One-off HTTP requests or saved/replayable profiles" ""
  printf '  1) Run a one-off request\n'
  printf '  2) Save a reusable request profile\n'
  printf '  3) Run a saved profile\n'
  printf '  4) Show a saved profile\n'
  printf '  5) List saved profiles\n'
  printf ' %s Choose an action: ' "$UK_I_ARROW" >&2
  local choice method url header body name
  read -r choice
  case "$choice" in
  1)
    method="$(uk_prompt 'Enter HTTP method' 'GET' 'POST' 'Examples: GET, POST, PUT, PATCH, DELETE.')"
    url="$(uk_prompt 'Enter request URL' '' 'https://api.example.com/items' 'The URL must include the protocol such as https://.')"
    header="$(uk_prompt 'Optional single header in Key: Value format' '' 'Authorization: Bearer TOKEN' 'Leave blank if you do not need an extra header.')"
    body="$(uk_prompt 'Optional request body text' '' '{"name":"demo"}' 'Leave blank for requests that do not need a body.')"
    if [[ -n "$header" && -n "$body" ]]; then
      (at_main --method "$method" --url "$url" --header "$header" --body "$body")
    elif [[ -n "$header" ]]; then
      (at_main --method "$method" --url "$url" --header "$header")
    elif [[ -n "$body" ]]; then
      (at_main --method "$method" --url "$url" --body "$body")
    else
      (at_main --method "$method" --url "$url")
    fi
    ;;
  2)
    name="$(uk_prompt 'Profile name to save' '' 'staging-users' 'This name will be used later with the run/show actions.')"
    method="$(uk_prompt 'HTTP method' 'GET' 'POST' 'Examples: GET, POST, PUT, PATCH, DELETE.')"
    url="$(uk_prompt 'Request URL' '' 'https://api.example.com/items' 'The full URL will be stored in the profile.')"
    header="$(uk_prompt 'Optional single header in Key: Value format' '' 'Authorization: Bearer TOKEN' 'Leave blank if not needed.')"
    body="$(uk_prompt 'Optional request body text' '' '{"name":"demo"}' 'Leave blank for requests without a body.')"
    if [[ -n "$header" && -n "$body" ]]; then
      (at_main --save "$name" --method "$method" --url "$url" --header "$header" --body "$body")
    elif [[ -n "$header" ]]; then
      (at_main --save "$name" --method "$method" --url "$url" --header "$header")
    elif [[ -n "$body" ]]; then
      (at_main --save "$name" --method "$method" --url "$url" --body "$body")
    else
      (at_main --save "$name" --method "$method" --url "$url")
    fi
    ;;
  3)
    name="$(uk_prompt 'Profile name to run' '' 'staging-users' 'Use a previously saved API profile name.')"
    (at_main --run "$name")
    ;;
  4)
    name="$(uk_prompt 'Profile name to display' '' 'staging-users' 'Use a previously saved API profile name.')"
    (at_main --show "$name")
    ;;
  5) (at_main --list) ;;
  *) uk_warn 'No API-tester action selected.' ;;
  esac
}
run_password_wizard() {
  uk_banner "password-gen" "XKCD-style passphrases or random strings with entropy" ""
  local mode copy words length
  mode="$(uk_prompt 'Choose generator mode (passphrase|string)' 'passphrase' 'string' 'Passphrases are easier to remember; random strings are denser.')"
  if [[ "$mode" == 'string' ]]; then
    length="$(uk_prompt 'Enter string length' '20' '32' 'Longer strings give you higher theoretical entropy.')"
    if uk_confirm 'Copy the generated password to clipboard too?' 'N'; then copy=y; else copy=n; fi
    if [[ "$copy" =~ ^[Yy]$ ]]; then
      (pg_main --mode string --length "$length" --copy)
    else
      (pg_main --mode string --length "$length")
    fi
  else
    words="$(uk_prompt 'Enter passphrase word count' '4' '5' 'More words increase entropy and length.')"
    if uk_confirm 'Copy the generated passphrase to clipboard too?' 'N'; then copy=y; else copy=n; fi
    if [[ "$copy" =~ ^[Yy]$ ]]; then
      (pg_main --mode passphrase --words "$words" --copy)
    else
      (pg_main --mode passphrase --words "$words")
    fi
  fi
}
run_ssh_wizard() {
  uk_banner "ssh-assistant" "Parse ~/.ssh/config and connect to named hosts" ""
  printf '  1) Show named hosts from ~/.ssh/config\n'
  printf '  2) Connect to a host from ~/.ssh/config\n'
  printf '  3) Run ssh-copy-id for a host\n'
  printf ' %s Choose an action: ' "$UK_I_ARROW" >&2
  local choice host
  read -r choice
  case "$choice" in
  1) (sa_main) ;;
  2)
    host="$(uk_prompt 'Enter SSH host alias to connect to' '' 'gitlab' 'If this is a Git hosting service, it may close after a successful auth handshake.')"
    (sa_main --connect "$host")
    ;;
  3)
    host="$(uk_prompt 'Enter host for ssh-copy-id' '' 'user@example.com' 'This pushes your public SSH key to the remote host for easier login later.')"
    (sa_main --copy-id "$host")
    ;;
  *) uk_warn 'No SSH action selected.' ;;
  esac
}
run_shred_wizard() {
  uk_banner "shredder" "Multi-pass overwrite using shred or /dev/urandom fallback" ""
  local file passes apply
  file="$(uk_prompt 'Enter file path to securely erase' '' '~/secret.txt' 'Shredding overwrites file contents before unlinking the file.')"
  passes="$(uk_prompt 'How many overwrite passes should be used?' '3' '7' 'Higher values are slower but overwrite the file more times.')"
  if uk_confirm 'Apply secure erase now?' 'N'; then apply=y; else apply=n; fi
  if [[ "$apply" =~ ^[Yy]$ ]]; then
    (sd_main --passes "$passes" --apply "$(uk_expand_path "$file")")
  else
    (sd_main --passes "$passes" "$(uk_expand_path "$file")")
  fi
}
run_media_wizard() {
  uk_banner "media-convert" "Batch image and video conversion via ImageMagick or ffmpeg" ""
  local kind path to output strip apply
  kind="$(uk_prompt 'Choose conversion kind (image|video)' 'image' 'image' 'Images use web-oriented conversion; videos use ffmpeg compression.')"
  path="$(uk_prompt 'Enter source file or directory to convert' '' '~/Pictures' 'The output will be written into a separate output directory.')"
  if [[ "$kind" == 'video' ]]; then
    to="$(uk_prompt 'Enter target video format' 'mp4' 'mp4' 'For Termux, mp4 is usually the safest default.')"
  else
    to="$(uk_prompt 'Enter target image format' 'webp' 'webp' 'WebP is a good lightweight default for the web and chat apps.')"
  fi
  output="$(uk_prompt 'Enter output directory for converted files' 'converted' '~/converted-media' 'Converted files are written here so your originals stay intact.')"
  strip='n'
  if [[ "$kind" == 'image' ]]; then
    if uk_confirm 'Strip EXIF metadata from images?' 'Y'; then strip=y; else strip=n; fi
  fi
  if uk_confirm 'Apply conversion now?' 'Y'; then apply=y; else apply=n; fi
  local args=()
  [[ ! "$strip" =~ ^[Nn]$ && "$kind" == 'image' ]] && args+=(--strip-exif)
  [[ ! "$apply" =~ ^[Nn]$ ]] && args+=(--apply)
  (mc_main --kind "$kind" --to "$to" --output "$(uk_expand_path "$output")" "${args[@]}" "$(uk_expand_path "$path")")
}
run_toc_wizard() {
  uk_banner "markdown-toc" "Insert or refresh markdown TOC with link validation" ""
  local file apply check align show_diff before after
  file="$(uk_prompt 'Enter markdown file to update' '' 'README.md' 'A table of contents will be inserted or refreshed based on headings in this file.')"
  if uk_confirm 'Apply changes now?' 'Y'; then apply=y; else apply=n; fi
  if uk_confirm 'Check relative links too?' 'Y'; then check=y; else check=n; fi
  if uk_confirm 'Align markdown tables too?' 'Y'; then align=y; else align=n; fi
  if uk_confirm 'Show a unified diff after the change?' 'Y'; then show_diff=y; else show_diff=n; fi
  file="$(uk_expand_path "$file")"
  before="$(mktemp)"
  after="$(mktemp)"
  cp "$file" "$before"
  local args=()
  [[ ! "$apply" =~ ^[Nn]$ ]] && args+=(--apply)
  [[ ! "$check" =~ ^[Nn]$ ]] && args+=(--check-links)
  [[ ! "$align" =~ ^[Nn]$ ]] && args+=(--align-tables)
  (mt_main "$file" "${args[@]}")
  if [[ ! "$show_diff" =~ ^[Nn]$ && -f "$file" ]]; then
    cp "$file" "$after"
    uk_section_title 'Markdown TOC diff'
    diff -u "$before" "$after" || true
  fi
  rm -f "$before" "$after"
}
run_move_wizard() {
  uk_banner "move-in-batch" "Bulk copy or move files with exclusions and collision-safe renaming" ""
  local target output method flatten excludes exclude_args=()
  target="$(uk_prompt 'Enter source directory to copy/move from' '.' '~/Downloads' 'Files under this directory will be transferred recursively.')"
  output="$(uk_prompt 'Enter output directory' './moved-files' '~/Organized' 'The destination must not be inside the source directory.')"
  method="$(uk_prompt 'Transfer method (cp or mv)' 'cp' 'mv' 'cp keeps originals; mv removes originals after transfer.')"
  flatten="$(uk_prompt 'Flatten subdirectories? (y/N)' 'N' 'y' 'Flatten puts all files directly in the output root with collision renames.')"
  excludes="$(uk_prompt 'Optional exclusions separated by spaces' '' '.git .md node_modules' 'Matches filename suffixes and path components; leave blank for none.')"
  if [[ -n "$excludes" ]]; then
    # shellcheck disable=SC2206
    exclude_args=(--exclude $excludes)
  fi
  local args=(--target "$(uk_expand_path "$target")" --output "$(uk_expand_path "$output")" --method "$method")
  [[ "$flatten" =~ ^[Yy]$ ]] && args+=(--flatten)
  [[ ${#exclude_args[@]} -gt 0 ]] && args+=("${exclude_args[@]}")
  (mib_main "${args[@]}")
}
run_pomodoro_wizard() {
  (po_main)
}
run_cheat_wizard() {
  (cs_main)
}
run_setup_wizard() {
  bash "$UK_ROOT_DIR/setup.sh"
}
uk_demo_file() {
  local kind="${1:-}" dir path
  dir="$(uk_state_dir)/demo-fixtures"
  mkdir -p "$dir"
  case "$kind" in
  json)
    path="$dir/demo.json"
    [[ -f "$path" ]] || printf '{"users":[{"name":"ada","email":"ada@example.com"}],"ok":true}\n' >"$path"
    ;;
  csv)
    path="$dir/demo.csv"
    [[ -f "$path" ]] || printf 'name,role\nada,developer\nlinus,maintainer\n' >"$path"
    ;;
  log)
    path="$dir/demo.log"
    [[ -f "$path" ]] || printf 'INFO boot\nWARN cache nearly full\nERROR demo failure\nERROR demo failure\n' >"$path"
    ;;
  env)
    path="$dir/demo.env"
    [[ -f "$path" ]] || printf 'API_TOKEN=demo-token\nAPP_ENV=local\n' >"$path"
    ;;
  archive)
    path="$dir/demo.tar.gz"
    if [[ ! -f "$path" ]]; then
      printf 'demo archive content\n' >"$dir/archive-demo.txt"
      tar -czf "$path" -C "$dir" archive-demo.txt 2>/dev/null || true
    fi
    ;;
  md)
    path="$dir/demo.md"
    [[ -f "$path" ]] || { printf '# Demo\n\n[README](../../README.md)\n' >"$path"; }
    ;;
  *)
    path="$dir/demo.txt"
    [[ -f "$path" ]] || printf 'UtilityKit demo\n' >"$path"
    ;;
  esac
  printf '%s\n' "$path"
}
run_new_utility_wizard() {
  local tool="${1:-}"
  case "$tool" in
  network)
    uk_banner "network-probe" "Ping, DNS lookup, public IP, and route tracing" ""
    local host count dns public trace args=()
    host="$(uk_prompt 'Host to test with ping and route tracing' 'example.com' 'github.com | 1.1.1.1' 'Use a domain or IP address. Missing ping/traceroute tools will be skipped safely.')"
    count="$(uk_prompt 'How many ping packets should be sent?' '4' '4' 'Small numbers are better on mobile networks.')"
    dns="$(uk_prompt 'Domain to use for DNS resolution timing' "$host" 'example.com' 'Usually this can be the same as the target host.')"
    public="$(uk_prompt 'Look up public IP using curl? (Y/n)' 'Y' 'n' 'Requires curl and an internet connection.')"
    trace="$(uk_prompt 'Attempt traceroute/tracepath? (Y/n)' 'Y' 'n' 'Skipped automatically if traceroute tools are unavailable.')"
    args+=("$host" --count "$count" --dns "$dns")
    [[ "$public" =~ ^[Nn]$ ]] && args+=(--no-public-ip)
    [[ "$trace" =~ ^[Nn]$ ]] && args+=(--no-trace)
    (np_main "${args[@]}")
    ;;
  service)
    uk_banner "service-watcher" "HTTP endpoint status and response-time checks" ""
    local urls expect interval
    urls="$(uk_prompt 'Enter one or more URLs separated by spaces' 'https://example.com' 'https://example.com http://127.0.0.1:3000' 'The tool checks HTTP status and response time for each URL.')"
    expect="$(uk_prompt 'Expected status codes/ranges' '2xx,3xx' '200,204,2xx' 'Anything outside this list is marked down.')"
    interval="$(uk_prompt 'Loop interval in seconds (0 for one-time check)' '0' '10' 'Use 0 for a single run.')"
    # shellcheck disable=SC2206
    local arr=($urls)
    (sw_main "${arr[@]}" --expect "$expect" --interval "$interval")
    ;;
  git-stats)
    uk_banner "git-stats" "Commit counts, most-changed files, branch activity" ""
    local repo since
    repo="$(uk_prompt 'Git repository directory to analyze' '.' '~/project' 'Must be inside a Git work tree.')"
    since="$(uk_prompt 'Since date/filter' '30 days ago' '30 days ago | 2026-01-01' 'Default shows recent activity; use direct CLI without --since for all history.')"
    if [[ -n "$since" ]]; then (gst_main --repo "$(uk_expand_path "$repo")" --since "$since"); else (gst_main --repo "$(uk_expand_path "$repo")"); fi
    ;;
  json)
    uk_banner "json-explorer" "JSON pretty-print, dot-path extraction, key listing" ""
    local file mode path
    file="$(uk_prompt 'JSON file path' "$(uk_demo_file json)" './package.json' 'A demo JSON file is used if you just press Enter.')"
    mode="$(uk_prompt 'Mode: pretty, summary, keys, or path' 'summary' 'path' 'summary shows structure; path extracts a dot path like users.0.name.')"
    case "$mode" in
    keys) (jx_main "$(uk_expand_path "$file")" --keys) ;;
    path)
      path="$(uk_prompt 'Dot path to extract' 'users.0.name' 'users.0.email' 'Use numbers for array indexes.')"
      (jx_main "$(uk_expand_path "$file")" --path "$path")
      ;;
    pretty) (jx_main "$(uk_expand_path "$file")") ;;
    *) (jx_main "$(uk_expand_path "$file")" --summary) ;;
    esac
    ;;
  links)
    uk_banner "link-checker" "Markdown link validator with optional HTTP/HTTPS checks" ""
    local files http args=()
    files="$(uk_prompt 'Markdown files to check, separated by spaces' 'README.md' 'README.md docs/*.md' 'Local relative links are checked by default.')"
    http="$(uk_prompt 'Also check HTTP/HTTPS links? (y/N)' 'N' 'y' 'HTTP checks require network access and can be slower.')"
    # shellcheck disable=SC2206
    args=($files)
    [[ "$http" =~ ^[Yy]$ ]] && args+=(--http)
    (lc_main "${args[@]}")
    ;;
  backup)
    uk_banner "backup-sync" "Dry-run-first backup wrapper around rsync" ""
    local src dst apply delete
    src="$(uk_prompt 'Source directory to back up' '.' '~/project' 'The contents of this directory are copied into the destination.')"
    dst="$(uk_prompt 'Destination directory' "$(uk_state_dir)/backup-demo" '~/backup/project' 'Created if missing. Dry-run is default.')"
    delete="$(uk_prompt 'Mirror delete files missing from source? (y/N)' 'N' 'y' 'Dangerous; only enable when destination is dedicated backup storage.')"
    apply="$(uk_prompt 'Apply backup now? (y/N)' 'N' 'y' 'No files are copied unless you answer yes.')"
    local args=(--source "$(uk_expand_path "$src")" --dest "$(uk_expand_path "$dst")")
    [[ "$delete" =~ ^[Yy]$ ]] && args+=(--delete)
    [[ "$apply" =~ ^[Yy]$ ]] && args+=(--apply)
    (bs_main "${args[@]}")
    ;;
  search)
    uk_banner "project-search" "Text or filename search with rg → grep → find fallback" ""
    local dir mode term
    dir="$(uk_prompt 'Directory to search' '.' '~/project' 'Search respects available rg/grep/find behavior.')"
    mode="$(uk_prompt 'Search by text or filename? (text/name)' 'text' 'name' 'Text searches file contents; name searches paths.')"
    term="$(uk_prompt 'Search pattern' 'UtilityKit' 'TODO | *.sh' 'Use a text pattern or filename glob.')"
    if [[ "$mode" == name ]]; then (psrch_main --name "$term" "$(uk_expand_path "$dir")"); else (psrch_main --text "$term" "$(uk_expand_path "$dir")"); fi
    ;;
  log-inspect)
    uk_banner "log-inspector" "Grep error/warn/fail patterns and surface frequent lines" ""
    local file pattern
    file="$(uk_prompt 'Log file to inspect' "$(uk_demo_file log)" './app.log' 'A demo log is used if you just press Enter.')"
    pattern="$(uk_prompt 'Error/warning regex pattern' 'error|warn|fail|exception' 'ERROR|WARN|panic' 'Case-insensitive grep pattern.')"
    (li_main "$(uk_expand_path "$file")" --pattern "$pattern")
    ;;
  csv)
    uk_banner "csv-toolkit" "CSV column header print and row preview" ""
    local file mode
    file="$(uk_prompt 'CSV file to inspect' "$(uk_demo_file csv)" './data.csv' 'A demo CSV is used if you just press Enter.')"
    mode="$(uk_prompt 'Show columns or preview rows? (columns/preview)' 'preview' 'columns' 'Columns prints headers; preview prints first rows.')"
    if [[ "$mode" == columns ]]; then (csvt_main "$(uk_expand_path "$file")" --columns); else (csvt_main "$(uk_expand_path "$file")"); fi
    ;;
  cron)
    uk_banner "cron-manager" "List, add, and remove crontab entries with format validation" ""
    local mode line num apply
    mode="$(uk_prompt 'Action: list, add, or remove' 'list' 'add' 'Requires crontab; Termux may need cronie installed.')"
    case "$mode" in
    add)
      line="$(uk_prompt 'Full cron entry' '*/15 * * * * echo UtilityKit cron demo' '*/15 * * * * /path/to/script.sh' 'Five cron fields followed by the command.')"
      apply="$(uk_prompt 'Apply crontab change? (y/N)' 'N' 'y' 'Dry-run is shown unless you confirm.')"
      [[ "$apply" =~ ^[Yy]$ ]] && (cm_main --add "$line" --apply) || (cm_main --add "$line")
      ;;
    remove)
      num="$(uk_prompt 'Line number to remove from crontab listing' '1' '2' 'Run list first if you are unsure.')"
      apply="$(uk_prompt 'Apply crontab change? (y/N)' 'N' 'y' 'Dry-run is shown unless you confirm.')"
      [[ "$apply" =~ ^[Yy]$ ]] && (cm_main --remove "$num" --apply) || (cm_main --remove "$num")
      ;;
    *) (cm_main --list) ;;
    esac
    ;;
  dotenv)
    uk_banner "dotenv-vault" "Encrypt .env values to ENC:: tokens with gpg" ""
    local file key action apply
    file="$(uk_prompt 'Dotenv file path' "$(uk_demo_file env)" './.env.local' 'A demo dotenv file is used if you just press Enter; encryption still requires gpg.')"
    action="$(uk_prompt 'Action: encrypt or decrypt' 'encrypt' 'decrypt' 'Encrypt modifies selected key only when applied; decrypt prints or writes decrypted output.')"
    if [[ "$action" == decrypt ]]; then (dv_main --file "$(uk_expand_path "$file")" --decrypt); else
      key="$(uk_prompt 'Key to encrypt' 'API_TOKEN' 'API_TOKEN' 'Must already exist in the dotenv file.')"
      apply="$(uk_prompt 'Apply encryption to file? (y/N)' 'N' 'y' 'A backup is created when applied.')"
      [[ "$apply" =~ ^[Yy]$ ]] && (dv_main --file "$(uk_expand_path "$file")" --encrypt "$key" --apply) || (dv_main --file "$(uk_expand_path "$file")" --encrypt "$key")
    fi
    ;;
  disk-health)
    uk_banner "disk-health" "SMART health and attribute report via smartctl" ""
    local mode dev
    mode="$(uk_prompt 'Action: list or device' 'list' 'device' 'Requires smartctl and device permissions; often unavailable in Termux.')"
    if [[ "$mode" == device ]]; then
      dev="$(uk_prompt 'Device path' '/dev/sda' '/dev/sda | /dev/nvme0' 'Use a device shown by --list.')"
      (dh_main --device "$dev")
    else (dh_main --list); fi
    ;;
  weather)
    uk_banner "weather" "Current weather from wttr.in with offline cache fallback" ""
    local loc units
    loc="$(uk_prompt 'Location' 'Kathmandu' 'Kathmandu | London | 27.7,85.3' 'Uses wttr.in through curl; cached result is shown if lookup fails.')"
    units="$(uk_prompt 'Units: metric or imperial' 'metric' 'imperial' 'Metric uses Celsius; imperial uses Fahrenheit.')"
    (wt_main "$loc" --units "$units")
    ;;
  tmux)
    uk_banner "tmux-session" "Friendly wrapper for tmux list / new / attach / kill" ""
    local mode name
    mode="$(uk_prompt 'Action: list, new, attach, or kill' 'list' 'new' 'Requires tmux; Termux users can install with pkg install tmux.')"
    case "$mode" in new)
      name="$(uk_prompt 'New session name' 'work' 'api-server' 'Short memorable names are best.')"
      (tms_main --new "$name")
      ;;
    attach)
      name="$(uk_prompt 'Session name to attach' 'work' 'work' 'Attaching hands control to tmux.')"
      (tms_main --attach "$name")
      ;;
    kill)
      name="$(uk_prompt 'Session name to kill' 'work' 'work' 'This closes the tmux session.')"
      (tms_main --kill "$name")
      ;;
    *) (tms_main --list) ;; esac
    ;;
  font) (fi_main --glyphs) ;;
  toolbox) (tb_main) ;;
  github) (ghh_main --status) ;;
  hash)
    local paths
    paths="$(uk_prompt 'Files/directories to hash, separated by spaces' 'README.md' './README.md' 'Directories are traversed recursively.')" # shellcheck disable=SC2206
    local arr=($paths)
    (ht_main "${arr[@]}")
    ;;
  archive)
    local mode archive dest out paths
    mode="$(uk_prompt 'Action: list, extract, or create' 'list' 'create' 'A demo archive is listed if you just press Enter.')"
    case "$mode" in extract)
      archive="$(uk_prompt 'Archive file' "$(uk_demo_file archive)" './backup.tar.gz' 'Archive paths are checked before extraction.')"
      dest="$(uk_prompt 'Destination directory' './extracted' './out' 'Created if missing.')"
      (am_main --extract "$(uk_expand_path "$archive")" --dest "$(uk_expand_path "$dest")")
      ;;
    create)
      out="$(uk_prompt 'Output archive path' './archive.tar.gz' './backup.tar.gz' 'Use .zip only if zip is installed.')"
      paths="$(uk_prompt 'Input paths separated by spaces' '.' './src README.md' 'These paths are added to the archive.')" # shellcheck disable=SC2206
      local arr=($paths)
      (am_main --create "$(uk_expand_path "$out")" "${arr[@]}")
      ;;
    *)
      archive="$(uk_prompt 'Archive file to list' "$(uk_demo_file archive)" './backup.tar.gz' 'Supports tar archives and zip when unzip exists.')"
      (am_main --list "$(uk_expand_path "$archive")")
      ;;
    esac
    ;;
  snapshot)
    local out
    out="$(uk_prompt 'Optional output file' '' './snapshot.txt' 'Default prints to terminal; enter a path to save a copy.')"
    [[ -n "$out" ]] && (ssn_main --output "$(uk_expand_path "$out")") || (ssn_main)
    ;;
  open-files)
    local mode val
    mode="$(uk_prompt 'Inspect by path or port?' 'path' 'port' 'Requires lsof for best results.')"
    val="$(uk_prompt 'Path or port value' 'README.md' './file.txt | 3000' 'Enter a filesystem path or TCP port.')"
    [[ "$mode" == port ]] && (of_main --port "$val") || (of_main --path "$(uk_expand_path "$val")")
    ;;
  battery) (bd_main) ;;
  release)
    local repo tag
    repo="$(uk_prompt 'Git repository directory' '.' '~/project' 'Shows status and recent commits.')"
    tag="$(uk_prompt 'Optional tag to preview' '' 'v1.2.3' 'Default only shows status; enter a tag to preview tag creation.')"
    [[ -n "$tag" ]] && (rel_main --repo "$(uk_expand_path "$repo")" --tag "$tag") || (rel_main --repo "$(uk_expand_path "$repo")")
    ;;
  license)
    local name
    name="$(uk_prompt 'Name for MIT license generation' 'UtilityKit User' 'Your Name' 'Generated text is printed to terminal.')"
    [[ -n "$name" ]] && (lic_main --generate mit --name "$name") || (lic_main --detect)
    ;;
  regex)
    local pattern text
    pattern="$(uk_prompt 'Regex pattern' 'Util' 'error|warn' 'Uses grep extended regex.')"
    text="$(uk_prompt 'Text to test' 'UtilityKit warning example' 'UtilityKit warning example' 'For file mode use direct CLI --file.')"
    (rx_main --pattern "$pattern" --text "$text")
    ;;
  todo)
    local mode text tag term id
    mode="$(uk_prompt 'Action: list, add, done, or search' 'list' 'add' 'Tasks are stored as plain text in UtilityKit data dir.')"
    case "$mode" in add)
      text="$(uk_prompt 'Task text' 'Review UtilityKit' 'Review UtilityKit PR' 'Short actionable tasks work best.')"
      tag="$(uk_prompt 'Optional tag' 'utilitykit' 'utilitykit' 'Tags help searching later.')"
      (td_main --add "$text" --tag "$tag")
      ;;
    done)
      id="$(uk_prompt 'Task line number to mark done' '1' '1' 'Use list to see numbers.')"
      (td_main --done "$id")
      ;;
    search)
      term="$(uk_prompt 'Search term' 'review' 'review' 'Searches task text and tags.')"
      (td_main --search "$term")
      ;;
    *) (td_main --list) ;; esac
    ;;
  *)
    uk_warn "No wizard is available for $tool yet. Showing help."
    run_tool "$tool" --help
    ;;
  esac
}
uk_menu_execute() {
  local status=0
  run_tool "$@" || status=$?
  if ((status != 0)); then
    uk_warn "The selected tool exited with status $status."
  fi
  return 0
}
run_tool() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
  apply | apply-changes)
    uk_load apply_changes
    ([[ $# -gt 0 ]] && ac_main "$@" || run_apply_wizard)
    ;;
  rename | rename-batch)
    uk_load rename_batch
    ([[ $# -gt 0 ]] && rb_main "$@" || run_rename_wizard)
    ;;
  move | move-in-batch | move-batch)
    uk_load move_in_batch
    ([[ $# -gt 0 ]] && mib_main "$@" || run_move_wizard)
    ;;
  cacheclean | cache-clean)
    uk_load cache_clean
    ([[ $# -gt 0 ]] && cc_main "$@" || cc_main)
    ;;
  symlink | symlink-manager)
    uk_load symlink_manager
    ([[ $# -gt 0 ]] && sm_main "$@" || run_symlink_wizard)
    ;;
  disk | disk-analyzer)
    uk_load disk_analyzer
    ([[ $# -gt 0 ]] && da_main "$@" || run_disk_wizard)
    ;;
  env | env-manager)
    uk_load env_manager
    ([[ $# -gt 0 ]] && em_main "$@" || run_env_wizard)
    ;;
  git | git-sweep)
    uk_load git_sweep
    ([[ $# -gt 0 ]] && gs_main "$@" || run_git_wizard)
    ;;
  docker | docker-janitor)
    uk_load docker_janitor
    if [[ "$(uk_platform)" == 'termux' && $# -eq 0 ]]; then
      uk_warn 'Docker Janitor is not useful in Termux because Docker is usually unavailable there.'
      return 0
    fi
    (dj_main "$@")
    ;;
  scaffold | project-scaffold)
    uk_load project_scaffold
    ([[ $# -gt 0 ]] && ps_main "$@" || run_scaffold_wizard)
    ;;
  dup | duplicate-finder)
    uk_load duplicate_finder
    ([[ $# -gt 0 ]] && df_main "$@" || run_duplicate_wizard)
    ;;
  proc | process-killer)
    uk_load process_killer
    ([[ $# -gt 0 ]] && pk_main "$@" || run_process_wizard)
    ;;
  port | port-inspector)
    uk_load port_inspector
    ([[ $# -gt 0 ]] && pi_main "$@" || run_port_wizard)
    ;;
  ssl | ssl-checker)
    uk_load ssl_checker
    ([[ $# -gt 0 ]] && sc_main "$@" || run_ssl_wizard)
    ;;
  api | api-tester)
    uk_load api_tester
    ([[ $# -gt 0 ]] && at_main "$@" || run_api_wizard)
    ;;
  pass | password | password-gen)
    uk_load password_gen
    ([[ $# -gt 0 ]] && pg_main "$@" || run_password_wizard)
    ;;
  ssh | ssh-assistant)
    uk_load ssh_assistant
    ([[ $# -gt 0 ]] && sa_main "$@" || run_ssh_wizard)
    ;;
  shred | shredder)
    uk_load shredder
    ([[ $# -gt 0 ]] && sd_main "$@" || run_shred_wizard)
    ;;
  media | media-convert)
    uk_load media_convert
    ([[ $# -gt 0 ]] && mc_main "$@" || run_media_wizard)
    ;;
  toc | markdown-toc)
    uk_load markdown_toc
    ([[ $# -gt 0 ]] && mt_main "$@" || run_toc_wizard)
    ;;
  pomodoro | pomo)
    uk_load pomodoro
    ([[ $# -gt 0 ]] && po_main "$@" || run_pomodoro_wizard)
    ;;
  cheat | cheat-sheet)
    uk_load cheat_sheet
    ([[ $# -gt 0 ]] && cs_main "$@" || run_cheat_wizard)
    ;;
  net | network | network-probe)
    uk_load network_probe
    ([[ $# -gt 0 ]] && np_main "$@" || run_new_utility_wizard network)
    ;;
  cron | cron-manager)
    uk_load cron_manager
    ([[ $# -gt 0 ]] && cm_main "$@" || run_new_utility_wizard cron)
    ;;
  dotenv | dotenv-vault)
    uk_load dotenv_vault
    ([[ $# -gt 0 ]] && dv_main "$@" || run_new_utility_wizard dotenv)
    ;;
  disk-health | smart)
    uk_load disk_health
    ([[ $# -gt 0 ]] && dh_main "$@" || run_new_utility_wizard disk-health)
    ;;
  watch | service | service-watcher)
    uk_load service_watcher
    ([[ $# -gt 0 ]] && sw_main "$@" || run_new_utility_wizard service)
    ;;
  git-stats | gstats)
    uk_load git_stats
    ([[ $# -gt 0 ]] && gst_main "$@" || run_new_utility_wizard git-stats)
    ;;
  backup | backup-sync)
    uk_load backup_sync
    ([[ $# -gt 0 ]] && bs_main "$@" || run_new_utility_wizard backup)
    ;;
  weather)
    uk_load weather
    ([[ $# -gt 0 ]] && wt_main "$@" || run_new_utility_wizard weather)
    ;;
  json | json-explorer)
    uk_load json_explorer
    ([[ $# -gt 0 ]] && jx_main "$@" || run_new_utility_wizard json)
    ;;
  tmux | tmux-session)
    uk_load tmux_session
    ([[ $# -gt 0 ]] && tms_main "$@" || run_new_utility_wizard tmux)
    ;;
  font | font-inspector)
    uk_load font_inspector
    ([[ $# -gt 0 ]] && fi_main "$@" || run_new_utility_wizard font)
    ;;
  toolbox | toolbox-bootstrap)
    uk_load toolbox_bootstrap
    ([[ $# -gt 0 ]] && tb_main "$@" || run_new_utility_wizard toolbox)
    ;;
  search | project-search)
    uk_load project_search
    ([[ $# -gt 0 ]] && psrch_main "$@" || run_new_utility_wizard search)
    ;;
  github | github-helper)
    uk_load github_helper
    ([[ $# -gt 0 ]] && ghh_main "$@" || run_new_utility_wizard github)
    ;;
  links | link-checker)
    uk_load link_checker
    ([[ $# -gt 0 ]] && lc_main "$@" || run_new_utility_wizard links)
    ;;
  log-inspect | log-inspector)
    uk_load log_inspector
    ([[ $# -gt 0 ]] && li_main "$@" || run_new_utility_wizard log-inspect)
    ;;
  csv | csv-toolkit)
    uk_load csv_toolkit
    ([[ $# -gt 0 ]] && csvt_main "$@" || run_new_utility_wizard csv)
    ;;
  hash | hash-tools)
    uk_load hash_tools
    ([[ $# -gt 0 ]] && ht_main "$@" || run_new_utility_wizard hash)
    ;;
  archive | archive-manager)
    uk_load archive_manager
    ([[ $# -gt 0 ]] && am_main "$@" || run_new_utility_wizard archive)
    ;;
  snapshot | system-snapshot)
    uk_load system_snapshot
    ([[ $# -gt 0 ]] && ssn_main "$@" || run_new_utility_wizard snapshot)
    ;;
  open-files | lsof)
    uk_load open_files
    ([[ $# -gt 0 ]] && of_main "$@" || run_new_utility_wizard open-files)
    ;;
  battery | battery-doctor)
    uk_load battery_doctor
    ([[ $# -gt 0 ]] && bd_main "$@" || run_new_utility_wizard battery)
    ;;
  release | release-helper)
    uk_load release_helper
    ([[ $# -gt 0 ]] && rel_main "$@" || run_new_utility_wizard release)
    ;;
  license | license-helper)
    uk_load license_helper
    ([[ $# -gt 0 ]] && lic_main "$@" || run_new_utility_wizard license)
    ;;
  todo | todo-manager)
    uk_load todo_manager
    ([[ $# -gt 0 ]] && td_main "$@" || run_new_utility_wizard todo)
    ;;
  update | update-managers | upgrade)
    uk_load update_managers
    # With args, pass straight through (e.g. --list, --dry-run, --only apt,brew).
    # With no args, launch the tool's own rich interactive menu.
    (um_main "$@")
    ;;
  setup | install) bash "$UK_ROOT_DIR/setup.sh" "$@" ;;
  help | --help | -h) uk_main_show_help ;;
  doctor | diagnostics)
    uk_doctor "$@"
    ;;
  *)
    uk_error "Unknown command: $cmd"
    uk_main_show_help
    return 1
    ;;
  esac
}
# =============================================================================
# uk_doctor — installation & registry integrity checks
# -----------------------------------------------------------------------------
# Validates that the single-source-of-truth UK_REGISTRY agrees with reality:
#   1. every registry tool has its directory + script on disk
#   2. every registry action has a matching run_tool dispatch case
#   3. the derived dashboard menu arrays are all the same length
#   4. every tool answers `--help` (optional deep check, on by default)
#   5. reports orphan tool directories not present in the registry
# Exit status is nonzero if any hard problem is found, so it is CI-friendly.
# Flags: --quick (skip the per-tool --help check), --no-color
# =============================================================================
uk_doctor() {
  local quick=0 arg
  for arg in "$@"; do
    case "$arg" in
    --quick) quick=1 ;;
    --no-color) UK_C_RESET='' ;;
    esac
  done

  local problems=0 warnings=0 checked=0
  local ok="${UK_C_GREEN}${UK_I_READY:-OK}${UK_C_RESET}"
  local bad="${UK_C_RED}x${UK_C_RESET}"
  local wrn="${UK_C_YELLOW}!${UK_C_RESET}"

  printf '\n%s UtilityKit Doctor%s  %s(registry + installation integrity)%s\n\n' \
    "$UK_C_BOLD$UK_C_BRIGHT_CYAN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"

  # --- 1 & 2: registry vs disk vs dispatch -----------------------------------
  printf '%sRegistry checks%s\n' "$UK_C_BOLD" "$UK_C_RESET"
  local rec key action rest path dispatch_body
  dispatch_body="$(declare -f run_tool 2>/dev/null || true)"

  for rec in "${UK_REGISTRY[@]}"; do
    key="${rec%%|*}"
    rest="${rec#*|}"
    action="${rest%%|*}"
    checked=$((checked + 1))
    path="${UK_TOOL_PATHS[$key]:-}"

    # (a) path mapped?
    if [[ -z "$path" ]]; then
      printf '  %s %-20s no path derived for key\n' "$bad" "$key"
      problems=$((problems + 1))
      continue
    fi
    # (b) script exists?
    if [[ ! -f "$path" ]]; then
      printf '  %s %-20s missing script: %s\n' "$bad" "$key" "$path"
      problems=$((problems + 1))
      continue
    fi
    # (c) dispatch case exists for the action?
    if [[ -n "$dispatch_body" ]] && ! printf '%s' "$dispatch_body" | grep -Eq "(^|[^A-Za-z0-9_-])$action([^A-Za-z0-9_-]|\))"; then
      printf '  %s %-20s no run_tool case for action "%s"\n' "$wrn" "$key" "$action"
      warnings=$((warnings + 1))
      continue
    fi
    printf '  %s %-20s %s\n' "$ok" "$key" "${UK_C_DIM}ok${UK_C_RESET}"
  done

  # --- 3: menu array alignment ------------------------------------------------
  printf '\n%sDashboard menu%s\n' "$UK_C_BOLD" "$UK_C_RESET"
  load_all_tools
  local ni=${#M_ICONS[@]} nc=${#M_COLORS[@]} nn=${#M_NAMES[@]} nd=${#M_DESCS[@]} na=${#M_ACTIONS[@]}
  if [[ "$ni" == "$nc" && "$nc" == "$nn" && "$nn" == "$nd" && "$nd" == "$na" ]]; then
    printf '  %s all 5 menu arrays aligned (%d entries)\n' "$ok" "$na"
  else
    printf '  %s menu arrays MISALIGNED: icons=%d colors=%d names=%d descs=%d actions=%d\n' \
      "$bad" "$ni" "$nc" "$nn" "$nd" "$na"
    problems=$((problems + 1))
  fi

  # --- 5: orphan directories --------------------------------------------------
  printf '\n%sOrphan directories%s\n' "$UK_C_BOLD" "$UK_C_RESET"
  local d dkey found orphans=0
  for d in "$UK_ROOT_DIR"/_*/; do
    [[ -d "$d" ]] || continue
    dkey="$(basename "$d")"
    dkey="${dkey#_}"
    found=0
    for rec in "${UK_REGISTRY[@]}"; do [[ "${rec%%|*}" == "$dkey" ]] && {
      found=1
      break
    }; done
    if [[ "$found" -eq 0 ]]; then
      printf '  %s %-20s on disk but not in registry\n' "$wrn" "$dkey"
      warnings=$((warnings + 1))
      orphans=$((orphans + 1))
    fi
  done
  [[ "$orphans" -eq 0 ]] && printf '  %s none\n' "$ok"

  # --- 4: per-tool --help (deep) ---------------------------------------------
  if [[ "$quick" -eq 0 ]]; then
    printf '\n%sPer-tool --help%s %s(use --quick to skip)%s\n' \
      "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
    for rec in "${UK_REGISTRY[@]}"; do
      key="${rec%%|*}"
      rest="${rec#*|}"
      action="${rest%%|*}"
      if NO_COLOR=1 bash "$UK_ROOT_DIR/main.sh" "$action" --help >/dev/null 2>&1; then
        printf '  %s %-20s\n' "$ok" "$action"
      else
        printf '  %s %-20s "%s --help" failed\n' "$bad" "$key" "$action"
        problems=$((problems + 1))
      fi
    done
  fi

  # --- summary ----------------------------------------------------------------
  printf '\n%s────────────────────────────────────────────%s\n' "$UK_C_DIM" "$UK_C_RESET"
  printf '  Checked %d tools — %s%d problem(s)%s, %s%d warning(s)%s\n\n' \
    "$checked" \
    "$([[ $problems -gt 0 ]] && printf '%s' "$UK_C_RED" || printf '%s' "$UK_C_GREEN")" "$problems" "$UK_C_RESET" \
    "$([[ $warnings -gt 0 ]] && printf '%s' "$UK_C_YELLOW" || printf '%s' "$UK_C_GREEN")" "$warnings" "$UK_C_RESET"

  [[ "$problems" -eq 0 ]]
}

uk_main_show_help() {
  uk_main_banner
  cat <<'EOF'
Usage:
  ./main.sh <command> [args]

Core commands:
  apply, rename, move, cacheclean, symlink, disk, env, git, scaffold, dup,
  proc, port, ssl, api, pass, ssh, shred, media, toc, pomodoro,
  cheat, setup, docker

New utility commands:
  network, cron, dotenv, disk-health, service, git-stats, backup,
  weather, json, tmux, font, toolbox, search, github, links, log-inspect,
  csv, hash, archive, snapshot, open-files, battery, release, license, todo,
  update

Maintenance:
  doctor     Run integrity checks on the tool registry and installation

Use ./main.sh <command> --help for each tool's detailed options.
EOF
}

# Keypress listener translating Arrows, Enter and Vim keys.
uk_read_key() {
  local key
  IFS= read -rsn1 key 2>/dev/null || true
  if [[ "$key" == $'\x1b' ]]; then
    read -rsn2 -t 0.1 key 2>/dev/null || true
    case "$key" in
    '[A' | 'OA') echo "UP" ;;
    '[B' | 'OB') echo "DOWN" ;;
    *) echo "ESC" ;;
    esac
  elif [[ "$key" == "" ]]; then
    echo "ENTER"
  else
    echo "$key"
  fi
}

# Flat arrays for the master unified list
declare -a M_ICONS=()
declare -a M_COLORS=()
declare -a M_NAMES=()
declare -a M_DESCS=()
declare -a M_ACTIONS=()

load_all_tools() {
  # The dashboard menu is now DERIVED from UK_REGISTRY (single source of truth),
  # so it can never fall out of sync with the loader map again. Only tools with
  # menu flag = 1 are shown here; the trailing "Setup / Install" pseudo-entry is
  # appended because it is a launcher action, not a tool directory.
  M_ICONS=()
  M_COLORS=()
  M_NAMES=()
  M_DESCS=()
  M_ACTIONS=()

  local rec key action icon color_var name desc menu color
  for rec in "${UK_REGISTRY[@]}"; do
    IFS='|' read -r key action icon color_var name desc menu <<<"$rec"
    [[ "$menu" == "1" ]] || continue
    # Indirectly expand the color variable name (e.g. UK_C_GREEN) to its code.
    color="${!color_var:-$UK_C_WHITE}"
    M_ICONS+=("$icon")
    M_COLORS+=("$color")
    M_NAMES+=("$name")
    M_DESCS+=("$desc")
    M_ACTIONS+=("$action")
  done

  # Launcher / installer pseudo-tool (kept last, matches historical behavior).
  M_ICONS+=("⚙")
  M_COLORS+=("$UK_C_WHITE")
  M_NAMES+=("Setup / Install")
  M_DESCS+=("Launcher & Path Configuration")
  M_ACTIONS+=("setup")

  # Hide Docker Janitor in Termux
  if [[ "$(uk_platform)" == 'termux' ]]; then
    local i
    for ((i = 0; i < ${#M_ACTIONS[@]}; i++)); do
      if [[ "${M_ACTIONS[$i]}" == "docker" ]]; then
        M_COLORS[$i]="$UK_C_DIM"
        M_DESCS[$i]="unavailable / usually not useful in Termux"
        break
      fi
    done
  fi
}

interactive_menu_loop() {
  # Gate the dashboard on a 78-column terminal — the master banner ASCII art
  # and the item viewport are both hand-tuned for that width. The check is a
  # no-op on non-TTYs and when UK_NO_WIDTH_GATE=1, so smoke tests, pipes, and
  # `main.sh <cmd>` CLI invocations are unaffected.
  uk_require_width || { printf '\n'; return 0; }

  load_all_tools

  local TOTAL_ITEMS=${#M_ACTIONS[@]}
  local SELECTED_INDEX=0
  local WINDOW_START=0
  local VISIBLE_COUNT=8 # Strictly sets the visible viewport item count

  # Hide the cursor while the interactive menu is active, and make sure
  # it gets restored no matter how the script exits (clean exit, Ctrl+C,
  # SIGTERM, or any uncaught error from `set -e`).
  uk_cursor_show() { tput cnorm 2>/dev/null || printf '\033[?25h'; }
  uk_cursor_hide() { tput civis 2>/dev/null || printf '\033[?25l'; }
  trap 'uk_cursor_show' EXIT INT TERM HUP
  uk_cursor_hide

  # Print banner ONCE to eliminate top-level screen flicker
  uk_main_banner
  # Save the cursor position right below the banner (ANSI standard)
  printf '\033[s'

  while true; do
    # Boundary logic for looping array
    if ((SELECTED_INDEX < 0)); then
      SELECTED_INDEX=$((TOTAL_ITEMS - 1))
    elif ((SELECTED_INDEX >= TOTAL_ITEMS)); then
      SELECTED_INDEX=0
    fi

    # Viewport tracking: Moves the sliding window of visible items
    if ((SELECTED_INDEX < WINDOW_START)); then
      WINDOW_START=$SELECTED_INDEX
    elif ((SELECTED_INDEX >= WINDOW_START + VISIBLE_COUNT)); then
      WINDOW_START=$((SELECTED_INDEX - VISIBLE_COUNT + 1))
    fi

    # Restore cursor to below banner and clear everything downwards
    printf '\033[u\033[0J'

    printf '  %s❯ %sUtilityKit Master Suite%s — %sTool %d of %d%s\n\n' \
      "$UK_C_BOLD" "$UK_C_BOLD$UK_C_GREEN" "$UK_C_RESET" \
      "$UK_C_DIM" "$((SELECTED_INDEX + 1))" "$TOTAL_ITEMS" "$UK_C_RESET"

    # Upwards scrolling indicator
    if ((WINDOW_START > 0)); then
      printf '     %s▲  (scroll up for more tools)%s\n' "$UK_C_DIM" "$UK_C_RESET"
    else
      printf '\n' # Maintain spacing consistency
    fi

    # Print the visible chunk of tools (The Viewport)
    local i
    for ((i = WINDOW_START; i < WINDOW_START + VISIBLE_COUNT; i++)); do
      if ((i >= TOTAL_ITEMS)); then break; fi

      local icon="${M_ICONS[$i]}"
      local color="${M_COLORS[$i]}"
      local name="${M_NAMES[$i]}"
      local desc="${M_DESCS[$i]}"

      if ((i == SELECTED_INDEX)); then
        printf '  %s➔%s  %s%s %-18s%s %s(%s)%s\n' \
          "$UK_C_BRIGHT_CYAN" "$UK_C_RESET" \
          "$UK_C_BOLD$color" "$icon" "$name" "$UK_C_RESET" \
          "$UK_C_BOLD" "$desc" "$UK_C_RESET"
      else
        printf '     %s%s %-18s%s %s(%s)%s\n' \
          "$UK_C_BOLD$color" "$icon" "$name" "$UK_C_RESET" \
          "$UK_C_DIM" "$desc" "$UK_C_RESET"
      fi
    done

    # Downwards scrolling indicator
    if ((WINDOW_START + VISIBLE_COUNT < TOTAL_ITEMS)); then
      printf '     %s▼  (scroll down for more tools)%s\n' "$UK_C_DIM" "$UK_C_RESET"
    else
      printf '\n'
    fi

    # Static Footer Legend
    printf '\n  %s──────────────────────────────────────────────────────────────────────%s\n' "$UK_C_DIM" "$UK_C_RESET"
    printf '  %sNavigation Info:%s\n\n' "$UK_C_BOLD$UK_C_WHITE" "$UK_C_RESET"
    printf '   Use %s▲/▼%s or %sj/k%s : Scroll Tools         %s[Enter]%s : Execute selected\n' \
      "$UK_C_BRIGHT_CYAN" "$UK_C_RESET" "$UK_C_BRIGHT_CYAN" "$UK_C_RESET" \
      "$UK_C_BRIGHT_GREEN" "$UK_C_RESET"
    printf '                                         %s[q]%s     : Exit UtilityKit\n' \
      "$UK_C_RED" "$UK_C_RESET"
    printf '\n'

    local key_press
    key_press=$(uk_read_key)

    case "$key_press" in
    UP | k | K)
      SELECTED_INDEX=$((SELECTED_INDEX - 1))
      ;;
    DOWN | j | J)
      SELECTED_INDEX=$((SELECTED_INDEX + 1))
      ;;
    ENTER)
      local act="${M_ACTIONS[$SELECTED_INDEX]}"

      # Show the cursor while the tool runs and accepts input, then
      # hide it again once we re-enter the menu.
      uk_cursor_show

      # We clear the screen right before executing the tool, so the tool's
      # output takes over smoothly without crashing into the menu.
      clear 2>/dev/null || printf '\n'

      uk_menu_execute "$act"

      printf '\n  %sPress Enter to return to the UtilityKit Dashboard...%s' "$UK_C_DIM" "$UK_C_RESET"
      read -r 2>/dev/null || true

      uk_cursor_hide

      # When coming back from a tool, the screen is dirty.
      # We MUST re-print the master banner and re-save the cursor position.
      uk_main_banner
      printf '\033[s'
      ;;
    q | Q)
      uk_cursor_show
      exit 0
      ;;
    esac
  done
}

if [[ $# -gt 0 ]]; then
  subcmd="${1:-}"
  shift
  run_tool "$subcmd" "$@"
else
  interactive_menu_loop
fi
