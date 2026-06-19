# changes.md

This file documents the work completed for the UtilityKit roadmap implementation task.

## Directory separation

To keep the original clone isolated from the modified work, two separate directories were prepared:

- `delivery/original` — preserved clone snapshot
- `delivery/edited` — edited implementation and test target

## Major implementation work

### 1. Implemented the full 18-tool roadmap from `idea.md`
The following new modular directories were added, each with a guarded script entry point and standalone `README.md`:

- `_env_manager`
- `_git_sweep`
- `_docker_janitor`
- `_project_scaffold`
- `_duplicate_finder`
- `_log_rotator`
- `_process_killer`
- `_port_inspector`
- `_ssl_checker`
- `_api_tester`
- `_password_gen`
- `_ssh_assistant`
- `_shredder`
- `_media_convert`
- `_markdown_toc`
- `_pomodoro`
- `_cheat_sheet`
- `_zen_mode`

### 2. Shared platform/UI layer
Added `lib/uk_common.sh` to provide:

- color handling
- Unicode/ASCII fallback icons
- prompts and confirmations
- platform helpers
- clipboard helper detection
- common data/state directory handling
- reusable progress bar helper

### 3. Central dashboard rewrite
`main.sh` was rebuilt to:

- source the full tool suite safely
- expose a menu for all 23 tools
- provide direct command routing
- keep existing core tools available
- add menu wrappers for tools that benefit from guided prompts

### 4. Installer modernization
`setup.sh` was updated so it now installs:

- all `_*/` tool directories
- `lib/`
- `docs/`
- `tests/`
- updated root documentation files

### 5. Existing bug fixes
Fixed pre-existing issues found during auditing:

- broken cache cleaner sourcing path in the dashboard
- missing runtime variables in `_cache_clean/_cache_clean.sh`
- missing compatibility entrypoint for legacy `_cache_clean.sh` references

### 6. Documentation additions
Added/reworked:

- `README.md`
- `CHANGES.md`
- `changes.md`
- `docs/ICON_STYLE_GUIDE.md`
- `docs/ROADMAP_STATUS.md`

### 7. Testing
Added `tests/smoke_test.sh` and used it to validate:

- shell syntax across every `.sh` file
- help/entrypoint coverage for all tools
- representative functional smoke tests for both original core tools and new roadmap tools

## Follow-up UX fixes after Termux feedback

After the first implementation pass, additional real-device fixes were applied based on Termux screenshots and the later `feedback.txt` notes:

- restored a dashboard style closer to the earlier UtilityKit home screen instead of showing every tool on one long page
- introduced a `More tools` paging flow so the dashboard stays compact on mobile screens
- removed the `zen` screensaver from the visible dashboard menu while keeping it available as a direct CLI command if ever needed
- added detailed prompts with examples/defaults to make each guided workflow easier to understand
- added dashboard wizards for tools that previously launched too abruptly or looked like they did nothing
- fixed the batch renamer's blank-output bug that caused copy mode to target the filesystem root
- made rename copy mode preserve subdirectories instead of flattening everything into a single folder
- improved project scaffold destination handling so the requested parent destination is actually respected
- improved git sweep so empty sections say `none found` instead of looking broken or blank
- improved process-kill output so it describes the target process and confirms whether it actually exited
- improved SSH assistant behavior for auth-only Git host handshakes that intentionally close after successful authentication
- improved markdown TOC feedback so the tool reports inserted entries and the dashboard can show a unified diff afterwards
- improved cheat sheet behavior so users stay inside the cheat-sheet loop until they explicitly choose to leave it
- improved pomodoro visuals and prompting so the timer is clearer before and during a run
- suppressed noisy network summary warnings in Termux for the port inspector
- made the disk analyzer skip metadata folders like `.git` in top-level summaries
- improved the setup wizard prompts so installation paths and launcher behavior are easier to understand
- fixed the cache cleaner dashboard entry so choosing option 3 no longer silently drops back to the shell
- restored colored/iconized home menu labels while keeping the compact dashboard structure

## Notes on icon and symbol work

The new features use a consistent terminal visual style based on:

- standard Unicode symbols first
- ASCII fallbacks for limited terminals
- optional compatibility with Nerd Font-style terminal environments
- no bundled third-party font assets, to keep licensing and distribution simple
