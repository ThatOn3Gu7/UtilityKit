# UtilityKit — Session Handoff

## 1) Goals

- Implement 10 new tools from `idea.md` following existing repo conventions (BASH_SOURCE guard, `<prefix>_main`, `<prefix>_wizard`, uk_common.sh, `--help`/`--json`/`--no-color`, fallback functions, standalone + integrated usage)
- Wire all tools into `main.sh` (UK_REGISTRY, case dispatch, help text, dashboard menu)
- Add smoke tests for all new tools in `tests/smoke_test.sh`
- Fix pre-existing test failures (stale `_log_rotator`/`_zen_mode` references, `logs` missing route)
- Fix `awk` syntax errors caused by `${N:-}` inside single-quoted scripts across the codebase
- Ensure clean doctor and smoke test output: `0 problems`, `PASS=7 FAIL=0`

## 2) Current status

- **63 tools in registry**, all passing `doctor --quick` with 0 problems, 0 warnings
- **Smoke test: PASS=7 FAIL=0** — all 7 test groups (syntax, help routing, core, roadmap, new utilities, wave-1, wave-2) pass
- **8 commits landed** on `testBranch`, authored as `Thaton3gu7 <socialzoneop@gmail.com>`
- **Working directory clean** — no unstaged files. `.env.production`, `config.js`, `.claude/` excluded via `.gitignore`

## 3) Active files

| File | Role |
|---|---|
| `main.sh` | Central router — UK_REGISTRY (63 entries), `run_tool()` case dispatch, `uk_main_show_help()`, `uk_doctor()`, `load_all_tools()` menu |
| `tests/smoke_test.sh` | Smoke test suite — `help_check`, `core_smoke`, `wave1_tools_smoke`, `wave2_tools_smoke` |
| `lib/uk_common.sh` | Shared helpers — colors, icons, prompts, progress bars, platform detection |
| `.gitignore` | Excludes `.env*`, `config.js`, `.claude/`, `*.bak`, `*.tmp`, `*.swp` |
| `idea.md` | Tool roadmap with priority matrix for remaining candidates |

## 4) Changes made

### New tools (15 total)

**Wave 1 (5 — existed as unstaged stubs):**
- `_qr_tool/` — encode text/URL/Wi-Fi/vCard, decode images (prefix `qr_`)
- `_clipboard_history/` — persistent clipboard log with pins & search (prefix `ch_`)
- `_secret_scan/` — regex + entropy credential scanner (prefix `sec_`)
- `_dns_probe/` — multi-resolver DNS queries, propagation checks (prefix `dp_`)
- `_ip_info/` — public/local IP, ASN, GeoIP, WHOIS (prefix `ii_`)

**Wave 2 (10 — fully implemented this session):**
- `_regex_lab/` — live regex tester, match/substitution preview (prefix `rl_`, route `regex`)
- `_uuid_gen/` — UUID v4/v7, ULID, NanoID, short IDs, bulk gen (prefix `ug_`, route `uuid`)
- `_time_convert/` — epoch ↔ ISO 8601 ↔ RFC 3339 ↔ human, cron analyzer (prefix `tc_`, route `time`)
- `_http_bench/` — HTTP benchmark, p50/p95/p99/RPS (prefix `hb_`, route `bench`)
- `_yaml_toolkit/` — lint, convert, query, merge YAML (prefix `yt_`, route `yaml`)
- `_pdf_toolkit/` — page count, merge, split, text extract, compress (prefix `pt_`, route `pdf`)
- `_image_tool/` — resize, convert, strip EXIF, optimize (prefix `it_`, route `image`)
- `_file_watcher/` — run command on file change via inotify/fswatch/poll (prefix `fw_`, route `fwatch`)
- `_ssh_tunnel/` — create/list/kill/restart SSH port-forwards with config persistence (prefix `st_`, route `tunnel`)
- `_git_hooks/` — install/remove/list/show git hook templates (prefix `gh_`, route `hooks`)

### Fixes

- **awk `${N:-}` → `$N`** — replaced all 22 occurrences of `${1:-}`, `${2:-}`, `${4:-}` inside single-quoted awk scripts across 9 tools (_apply_changes, _archive_manager, _cache_clean, _disk_health, _duplicate_finder, _git_stats, _process_killer, _ssl_checker, _todo_manager). These were bash default-value operators being passed literally to awk, causing syntax errors on stderr. All smoke-test visible errors eliminated.
- **Removed stale smoke test refs** — `_log_rotator` and `_zen_mode` were deleted from the codebase but still referenced in `tests/smoke_test.sh`. Removed both references.
- **Added `logs` route** — Added `logs` alias for `log-inspect` in `main.sh` dispatch. Removed `logs` and `zen` from `help_check` cmds array (only `logs` has a route now via the alias).
- **Fixed `watch`/`fwatch` route conflict** — `watch` was already claimed by `service_watcher` as an alias. Changed `file_watcher`'s route from `watch` to `fwatch` to avoid dispatch collision.
- **Added `--json` to `_git_hooks`** — `list --json` now emits machine-readable hook status.
- **Route deduplication** — The `UK_TOOL_PATHS` map is now derived from `UK_REGISTRY` automatically (line 100), so they can never fall out of sync.

## 5) Failed attempts

- **Initial `main.sh` edits failed** due to whitespace mismatches with `edit` tool. Resolved by reading the exact file content with `read` and matching precisely, plus using `grep` to confirm content before retrying.
- **`watch` route silently dispatched to wrong tool** — The `watch | service | service-watcher` alias at line 889 matched before `file_watcher`'s `watch` entry. Had to rename file_watcher action to `fwatch` in both UK_REGISTRY and case dispatch.

## 6) Next steps

### Immediate
- Push `testBranch` to remote once ready
- Consider squashing the 8 commit chain into fewer commits before push if preferred

### Tool candidates from `idea.md` (not yet implemented)
| Tool | Priority | Notes |
|---|---|---|
| `_git_worktree_mgr` (prefix `gw_`) | High | Interactive worktree management, requires git ≥ 2.5 |
| `_notes_quick` (prefix `nq_`) | Medium | Append-only markdown daybook with tags |
| `_color_picker` (prefix `cp_`) | Medium | Extract color palette from images, show ANSI 256 chart |
| `_network_scanner` (prefix `ns_`) | Medium | ARP scan, port scan, mDNS browse |
| `_ci_runner` (prefix `cir_`) | Low | Run `.ci/` scripts locally, validate CI configs |
| `_browser_session` (prefix `br_`) | Low | Save/restore browser tabs via browser API |
| `_git_bisect_helper` (prefix `gbh_`) | Low | Automate `git bisect` with build/test script |
| `_procfilter` (prefix `pf_`) | Med | `ps` wrapper — filter, sort, tree, watch, signal |
| `_crypt_file` (prefix `cf_`) | Med | Encrypt/decrypt with gpg/age/openssl, shred originals |
| `_sysd_service` (prefix `sysd_`) | Low | List, enable, disable, restart, log sysd units |
| `_keycast` (prefix `kc_`) | Med | Record keystrokes to script/snippet (Termux: `termux-keyboard`) |
| `_audio_rec` (prefix `ar_`) | Low | Record mic, convert, transcribe (Termux: `termux-media-recorder`) |

### Maintenance
- Run `bash main.sh doctor` (full, not `--quick`) before any release to validate `--help` on all tools
- Ensure any new tool follows the touchpoint checklist in `CLAUDE.md`
