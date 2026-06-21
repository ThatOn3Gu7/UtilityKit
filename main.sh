#!/usr/bin/env bash
# UtilityKit central hub
set -euo pipefail
readonly UK_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UK_ROOT_DIR/lib/uk_common.sh"

readonly UK_VERSION='4.1.2'

uk_source_tool() {
  local path="$1"
  [[ -f "$path" ]] || { uk_warn "Missing tool: $path"; return 0; }
  # shellcheck disable=SC1090
  source "$path"
}

uk_source_tool "$UK_ROOT_DIR/_apply_changes/_apply_changes.sh"
uk_source_tool "$UK_ROOT_DIR/_rename_batch/_rename_batch.sh"
uk_source_tool "$UK_ROOT_DIR/_move_in_batch/_move_in_batch.sh"
uk_source_tool "$UK_ROOT_DIR/_cache_clean/_cache_clean.sh"
uk_source_tool "$UK_ROOT_DIR/_symlink_manager/_symlink_manager.sh"
uk_source_tool "$UK_ROOT_DIR/_disk_analyzer/_disk_analyzer.sh"
uk_source_tool "$UK_ROOT_DIR/_env_manager/_env_manager.sh"
uk_source_tool "$UK_ROOT_DIR/_git_sweep/_git_sweep.sh"
uk_source_tool "$UK_ROOT_DIR/_docker_janitor/_docker_janitor.sh"
uk_source_tool "$UK_ROOT_DIR/_project_scaffold/_project_scaffold.sh"
uk_source_tool "$UK_ROOT_DIR/_duplicate_finder/_duplicate_finder.sh"
uk_source_tool "$UK_ROOT_DIR/_log_rotator/_log_rotator.sh"
uk_source_tool "$UK_ROOT_DIR/_process_killer/_process_killer.sh"
uk_source_tool "$UK_ROOT_DIR/_port_inspector/_port_inspector.sh"
uk_source_tool "$UK_ROOT_DIR/_ssl_checker/_ssl_checker.sh"
uk_source_tool "$UK_ROOT_DIR/_api_tester/_api_tester.sh"
uk_source_tool "$UK_ROOT_DIR/_password_gen/_password_gen.sh"
uk_source_tool "$UK_ROOT_DIR/_ssh_assistant/_ssh_assistant.sh"
uk_source_tool "$UK_ROOT_DIR/_shredder/_shredder.sh"
uk_source_tool "$UK_ROOT_DIR/_media_convert/_media_convert.sh"
uk_source_tool "$UK_ROOT_DIR/_markdown_toc/_markdown_toc.sh"
uk_source_tool "$UK_ROOT_DIR/_pomodoro/_pomodoro.sh"
uk_source_tool "$UK_ROOT_DIR/_cheat_sheet/_cheat_sheet.sh"
uk_source_tool "$UK_ROOT_DIR/_zen_mode/_zen_mode.sh"

uk_expand_path() {
  local input="$1"
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

███████╗████████╗██╗██╗     ██╗████████╗██╗   ██╗██╗  ██╗██╗████████╗
██╔════╝╚══██╔══╝██║██║     ██║╚══██╔══╝╚██╗ ██╔╝██║ ██╔╝██║╚══██╔══╝
███████╗   ██║   ██║██║     ██║   ██║    ╚████╔╝ █████╔╝ ██║   ██║   
╚════██║   ██║   ██║██║     ██║   ██║     ╚██╔╝  ██╔═██╗ ██║   ██║   
███████║   ██║   ██║███████╗██║   ██║      ██║   ██║  ██╗██║   ██║   
╚══════╝   ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝   ╚═╝${UK_C_RESET}
EOF
  printf '%s\n' "${UK_C_DIM}----------------------------------------------------------------------${UK_C_RESET}"
  printf "        %s %s READY%s   %s %s UtilityKit Central Hub %s Suite %sv%s%s\n" \
         "$UK_C_GREEN" "$UK_I_READY" "$UK_C_RESET" "$UK_C_DIM$UK_I_SEP$UK_C_RESET" \
         "$UK_C_BOLD$UK_C_WHITE" "$UK_C_RESET$UK_C_DIM$UK_I_SEP$UK_C_RESET" "$UK_C_BRIGHT_BLUE" "${UK_VERSION}" "$UK_C_RESET"
  printf '%s\n\n' "${UK_C_DIM}----------------------------------------------------------------------${UK_C_RESET}"
}

uk_home_menu() {
  printf '  %s❯ %sPlease select a utility from the suite below:%s\n\n' "$UK_C_BOLD" "$UK_C_BOLD$UK_C_GREEN" "$UK_C_RESET"
  printf '    %s1)%s %s↻ Apply Changes%s    %s(Robust Directory Synchronization)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_BOLD$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    %s2)%s %s✎ Batch Rename%s     %s(Recursive File Renaming & Copying)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_BOLD$UK_C_BRIGHT_BLUE" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    %s3)%s %s🗑 Cache Cleaner%s    %s(Intelligent System Cache Cleanup)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_BOLD$UK_C_BRIGHT_MAGENTA" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    %s4)%s %s► Symlink Manager%s  %s(Dotfiles & System Config Management)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_BOLD$UK_C_YELLOW" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    %s5)%s %s◆ Disk Analyzer%s    %s(Storage Inspection & Quick Archiving)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_BOLD$UK_C_BRIGHT_CYAN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    %s6)%s %s⚙ Setup / Install%s  %s(Launcher & Path Configuration)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_BOLD$UK_C_WHITE" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    %sm)%s %s☰ More tools%s       %s(Load additional utilities)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_BOLD$UK_C_CYAN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    %sq)%s %s✖ Quit UtilityKit%s  %s(Quit out of UtilityKit)%s\n' "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_BOLD$UK_C_RED" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
}

uk_more_menu_page_1() {
  printf ' %s❯ %sMore tools%s — %sPage 1 of 2%s\n\n' "$UK_C_BOLD" "$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    %s1)%s Env Manager       2) Git Sweep         3) Project Scaffold\n' "$UK_C_BOLD" "$UK_C_RESET"
  printf '    %s4)%s Duplicate Finder  5) Log Rotator       6) Process Killer\n' "$UK_C_BOLD" "$UK_C_RESET"
  printf '    %s7)%s Port Inspector    8) Next Page         b) Back to Home\n\n' "$UK_C_BOLD" "$UK_C_RESET"
}

uk_more_menu_page_2() {
  printf '  %s❯ %sMore tools%s — %sPage 2 of 2%s\n\n' "$UK_C_BOLD" "$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  printf '    1) SSL Checker       2) API Tester        3) Password Generator\n'
  printf '    4) SSH Assistant     5) Shredder          6) Media Convert\n'
  printf '    7) Markdown TOC      8) Pomodoro          9) Cheat Sheet\n'
  printf '   10) Move in Batch\n'
  if [[ "$(uk_platform)" != 'termux' ]]; then
    printf '   11) Docker Janitor\n'
  else
    printf '   11) Docker Janitor    %s(unavailable in Termux)%s\n' "$UK_C_DIM" "$UK_C_RESET"
  fi
  printf '    p) Previous Page     b) Back to Home      q) Quit\n\n'
}

run_apply_wizard() {
  uk_section_title 'Directory Synchronization (Apply Changes)'
  local src dst apply mirror force include_runtime custom
  src="$(uk_prompt 'Enter updated source directory to sync from' '.' '~/path/to/source' 'Use a directory that contains the newest version of your files.')"
  dst="$(uk_prompt 'Enter local target directory to update' '.' '~/path/to/target' 'The target directory will be compared against the source.')"
  printf ' %s Apply changes now? [y/N]: ' "$UK_I_ARROW" >&2; read -r apply
  printf ' %s Mirror delete missing target files too? [y/N]: ' "$UK_I_ARROW" >&2; read -r mirror
  printf ' %s Force past local git changes if needed? [y/N]: ' "$UK_I_ARROW" >&2; read -r force
  printf ' %s Include runtime logs/tmp files? [y/N]: ' "$UK_I_ARROW" >&2; read -r include_runtime
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
  ( ac_main "${args[@]}" "$(uk_expand_path "$src")" "$(uk_expand_path "$dst")" )
}

run_rename_wizard() {
  uk_section_title 'Batch File Renamer'
  local src ext out force
  src="$(uk_prompt 'Enter target directory to process' '.' '~/path/to/your/directory' 'Every non-hidden file in this folder tree will be considered.')"
  ext="$(uk_prompt 'Enter target new extension format (e.g. sh, py, txt)' '' '.md' 'Do not worry about the leading dot; both md and .md work.')"
  out="$(uk_prompt 'Enter output export directory (leave blank for in-place rename)' '' '~/path/to/export-folder' 'Leave blank to rename files where they already live.')"
  printf ' %s Force protected files too (README, LICENSE, *.md, *.json)? [y/N]: ' "$UK_I_ARROW" >&2
  read -r force
  if [[ "$force" =~ ^[Yy]$ ]]; then
    if [[ -n "$out" ]]; then
      ( rb_main --force "$(uk_expand_path "$src")" "$ext" "$(uk_expand_path "$out")" )
    else
      ( rb_main --force "$(uk_expand_path "$src")" "$ext" )
    fi
  else
    if [[ -n "$out" ]]; then
      ( rb_main "$(uk_expand_path "$src")" "$ext" "$(uk_expand_path "$out")" )
    else
      ( rb_main "$(uk_expand_path "$src")" "$ext" )
    fi
  fi
}

run_symlink_wizard() {
  uk_section_title 'Symlink Manager'
  local src dst apply
  src="$(uk_prompt 'Enter source file or directory to link from' '' '~/.dotfiles/.bashrc' 'This is the real file or folder that should back the symlink.')"
  dst="$(uk_prompt 'Enter target link path to create or replace' '' '~/.bashrc' 'If the target already exists, the tool can back it up first.')"
  printf ' %s Apply the symlink change now? [Y/n]: ' "$UK_I_ARROW" >&2
  read -r apply
  if [[ "$apply" =~ ^[Nn]$ ]]; then
    ( sm_main "$(uk_expand_path "$src")" "$(uk_expand_path "$dst")" )
  else
    ( sm_main --apply -y "$(uk_expand_path "$src")" "$(uk_expand_path "$dst")" )
  fi
}

run_disk_wizard() {
  uk_section_title 'Disk Space Analyzer'
  local dir count
  dir="$(uk_prompt 'Enter target directory to scan' '.' '~/projects' 'For large folders, the scan can take a little while.')"
  count="$(uk_prompt 'Enter how many top items to display' '10' '15' 'Smaller numbers render faster and are easier to read on mobile screens.')"
  ( da_main --count "$count" "$(uk_expand_path "$dir")" )
}

run_env_wizard() {
  uk_section_title 'Environment Profile Manager'
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
    1) ( em_main --dir "$dir" --compare ) ;;
    2)
      file="$(uk_prompt 'Enter env file path to validate' "$dir/.env" "$dir/.env.production" 'The validator checks key=value syntax lines.')"
      ( em_main --validate "$(uk_expand_path "$file")" )
      ;;
    3)
      profile="$(uk_prompt 'Enter profile name without the .env. prefix' 'local' 'production' 'For example, profile=local means the tool will use .env.local.')"
      ( em_main --dir "$dir" --profile "$profile" --apply )
      ;;
    4)
      file="$(uk_prompt 'Enter the file path to encrypt' "$dir/.env" "$dir/.env.production" 'The tool will use gpg first, or openssl as a fallback.')"
      ( em_main --encrypt "$(uk_expand_path "$file")" )
      ;;
    5)
      file="$(uk_prompt 'Enter the .gpg or .enc file path to decrypt' '' "$dir/.env.production.gpg" 'The decrypted content will be printed by the active backend tool.')"
      ( em_main --decrypt "$(uk_expand_path "$file")" )
      ;;
    *) uk_warn 'No env-manager action selected.' ;;
  esac
}

run_git_wizard() {
  uk_section_title 'Git Sweep'
  local repo
  repo="$(uk_prompt 'Enter the Git repository directory to inspect' '.' '~/project' 'The tool looks for merged branches, stashes, artifacts, and git gc opportunities.')"
  ( gs_main --repo "$(uk_expand_path "$repo")" )
}

run_scaffold_wizard() {
  uk_section_title 'Project Scaffold'
  local type name dest
  type="$(uk_prompt 'Enter scaffold type (bash, python-flask, node-cli, go-service)' 'bash' 'python-flask' 'A new project folder will be generated for the selected stack.')"
  name="$(uk_prompt 'Enter the new project folder name' '' 'demo-app' 'This becomes the generated project directory name.')"
  dest="$(uk_prompt 'Enter the parent destination directory' '.' '~/projects' 'The generated folder will be created inside this destination.')"
  ( ps_main --type "$type" --name "$name" --dest "$(uk_expand_path "$dest")" )
}

run_duplicate_wizard() {
  uk_section_title 'Duplicate Finder'
  local dir mode apply_args=()
  dir="$(uk_prompt 'Enter directory to scan for duplicate files' '.' '~/Downloads' 'The tool matches file sizes first, then hashes exact candidates.')"
  printf '  1) Report only\n  2) Delete duplicates and keep the first copy\n  3) Replace duplicates with hardlinks\n'
  printf ' %s Choose an action: ' "$UK_I_ARROW" >&2
  read -r mode
  case "$mode" in
    1) ( df_main "$(uk_expand_path "$dir")" ) ;;
    2) ( df_main "$(uk_expand_path "$dir")" --delete --apply ) ;;
    3) ( df_main "$(uk_expand_path "$dir")" --hardlink --apply ) ;;
    *) uk_warn 'No duplicate-finder action selected.' ;;
  esac
}

run_logs_wizard() {
  uk_section_title 'Log Rotator'
  local path older purge archive apply
  path="$(uk_prompt 'Enter a log directory to rotate' './logs' '~/project/logs' 'Use a folder that contains old log files you want to archive.')"
  older="$(uk_prompt 'Archive logs older than how many days?' '7' '30' 'Files older than this threshold are packaged into a tar.gz archive.')"
  purge="$(uk_prompt 'Purge old archives after how many days?' '30' '90' 'Old archive files past this threshold will be removed.')"
  archive="$(uk_prompt 'Enter archive output directory' '' '~/log-archives' 'Leave blank to use the default UtilityKit state directory.')"
  printf ' %s Apply archive and purge now? [Y/n]: ' "$UK_I_ARROW" >&2
  read -r apply
  if [[ -n "$archive" ]]; then
    if [[ "$apply" =~ ^[Nn]$ ]]; then
      ( lr_main --path "$(uk_expand_path "$path")" --older-than "$older" --purge-older-than "$purge" --archive-dir "$(uk_expand_path "$archive")" )
    else
      ( lr_main --path "$(uk_expand_path "$path")" --older-than "$older" --purge-older-than "$purge" --archive-dir "$(uk_expand_path "$archive")" --apply )
    fi
  else
    if [[ "$apply" =~ ^[Nn]$ ]]; then
      ( lr_main --path "$(uk_expand_path "$path")" --older-than "$older" --purge-older-than "$purge" )
    else
      ( lr_main --path "$(uk_expand_path "$path")" --older-than "$older" --purge-older-than "$purge" --apply )
    fi
  fi
}

run_process_wizard() {
  uk_section_title 'Process Killer'
  local pid sig
  printf '  The tool will show memory pressure and the top memory consumers first.\n'
  pid="$(uk_prompt 'Enter a PID to terminate (leave blank to only inspect processes)' '' '12345' 'If you leave this blank, no signal will be sent.')"
  if [[ -n "$pid" ]]; then
    sig="$(uk_prompt 'Enter signal type (TERM or KILL)' 'TERM' 'KILL' 'TERM is safer; KILL is more forceful.')"
    ( pk_main --pid "$pid" --signal "$sig" )
  else
    ( pk_main )
  fi
}

run_port_wizard() {
  uk_section_title 'Port Inspector'
  local port kill_flag
  port="$(uk_prompt 'Enter the local TCP port to inspect' '' '3000' 'The tool will search for whichever process is listening on this port.')"
  printf ' %s Terminate the process if one is found? [y/N]: ' "$UK_I_ARROW" >&2
  read -r kill_flag
  if [[ "$kill_flag" =~ ^[Yy]$ ]]; then
    ( pi_main "$port" --kill )
  else
    ( pi_main "$port" )
  fi
}

run_ssl_wizard() {
  uk_section_title 'SSL Checker'
  local host port
  host="$(uk_prompt 'Enter host or domain name to inspect' '' 'example.com' 'The tool will fetch certificate metadata and DNS information.')"
  port="$(uk_prompt 'Enter port number to check' '443' '443' 'Most HTTPS services use port 443.')"
  ( sc_main "$host" --port "$port" )
}

run_api_wizard() {
  uk_section_title 'API Tester'
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
        ( at_main --method "$method" --url "$url" --header "$header" --body "$body" )
      elif [[ -n "$header" ]]; then
        ( at_main --method "$method" --url "$url" --header "$header" )
      elif [[ -n "$body" ]]; then
        ( at_main --method "$method" --url "$url" --body "$body" )
      else
        ( at_main --method "$method" --url "$url" )
      fi
      ;;
    2)
      name="$(uk_prompt 'Profile name to save' '' 'staging-users' 'This name will be used later with the run/show actions.')"
      method="$(uk_prompt 'HTTP method' 'GET' 'POST' 'Examples: GET, POST, PUT, PATCH, DELETE.')"
      url="$(uk_prompt 'Request URL' '' 'https://api.example.com/items' 'The full URL will be stored in the profile.')"
      header="$(uk_prompt 'Optional single header in Key: Value format' '' 'Authorization: Bearer TOKEN' 'Leave blank if not needed.')"
      body="$(uk_prompt 'Optional request body text' '' '{"name":"demo"}' 'Leave blank for requests without a body.')"
      if [[ -n "$header" && -n "$body" ]]; then
        ( at_main --save "$name" --method "$method" --url "$url" --header "$header" --body "$body" )
      elif [[ -n "$header" ]]; then
        ( at_main --save "$name" --method "$method" --url "$url" --header "$header" )
      elif [[ -n "$body" ]]; then
        ( at_main --save "$name" --method "$method" --url "$url" --body "$body" )
      else
        ( at_main --save "$name" --method "$method" --url "$url" )
      fi
      ;;
    3)
      name="$(uk_prompt 'Profile name to run' '' 'staging-users' 'Use a previously saved API profile name.')"
      ( at_main --run "$name" )
      ;;
    4)
      name="$(uk_prompt 'Profile name to display' '' 'staging-users' 'Use a previously saved API profile name.')"
      ( at_main --show "$name" )
      ;;
    5) ( at_main --list ) ;;
    *) uk_warn 'No API-tester action selected.' ;;
  esac
}

run_password_wizard() {
  uk_section_title 'Password Generator'
  local mode copy words length
  mode="$(uk_prompt 'Choose generator mode (passphrase|string)' 'passphrase' 'string' 'Passphrases are easier to remember; random strings are denser.')"
  if [[ "$mode" == 'string' ]]; then
    length="$(uk_prompt 'Enter string length' '20' '32' 'Longer strings give you higher theoretical entropy.')"
    printf ' %s Copy the generated password to clipboard too? [y/N]: ' "$UK_I_ARROW" >&2
    read -r copy
    if [[ "$copy" =~ ^[Yy]$ ]]; then
      ( pg_main --mode string --length "$length" --copy )
    else
      ( pg_main --mode string --length "$length" )
    fi
  else
    words="$(uk_prompt 'Enter passphrase word count' '4' '5' 'More words increase entropy and length.')"
    printf ' %s Copy the generated passphrase to clipboard too? [y/N]: ' "$UK_I_ARROW" >&2
    read -r copy
    if [[ "$copy" =~ ^[Yy]$ ]]; then
      ( pg_main --mode passphrase --words "$words" --copy )
    else
      ( pg_main --mode passphrase --words "$words" )
    fi
  fi
}

run_ssh_wizard() {
  uk_section_title 'SSH Assistant'
  printf '  1) Show named hosts from ~/.ssh/config\n'
  printf '  2) Connect to a host from ~/.ssh/config\n'
  printf '  3) Run ssh-copy-id for a host\n'
  printf ' %s Choose an action: ' "$UK_I_ARROW" >&2
  local choice host
  read -r choice
  case "$choice" in
    1) ( sa_main ) ;;
    2)
      host="$(uk_prompt 'Enter SSH host alias to connect to' '' 'gitlab' 'If this is a Git hosting service, it may close after a successful auth handshake.')"
      ( sa_main --connect "$host" )
      ;;
    3)
      host="$(uk_prompt 'Enter host for ssh-copy-id' '' 'user@example.com' 'This pushes your public SSH key to the remote host for easier login later.')"
      ( sa_main --copy-id "$host" )
      ;;
    *) uk_warn 'No SSH action selected.' ;;
  esac
}

run_shred_wizard() {
  uk_section_title 'Shredder'
  local file passes apply
  file="$(uk_prompt 'Enter file path to securely erase' '' '~/secret.txt' 'Shredding overwrites file contents before unlinking the file.')"
  passes="$(uk_prompt 'How many overwrite passes should be used?' '3' '7' 'Higher values are slower but overwrite the file more times.')"
  printf ' %s Apply secure erase now? [y/N]: ' "$UK_I_ARROW" >&2
  read -r apply
  if [[ "$apply" =~ ^[Yy]$ ]]; then
    ( sd_main --passes "$passes" --apply "$(uk_expand_path "$file")" )
  else
    ( sd_main --passes "$passes" "$(uk_expand_path "$file")" )
  fi
}

run_media_wizard() {
  uk_section_title 'Media Convert'
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
    printf ' %s Strip EXIF metadata from images? [Y/n]: ' "$UK_I_ARROW" >&2
    read -r strip
  fi
  printf ' %s Apply conversion now? [Y/n]: ' "$UK_I_ARROW" >&2
  read -r apply
  local args=()
  [[ ! "$strip" =~ ^[Nn]$ && "$kind" == 'image' ]] && args+=(--strip-exif)
  [[ ! "$apply" =~ ^[Nn]$ ]] && args+=(--apply)
  ( mc_main --kind "$kind" --to "$to" --output "$(uk_expand_path "$output")" "${args[@]}" "$(uk_expand_path "$path")" )
}

run_toc_wizard() {
  uk_section_title 'Markdown TOC'
  local file apply check align show_diff before after
  file="$(uk_prompt 'Enter markdown file to update' '' 'README.md' 'A table of contents will be inserted or refreshed based on headings in this file.')"
  printf ' %s Apply changes now? [Y/n]: ' "$UK_I_ARROW" >&2
  read -r apply
  printf ' %s Check relative links too? [Y/n]: ' "$UK_I_ARROW" >&2
  read -r check
  printf ' %s Align markdown tables too? [Y/n]: ' "$UK_I_ARROW" >&2
  read -r align
  printf ' %s Show a unified diff after the change? [Y/n]: ' "$UK_I_ARROW" >&2
  read -r show_diff
  file="$(uk_expand_path "$file")"
  before="$(mktemp)"
  after="$(mktemp)"
  cp "$file" "$before"
  local args=()
  [[ ! "$apply" =~ ^[Nn]$ ]] && args+=(--apply)
  [[ ! "$check" =~ ^[Nn]$ ]] && args+=(--check-links)
  [[ ! "$align" =~ ^[Nn]$ ]] && args+=(--align-tables)
  ( mt_main "$file" "${args[@]}" )
  if [[ ! "$show_diff" =~ ^[Nn]$ && -f "$file" ]]; then
    cp "$file" "$after"
    uk_section_title 'Markdown TOC diff'
    diff -u "$before" "$after" || true
  fi
  rm -f "$before" "$after"
}

run_move_wizard() {
  uk_section_title 'Move in Batch'
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
  ( mib_main "${args[@]}" )
}

run_pomodoro_wizard() {
  ( po_main )
}

run_cheat_wizard() {
  ( cs_main )
}

run_setup_wizard() {
  bash "$UK_ROOT_DIR/setup.sh"
}

uk_menu_execute() {
  local status=0
  run_tool "$@"
  status=$?
  if (( status != 0 )); then
    uk_warn "The selected tool exited with status $status."
  fi
  return 0
}

run_tool() {
  local cmd="$1"
  shift || true
  case "$cmd" in
    apply|apply-changes) ( [[ $# -gt 0 ]] && ac_main "$@" || run_apply_wizard ) ;;
    rename|rename-batch) ( [[ $# -gt 0 ]] && rb_main "$@" || run_rename_wizard ) ;;
    move|move-in-batch|move-batch) ( [[ $# -gt 0 ]] && mib_main "$@" || run_move_wizard ) ;;
    cacheclean|cache-clean) ( [[ $# -gt 0 ]] && cc_main "$@" || cc_main ) ;;
    symlink|symlink-manager) ( [[ $# -gt 0 ]] && sm_main "$@" || run_symlink_wizard ) ;;
    disk|disk-analyzer) ( [[ $# -gt 0 ]] && da_main "$@" || run_disk_wizard ) ;;
    env|env-manager) ( [[ $# -gt 0 ]] && em_main "$@" || run_env_wizard ) ;;
    git|git-sweep) ( [[ $# -gt 0 ]] && gs_main "$@" || run_git_wizard ) ;;
    docker|docker-janitor)
      if [[ "$(uk_platform)" == 'termux' && $# -eq 0 ]]; then
        uk_warn 'Docker Janitor is not useful in Termux because Docker is usually unavailable there.'
        return 0
      fi
      ( dj_main "$@" )
      ;;
    scaffold|project-scaffold) ( [[ $# -gt 0 ]] && ps_main "$@" || run_scaffold_wizard ) ;;
    dup|duplicate-finder) ( [[ $# -gt 0 ]] && df_main "$@" || run_duplicate_wizard ) ;;
    logs|log-rotator) ( [[ $# -gt 0 ]] && lr_main "$@" || run_logs_wizard ) ;;
    proc|process-killer) ( [[ $# -gt 0 ]] && pk_main "$@" || run_process_wizard ) ;;
    port|port-inspector) ( [[ $# -gt 0 ]] && pi_main "$@" || run_port_wizard ) ;;
    ssl|ssl-checker) ( [[ $# -gt 0 ]] && sc_main "$@" || run_ssl_wizard ) ;;
    api|api-tester) ( [[ $# -gt 0 ]] && at_main "$@" || run_api_wizard ) ;;
    pass|password|password-gen) ( [[ $# -gt 0 ]] && pg_main "$@" || run_password_wizard ) ;;
    ssh|ssh-assistant) ( [[ $# -gt 0 ]] && sa_main "$@" || run_ssh_wizard ) ;;
    shred|shredder) ( [[ $# -gt 0 ]] && sd_main "$@" || run_shred_wizard ) ;;
    media|media-convert) ( [[ $# -gt 0 ]] && mc_main "$@" || run_media_wizard ) ;;
    toc|markdown-toc) ( [[ $# -gt 0 ]] && mt_main "$@" || run_toc_wizard ) ;;
    pomodoro|pomo) ( [[ $# -gt 0 ]] && po_main "$@" || run_pomodoro_wizard ) ;;
    cheat|cheat-sheet) ( [[ $# -gt 0 ]] && cs_main "$@" || run_cheat_wizard ) ;;
    setup|install) bash "$UK_ROOT_DIR/setup.sh" "$@" ;;
    help|--help|-h) uk_main_show_help ;;
    zen|zen-mode) ( zm_main "$@" ) ;;
    *) uk_error "Unknown command: $cmd"; uk_main_show_help; return 1 ;;
  esac
}

uk_main_show_help() {
  uk_main_banner
  cat <<'EOF'
Usage:
  ./main.sh <command> [args]

Dashboard-visible commands:
  apply, rename, cacheclean, symlink, disk, env, git, scaffold, dup,
  logs, proc, port, ssl, api, pass, ssh, shred, media, toc, pomodoro,
  cheat, move, setup

Additional direct commands:
  docker      Docker janitor (mainly useful off Termux)
  move        Batch copy/move files into an output directory
  zen         Hidden CLI-only screensaver experiment
  help        This help screen
EOF
}

home_menu_loop() {
  local choice skip_pause=0
  while true; do
    skip_pause=0
    uk_main_banner
    uk_home_menu
     echo ""
     printf "  %sChoose an option [1-6/m/q]: %s" "${UK_C_BOLD}${UK_C_CYAN}${UK_I_ARROW} " "${UK_C_RESET}"
   # printf '  %sChoose an option [1-6/m/q]: %s' "$UK_I_ARROW" "$UK_C_RESET"
    read -r choice
    case "$choice" in
      1) uk_menu_execute apply ;;
      2) uk_menu_execute rename ;;
      3) uk_menu_execute cacheclean ;;
      4) uk_menu_execute symlink ;;
      5) uk_menu_execute disk ;;
      6|s|setup) uk_menu_execute setup ;;
      m|M|more) more_menu_loop_page_1; skip_pause=1 ;;
      q|Q|quit|exit) exit 0 ;;
      *) uk_warn 'Invalid selection. Please enter 1-6, m, or q.' ;;
    esac
    if (( skip_pause == 0 )); then
      printf '\n  %sPress Enter to return to the UtilityKit Dashboard...%s' "$UK_C_DIM" "$UK_C_RESET"
      read -r
    fi
  done
}

more_menu_loop_page_1() {
  local choice
  while true; do
    uk_main_banner
    uk_more_menu_page_1
    printf "  %sChoose an option [1-8/b/q]: %s" "${UK_C_BOLD}${UK_C_CYAN}${UK_I_ARROW} " "${UK_C_RESET}"
    read -r choice
    case "$choice" in
      1) uk_menu_execute env ;;
      2) uk_menu_execute git ;;
      3) uk_menu_execute scaffold ;;
      4) uk_menu_execute dup ;;
      5) uk_menu_execute logs ;;
      6) uk_menu_execute proc ;;
      7) uk_menu_execute port ;;
      8|n|next) more_menu_loop_page_2; return 0 ;;
      b|B|back) return 0 ;;
      q|Q|quit|exit) exit 0 ;;
      *) uk_warn 'Invalid selection. Please enter 1-8, b, or q.' ;;
    esac
    printf '\n  %sPress Enter to stay in More Tools Page 1...%s' "$UK_C_DIM" "$UK_C_RESET"
    read -r
  done
}

more_menu_loop_page_2() {
  local choice
  while true; do
    uk_main_banner
    uk_more_menu_page_2
    printf "  %sChoose an option [1-11/p/b/q]: %s" "${UK_C_BOLD}${UK_C_CYAN}${UK_I_ARROW} " "${UK_C_RESET}"
    read -r choice
    case "$choice" in
      1) uk_menu_execute ssl ;;
      2) uk_menu_execute api ;;
      3) uk_menu_execute pass ;;
      4) uk_menu_execute ssh ;;
      5) uk_menu_execute shred ;;
      6) uk_menu_execute media ;;
      7) uk_menu_execute toc ;;
      8) uk_menu_execute pomodoro ;;
      9) uk_menu_execute cheat ;;
      10) uk_menu_execute move ;;
      11)
        if [[ "$(uk_platform)" == 'termux' ]]; then
          uk_warn 'Docker Janitor is disabled in the Termux dashboard.'
        else
          uk_menu_execute docker
        fi
        ;;
      p|P|prev|previous) return 0 ;;
      b|B|back) return 0 ;;
      q|Q|quit|exit) exit 0 ;;
      *) uk_warn 'Invalid selection. Please enter 1-11, p, b, or q.' ;;
    esac
    printf '\n  %sPress Enter to stay in More Tools Page 2...%s' "$UK_C_DIM" "$UK_C_RESET"
    read -r
  done
}

if [[ $# -gt 0 ]]; then
  subcmd="$1"
  shift
  run_tool "$subcmd" "$@"
else
  home_menu_loop
fi
