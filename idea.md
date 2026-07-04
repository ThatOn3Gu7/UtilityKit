# UtilityKit — New Tool Ideas

Candidate tools that fill gaps in the current 48-tool suite. Each entry follows the repo convention: `_<tool>/_<tool>.sh` with a namespaced prefix, `<prefix>_main`, and a `run_<tool>_wizard` in `main.sh`. All ideas assume pure Bash orchestrating widely-available CLIs, respect `NO_COLOR` / `NO_UNICODE`, and degrade gracefully on Termux.

Legend: **prefix** — function namespace • **deps** — external binaries with fallbacks • **why** — gap it fills.

---

## Tier 1 — High-value, low-friction (build first)

### 1. `_clipboard_history` (prefix `ch_`)
Persistent clipboard history with fuzzy search and pin support.
- **deps**: `wl-paste` / `xclip` / `pbpaste` / `termux-clipboard-get` (already wrapped in `uk_common.sh`).
- **why**: `uk_common.sh` only *writes* to the clipboard; no history layer exists.
- **routes**: `clip add`, `clip list`, `clip get <n>`, `clip pin <n>`, `clip clear`.
- **storage**: `${XDG_DATA_HOME}/utility/clipboard.jsonl`, capped at N entries.

### 2. `_qr_tool` (prefix `qr_`)
Encode text / URL / Wi-Fi / vCard to QR PNG or terminal ASCII; decode from image.
- **deps**: `qrencode`, `zbarimg` (fallback to python `qrcode` module).
- **why**: mobile-first repo (Termux) with no QR helper — huge usability win on Android.
- **wizard**: templated presets (Wi-Fi SSID/PSK, contact card, plain URL).

### 3. `_regex_lab` (prefix `rl_`)
Live regex tester: pattern + sample text, prints matches, named captures, substitution preview.
- **deps**: `perl` or `grep -P` fallback to `awk`; `python3` for full PCRE features.
- **why**: no interactive regex helper; often needed alongside `_log_inspector`.
- **flags**: `--sub 's/foo/bar/g'`, `--file`, `--multiline`, `--case-insensitive`.

### 4. `_uuid_gen` (prefix `ug_`)
Generate UUID v4, v7 (time-ordered), ULID, nanoid, short IDs. Bulk mode with count and format.
- **deps**: `uuidgen`, `/dev/urandom` fallback, `python3 -c` for v7/ULID.
- **why**: password gen exists but no ID gen; complements `_project_scaffold`.

### 5. `_time_convert` (prefix `tc_`)
Epoch ↔ ISO 8601 ↔ RFC 3339 ↔ human. Cron expression → next N fire times. Timezone diff table.
- **deps**: `date` (GNU + BSD both handled), optional `python3` for cron parsing.
- **why**: `_cron_manager` schedules jobs but never explains "when will this fire?".

### 6. `_ip_info` (prefix `ii_`)
Local + public IP, reverse DNS, ASN, GeoIP, WHOIS summary, IPv6 status.
- **deps**: `curl` (ifconfig.co, ipinfo.io), `whois`, `dig`.
- **why**: `_network_probe` is LAN-focused; no WAN-side introspection tool.

### 7. `_dns_probe` (prefix `dp_`)
Query A / AAAA / MX / TXT / CAA / NS / SOA against multiple resolvers in parallel. Propagation checker (compare authoritative vs public resolvers).
- **deps**: `dig` (bind-utils), `drill` fallback.
- **why**: DNS debugging is currently manual; complements `_ssl_checker`.

### 8. `_secret_scan` (prefix `ss_`)
Scan working tree for leaked credentials (AWS keys, GitHub tokens, private keys, `.env` values). Regex + entropy heuristics. Respects `.gitignore`.
- **deps**: `grep -P`, `git ls-files`, optional `gitleaks` if installed.
- **why**: `_dotenv_vault` protects secrets but nothing audits their leakage.
- **exit codes**: non-zero on findings — CI-friendly.

---

## Tier 2 — Useful, medium scope

### 9. `_http_bench` (prefix `hb_`)
Lightweight HTTP benchmark: N requests, C concurrency; reports p50/p95/p99, RPS, error rate.
- **deps**: `curl` + Bash coprocs, `hey` / `wrk` if installed.
- **why**: `_api_tester` verifies correctness, not performance.

### 10. `_bench_cmd` (prefix `bc_`)
`hyperfine`-lite: run a command N times, report mean/median/stddev, warmup runs, comparison mode between two commands.
- **deps**: `date +%s%N`, `python3` for stats (fallback: awk).
- **why**: no shell-level micro-benchmark helper.

### 11. `_pdf_toolkit` (prefix `pt_`)
Merge, split by page range, extract text, extract images, compress, rotate, page count.
- **deps**: `qpdf`, `pdftotext`, `pdfimages` (poppler-utils), `gs` for compress.
- **why**: `_media_convert` covers audio/video only; PDFs are a common gap.

### 12. `_image_tool` (prefix `it_`)
Resize, convert format, strip EXIF, batch-optimize (PNG/JPEG/WebP), thumbnail grid, color histogram.
- **deps**: `magick` / `convert`, `cwebp`, `exiftool`, `optipng` / `jpegoptim`.
- **why**: overlap with `_media_convert` is intentional — images deserve dedicated flows (batch rename, EXIF privacy).

### 13. `_yaml_toolkit` (prefix `yt_`)
Lint, validate against schema, YAML ↔ JSON convert, key extract, merge, anchor expansion.
- **deps**: `yq` (Go version), `python3 -m yaml` fallback.
- **why**: `_json_explorer` exists; YAML has no equivalent despite heavy Kubernetes/CI usage.

### 14. `_file_watcher` (prefix `fw_`)
Run a command whenever files matching a glob change. Debounce, ignore rules, initial-run flag.
- **deps**: `inotifywait` (Linux), `fswatch` (macOS/Termux), polling fallback.
- **why**: dev-loop utility missing from the suite; pairs with `_project_scaffold`.

### 15. `_ssh_tunnel` (prefix `st_`)
Manage persistent SSH port-forwards: create, list, kill, restart on failure. Config file `~/.config/utility/tunnels.conf`.
- **deps**: `ssh`, `autossh` if available.
- **why**: `_ssh_assistant` handles keys; nothing manages long-running tunnels.

### 16. `_git_hooks` (prefix `gh_`)
Install, remove, list `.git/hooks/*`. Bundled templates: pre-commit lint, commit-msg format check, pre-push tests.
- **deps**: pure Bash.
- **why**: `_git_stats` / `_git_sweep` / `_github_helper` exist; hook management doesn't.

### 17. `_git_worktree_mgr` (prefix `gw_`)
Interactive list / add / remove / prune worktrees. Auto-name branches, jump-to-worktree shortcut.
- **deps**: `git ≥ 2.5`.
- **why**: worktrees are underused; TUI wrapper removes the friction.

### 18. `_notes_quick` (prefix `nq_`)
Append-only markdown daybook with tags. `note "text #idea #urgent"`, `note --today`, `note --tag idea`, `note --grep foo`.
- **deps**: pure Bash + `grep`.
- **why**: `_todo_manager` handles tasks; freeform notes have no home.

---

## Tier 3 — Nice-to-have / niche

### 19. `_ascii_art` (prefix `aa_`)
Text → ASCII banner (multiple fonts), image → ASCII preview.
- **deps**: `figlet` / `toilet`, `jp2a` / `chafa`.
- **why**: matches the repo's visual character (banner in `main.sh`).

### 20. `_lorem_data` (prefix `ld_`)
Generate fake data: names, emails, addresses, lorem paragraphs, JSON records, CSV rows.
- **deps**: pure Bash word lists shipped under `_lorem_data/data/`.
- **why**: pairs with `_api_tester` and `_csv_toolkit` for fixture generation.

### 21. `_kv_store` (prefix `kv_`)
Shell-scriptable key-value cache with TTL. `kv set foo bar --ttl 3600`, `kv get foo`, `kv keys`, `kv gc`.
- **deps**: pure Bash + file locks (`flock` or noclobber).
- **why**: other tools can adopt it (rate limiting, memoization, cross-run state).

### 22. `_desktop_notify` (prefix `dn_`)
Unified notifier: `notify-send` / `terminal-notifier` / `termux-notification`. Scheduling ("remind me in 25m"), progress bars, sound.
- **deps**: whichever is present; already partially wrapped in `uk_common.sh` — promote to a full tool with scheduling.
- **why**: `_pomodoro` needs a richer notify layer; other tools would too.

### 23. `_screenshot_tool` (prefix `sc_`)
Capture screen / window / region, annotate (crop, blur redaction), upload to configurable host.
- **deps**: `grim` + `slurp` (Wayland), `scrot` / `maim` (X11), `screencapture` (macOS), `termux-camera-photo` fallback on Android.
- **why**: developer-facing capture with EXIF strip + auto-blur for secrets.

### 24. `_git_bisect_wiz` (prefix `gbw_`)
Guided `git bisect` wizard — prompts for good/bad, offers test-runner integration for `bisect run`, records the answer log.
- **deps**: `git`.
- **why**: bisect is powerful but underused because the ergonomics are rough.

### 25. `_makefile_lint` (prefix `ml_`)
Lint Makefiles: tab-vs-space, undeclared `.PHONY`, recursive-make anti-patterns, missing dependencies.
- **deps**: pure Bash + `awk`; optional `checkmake`.
- **why**: no build-system linters in the suite.

---

## Cross-cutting improvements (not new tools, but adjacent)

- **Tool discovery API** — expose `uk_list_tools` that emits JSON so external UIs can consume the catalog.
- **Plugin surface for `_api_tester`** — mirror the `_cache_clean` plugin pattern for auth schemes (bearer, HMAC, OAuth2 device flow).
- **Shared TUI list widget** — many wizards reimplement arrow-key menus; extract to `lib/uk_menu.sh`.
- **`--json` output flag standard** — every tool should emit machine-readable results behind a single flag, unblocking scripting and CI.
- **Manpage generator** — a `docs` route that renders `_<tool>_README.md` → `man/utility-<tool>.1`.

---

## Prioritization matrix

| Rank | Tool | Impact | Effort | Termux-friendly |
|-----:|:-----|:------:|:------:|:---------------:|
| 1 | `_qr_tool` | High | Low | Yes |
| 2 | `_clipboard_history` | High | Low | Yes |
| 3 | `_secret_scan` | High | Med | Yes |
| 4 | `_dns_probe` | High | Low | Yes |
| 5 | `_ip_info` | Med | Low | Yes |
| 6 | `_regex_lab` | Med | Low | Yes |
| 7 | `_time_convert` | Med | Low | Yes |
| 8 | `_uuid_gen` | Med | Low | Yes |
| 9 | `_http_bench` | Med | Med | Yes |
| 10 | `_yaml_toolkit` | Med | Med | Yes (needs `yq`) |
| 11 | `_pdf_toolkit` | Med | Med | Partial (Termux `qpdf` ok) |
| 12 | `_image_tool` | Med | Med | Yes |
| 13 | `_file_watcher` | Med | Med | Yes (`termux-fswatch`) |
| 14 | `_ssh_tunnel` | Med | Med | Yes |
| 15 | `_git_hooks` | Med | Low | Yes |
| 16 | `_git_worktree_mgr` | Low | Low | Yes |
| 17 | `_notes_quick` | Low | Low | Yes |
| 18 | `_bench_cmd` | Low | Med | Yes |
| 19 | `_ascii_art` | Low | Low | Yes |
| 20 | `_lorem_data` | Low | Low | Yes |
| 21 | `_kv_store` | Low | Low | Yes |
| 22 | `_desktop_notify` | Low | Low | Yes |
| 23 | `_screenshot_tool` | Low | Med | Partial |
| 24 | `_git_bisect_wiz` | Low | Med | Yes |
| 25 | `_makefile_lint` | Low | Low | Yes |

---

## Implementation checklist per tool (mirror of `CLAUDE.md`)

1. `_<tool>/_<tool>.sh` — namespaced prefix, `<prefix>_main`, BASH_SOURCE guard, traps inside `_main`.
2. `_<tool>/_<tool>_README.md` — standalone usage docs.
3. `main.sh` — `UK_TOOL_PATHS` entry, `case` branch, `run_<tool>_wizard`, parallel-array entry in `load_all_tools()` (icon, color, name, desc, action).
4. `tests/smoke_test.sh` — add CLI verb to the `cmds=(...)` array; add behavioral case if the tool has side effects.
5. `setup.sh` — no edit needed (glob-based installer).
6. `NO_COLOR=1` / `NO_UNICODE=1` — verified working.
7. Termux path — degrades gracefully or hides itself when dependencies unavailable.
