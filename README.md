# UtilityKit

UtilityKit is a modular Bash toolbox for Linux, macOS, and Termux. It bundles the original core tools, implemented roadmap tools, and the expanded next-generation utility set, all wired into a unified dashboard, direct CLI router, and installer.

The current dashboard build is tuned for Termux/mobile terminals with the original-style home dashboard, paged hidden tools, and safer guided prompts for interactive workflows.

## Included tools

### Core suite
- `_apply_changes` — safe directory synchronization with rollback support
- `_rename_batch` — recursive batch renamer / copy-renamer
- `_cache_clean` — multi-manager cache cleaner
- `_symlink_manager` — transactional symlink helper with backups
- `_disk_analyzer` — largest-items disk usage explorer

### Implemented roadmap tools
- `_env_manager` — `.env` profile switching, validation, compare, encrypt/decrypt
- `_git_sweep` — merged-branch, stash, artifact, and `git gc` janitor
- `_docker_janitor` — stopped container / dangling image / volume cleanup
- `_project_scaffold` — starter generator for Bash, Flask, Node CLI, and Go service projects
- `_duplicate_finder` — size-first, hash-second duplicate detector
- `_process_killer` — RAM/swap summary and process killer
- `_port_inspector` — find which process owns a listening port and optionally stop it
- `_ssl_checker` — certificate expiry, DNS, and legacy TLS probe helper
- `_api_tester` — lightweight saved-profile CLI API client with timing metrics
- `_password_gen` — passphrase and random string generator with clipboard support
- `_ssh_assistant` — `~/.ssh/config` host picker and `ssh-copy-id` helper
- `_shredder` — secure erase wrapper using `shred` or overwrite fallback
- `_media_convert` — batch image/video conversion and EXIF stripping wrapper
- `_markdown_toc` — TOC generator, relative link checker, and table aligner
- `_pomodoro` — colorful focus timer with daily work log
- `_cheat_sheet` — markdown snippet store/search utility
- `_zen_mode` — matrix, wave, and Game of Life console screensavers

### Expanded utility set
- `_network_probe` — ping, DNS, public IP, and route diagnostics with fallbacks
- `_cron_manager` — dry-run-first crontab listing/add/remove helper
- `_dotenv_vault` — gpg-backed encrypted `.env` value helper
- `_disk_health` — SMART drive health wrapper when `smartctl` is available
- `_service_watcher` — HTTP endpoint status and timing checks with profiles
- `_git_stats` — repository activity, author, file, and branch summaries
- `_backup_sync` — safe backup preview/apply wrapper around `rsync` or `cp`
- `_weather` — terminal weather lookup with cached fallback
- `_json_explorer` — JSON pretty-printing, path extraction, keys, and summary
- `_tmux_session` — friendly tmux session list/create/attach/kill wrapper
- `_font_inspector` — current terminal glyph and installed font inspection
- `_toolbox_bootstrap` — audit recommended CLI tools for the current environment
- `_project_search` — project text/name search with `rg`/`grep` and `find` fallbacks
- `_github_helper` — small `gh` wrapper for auth, PRs, issues, and runs
- `_link_checker` — Markdown local/HTTP link validation
- `_log_inspector` — error/warning and repeated-line log summaries
- `_csv_toolkit` — CSV header/head inspection through Python
- `_hash_tools` — checksum generation over files and directories
- `_archive_manager` — archive list/extract/create helper
- `_system_snapshot` — redacted machine diagnostic summary
- `_open_files` — file/path/port ownership helper via `lsof` where available
- `_battery_doctor` — battery and power diagnostics for Termux/Linux/macOS backends
- `_release_helper` — git release readiness and optional tag helper
- `_license_helper` — license detection and simple MIT generation
- `_regex_lab` — terminal regex testing against text or files
- `_todo_manager` — plain-text TODO tracker

## Dashboard and CLI

Launch the interactive hub:

```bash
bash main.sh
```

Run a specific tool directly:

```bash
bash main.sh env
bash main.sh git
bash main.sh port 3000
bash main.sh api --method GET --url http://127.0.0.1:8000
bash main.sh pomodoro --work 25 --break 5 --cycles 4
bash main.sh network example.com
bash main.sh json package.json --summary
bash main.sh links README.md
```

### Dashboard navigation update

The expanded dashboard now uses sequential pages: press `m` once to open More Tools, then use `n` for next page and `p` for previous page. All secondary pages use one tool per line with an icon, color, and short description so the purpose of each utility is visible before selection.

Many new utilities also have guided prompts when opened from the dashboard or through `main.sh <command>` without arguments. Direct CLI usage with flags still works for scripting.

## Installation

Local install:

```bash
git clone https://github.com/Thaton3gu7/UtilityKit.git
cd UtilityKit
bash setup.sh
```

Non-interactive install:

```bash
bash setup.sh --no-menu --launcher-name utility
```

## Project layout

```text
UtilityKit/
├── _*/                       # one directory per UtilityKit tool
├── _apply_changes/
├── _api_tester/
├── _cache_clean/
├── _cheat_sheet/
├── _disk_analyzer/
├── _docker_janitor/
├── _duplicate_finder/
├── _env_manager/
├── _git_sweep/
├── _markdown_toc/
├── _media_convert/
├── _password_gen/
├── _pomodoro/
├── _port_inspector/
├── _process_killer/
├── _project_scaffold/
├── _rename_batch/
├── _shredder/
├── _ssh_assistant/
├── _ssl_checker/
├── _symlink_manager/
├── _zen_mode/
├── docs/
├── lib/
├── tests/
├── main.sh
└── setup.sh
```

## Documentation

- `docs/ICON_STYLE_GUIDE.md` — symbol/icon strategy and terminal fallback notes
- `docs/ROADMAP_STATUS.md` — mapping from `idea.md` into implemented tools
- `changes.md` — task-specific implementation notes
- `CHANGES.md` — versioned changelog

## Testing

Run the automated smoke suite:

```bash
bash tests/smoke_test.sh
```
