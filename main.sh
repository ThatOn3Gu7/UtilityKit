#!/usr/bin/env bash
# UtilityKit central hub
set -euo pipefail
readonly UK_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$UK_ROOT_DIR/lib/uk_common.sh"

readonly UK_VERSION='4.1.2'

uk_source_tool() {
  local path="$1"
  [[ -f "$path" ]] || {
    uk_warn "Missing tool: $path"
    return 0
  }
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
uk_source_tool "$UK_ROOT_DIR/_network_probe/_network_probe.sh"
uk_source_tool "$UK_ROOT_DIR/_cron_manager/_cron_manager.sh"
uk_source_tool "$UK_ROOT_DIR/_dotenv_vault/_dotenv_vault.sh"
uk_source_tool "$UK_ROOT_DIR/_disk_health/_disk_health.sh"
uk_source_tool "$UK_ROOT_DIR/_service_watcher/_service_watcher.sh"
uk_source_tool "$UK_ROOT_DIR/_git_stats/_git_stats.sh"
uk_source_tool "$UK_ROOT_DIR/_backup_sync/_backup_sync.sh"
uk_source_tool "$UK_ROOT_DIR/_clipboard_manager/_clipboard_manager.sh"
uk_source_tool "$UK_ROOT_DIR/_log_rotator/_log_rotator.sh"
uk_source_tool "$UK_ROOT_DIR/_weather/_weather.sh"
uk_source_tool "$UK_ROOT_DIR/_json_explorer/_json_explorer.sh"
uk_source_tool "$UK_ROOT_DIR/_tmux_session/_tmux_session.sh"
uk_source_tool "$UK_ROOT_DIR/_font_inspector/_font_inspector.sh"
uk_source_tool "$UK_ROOT_DIR/_toolbox_bootstrap/_toolbox_bootstrap.sh"
uk_source_tool "$UK_ROOT_DIR/_project_search/_project_search.sh"
uk_source_tool "$UK_ROOT_DIR/_github_helper/_github_helper.sh"
uk_source_tool "$UK_ROOT_DIR/_link_checker/_link_checker.sh"
uk_source_tool "$UK_ROOT_DIR/_log_inspector/_log_inspector.sh"
uk_source_tool "$UK_ROOT_DIR/_csv_toolkit/_csv_toolkit.sh"
uk_source_tool "$UK_ROOT_DIR/_hash_tools/_hash_tools.sh"
uk_source_tool "$UK_ROOT_DIR/_archive_manager/_archive_manager.sh"
uk_source_tool "$UK_ROOT_DIR/_system_snapshot/_system_snapshot.sh"
uk_source_tool "$UK_ROOT_DIR/_open_files/_open_files.sh"
uk_source_tool "$UK_ROOT_DIR/_battery_doctor/_battery_doctor.sh"
uk_source_tool "$UK_ROOT_DIR/_release_helper/_release_helper.sh"
uk_source_tool "$UK_ROOT_DIR/_license_helper/_license_helper.sh"
uk_source_tool "$UK_ROOT_DIR/_regex_lab/_regex_lab.sh"
uk_source_tool "$UK_ROOT_DIR/_todo_manager/_todo_manager.sh"
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

uk_menu_line() {
  local num="$1" icon="$2" color="$3" name="$4" desc="$5"
  printf '    %s%2s)%s %s%s %-18s%s %s(%s)%s\n' \
    "$UK_C_BOLD" "$num" "$UK_C_RESET" "$UK_C_BOLD$color" "$icon" "$name" "$UK_C_RESET" "$UK_C_DIM" "$desc" "$UK_C_RESET"
}

uk_menu_nav() {
  printf '\n    %sn)%s %sNext page%s       %sp)%s %sPrevious%s       %sb)%s %sBack home%s       %sq)%s %sQuit%s\n\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$UK_C_RESET" \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$UK_C_RESET" \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$UK_C_RESET" \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_RED" "$UK_C_RESET"
}

uk_more_menu_page_1() {
  printf '  %s❯ %sMore tools%s — %sPage 1 of 5%s\n\n' "$UK_C_BOLD" "$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  uk_menu_line 1 '◎' "$UK_C_CYAN" 'Env Manager' 'compare, validate, and switch .env profiles'
  uk_menu_line 2 '⑂' "$UK_C_GREEN" 'Git Sweep' 'clean merged branches, stashes, and artifacts'
  uk_menu_line 3 '▣' "$UK_C_BRIGHT_BLUE" 'Project Scaffold' 'generate starter projects from guided templates'
  uk_menu_line 4 '◆' "$UK_C_MAGENTA" 'Duplicate Finder' 'find exact duplicate files and reclaim space'
  uk_menu_line 5 '✖' "$UK_C_RED" 'Process Killer' 'inspect memory pressure and terminate processes'
  uk_menu_line 6 '◉' "$UK_C_BRIGHT_CYAN" 'Port Inspector' 'find which process owns a local port'
  uk_menu_nav
}

uk_more_menu_page_2() {
  printf '  %s❯ %sMore tools%s — %sPage 2 of 5%s\n\n' "$UK_C_BOLD" "$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  uk_menu_line 1 '🔒' "$UK_C_CYAN" 'SSL Checker' 'inspect certificate expiry, DNS, and TLS support'
  uk_menu_line 2 '⇄' "$UK_C_GREEN" 'API Tester' 'send HTTP requests and save reusable profiles'
  uk_menu_line 3 '✦' "$UK_C_YELLOW" 'Password Gen' 'generate passphrases or random strings'
  uk_menu_line 4 '⇢' "$UK_C_BRIGHT_BLUE" 'SSH Assistant' 'list SSH hosts and run connection helpers'
  uk_menu_line 5 '⌫' "$UK_C_RED" 'Shredder' 'securely erase sensitive files with fallbacks'
  uk_menu_line 6 '▧' "$UK_C_MAGENTA" 'Media Convert' 'batch convert images/videos when tools exist'
  uk_menu_line 7 '☷' "$UK_C_CYAN" 'Markdown TOC' 'generate TOCs, check links, align tables'
  uk_menu_line 8 '◷' "$UK_C_GREEN" 'Pomodoro' 'run focused work/break cycles'
  uk_menu_line 9 '☰' "$UK_C_YELLOW" 'Cheat Sheet' 'store, search, and show command snippets'
  uk_menu_line 10 '⇥' "$UK_C_BRIGHT_CYAN" 'Move in Batch' 'copy/move files safely with exclusions'
  if [[ "$(uk_platform)" != 'termux' ]]; then
    uk_menu_line 11 '⬢' "$UK_C_BRIGHT_BLUE" 'Docker Janitor' 'clean containers, images, and volumes'
  else
    uk_menu_line 11 '⬢' "$UK_C_DIM" 'Docker Janitor' 'unavailable / usually not useful in Termux'
  fi
  uk_menu_nav
}

uk_more_menu_page_3() {
  printf '  %s❯ %sNew utilities%s — %sPage 3 of 5%s\n\n' "$UK_C_BOLD" "$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  uk_menu_line 1 '⌁' "$UK_C_BRIGHT_CYAN" 'Network Probe' 'ping, DNS, public IP, and route diagnostics'
  uk_menu_line 2 '◍' "$UK_C_GREEN" 'Service Watcher' 'check HTTP services and response times'
  uk_menu_line 3 '⑂' "$UK_C_YELLOW" 'Git Stats' 'summarize authors, branches, and changed files'
  uk_menu_line 4 '{}' "$UK_C_MAGENTA" 'JSON Explorer' 'pretty-print, inspect, and extract JSON paths'
  uk_menu_line 5 '🔗' "$UK_C_CYAN" 'Link Checker' 'validate Markdown local and HTTP links'
  uk_menu_line 6 '⇄' "$UK_C_GREEN" 'Backup Sync' 'dry-run-first backup wrapper with fallbacks'
  uk_menu_line 7 '⌕' "$UK_C_BRIGHT_BLUE" 'Project Search' 'search files/text with rg/grep/find fallbacks'
  uk_menu_line 8 '≡' "$UK_C_YELLOW" 'Log Inspector' 'summarize warnings, errors, repeated lines'
  uk_menu_line 9 '▤' "$UK_C_MAGENTA" 'CSV Toolkit' 'inspect CSV headers and preview rows'
  uk_menu_nav
}

uk_more_menu_page_4() {
  printf '  %s❯ %sNew utilities%s — %sPage 4 of 5%s\n\n' "$UK_C_BOLD" "$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  uk_menu_line 1 '◷' "$UK_C_CYAN" 'Cron Manager' 'list/add/remove crontab entries safely'
  uk_menu_line 2 '🔐' "$UK_C_GREEN" 'Dotenv Vault' 'encrypt selected .env values with gpg'
  uk_menu_line 3 '◆' "$UK_C_YELLOW" 'Disk Health' 'SMART health check when smartctl exists'
  uk_menu_line 4 '☁' "$UK_C_BRIGHT_CYAN" 'Weather' 'terminal forecast lookup with cache fallback'
  uk_menu_line 5 '▥' "$UK_C_GREEN" 'Tmux Session' 'list, create, attach, or kill tmux sessions'
  uk_menu_line 6 'A' "$UK_C_BRIGHT_BLUE" 'Font Inspector' 'check glyph support and list fonts'
  uk_menu_line 7 '⚙' "$UK_C_YELLOW" 'Toolbox Audit' 'detect recommended CLI tools'
  uk_menu_line 8 '' "$UK_C_MAGENTA" 'GitHub Helper' 'wrap common gh CLI tasks'
  uk_menu_nav
}

uk_more_menu_page_5() {
  printf '  %s❯ %sNew utilities%s — %sPage 5 of 5%s\n\n' "$UK_C_BOLD" "$UK_C_GREEN" "$UK_C_RESET" "$UK_C_DIM" "$UK_C_RESET"
  uk_menu_line 1 '#' "$UK_C_CYAN" 'Hash Tools' 'create checksums for files and trees'
  uk_menu_line 2 '▦' "$UK_C_GREEN" 'Archive Manager' 'list, create, and safely extract archives'
  uk_menu_line 3 '◈' "$UK_C_YELLOW" 'System Snapshot' 'collect a compact diagnostic summary'
  uk_menu_line 4 '◉' "$UK_C_MAGENTA" 'Open Files' 'find processes using paths or ports'
  uk_menu_line 5 '▰' "$UK_C_BRIGHT_CYAN" 'Battery Doctor' 'show battery and power diagnostics'
  uk_menu_line 6 '✦' "$UK_C_GREEN" 'Release Helper' 'run git release checks and optional tags'
  uk_menu_line 7 '§' "$UK_C_BRIGHT_BLUE" 'License Helper' 'detect or generate simple license text'
  uk_menu_line 8 '.*' "$UK_C_YELLOW" 'Regex Lab' 'test regex patterns against text/files'
  uk_menu_line 9 '☑' "$UK_C_MAGENTA" 'Todo Manager' 'plain-text tasks with tags and search'
  printf '\n    %sp)%s %sPrevious%s       %sb)%s %sBack home%s       %sq)%s %sQuit%s\n\n' \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$UK_C_RESET" \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_CYAN" "$UK_C_RESET" \
    "$UK_C_BOLD" "$UK_C_RESET" "$UK_C_RED" "$UK_C_RESET"
}

run_apply_wizard() {
  uk_section_title 'Directory Synchronization (Apply Changes)'
  local src dst apply mirror force include_runtime custom
  src="$(uk_prompt 'Enter updated source directory to sync from' '.' '~/path/to/source' 'Use a directory that contains the newest version of your files.')"
  dst="$(uk_prompt 'Enter local target directory to update' '.' '~/path/to/target' 'The target directory will be compared against the source.')"
  printf ' %s Apply changes now? [y/N]: ' "$UK_I_ARROW" >&2
  read -r apply
  printf ' %s Mirror delete missing target files too? [y/N]: ' "$UK_I_ARROW" >&2
  read -r mirror
  printf ' %s Force past local git changes if needed? [y/N]: ' "$UK_I_ARROW" >&2
  read -r force
  printf ' %s Include runtime logs/tmp files? [y/N]: ' "$UK_I_ARROW" >&2
  read -r include_runtime
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
  uk_section_title 'Batch File Renamer'
  local src ext out force
  src="$(uk_prompt 'Enter target directory to process' '.' '~/path/to/your/directory' 'Every non-hidden file in this folder tree will be considered.')"
  ext="$(uk_prompt 'Enter target new extension format (e.g. sh, py, txt)' '' '.md' 'Do not worry about the leading dot; both md and .md work.')"
  out="$(uk_prompt 'Enter output export directory (leave blank for in-place rename)' '' '~/path/to/export-folder' 'Leave blank to rename files where they already live.')"
  printf ' %s Force protected files too (README, LICENSE, *.md, *.json)? [y/N]: ' "$UK_I_ARROW" >&2
  read -r force
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
  uk_section_title 'Symlink Manager'
  local src dst apply
  src="$(uk_prompt 'Enter source file or directory to link from' '' '~/.dotfiles/.bashrc' 'This is the real file or folder that should back the symlink.')"
  dst="$(uk_prompt 'Enter target link path to create or replace' '' '~/.bashrc' 'If the target already exists, the tool can back it up first.')"
  printf ' %s Apply the symlink change now? [Y/n]: ' "$UK_I_ARROW" >&2
  read -r apply
  if [[ "$apply" =~ ^[Nn]$ ]]; then
    (sm_main "$(uk_expand_path "$src")" "$(uk_expand_path "$dst")")
  else
    (sm_main --apply -y "$(uk_expand_path "$src")" "$(uk_expand_path "$dst")")
  fi
}

run_disk_wizard() {
  uk_section_title 'Disk Space Analyzer'
  local dir count
  dir="$(uk_prompt 'Enter target directory to scan' '.' '~/projects' 'For large folders, the scan can take a little while.')"
  count="$(uk_prompt 'Enter how many top items to display' '10' '15' 'Smaller numbers render faster and are easier to read on mobile screens.')"
  (da_main --count "$count" "$(uk_expand_path "$dir")")
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
  uk_section_title 'Git Sweep'
  local repo
  repo="$(uk_prompt 'Enter the Git repository directory to inspect' '.' '~/project' 'The tool looks for merged branches, stashes, artifacts, and git gc opportunities.')"
  (gs_main --repo "$(uk_expand_path "$repo")")
}

run_scaffold_wizard() {
  uk_section_title 'Project Scaffold'
  local type name dest
  type="$(uk_prompt 'Enter scaffold type (bash, python-flask, node-cli, go-service)' 'bash' 'python-flask' 'A new project folder will be generated for the selected stack.')"
  name="$(uk_prompt 'Enter the new project folder name' '' 'demo-app' 'This becomes the generated project directory name.')"
  dest="$(uk_prompt 'Enter the parent destination directory' '.' '~/projects' 'The generated folder will be created inside this destination.')"
  (ps_main --type "$type" --name "$name" --dest "$(uk_expand_path "$dest")")
}

run_duplicate_wizard() {
  uk_section_title 'Duplicate Finder'
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
  uk_section_title 'Process Killer'
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
  uk_section_title 'Port Inspector'
  local port kill_flag
  port="$(uk_prompt 'Enter the local TCP port to inspect' '' '3000' 'The tool will search for whichever process is listening on this port.')"
  printf ' %s Terminate the process if one is found? [y/N]: ' "$UK_I_ARROW" >&2
  read -r kill_flag
  if [[ "$kill_flag" =~ ^[Yy]$ ]]; then
    (pi_main "$port" --kill)
  else
    (pi_main "$port")
  fi
}

run_ssl_wizard() {
  uk_section_title 'SSL Checker'
  local host port
  host="$(uk_prompt 'Enter host or domain name to inspect' '' 'example.com' 'The tool will fetch certificate metadata and DNS information.')"
  port="$(uk_prompt 'Enter port number to check' '443' '443' 'Most HTTPS services use port 443.')"
  (sc_main "$host" --port "$port")
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
  uk_section_title 'Password Generator'
  local mode copy words length
  mode="$(uk_prompt 'Choose generator mode (passphrase|string)' 'passphrase' 'string' 'Passphrases are easier to remember; random strings are denser.')"
  if [[ "$mode" == 'string' ]]; then
    length="$(uk_prompt 'Enter string length' '20' '32' 'Longer strings give you higher theoretical entropy.')"
    printf ' %s Copy the generated password to clipboard too? [y/N]: ' "$UK_I_ARROW" >&2
    read -r copy
    if [[ "$copy" =~ ^[Yy]$ ]]; then
      (pg_main --mode string --length "$length" --copy)
    else
      (pg_main --mode string --length "$length")
    fi
  else
    words="$(uk_prompt 'Enter passphrase word count' '4' '5' 'More words increase entropy and length.')"
    printf ' %s Copy the generated passphrase to clipboard too? [y/N]: ' "$UK_I_ARROW" >&2
    read -r copy
    if [[ "$copy" =~ ^[Yy]$ ]]; then
      (pg_main --mode passphrase --words "$words" --copy)
    else
      (pg_main --mode passphrase --words "$words")
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
  uk_section_title 'Shredder'
  local file passes apply
  file="$(uk_prompt 'Enter file path to securely erase' '' '~/secret.txt' 'Shredding overwrites file contents before unlinking the file.')"
  passes="$(uk_prompt 'How many overwrite passes should be used?' '3' '7' 'Higher values are slower but overwrite the file more times.')"
  printf ' %s Apply secure erase now? [y/N]: ' "$UK_I_ARROW" >&2
  read -r apply
  if [[ "$apply" =~ ^[Yy]$ ]]; then
    (sd_main --passes "$passes" --apply "$(uk_expand_path "$file")")
  else
    (sd_main --passes "$passes" "$(uk_expand_path "$file")")
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
  (mc_main --kind "$kind" --to "$to" --output "$(uk_expand_path "$output")" "${args[@]}" "$(uk_expand_path "$path")")
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
  (mt_main "$file" "${args[@]}")
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
  local kind="$1" dir path
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
  local tool="$1"
  case "$tool" in
  network)
    uk_section_title 'Network Probe'
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
    uk_section_title 'Service Watcher'
    local urls expect interval
    urls="$(uk_prompt 'Enter one or more URLs separated by spaces' 'https://example.com' 'https://example.com http://127.0.0.1:3000' 'The tool checks HTTP status and response time for each URL.')"
    expect="$(uk_prompt 'Expected status codes/ranges' '2xx,3xx' '200,204,2xx' 'Anything outside this list is marked down.')"
    interval="$(uk_prompt 'Loop interval in seconds (0 for one-time check)' '0' '10' 'Use 0 for a single run.')"
    # shellcheck disable=SC2206
    local arr=($urls)
    (sw_main "${arr[@]}" --expect "$expect" --interval "$interval")
    ;;
  git-stats)
    uk_section_title 'Git Stats'
    local repo since
    repo="$(uk_prompt 'Git repository directory to analyze' '.' '~/project' 'Must be inside a Git work tree.')"
    since="$(uk_prompt 'Since date/filter' '30 days ago' '30 days ago | 2026-01-01' 'Default shows recent activity; use direct CLI without --since for all history.')"
    if [[ -n "$since" ]]; then (gst_main --repo "$(uk_expand_path "$repo")" --since "$since"); else (gst_main --repo "$(uk_expand_path "$repo")"); fi
    ;;
  json)
    uk_section_title 'JSON Explorer'
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
    uk_section_title 'Link Checker'
    local files http args=()
    files="$(uk_prompt 'Markdown files to check, separated by spaces' 'README.md' 'README.md docs/*.md' 'Local relative links are checked by default.')"
    http="$(uk_prompt 'Also check HTTP/HTTPS links? (y/N)' 'N' 'y' 'HTTP checks require network access and can be slower.')"
    # shellcheck disable=SC2206
    args=($files)
    [[ "$http" =~ ^[Yy]$ ]] && args+=(--http)
    (lc_main "${args[@]}")
    ;;
  backup)
    uk_section_title 'Backup Sync'
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
    uk_section_title 'Project Search'
    local dir mode term
    dir="$(uk_prompt 'Directory to search' '.' '~/project' 'Search respects available rg/grep/find behavior.')"
    mode="$(uk_prompt 'Search by text or filename? (text/name)' 'text' 'name' 'Text searches file contents; name searches paths.')"
    term="$(uk_prompt 'Search pattern' 'UtilityKit' 'TODO | *.sh' 'Use a text pattern or filename glob.')"
    if [[ "$mode" == name ]]; then (psrch_main --name "$term" "$(uk_expand_path "$dir")"); else (psrch_main --text "$term" "$(uk_expand_path "$dir")"); fi
    ;;
  log-inspect)
    uk_section_title 'Log Inspector'
    local file pattern
    file="$(uk_prompt 'Log file to inspect' "$(uk_demo_file log)" './app.log' 'A demo log is used if you just press Enter.')"
    pattern="$(uk_prompt 'Error/warning regex pattern' 'error|warn|fail|exception' 'ERROR|WARN|panic' 'Case-insensitive grep pattern.')"
    (li_main "$(uk_expand_path "$file")" --pattern "$pattern")
    ;;
  csv)
    uk_section_title 'CSV Toolkit'
    local file mode
    file="$(uk_prompt 'CSV file to inspect' "$(uk_demo_file csv)" './data.csv' 'A demo CSV is used if you just press Enter.')"
    mode="$(uk_prompt 'Show columns or preview rows? (columns/preview)' 'preview' 'columns' 'Columns prints headers; preview prints first rows.')"
    if [[ "$mode" == columns ]]; then (csvt_main "$(uk_expand_path "$file")" --columns); else (csvt_main "$(uk_expand_path "$file")"); fi
    ;;
  cron)
    uk_section_title 'Cron Manager'
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
    uk_section_title 'Dotenv Vault'
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
    uk_section_title 'Disk Health'
    local mode dev
    mode="$(uk_prompt 'Action: list or device' 'list' 'device' 'Requires smartctl and device permissions; often unavailable in Termux.')"
    if [[ "$mode" == device ]]; then
      dev="$(uk_prompt 'Device path' '/dev/sda' '/dev/sda | /dev/nvme0' 'Use a device shown by --list.')"
      (dh_main --device "$dev")
    else (dh_main --list); fi
    ;;
  weather)
    uk_section_title 'Weather'
    local loc units
    loc="$(uk_prompt 'Location' 'Kathmandu' 'Kathmandu | London | 27.7,85.3' 'Uses wttr.in through curl; cached result is shown if lookup fails.')"
    units="$(uk_prompt 'Units: metric or imperial' 'metric' 'imperial' 'Metric uses Celsius; imperial uses Fahrenheit.')"
    (wt_main "$loc" --units "$units")
    ;;
  tmux)
    uk_section_title 'Tmux Session'
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
  run_tool "$@"
  status=$?
  if ((status != 0)); then
    uk_warn "The selected tool exited with status $status."
  fi
  return 0
}

run_tool() {
  local cmd="$1"
  shift || true
  case "$cmd" in
  apply | apply-changes) ([[ $# -gt 0 ]] && ac_main "$@" || run_apply_wizard) ;;
  rename | rename-batch) ([[ $# -gt 0 ]] && rb_main "$@" || run_rename_wizard) ;;
  move | move-in-batch | move-batch) ([[ $# -gt 0 ]] && mib_main "$@" || run_move_wizard) ;;
  cacheclean | cache-clean) ([[ $# -gt 0 ]] && cc_main "$@" || cc_main) ;;
  symlink | symlink-manager) ([[ $# -gt 0 ]] && sm_main "$@" || run_symlink_wizard) ;;
  disk | disk-analyzer) ([[ $# -gt 0 ]] && da_main "$@" || run_disk_wizard) ;;
  env | env-manager) ([[ $# -gt 0 ]] && em_main "$@" || run_env_wizard) ;;
  git | git-sweep) ([[ $# -gt 0 ]] && gs_main "$@" || run_git_wizard) ;;
  docker | docker-janitor)
    if [[ "$(uk_platform)" == 'termux' && $# -eq 0 ]]; then
      uk_warn 'Docker Janitor is not useful in Termux because Docker is usually unavailable there.'
      return 0
    fi
    (dj_main "$@")
    ;;
  scaffold | project-scaffold) ([[ $# -gt 0 ]] && ps_main "$@" || run_scaffold_wizard) ;;
  dup | duplicate-finder) ([[ $# -gt 0 ]] && df_main "$@" || run_duplicate_wizard) ;;
  proc | process-killer) ([[ $# -gt 0 ]] && pk_main "$@" || run_process_wizard) ;;
  port | port-inspector) ([[ $# -gt 0 ]] && pi_main "$@" || run_port_wizard) ;;
  ssl | ssl-checker) ([[ $# -gt 0 ]] && sc_main "$@" || run_ssl_wizard) ;;
  api | api-tester) ([[ $# -gt 0 ]] && at_main "$@" || run_api_wizard) ;;
  pass | password | password-gen) ([[ $# -gt 0 ]] && pg_main "$@" || run_password_wizard) ;;
  ssh | ssh-assistant) ([[ $# -gt 0 ]] && sa_main "$@" || run_ssh_wizard) ;;
  shred | shredder) ([[ $# -gt 0 ]] && sd_main "$@" || run_shred_wizard) ;;
  media | media-convert) ([[ $# -gt 0 ]] && mc_main "$@" || run_media_wizard) ;;
  toc | markdown-toc) ([[ $# -gt 0 ]] && mt_main "$@" || run_toc_wizard) ;;
  pomodoro | pomo) ([[ $# -gt 0 ]] && po_main "$@" || run_pomodoro_wizard) ;;
  cheat | cheat-sheet) ([[ $# -gt 0 ]] && cs_main "$@" || run_cheat_wizard) ;;
  net | network | network-probe) ([[ $# -gt 0 ]] && np_main "$@" || run_new_utility_wizard network) ;;
  cron | cron-manager) ([[ $# -gt 0 ]] && cm_main "$@" || run_new_utility_wizard cron) ;;
  dotenv | dotenv-vault) ([[ $# -gt 0 ]] && dv_main "$@" || run_new_utility_wizard dotenv) ;;
  disk-health | smart) ([[ $# -gt 0 ]] && dh_main "$@" || run_new_utility_wizard disk-health) ;;
  watch | service | service-watcher) ([[ $# -gt 0 ]] && sw_main "$@" || run_new_utility_wizard service) ;;
  git-stats | gstats) ([[ $# -gt 0 ]] && gst_main "$@" || run_new_utility_wizard git-stats) ;;
  backup | backup-sync) ([[ $# -gt 0 ]] && bs_main "$@" || run_new_utility_wizard backup) ;;
  clipboard | clipboard-manager) ([[ $# -gt 0 ]] && cb_main "$@" || cb_main --help) ;;
  logs | log-rotator) ([[ $# -gt 0 ]] && lr_main "$@" || lr_main --help) ;;
  weather) ([[ $# -gt 0 ]] && wt_main "$@" || run_new_utility_wizard weather) ;;
  json | json-explorer) ([[ $# -gt 0 ]] && jx_main "$@" || run_new_utility_wizard json) ;;
  tmux | tmux-session) ([[ $# -gt 0 ]] && tms_main "$@" || run_new_utility_wizard tmux) ;;
  font | font-inspector) ([[ $# -gt 0 ]] && fi_main "$@" || run_new_utility_wizard font) ;;
  toolbox | toolbox-bootstrap) ([[ $# -gt 0 ]] && tb_main "$@" || run_new_utility_wizard toolbox) ;;
  search | project-search) ([[ $# -gt 0 ]] && psrch_main "$@" || run_new_utility_wizard search) ;;
  github | github-helper) ([[ $# -gt 0 ]] && ghh_main "$@" || run_new_utility_wizard github) ;;
  links | link-checker) ([[ $# -gt 0 ]] && lc_main "$@" || run_new_utility_wizard links) ;;
  log-inspect | log-inspector) ([[ $# -gt 0 ]] && li_main "$@" || run_new_utility_wizard log-inspect) ;;
  csv | csv-toolkit) ([[ $# -gt 0 ]] && csvt_main "$@" || run_new_utility_wizard csv) ;;
  hash | hash-tools) ([[ $# -gt 0 ]] && ht_main "$@" || run_new_utility_wizard hash) ;;
  archive | archive-manager) ([[ $# -gt 0 ]] && am_main "$@" || run_new_utility_wizard archive) ;;
  snapshot | system-snapshot) ([[ $# -gt 0 ]] && ssn_main "$@" || run_new_utility_wizard snapshot) ;;
  open-files | lsof) ([[ $# -gt 0 ]] && of_main "$@" || run_new_utility_wizard open-files) ;;
  battery | battery-doctor) ([[ $# -gt 0 ]] && bd_main "$@" || run_new_utility_wizard battery) ;;
  release | release-helper) ([[ $# -gt 0 ]] && rel_main "$@" || run_new_utility_wizard release) ;;
  license | license-helper) ([[ $# -gt 0 ]] && lic_main "$@" || run_new_utility_wizard license) ;;
  regex | regex-lab) ([[ $# -gt 0 ]] && rx_main "$@" || run_new_utility_wizard regex) ;;
  todo | todo-manager) ([[ $# -gt 0 ]] && td_main "$@" || run_new_utility_wizard todo) ;;
  setup | install) bash "$UK_ROOT_DIR/setup.sh" "$@" ;;
  help | --help | -h) uk_main_show_help ;;
  zen | zen-mode) (zm_main "$@") ;;
  *)
    uk_error "Unknown command: $cmd"
    uk_main_show_help
    return 1
    ;;
  esac
}

uk_main_show_help() {
  uk_main_banner
  cat <<'EOF'
Usage:
  ./main.sh <command> [args]

Core commands:
  apply, rename, move, cacheclean, symlink, disk, env, git, scaffold, dup, logs,
  proc, port, ssl, api, pass, ssh, shred, media, toc, pomodoro,
  cheat, setup, docker, zen

New utility commands:
  network, cron, dotenv, disk-health, service, git-stats, backup,
  clipboard, weather, json, tmux, font, toolbox, search, github, links, log-inspect,
  csv, hash, archive, snapshot, open-files, battery, release, license, regex, todo

Use ./main.sh <command> --help for each tool's detailed options.
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
    6 | s | setup) uk_menu_execute setup ;;
    m | M | more)
      more_menu_loop_page_1
      skip_pause=1
      ;;
    q | Q | quit | exit) exit 0 ;;
    *) uk_warn 'Invalid selection. Please enter 1-6, m, or q.' ;;
    esac
    if ((skip_pause == 0)); then
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
    printf "  %sChoose an option [1-7/n/b/q]: %s" "${UK_C_BOLD}${UK_C_CYAN}${UK_I_ARROW} " "${UK_C_RESET}"
    read -r choice
    case "$choice" in
    1) uk_menu_execute env ;;
    2) uk_menu_execute git ;;
    3) uk_menu_execute scaffold ;;
    4) uk_menu_execute dup ;;
    5) uk_menu_execute proc ;;
    6) uk_menu_execute port ;;
    n | N | next)
      more_menu_loop_page_2
      return 0
      ;;
    b | B | back) return 0 ;;
    q | Q | quit | exit) exit 0 ;;
    *) uk_warn 'Invalid selection. Please enter 1-7, n, b, or q.' ;;
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
    printf "  %sChoose an option [1-11/n/p/b/q]: %s" "${UK_C_BOLD}${UK_C_CYAN}${UK_I_ARROW} " "${UK_C_RESET}"
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
    n | N | next)
      more_menu_loop_page_3
      return 0
      ;;
    p | P | prev | previous) return 0 ;;
    b | B | back) return 0 ;;
    q | Q | quit | exit) exit 0 ;;
    *) uk_warn 'Invalid selection. Please enter 1-11, n, p, b, or q.' ;;
    esac
    printf '\n  %sPress Enter to stay in More Tools Page 2...%s' "$UK_C_DIM" "$UK_C_RESET"
    read -r
  done
}

more_menu_loop_page_3() {
  local choice
  while true; do
    uk_main_banner
    uk_more_menu_page_3
    printf "  %sChoose an option [1-9/n/p/b/q]: %s" "${UK_C_BOLD}${UK_C_CYAN}${UK_I_ARROW} " "${UK_C_RESET}"
    read -r choice
    case "$choice" in
    1) uk_menu_execute network ;;
    2) uk_menu_execute service ;;
    3) uk_menu_execute git-stats ;;
    4) uk_menu_execute json ;;
    5) uk_menu_execute links ;;
    6) uk_menu_execute backup ;;
    7) uk_menu_execute search ;;
    8) uk_menu_execute log-inspect ;;
    9) uk_menu_execute csv ;;
    n | N | next)
      more_menu_loop_page_4
      return 0
      ;;
    p | P | prev | previous) return 0 ;;
    b | B | back) return 0 ;;
    q | Q | quit | exit) exit 0 ;;
    *) uk_warn 'Invalid selection. Please enter 1-9, n, p, b, or q.' ;;
    esac
    printf '\n  %sPress Enter to stay in New Utilities Page 3...%s' "$UK_C_DIM" "$UK_C_RESET"
    read -r
  done
}

more_menu_loop_page_4() {
  local choice
  while true; do
    uk_main_banner
    uk_more_menu_page_4
    printf "  %sChoose an option [1-9/n/p/b/q]: %s" "${UK_C_BOLD}${UK_C_CYAN}${UK_I_ARROW} " "${UK_C_RESET}"
    read -r choice
    case "$choice" in
    1) uk_menu_execute cron ;;
    2) uk_menu_execute dotenv ;;
    3) uk_menu_execute disk-health ;;
    4) uk_menu_execute weather ;;
    5) uk_menu_execute tmux ;;
    6) uk_menu_execute font ;;
    7) uk_menu_execute toolbox ;;
    8) uk_menu_execute github ;;
    n | N | next)
      more_menu_loop_page_5
      return 0
      ;;
    p | P | prev | previous) return 0 ;;
    b | B | back) return 0 ;;
    q | Q | quit | exit) exit 0 ;;
    *) uk_warn 'Invalid selection. Please enter 1-9, n, p, b, or q.' ;;
    esac
    printf '\n  %sPress Enter to stay in New Utilities Page 4...%s' "$UK_C_DIM" "$UK_C_RESET"
    read -r
  done
}

more_menu_loop_page_5() {
  local choice
  while true; do
    uk_main_banner
    uk_more_menu_page_5
    printf "  %sChoose an option [1-9/p/b/q]: %s" "${UK_C_BOLD}${UK_C_CYAN}${UK_I_ARROW} " "${UK_C_RESET}"
    read -r choice
    case "$choice" in
    1) uk_menu_execute hash ;;
    2) uk_menu_execute archive ;;
    3) uk_menu_execute snapshot ;;
    4) uk_menu_execute open-files ;;
    5) uk_menu_execute battery ;;
    6) uk_menu_execute release ;;
    7) uk_menu_execute license ;;
    8) uk_menu_execute regex ;;
    9) uk_menu_execute todo ;;
    p | P | prev | previous) return 0 ;;
    b | B | back) return 0 ;;
    q | Q | quit | exit) exit 0 ;;
    *) uk_warn 'Invalid selection. Please enter 1-9, p, b, or q.' ;;
    esac
    printf '\n  %sPress Enter to stay in New Utilities Page 5...%s' "$UK_C_DIM" "$UK_C_RESET"
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
