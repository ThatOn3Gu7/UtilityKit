# Changelog

## Unreleased

### Added (Update Managers)
- New tool `_update_managers` (command `update`, aliases `update-managers`,
  `upgrade`): detects and updates 60+ system/app/language/toolchain package
  managers from one place, with a live per-sub-command spinner, extracted
  failure reasons, and isolated failures (one manager failing never aborts the
  batch). Registered in the hub and shown on the dashboard.

### Added (Registry & Doctor)
- Introduced `UK_REGISTRY`, a single source of truth describing every tool. The
  `UK_TOOL_PATHS` loader map and the dashboard menu arrays are now derived from
  it, so they can no longer drift out of sync.
- New `doctor` command (`./main.sh doctor`, alias `diagnostics`) that validates
  the registry against the files on disk, the `run_tool` dispatch cases, menu
  array alignment, orphan directories, and each tool's `--help`. Exits nonzero on
  any hard problem, so it is CI-friendly. Two new checks were added to
  `tests/smoke_test.sh` (Update Managers smoke + doctor integrity).

### Removed (Cleanup)
- Removed all references to the deleted tools `_log_rotator`, `_zen_mode`,
  `_clipboard_manager`, and `_regex_lab`, plus the never-routed `logs` command,
  from `main.sh`, the tests, `README.md`, `docs/ROADMAP_STATUS.md`, and
  `docs/index.html`. Tool counts were corrected to 48. (Clipboard *helper*
  functions used by `_password_gen` and `lib/uk_common.sh` were kept.)

### Changed (Dashboard)
- Replaced the paged "More tools" navigation with a single unified scroll list
  driven by `▲`/`▼` arrow keys (or Vim `j`/`k`). 8 tools are visible at a time
  and scroll indicators show when more tools exist above or below the viewport.
- Hide the terminal cursor (`tput civis`) while the interactive dashboard is
  active for a cleaner appearance, and restore it (`tput cnorm`) via a
  `trap ... EXIT INT TERM HUP` so Ctrl+C, SIGTERM, or any uncaught error
  from `set -e` still leaves the cursor visible.

### Fixed (Dashboard)
- Re-enabled `set -euo pipefail` in `main.sh` and resolved the only remaining
  unbound-variable site: provide a fallback `UK_C_BRIGHT_GREEN := UK_C_GREEN`
  for the legend, since `UK_C_BRIGHT_GREEN` is not defined in
  `lib/uk_common.sh`.

### Fixed (Deep Review)
- fix: guard sourced tool scripts from enabling strict shell options in the parent shell.
- fix: prevent rename, move, and apply-change color setup from clobbering shared UtilityKit color variables when sourced.
- fix: URL-encode weather locations before calling wttr.in.
- fix: make license detection robust when only LICENSE* or COPYING* exists.
- fix: validate todo IDs before marking tasks done.
- fix: clarify degraded battery backend output instead of silently swallowing unavailable backends.
- fix: harden project scaffold target deletion against unsafe names and paths.
- fix: add macOS-compatible fallbacks for find/stat/sort portability checks.
- fix: align password generator passphrase entropy documentation with the 37-word built-in list.
- fix: add deep review regression coverage for sourcing safety, known bug fixes, archive traversal, cron validation, and duplicate scans.

### Added
- Added 27 new cross-platform utility modules, each with a README and direct `main.sh` command route:
  network probe, cron manager, dotenv vault, disk health, service watcher, git stats,
  backup sync, clipboard manager, weather, JSON explorer, tmux session manager,
  font inspector, toolbox bootstrap, project search, GitHub helper, link checker,
  log inspector, CSV toolkit, hash tools, archive manager, system snapshot,
  open files, battery doctor, release helper, license helper, regex lab, and todo manager.
- Added smoke-test help coverage and functional smoke checks for representative new tools.


### Changed
- Reworked expanded dashboard navigation so More Tools pages advance with `n`/`p` instead of requiring numbered next-page hops.
- Restyled all secondary dashboard pages to match the main dashboard with one-line-per-tool entries, icons, colors, and short descriptions.
- Added guided `main.sh <new-tool>` prompts for the new utilities so dashboard-launched tools ask self-explanatory questions instead of dropping users into terse usage output.

### Notes
- New tools are designed to degrade safely on minimal systems and Termux: optional dependencies are detected at runtime, and unavailable backends produce warnings rather than hard failures where possible.


All notable changes to UtilityKit are documented here.

## [4.2.1] - 2026-07-05

### Fixed
- **process_killer**: Replace `${1:-}` with `$1` in awk printf to fix field
  expansion producing empty columns in the top-process table.
- **ssh_tunnel**: Fix the interactive wizard so `kill` and `restart` correctly
  pass the subcommand to the backend instead of a shared `case` branch.
- **tmux_session**, **update_managers**, **weather**: Use `${VAR:=value}` default
  syntax for color variables so parent-shell values are not clobbered.
- **deep_review_test**: Add `_move_in_batch` and `_apply_changes` exclusions to
  the `find -printf` portability check.

## [4.1.1] - 2026-06-19

### Fixed
- Repaired the Cache Cleaner dashboard option by fixing `cacheclean` runtime failures under `set -e` in non-root sessions.
- Hardened cache-clean terminal-width detection so it no longer exits early when no TTY width can be queried.
- Restored richer colored/iconized dashboard labels on the compact home screen while keeping the paged layout.
- Prevented menu-driven tool exits from dropping the entire dashboard unexpectedly.

## [4.1.0] - 2026-06-19

### Changed
- Restored a dashboard style closer to the earlier UtilityKit home screen, but now with hidden-tool paging via a `More tools` flow instead of dumping every option on one screen.
- Removed the `zen` screensaver from the visible dashboard menu while keeping it available as a direct CLI-only command.
- Added detailed, example-driven interactive prompts across the dashboard and setup flow so users can understand what each field means before entering values.

### Fixed
- Fixed `_rename_batch` so leaving the output directory blank correctly performs in-place renaming instead of trying to write into `/`.
- Improved `_rename_batch` copy mode so it preserves relative subdirectories and creates destination folders safely.
- Improved `_git_sweep` empty-state output so sections no longer look blank/confusing when nothing is found.
- Fixed project scaffold destination handling by resolving and respecting the provided parent destination path.
- Improved `_process_killer` so targeted kill operations describe the process and confirm whether it actually exited.
- Improved `_ssh_assistant` so Git hosting SSH test sessions are less confusing by explaining intentional auth-only disconnects.
- Improved `_cheat_sheet` with a persistent internal loop so users can keep listing, adding, showing, and searching without being thrown back to the main dashboard after one action.
- Improved `_pomodoro` visuals and interactive setup so it no longer jumps straight into a 25-minute run with minimal context.
- Improved `_markdown_toc` so it reports how many TOC entries were inserted and the dashboard can show a unified diff after changes.
- Suppressed noisy Termux network summary warnings in `_port_inspector`.
- Updated `_disk_analyzer` to skip metadata folders like `.git` in the top-level summary.
- Refined the interactive setup wizard with clearer installation-path prompts.

## [4.0.1] - 2026-06-19

### Fixed
- Reworked the main dashboard into a smaller, cleaner, Termux-friendlier layout.
- Added guided dashboard wizards for rename, password generation, port inspection, media conversion, TOC generation, cheat sheets, pomodoro, and zen mode.
- Improved `_markdown_toc` so it reports how many entries were inserted and places new TOCs near the top of the document.

## [4.0.0] - 2026-06-19

### Added
- Implemented all 18 roadmap tools from `idea.md` as dedicated modular directories with guarded entry points and standalone READMEs.
- Added `lib/uk_common.sh` for shared terminal visuals, prompts, platform detection, and clipboard helpers.
- Rebuilt `main.sh` into a unified 23-tool dashboard with direct command routing and menu execution wrappers.
- Added `docs/ICON_STYLE_GUIDE.md` and `docs/ROADMAP_STATUS.md`.
- Added `tests/smoke_test.sh` for automated syntax and behavioral smoke coverage.
- Added lowercase `changes.md` with implementation-specific notes.

### Fixed
- Restored cache-cleaner routing by sourcing the correct `_cache_clean/_cache_clean.sh` entry point.
- Added `_cache_clean/_cache_clean.sh` compatibility wrapper for older references.
- Patched `_cache_clean/_cache_clean.sh` color and border variables that could break parts of the UI at runtime.
- Modernized `setup.sh` so installation copies all modular tool directories plus shared docs/lib/tests.

### Changed
- Expanded the suite from the original core tools into a full UtilityKit ecosystem release.
- Standardized new tools on Unicode-first visuals with ASCII fallbacks for limited terminals.
