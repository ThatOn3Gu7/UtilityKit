# Changelog

All notable changes to UtilityKit are documented here.

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
