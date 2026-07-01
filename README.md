<div align="center">

```
██╗   ██╗████████╗██╗██╗     ██╗████████╗██╗   ██╗██╗  ██╗██╗████████╗
██║   ██║╚══██╔══╝██║██║     ██║╚══██╔══╝╚██╗ ██╔╝██║ ██╔╝██║╚══██╔══╝
██║   ██║   ██║   ██║██║     ██║   ██║    ╚████╔╝ █████╔╝ ██║   ██║
██║   ██║   ██║   ██║██║     ██║   ██║     ╚██╔╝  ██╔═██╗ ██║   ██║
╚██████╔╝   ██║   ██║███████╗██║   ██║      ██║   ██║  ██╗██║   ██║
 ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝   ╚═╝
                                                   > C0ded by: ThatOn3Gu7
```

**A modular Bash toolbox for Linux, macOS, and Termux — 48 tools, one dashboard.**

[![License: MIT](https://img.shields.io/badge/License-MIT-cyan.svg?style=flat-square)](LICENSE)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash_5%2B-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Termux-blueviolet?style=flat-square)](https://github.com/Thaton3gu7/UtilityKit)
[![Tests](https://img.shields.io/badge/Smoke%20Tests-PASS%204%2F4-brightgreen?style=flat-square)](#testing)
[![Version](https://img.shields.io/badge/Version-2.0.2-orange?style=flat-square)](CHANGES.md)

</div>

---

## What is UtilityKit?

UtilityKit is a collection of 51 standalone Bash scripts, each living in its own subdirectory with its own README. Every tool runs standalone, can be sourced as a library module, and is wired into a unified interactive dashboard (`main.sh`) with guided prompts and a direct CLI router.

The suite targets three platforms without modification:

```
  Linux         macOS         Termux / Android
  ─────         ─────         ────────────────
  Full support  Full support  ASCII-safe, emoji-friendly,
                              no root required
```

---

## Quick Start

```bash
# Clone and run
git clone https://github.com/Thaton3gu7/UtilityKit.git
cd UtilityKit
bash main.sh

# Or install a launcher
bash setup.sh
utility help
```

**Direct CLI** — no menu required:

```bash
bash main.sh env --dir . --compare
bash main.sh port 3000
bash main.sh pass --mode passphrase --words 6
bash main.sh json package.json --summary
bash main.sh toc README.md --apply --check-links
```

---

## Architecture

```
UtilityKit/
├── main.sh                  ← unified dashboard + CLI router
├── setup.sh                 ← installer (creates launcher in ~/.local/bin)
├── lib/
│   └── uk_common.sh         ← shared helpers: colors, prompts, platform detection
├── _<tool>/
│   ├── _<tool>.sh           ← guarded entry point  (BASH_SOURCE guard)
│   └── _<tool>_README.md    ← standalone docs
├── _cache_clean/
│   ├── _cache_clean.sh
│   └── plugins/             ← 17 package-manager plugins (npm, pip, cargo…)
├── docs/
│   ├── ICON_STYLE_GUIDE.md
│   └── ROADMAP_STATUS.md
└── tests/
    └── smoke_test.sh        ← syntax + behavioral smoke suite
```

Every script wraps its logic in a namespaced `*_main()` function and guards execution with:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  tool_main "$@"
fi
```

This means `main.sh` can safely `source` all 51 scripts without side effects, color variable pollution, or unexpected `exit` calls.

---

## The Full Toolbox

### ── Core Suite ──

| Tool | Command | What it does |
|---|---|---|
| `_apply_changes` | `apply` | Enterprise-grade directory sync: dry-run preview → backup → apply → verify. Supports mirror delete, rollback on failure, concurrency locking, and audit logging. |
| `_rename_batch` | `rename` | Recursively rename or copy-rename files to a new extension. Preview budgets, transactional Ctrl+C rollback, safety exclusions for LICENSE/README/lockfiles. |
| `_move_in_batch` | `move` | Bulk copy or move files with exclusion patterns, optional flattening, collision-safe renaming, and Ctrl+C rollback. Sourceable as a library. |
| `_cache_clean` | `cacheclean` | Multi-manager cache cleaner with a plugin system. Two-confirmation deletion flow, orphan listing, responsive layout. See plugin list below. |
| `_symlink_manager` | `symlink` | Transactional symlink creator with automatic backup of existing targets. Dry-run default. |
| `_disk_analyzer` | `disk` | Largest-items disk usage explorer with optional in-place archive creation. Skips `.git` and VCS metadata. |

#### `_cache_clean` Plugins (17 built-in)

```
npm · yarn · pnpm · bun · pip · cargo · go · gem · composer
dotnet · conan · vcpkg · apt · pacman · dnf · brew · apk
```

Each plugin follows a five-function contract (`*_plugin_info`, `*_detect`, `*_get_cache_dirs`, `*_scan_cache`, `*_clean_orphans`) and is auto-loaded at runtime when its package manager is detected. Writing a new plugin requires only one file in `plugins/`.

---

### ── Roadmap Tools ───

| Tool | Command | What it does |
|---|---|---|
| `_env_manager` | `env` | `.env` profile switching, key comparison against `.env.example`, syntax validation, gpg/openssl encrypt/decrypt. |
| `_git_sweep` | `git` | Merged-branch detection, stash cleanup, `git clean -fdx` artifact sweep, `git gc --prune=now`. Safe preview before every action. |
| `_docker_janitor` | `docker` | Preview and prune stopped containers, dangling images, and orphaned volumes. Requires Docker daemon. Not shown in Termux dashboard. |
| `_project_scaffold` | `scaffold` | Starter project generator for Bash, Python Flask, Node CLI, and Go service stacks. Creates CI workflow, Dockerfile, Makefile, and README. |
| `_duplicate_finder` | `dup` | Size-first, hash-second duplicate detection. Actions: report, delete, or replace with hardlinks. Skips `.git`/`.hg`/`.svn`. |
| `_process_killer` | `proc` | RAM/swap bar chart, top-10 memory consumers, optional SIGTERM/SIGKILL by PID with post-signal confirmation. |
| `_port_inspector` | `port` | Find which process owns a local TCP port via `lsof` or `ss`. Interface summary, optional SIGTERM. |
| `_ssl_checker` | `ssl` | Certificate expiry (colored by days remaining), DNS A/AAAA/MX/TXT records, legacy TLS 1.0/1.1 probe. |
| `_api_tester` | `api` | One-off HTTP requests or saved/replayable profiles. Timing breakdown (DNS, TCP, TTFB, total), `jq` pretty-print, status-code coloring. |
| `_password_gen` | `pass` | XKCD-style passphrases from a 37-word list, or random strings from a 72-char charset. Entropy display. Clipboard copy via `wl-copy`/`xclip`/`pbcopy`/`termux-clipboard-set`. |
| `_ssh_assistant` | `ssh` | Parses `~/.ssh/config`, lists named hosts, connects by number, runs `ssh-copy-id`. Explains auth-only disconnects from GitHub/GitLab/Bitbucket. |
| `_shredder` | `shred` | Multi-pass overwrite using `shred` or `/dev/urandom` fallback. Configurable passes (default 3). Dry-run preview with method/passes display. |
| `_media_convert` | `media` | Batch image conversion via ImageMagick or ffmpeg fallback. Video conversion via ffmpeg libx264. EXIF stripping, quality control, directory scanning. |
| `_markdown_toc` | `toc` | Insert or refresh TOC using `<!-- utilitykit:toc:start/end -->` markers. Relative link validation. Pipe-table column alignment via Python. |
| `_pomodoro` | `pomodoro` | Work/break cycle timer with a live progress bar, session log at `~/.local/state/utilitykit/pomodoro.log`, and Termux vibration support. |
| `_cheat_sheet` | `cheat` | Personal markdown snippet store with tagging, search, and a persistent interactive loop. Files at `~/.local/share/utilitykit/cheat_sheets/`. |

---

### ── Expanded Utility Set ───

| Tool | Command | What it does |
|---|---|---|
| `_network_probe` | `network` | Ping, DNS lookup, public IP via `curl`, route tracing with `traceroute`/`tracepath`. Graceful fallbacks when tools are missing. |
| `_cron_manager` | `cron` | List, add (with format validation), and remove crontab entries. Dry-run default, `--apply` to write. |
| `_dotenv_vault` | `dotenv` | Encrypt individual `KEY=value` pairs in a `.env` file to `ENC::` tokens using gpg symmetric encryption. Backup on apply. |
| `_disk_health` | `disk-health` | SMART health and attribute report via `smartctl`. Auto-detects first disk. Optional short self-test trigger. |
| `_service_watcher` | `service` | HTTP endpoint status and response-time checks. Saved URL profiles, looping interval mode, bell on failure. |
| `_git_stats` | `git-stats` | Commit counts by author, most-changed files, branch activity sorted by committer date. `--since`/`--until`/`--author` filters. |
| `_backup_sync` | `backup` | Dry-run-first backup wrapper around `rsync` (with `--delete` support) or `cp`/`find` fallback. Configurable excludes. |
| `_weather` | `weather` | Fetches current weather from `wttr.in`. Caches last result for offline fallback. Metric/imperial toggle. |
| `_json_explorer` | `json` | Python-backed JSON pretty-print, dot-path extraction, key listing, and structure summary. Reads stdin or file. |
| `_tmux_session` | `tmux` | Friendly wrapper for `tmux` list/new/attach/kill. Clear install hint for Termux. |
| `_font_inspector` | `font` | Terminal glyph sample output (ASCII, box-drawing, Powerline). Optional `fc-list` font enumeration with filter. |
| `_toolbox_bootstrap` | `toolbox` | Audits recommended CLI tools (`fzf`, `rg`, `fd`, `bat`, `eza`, `jq`, `curl`, `git`, `tmux`, `gh`, `zoxide`, `tldr`) and prints `[OK]`/`[MISSING]`. |
| `_project_search` | `search` | Text or filename search with `rg` → `grep -RIn` → `find` fallback chain. |
| `_github_helper` | `github` | Thin wrapper around `gh` for auth status, PR list, issue list, and workflow run list. |
| `_link_checker` | `links` | Python-backed Markdown link validator. Checks local relative links by default; optional HTTP/HTTPS live checks with configurable timeout. |
| `_log_inspector` | `log-inspect` | Grep for errors/warnings/failures with configurable pattern. Top-10 repeated line frequency summary. |
| `_csv_toolkit` | `csv` | Python-backed CSV column header print and row preview with configurable head count. |
| `_hash_tools` | `hash` | `sha256sum` (or `shasum`/`md5sum` fallback) over files and directory trees. |
| `_archive_manager` | `archive` | List, safely extract (with path traversal guard), and create `.tar.gz` or `.zip` archives. |
| `_system_snapshot` | `snapshot` | Compact diagnostic summary: OS, platform, disk usage. Optional file output. |
| `_open_files` | `open-files` | Find processes using a path or port via `lsof`. |
| `_battery_doctor` | `battery` | Battery status via `termux-battery-status` → `pmset` → `acpi`. Top CPU/memory process list. |
| `_release_helper` | `release` | Git status, recent commit log, optional tag creation with `--apply` guard. |
| `_license_helper` | `license` | Detects `LICENSE*`/`COPYING*` in current directory. Generates MIT or Apache 2.0 text. |
| `_todo_manager` | `todo` | Plain-text TSV task tracker with tags, `--done` by line number, and `--search`. |
| `_update_managers` | `update` | Detect and update 60+ package managers (apt, brew, npm, pip, cargo, winget, …) with a live per-command spinner and extracted failure reasons. Aliases: `update-managers`, `upgrade`. |

---

## Dashboard Navigation

```
bash main.sh         ← opens the interactive dashboard

UtilityKit Master Suite — Tool 1 of 49

  ➔  ↻ Apply Changes      (Robust Directory Synchronization)
     ✎ Batch Rename       (Recursive File Renaming & Copying)
     🗑 Cache Cleaner     (Intelligent System Cache Cleanup)
     ► Symlink Manager    (Dotfiles & System Config Management)
     ◆ Disk Analyzer      (Storage Inspection & Quick Archiving)
     ◎ Env Manager        (compare, validate, switch .env profiles)
     ⑂ Git Sweep          (clean merged branches, stashes, artifacts)
     ▣ Project Scaffold   (generate starter projects from templates)
     ▼  (scroll down for more tools)

 Use ▲/▼ or j/k : Scroll Tools         [Enter] : Execute selected
                                       [q]     : Exit UtilityKit
```

All 48 tools live in a single unified scroll list — no nested "More tools"
pages. Highlights:

- **Arrow keys** (`▲`/`▼`) or **Vim keys** (`k`/`j`) move the selection.
- **Enter** runs the highlighted tool's guided wizard.
- **q** exits.
- 8 tools are visible in the viewport; `▲`/`▼` indicators show when more
  tools exist above or below the window.
- The terminal cursor is hidden while the menu is active (via `tput civis`)
  and automatically restored on exit, Ctrl+C, or SIGTERM via an `EXIT` trap.

Every tool has a guided interactive wizard when launched from the dashboard or invoked without arguments. Direct CLI flags still work for scripting.

---

## Shared Library (`lib/uk_common.sh`)

All tools source `lib/uk_common.sh`, which provides:

```
uk_prompt            read -r with /dev/tty  (safe in subshells and pipelines)
uk_confirm           [Y/n] prompt with non-interactive fallback
uk_header            section header with color + divider
uk_section_title     inline section label
uk_note / uk_info    ℹ blue info line
uk_success           ✔ green success line
uk_warn              ⚠ yellow warning to stderr
uk_error             ✖ red error to stderr
uk_die               error + return 1
uk_bar               ASCII progress bar  (# fill, - empty)
uk_has_cmd           command -v wrapper
uk_is_interactive    [[ -t 0 && -t 1 ]]
uk_platform          linux | macos | termux
uk_abs_path          realpath → python3 → PWD fallback
uk_data_dir          ~/.local/share/utilitykit/  (auto-created)
uk_state_dir         ~/.local/state/utilitykit/  (auto-created)
uk_slugify           lowercase + hyphen-safe name
uk_copy_to_clipboard wl-copy → xclip → pbcopy → termux-clipboard-set → clip.exe
uk_pick_clipboard_cmd returns first available clipboard command
uk_repeat            repeat a character N times
uk_now / uk_stamp    date helpers
```

The library uses a load-once guard (`UK_COMMON_SH_LOADED`) so sourcing it multiple times from nested scripts is safe.

---

## Visual System

UtilityKit uses standard Unicode symbols that render in common terminal fonts, with plain ASCII fallbacks for dumb terminals, pipes, and `NO_COLOR` environments.

```
  ✔  Success       [OK]
  ✖  Error         [X]
  ⚠  Warning       [!]
  ℹ  Info          i
  ⚙  Working       *
  ❯  Prompt        >
  ●  Bullet        *
  ◆  Highlight     <>
  ╭─╮ Box corners  +-+
  █░ Progress bar  #.
```

Color is enhancement, never the only channel of meaning. `NO_COLOR=1` and `NO_UNICODE=1` are both respected globally.

---

## Installing

```bash
# Interactive — prompts for launcher name, install dir, and PATH update
bash setup.sh

# Non-interactive
bash setup.sh --no-menu --launcher-name utility --install-dir ~/.local/share/utility --bin-dir ~/.local/bin

# After install
utility help
utility env --dir . --compare
utility port 3000 --kill
```

`setup.sh` copies all `_*/` tool directories, `lib/`, `docs/`, and `tests/` to the install location, creates a launcher wrapper, and optionally adds `bin-dir` to `~/.bashrc`/`~/.zshrc`.

---

## Testing

```bash
bash tests/smoke_test.sh
# PASS=4 FAIL=0
```

The suite covers:

- **Syntax check** — `bash -n` across every `.sh` file in the repository
- **Help/routing** — `main.sh help`, `setup.sh --help`, and `main.sh <cmd> --help` for all routed commands
- **Core tool smoke** — apply changes mirror mode, rename copy mode, move with excludes, symlink backup/create, disk scan, cache cleaner entrypoint
- **Roadmap tool smoke** — env compare/validate, git sweep branch detection, scaffold generation, duplicate deletion, process kill, port inspect, API test, password gen, SSH config parse, shredder, media convert help, markdown TOC insertion, pomodoro short-duration, cheat sheet add/search
- **New utility smoke** — JSON path extraction, link checking, CSV column inspection, hash generation, git stats, backup sync, license generation, toolbox audit, font glyph check, system snapshot
- **Update Managers smoke** — `update --list` and a full `update --yes --dry-run`
- **Doctor / registry integrity** — `main.sh doctor --quick` validates the tool registry against the filesystem and dispatch

### Registry & `doctor`

All tools are registered once in `UK_REGISTRY` (in `main.sh`); the lazy-loader map
and dashboard menu are derived from it. Run a health check any time with:

```bash
./main.sh doctor          # full check (includes per-tool --help)
./main.sh doctor --quick  # skip the per-tool --help pass
```

---

## Writing a Plugin for `_cache_clean`

Drop a file in `_cache_clean/plugins/` named after the package manager:

```bash
# plugins/mybuild.sh

mybuild_plugin_info() {
  printf 'mybuild|MyBuild|🔨\n'   # id|display_name|icon
}

mybuild_detect() {
  command -v mybuild >/dev/null 2>&1
}

mybuild_get_cache_dirs() {
  printf '%s\n' "$HOME/.mybuild/cache"
}

mybuild_scan_cache() {
  local dir
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && { cc_emit_err "$dir" "not found"; continue; }
    cc_emit_tot "$dir" "$(cc_du_kb "$dir")"
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "stale cache older than ${CC_OLDER_THAN} days"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")
  done < <(mybuild_get_cache_dirs)
}

mybuild_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
```

Helper functions available to all plugins: `cc_find_old DIR DAYS`, `cc_find_partial DIR`, `cc_du_kb DIR`, `cc_file_size FILE`, `cc_emit_tot`, `cc_emit_orphan`, `cc_emit_err`, `cc_clean_orphans_from_file`.

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full guide. Key rules:

- Every tool lives in `_tool_name/_tool_name.sh` with its own `_tool_name_README.md`
- Wrap execution in a namespaced `*_main()` and guard with `[[ "${BASH_SOURCE[0]}" == "${0}" ]]`
- Register traps **inside** `*_main()`, never at the top level
- Source `lib/uk_common.sh` for visuals and helpers — don't re-implement colors
- Add a `main.sh` route, a dashboard wizard, and a `setup.sh` directory entry
- Use semantic commits: `feat(tool):`, `fix(tool):`, `refactor(tool):`, `docs:`

---

## Changelog

See [`CHANGES.md`](CHANGES.md) for the full versioned changelog.

**v4.2.0** — current — unified arrow-key scroll menu (8-row viewport), hidden cursor with restore trap, `set -euo pipefail` re-enabled  
**v4.1.2** — previous  
**v4.1.1** — cache cleaner runtime fixes under `set -e`, terminal-width hardening  
**v4.1.0** — dashboard restyle, paged more-tools navigation, expanded interactive prompts  
**v4.0.0** — initial unified suite: 18 roadmap tools + shared library + smoke suite  

---

## License

[MIT](LICENSE) — use, modify, and share freely.

---

<div align="center">

*Built for developers who live in the terminal.*

</div>
