# Changelog

## [5.10.6] - 2026-07-21

### Added
- **Shared `uk_menu()` interactive list selector in `lib/uk_common.sh`.** Extracted the arrow-key + viewport navigation from `main.sh`'s dashboard into a reusable function that any tool can call: `uk_menu --prompt "Choose" "Option A|description|icon" "Option B|..."`. Supports pipe-delimited enriched items (label, description, icon), viewport scrolling for long lists, vim/arrow keys, and automatic non-TTY fallback to a numbered prompt. `uk_read_key()` was also extracted to `uk_common.sh` from `main.sh` so all tools share the same key reader.
- **`_duplicate_finder.sh` and `_ssh_assistant.sh` migrated to `uk_menu()`.** Both tools now use the shared interactive menu instead of hand-rolled numbered prompts, gaining arrow-key navigation with zero per-tool viewport code.

## [5.10.5] - 2026-07-21

### Added
- **`main.sh tools` command.** `bash main.sh tools` renders a full-width table of every registered tool (key, action, name, description) from the single-source-of-truth `UK_REGISTRY`; `bash main.sh tools --json` emits a valid JSON array of objects suitable for external UIs and scripts. Aliases: `list`, `catalog`.

## [5.10.0] - 2026-07-19

### Added
- **Homebrew install path.** New `Formula/utilitykit.rb` lets the repository double as a tap: `brew tap thaton3gu7/utilitykit https://github.com/ThatOn3Gu7/UtilityKit.git && brew install utilitykit` (or `--HEAD` before any release tag exists). The formula depends on Homebrew `bash` (the suite needs bash ≥ 4, macOS ships 3.2), installs the runtime tree into `libexec`, writes a `utility` launcher that always runs under that bash, and registers the bash/zsh tab-completions. `packaging/update-formula.sh` re-points the formula's `url`/`sha256` at a released tag in one command.
- **Termux `.deb` install path.** New `packaging/build-termux-deb.sh` stages the runtime tree under `$PREFIX/opt/utilitykit`, a `utility` launcher in `$PREFIX/bin` (explicit Termux-bash shebang, no `termux-exec` dependency), and completions in the system bash/zsh completion dirs, then builds `utilitykit_<version>_all.deb` with `dpkg-deb --root-owner-group -Zxz`. Version is read from `UK_VERSION` so package and code can never drift. Installable with `pkg install ./utilitykit_<version>_all.deb`; removable with `pkg uninstall utilitykit`.
- **Release automation.** New `.github/workflows/release.yml`: on a `vX.Y.Z` tag push it fails fast unless the tag matches `UK_VERSION`, builds the Termux `.deb` plus a stable-named `utilitykit_all.deb` alias (so `releases/latest/download/utilitykit_all.deb` always works), publishes the GitHub Release with install instructions, and prints the source-tarball sha256 the formula needs. Full release flow documented in `packaging/README.md`.

### Changed
- README `Installing` section now leads with the clone-free Homebrew and Termux paths; `setup.sh` remains the from-checkout installer.

## [5.9.0] - 2026-07-18

### Added
- **Shell tab-completions generated from `UK_REGISTRY`.** New `scripts/gen_completions.sh` parses the registry block in `main.sh` (single source of truth) plus each tool's argument-parsing `case` labels and emits `completions/utility.bash` and `completions/utility.zsh`, so `utility <TAB>` completes all commands (tools + `setup`/`doctor`/`help`/`version`) and `utility <cmd> --<TAB>` completes that tool's flags. Both files register the default `utility` name and direct `main.sh` runs; a custom launcher name is picked up via `UK_COMPLETE_CMD`. zsh completions show the registry's one-line descriptions and work either sourced after `compinit` or dropped into `$fpath` as `_utility`. Re-run the generator whenever the registry or a tool's flags change — the files are committed artifacts, never hand-edited.
- **`setup.sh` installs the completions.** New step 7 copies `scripts/` and `completions/` into the install dir and appends a guarded `UK_COMPLETE_CMD='<launcher>' source .../utility.{bash,zsh}` line to `~/.bashrc`, `~/.zshrc`, and `$ZDOTDIR/.zshrc`. Idempotent: re-running setup (even with a different `--launcher-name`) rewrites the existing line in place instead of duplicating it.
- **Flags offered on empty word too.** `utility <cmd> <TAB>` (no `-` typed yet) now lists the tool's flags up front — bash shows flags only, zsh shows flags plus files. Typing `-` first still filters to flags alone.

## [5.8.0] - 2026-07-18

### Added
- **Shared `uk_output_format` table/json/csv rendering in `lib/uk_common.sh`.** A canonical output-format convention so new tools get table/JSON/CSV rendering for free instead of hand-rolling JSON escaping each time. `uk_json_escape` / `uk_json_str` / `uk_json_lit` / `uk_json_obj` / `uk_json_arr` provide shared, python3-aware JSON escaping and object/array builders (with a pure-bash fallback); `uk_table_init` / `uk_table_row` / `uk_table_count` / `uk_table_render` accumulate rows and render the same dataset as a boxed table (TTY), a JSON array of objects, or CSV. Format auto-resolves via `UK_FMT` env, `--format`/`--json`/`--csv` flags, then TTY?table:json. `uk_out_format_from_args` parses those flags and reports the arg count consumed.

### Changed
- **Ad-hoc JSON escapes migrated to the shared helper.** `_dns_probe` (`dp_json_escape`), `_yaml_toolkit` (`yt_json_escape`), and `_uuid_gen` (`--json` array emission) now delegate to `uk_json_escape`.

## [5.7.0] - 2026-07-18

### Added
- **Dry-run-by-default for `_image_tool` and `_pdf_toolkit`.** All file-writing subcommands (`resize`, `convert`, `strip`, `optimize`, `thumb`; and `merge`, `split`, `compress`, `rotate`) now preview only and require `--apply` to write output. Their interactive wizards prompt before writing. This closes the gap where `_image_tool optimize` rewrote files in place with no preview.
- **`CONTRIBUTING.md` safe-by-default write/delete convention.** A new section documents the project-wide rule that any tool mutating the filesystem or system state must protect the user by default (dry-run preview or `[y/N]` confirmation), plus a safety matrix table covering all write/delete tools.

### Changed
- **Project-wide version policy.** The single `UK_VERSION` in `lib/uk_common.sh` is the version of the whole UtilityKit project. A significant change to *any* script (not only files carrying their own `VERSION=`) bumps this project version according to the size of the change (patch / minor / major).

## [5.6.0] - 2026-07-18

- **User config file: `~/.config/utilitykit/config`.** `lib/uk_common.sh` now applies `${XDG_CONFIG_HOME:-~/.config}/utilitykit/config` (path overridable via `UK_CONFIG_FILE`) every time it is sourced, so `main.sh`, `setup.sh`, and every tool pick up suite-wide defaults like `DEFAULT_CACHE_OLDER_THAN=30`, `DEFAULT_PASSPHRASE_WORDS=6`, or `NO_UNICODE=1` without retyping flags. The file is parsed, never sourced: only `[export] KEY=VALUE` lines are accepted (bare or single/double-quoted values, blank lines, `# comments` — full-line or after an unquoted value), so a stray command in the file cannot execute and a typo cannot abort tools under `set -eu`; malformed lines are skipped with a `utilitykit: <file>:<line> skipped` warning on stderr. Precedence is flag > environment > config file > built-in default — a key already set in the environment (even to empty) is never overwritten, so one-off overrides like `NO_COLOR=1 bash main.sh` keep working. New smoke-test group `config_file_smoke` covers parsing, quoting, injection safety, and env precedence.


## [5.5.0] - 2026-07-18

### Added
- **Canonical `uk_spinner` in `lib/uk_common.sh`.** One wait-on-a-background-job spinner for the whole suite: braille frames with an ASCII fallback under `NO_UNICODE`, `NO_COLOR` honored at call time, width-safe `\r`+`ESC[K` redraws that never wrap, a static `label...` degradation on non-TTY stdout, and preserved exit status. Options: `--prefix` (static id before the label), `--label-file` (live label re-read every tick), `--elapsed` (running seconds counter), `--interval`. Shared `uk_spinner_frames` also feeds the width-gate notice.
- **Canonical `uk_fake_progress` in `lib/uk_common.sh`.** The indeterminate accelerating percent bar (formerly duplicated in `_media_convert` and `_disk_analyzer`): climbs to 99% and holds until the job exits, then prints a green 100% bar or a red failure line with the exit code.

### Changed
- **Spinner call sites now delegate to the library.** `setup.sh` (`setup_run_with_spinner`), `_cache_clean` (`cc_spinner`, now honoring `--no-color` via `NO_COLOR`), and `_update_managers` (both spin loops plus `draw_spinner_line`, replaced by a thin `um_spin` bridge that maps `--ascii`/`--no-color` onto `NO_UNICODE`/`NO_COLOR`) all use `uk_spinner`. `_media_convert` and `_disk_analyzer` use `uk_fake_progress`. Net: ~200 lines of duplicated animation code removed; `_cache_clean`'s spinner gains the previously missing `NO_UNICODE` fallback.

## [5.4.0] - 2026-07-17

### Added
- **`doctor --fix`.** Opt-in auto-repair for the easy integrity issues: creates missing `modules/_<tool>/_<tool>_README.md` stubs from registry metadata (name + description), and prints a suggested `git rm -r "modules/_<dir>"` command for orphan tool directories — never deletes anything itself. Summary line reports the auto-fixed count.
- **Per-tool README check.** `doctor` now verifies every registry tool has its `_<tool>_README.md` on disk and warns when missing.

### Fixed
- **Orphan-directory scan.** The scan globbed `$UK_ROOT_DIR/_*/` (repo root) instead of `modules/_*/`, so it never matched anything and always reported "none".

## [5.3.0] - 2026-07-15

### Security
- **Fail-fast error propagation.** Tools no longer return false success when a subcommand, traversal, parser, or cleanup step fails. Enumeration, scanning, conversion, rendering, and write-back stages now propagate real exit statuses across `_api_tester`, `_backup_sync`, `_cron_manager`, `_disk_health`, `_dotenv_vault`, `_dns_probe`, `_file_watcher`, `_git_sweep`, `_hash_tools`, `_http_bench`, `_image_tool`, `_installed`, `_link_checker`, `_log_inspector`, `_media_convert`, `_move_in_batch`, `_open_files`, `_pdf_toolkit`, `_port_inspector`, `_project_search`, `_release_helper`, `_secret_scan`, `_service_watcher`, `_ssl_checker`, `_update_managers`, `_yt_download`, and the core `uk_load`/`uk_source_tool` paths.
- **Injection & word-splitting.** Command/arithmetic injection closed via `--` terminators before user URLs and filenames (`_api_tester`, `_move_in_batch`, `_ssh_assistant`, `_ssh_tunnel`, `_yt_download`), `printf -v` instead of `eval` for prompt assignment (`_tmux_session`, `_weather`), and a single quoted `TZ=…` `env` assignment in `_time_convert`. Host/port/alias/field validators tightened (`_ssl_checker`, `_ssh_assistant`, `_ip_info`, `_dns_probe`, `_port_inspector`).
- **Path traversal & containment.** Project/path names confined to their directories (`_env_manager`, `_cheat_sheet`, `_rename_batch`, `_symlink_manager`, `_apply_changes`, `_cache_clean`, `_service_watcher`), and archive member names/types validated in Python with symlink/hardlink/device/FIFO rejection before extraction (`_archive_manager`).
- **NUL-safe traversal.** Switched to `find -print0` / `while IFS= read -r -d ''` records (instead of tab/newline) in `_apply_changes`, `_backup_sync`, `_duplicate_finder`, `_hash_tools`, `_move_in_batch`, `_rename_batch`, `_secret_scan`, `_git_hooks`, and `_cron_manager` (NUL-safe pre-commit loop).
- **Transport security.** TLS verified by default with explicit `--insecure` opt-in (`_service_watcher`); GeoIP moved from plaintext HTTP to verified HTTPS (`_ip_info`); connection failures separated from protocol rejection (`_ssl_checker`).
- **Least-privilege files & PIDs.** Temp/state files created with mode `600`/`700` and non-predictable paths (`_clipboard_history`, `_password_gen`, `_ssh_assistant`, `_ssh_tunnel`, `_log_inspector`, `_markdown_toc`); PID-identity checks before signaling to avoid unrelated-process kills (`_ssh_tunnel`, `_process_killer`, `_port_inspector`).
- **Stronger randomness & permissions.** Password generation uses rejection sampling from `/dev/urandom` (no `$RANDOM` modulo bias) with `700`/`600` saved-file modes (`_password_gen`).

### Fixed
- **`_ssh_tunnel`** — a stopped tunnel can once again be killed or restarted (dead-PID config entries were previously refused).
- **`_ip_info`** — `--json` no longer emits truncated/empty JSON when a transient GeoIP fetch fails.
- **`_installed`** — a benign empty parser result (empty global npm, newer pipx) no longer aborts the whole inventory or mislabels it "query failed".
- **`_secret_scan`** — a single unreadable subdirectory no longer aborts the entire scan; traversal errors are surfaced as a warning while still scanning what was enumerated.
- **`_cache_clean`** — `wc -c` whitespace padding no longer trips the `^[0-9]+$` size validation and falsely fails the scan.
- **`_yt_download`** — metadata fields are parsed from a single tab-delimited `--print` template with stderr captured separately, so `WARNING`/`ERROR` lines can no longer shift the field mapping.
- **`_cron_manager`** — adding the first entry to a fresh crontab still works; empty-read is treated as an empty crontab.
- **`_project_scaffold`** — removed a dead `slug` computation.
- **`_duplicate_finder`** — removed a no-op `awk` substitution and replaced O(n²) size grouping with O(n) associative-array bucketing.
- **`_docker_janitor`** — `dj_count` counts only stdout so a stderr warning cannot inflate the preview count.
- **`_clipboard_history`** — a corrupt trailing record no longer blocks new adds.
- **`_main.sh`** — restored the width-gate bail guard so pressing `q` drops into the dashboard instead of exiting the program.
- **`_archive_manager`** — no longer prints a misleading "unsafe paths" header when validation fails for a missing dependency or exception.

### Changed
- `lib/uk_common.sh` and `main.sh` gained defensive error handling for platform/data/state directory creation, `read`/`source` failures, terminal-dimension validation (`_uk_valid_term_dimension`), and the dispatch now uses explicit `if/else` (a failed tool no longer silently launches its wizard).
- `_cache_clean` plugins normalized `command -v` probes.

## [5.2.5] - 2026-07-13

### Added
- **`_installed` tool — package & PATH inventory.** New `installed` command lists every installed package (native + language package managers: apt, brew, npm, pip, cargo, and more) and every executable discovered on `$PATH`. Features: a live per-manager spinner (`◐◓◑◒` on UTF-8 terminals, ASCII `|/-\` otherwise, auto-disabled for `--json`/`--export`), per-package version detection printed as `[ - name → vX ]` (version forced to a `v` prefix; name-only when no version is reported), and a JSON summary of `{"name","version"}` objects. Read-only; every manager list is capped with a portable `timeout 25` so a blocked network (e.g. `npm ls -g`) degrades gracefully instead of hanging.

## [5.2.1] - 2026-07-13

### Added
- **Interactive directory picker expanded to more tools.** `_move_in_batch` gains a two-step wizard: pick the SOURCE directory, then the DESTINATION directory, with post-selection prompts for transfer method (`cp`/`mv`) and flatten mode. Triggered via `-i`/`--interactive` or the dashboard wizard.
- **Directory icons in pickers.** Every directory and symlink entry shows a 📁 / 🔗 glyph (or `[D]` / `[L]` fallback under `NO_UNICODE` / dumb terminals) in the full-screen and plain fallback menus of `_apply_changes`, `_move_in_batch`, and `_rename_batch`.
- **Banner-safe picker redraw.** The full-screen picker no longer clears the whole screen on every redraw — the UK banner and step messages stay visible above the menu, with emoji-width compensation for correct border alignment.
- **Canonical documentation site.** The React + Vite + Tailwind single-page app (HashRouter, semantic design tokens, system light/dark theme with anti-flash inline script) is now the source of truth for the docs, building to a self-contained single-file bundle via `vite-plugin-singlefile` and shipping to GitHub Pages on pushes touching `docs-site/` or `docs/`.

### Changed
- **Setup glyph.** Replaced `UK_I_STAR` (✦) with `UK_I_CLAUDE` (✽) in `lib/uk_common.sh` and `setup.sh`.
- **Docs directory renamed** `webAPP/` → `docs-site/` to match its role; all workflow, `CLAUDE.md`, and `README.md` references updated.

### Fixed
- **Flicker-free picker navigation.** UP/DOWN now use a surgical pointer redraw (`rb_ac_draw_pointer()`) instead of a full-screen repaint, restoring green+bold arrow styling across `_move_in_batch` and `_rename_batch`.
- **Robust terminal input.** `stty -echo` suppresses escape-fragment echo between `read` calls, and the escape-sequence parser now consumes full CSI parameter bytes (Shift+Arrow, Page Up/Down, Home, End). An ANSI DSR query (`\033[6n`) detects the cursor row at menu start so the viewport accounts for banners/messages without clearing the screen.
- **Interrupted transfers.** `handle_interrupt` now `exit 130` (Ctrl+C truly terminates the script instead of resuming the file loop), and rollback correctly handles `mv` mode by moving files back to the source instead of deleting the destination — preventing permanent data loss on interrupted moves.

## [5.1.1] - 2026-07-11

### Fixed
- **Unbound-variable safety under `set -u`.** The repo runs with `set -euo pipefail`, so any unset variable is fatal. `uk_setup_visuals` (in `lib/uk_common.sh`) was missing definitions for `UK_C_BRIGHT_GREEN`, `UK_C_BRIGHT_RED`, and `UK_C_BRIGHT_YELLOW` in both its color and no-color branches — they were only ever patched ad-hoc by `main.sh`. The interactive `_apply_changes` directory picker references `UK_C_BRIGHT_GREEN`, so it crashed with "unbound variable" whenever it ran through any entry point other than `main.sh`. The three colors are now defined in `uk_setup_visuals`, the redundant `main.sh` patch was removed, and the picker now initializes its own glyph/color/size dependencies (`ac_init_glyphs` + sane `AC_COLS`/`AC_ROWS`/`inner` defaults) and normalizes all read-buffer variables (`key`, `seq`, `tok`) so it is unbound-safe even when invoked standalone.

## [5.1.0] - 2026-07-11

### Added
- **`_apply_changes` interactive directory browser.** New `--interactive`/`-i` flag (and the replaced `Apply Changes` dashboard wizard) launches a hierarchical, arrow-key-driven browser that scans `$HOME` so you can pick the SOURCE and TARGET folders without typing paths. Features: live resize-aware viewport, scroll indicators, fuzzy `/` filter, hidden-directory toggle (`h`), symlink-loop guard, plain-ASCII fallback under `NO_UNICODE`, and a graceful non-TTY abort. After selection it runs the existing dry-run → backup → apply → verify pipeline.

## [5.0.0] - 2026-07-11

### Changed (Versioning & Layout)
- **Unified single project version.** All tools now share one version, `UK_VERSION`, defined once in `lib/uk_common.sh`. Independent per-tool version variables (`VERSION`, `DA_VERSION`, `SM_VERSION`, `MIB_SCRIPT_VERSION`, `SCRIPT_VERSION`) have been removed; each tool's header/version output now prints `UK_VERSION`.
- **Repository reorganized.** Every `_<tool>/` directory now lives under `modules/`. `main.sh` resolves tools via `modules/_<tool>/_<tool>.sh`, the installer preserves the `modules/` nesting, and tool scripts source the shared library via `../../lib/uk_common.sh`.
- Bumped version to `5.0.0` to mark the breaking layout change and the move to unified versioning.

### Added
- New `_yt_download` tool — interactive YouTube downloader wrapping `yt-dlp` with full format listing, audio extraction, subtitle support, thumbnail/metadata embedding, playlist handling, and a guided wizard. CLI subcommands: `list`, `info`, `audio`, `download`.

### Fixed (Stabilization)
- Removed a duplicated `_ssh_assistant` implementation that caused help output and runtime paths to execute twice.
- Fixed broken/invalid JSON output paths in `_http_bench`, `_regex_lab`, `_image_tool`, `_time_convert`, `_secret_scan`, `_pdf_toolkit`, and `_yaml_toolkit`.
- Hardened `_api_tester` with nonzero curl failures, expected-status checks, redacted sensitive headers, and JSON profile storage instead of sourced shell profiles.
- Fixed `_yaml_toolkit merge`, `_time_convert diff/parse`, `_secret_scan` filename parsing for paths containing colons, and `_env_manager --compare` missing-file handling.
- Added validation/safety checks for `_uuid_gen`, `_todo_manager`, `_ssh_tunnel`, `_shredder`, and `setup.sh`.
- Added `tests/stabilization_regression_test.sh` covering the regression cases above and made `tests/deep_review_test.sh` usable without ripgrep.

### Added (CI/CD)
- New `.github/workflows/ci.yml` runs on every push and pull request against
  `master`/`main`. Ten jobs: `shellcheck -S error` lint, `bash -n` syntax
  matrix (Ubuntu + macOS), smoke suite matrix (Ubuntu + macOS),
  `deep_review_test.sh`, router `--help` coverage across all registered
  commands, standalone `--help` sweep of every `_<tool>/_<tool>.sh`,
  `NO_COLOR=1 NO_UNICODE=1` smoke pass, installer smoke via
  `setup.sh --no-menu`, `gitleaks` secret scan, and a summary gate that
  fails if any upstream job did not succeed.
- `.github/dependabot.yml` keeps GitHub Actions versions current
  (weekly, `chore(ci)` commit prefix).
- `.github/PULL_REQUEST_TEMPLATE.md` bakes in the touchpoints + verification
  checklist so contributors self-audit before requesting review.
- `.github/ISSUE_TEMPLATE/bug_report.yml` and `feature_request.yml` give
  bug reports and feature proposals a consistent structured form.

### Fixed
- `main.sh`: relocate two misplaced `# shellcheck disable=SC2206` directives
  above their `local arr=($paths)` statements so the new lint job passes
  (SC1126: directives must precede the command).

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
  and `_clipboard_manager`, plus stale/unrouted command references, from
  `main.sh`, the tests, `README.md`, `docs/ROADMAP_STATUS.md`, and
  `docs/index.html`. `_regex_lab` is present and routed as `regex`.

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
