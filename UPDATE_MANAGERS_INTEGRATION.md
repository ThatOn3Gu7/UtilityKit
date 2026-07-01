# Update Managers — integration notes, repo review & next-step ideas

> UPDATE: The repo-review findings below (phantom tools, drift, no `doctor`) have
> since been **resolved**. See `REGISTRY_AND_DOCTOR.md` for the unified registry,
> the new `doctor` command, and the phantom-tool cleanup. The sections below are
> kept as the original analysis that motivated that work.

## 1. What was integrated

The polished `_update_managers.sh` (v2.4.0 — smart failure "grep-ping", live
per-sub-command spinner, single-line spinner fix, and all earlier bug fixes) was
added as a first-class UtilityKit tool.

New files:
- `_update_managers/_update_managers.sh`
- `_update_managers/_update_managers_README.md`

`main.sh` changes (5 standard wiring points, matching every other tool):
1. **`UK_TOOL_PATHS`** — added `[update_managers]=.../_update_managers.sh`.
2. **`run_tool` dispatch** — added `update | update-managers | upgrade)` which
   `uk_load update_managers` then calls `um_main "$@"` (args pass straight
   through; no args launches the tool's own interactive menu).
3. **`uk_main_show_help`** — added `update` to the command list.
4. **`load_all_tools`** — appended one aligned entry to all five parallel arrays
   (`M_ICONS`, `M_COLORS`, `M_NAMES`, `M_DESCS`, `M_ACTIONS`) so it shows in the
   arrow-key menu as **Update Managers** (action `update`).

### The one non-obvious adaptation
Other UtilityKit tools never change shell options at *source* time — they only
`set -euo pipefail` inside their bottom `BASH_SOURCE` guard. The original
`_update_managers.sh` ran `set -uo pipefail` + reset `IFS` at the top level,
which would have silently changed `main.sh`'s shell state when sourced.

Fix applied:
- Moved `set -uo pipefail` + `IFS` into the standalone entry guard.
- `um_main()` now does `local -; set +e -u -o pipefail` so it gets unset-var
  safety and pipefail **without** `errexit` — because the tool is designed so one
  failing manager never aborts the batch. `local -` scopes that back to the
  function on return (Bash 4.4+), leaving the caller untouched.

### Verified
- `bash -n` passes for the tool and every `.sh` in the repo.
- Sourcing the tool under `set -e` leaves the caller's `errexit` **ON**
  (isolation confirmed).
- `main.sh update --help`, `--list`, and `--yes --dry-run` all work.
- Under a `set -euo pipefail` caller with a **failing** manager, the batch still
  continues to the next manager and prints a correct `N succeeded / M failed`
  summary — then returns nonzero, which `uk_menu_execute` reports as a warning.
- Menu arrays stay aligned at 50 entries; "Update Managers" renders at the
  expected position.

---

## 2. Quick review of the rest of the repo

Overall this is a well-structured, genuinely nice codebase: a clean lazy-loading
hub, a shared `lib/uk_common.sh`, consistent `xx_main` entry points, per-tool
READMEs, and a smoke/deep test harness. A few concrete things worth tidying:

### A. Phantom tools (mapped/tested but not committed) — highest priority
`main.sh` and/or the tests/help reference tools whose directories don't exist:

| Referenced as | Where | Status |
|---|---|---|
| `_clipboard_manager` | `UK_TOOL_PATHS`, help, smoke test | directory missing |
| `_regex_lab` | `UK_TOOL_PATHS`, `run_tool` case | directory missing |
| `_zen_mode` | `UK_TOOL_PATHS`, `run_tool` case | directory missing |
| `_log_rotator` | roadmap + deep test | directory missing |
| `logs` command | help text + smoke test list | no `run_tool` case at all |

This is why `tests/smoke_test.sh` currently reports `FAIL=2` **before** my change
— the failures are pre-existing, not from the Update Managers work. Recommended:
either commit the missing tools or remove their references from `main.sh`, the
help text, `docs/ROADMAP_STATUS.md`, and the tests so the suite goes green.

### B. `docs/ROADMAP_STATUS.md` overstates status
It marks `_log_rotator`, `_zen_mode`, `_clipboard_manager` as "Implemented"
though they aren't in the tree. Worth reconciling with reality.

### C. Standalone robustness is inconsistent
Only ~2 of 48 tools define `uk_*` fallback shims for when `lib/uk_common.sh`
isn't found. Most `source` it unconditionally, so running a tool script directly
from an odd CWD (or copied out of the repo) can break. Consider a tiny shared
"bootstrap" snippet, or make each tool degrade gracefully like `_weather` does.

### D. Minor consistency nits
- `run_tool`'s help list mentions `logs` and `clipboard` that don't route.
- Some tools shell out to `awk`/`python` with scripts that error on certain
  awk builds (the `awk: syntax error at or near {` noise in the smoke run comes
  from a couple of tools, not from Update Managers).

None of these are blockers — the core hub and the majority of tools work well.

---

## 3. Ideas for what to build next

### Big swing
1. **`uk doctor` / self-diagnostics + registry integrity.** A built-in command
   that verifies every mapped tool exists, every `run_tool` case has a matching
   map entry and menu row, all parallel menu arrays are the same length, and each
   tool responds to `--help`. This would have caught the phantom-tool issues
   automatically and keeps the hub honest as it grows. Natural companion: a
   generated tool registry so the 5 wiring points become 1.

2. **Scheduling / automation layer.** Let any tool be registered to run on a
   schedule (e.g. `update --yes` weekly, `backup` nightly) via the existing
   `cron_manager`, with a unified run-log and last-status dashboard. Turns the
   kit from "manual tools" into a lightweight personal ops cockpit.

3. **Unified config + profiles.** A single `~/.config/uk/config` where users set
   defaults per tool (e.g. update `--skip snap`, preferred editor, color/unicode
   mode) and named profiles ("work", "server", "termux"). Tools read it via
   `uk_common`.

### Smaller, high-value
4. **`uk update --parallel`.** Run independent managers concurrently with a
   multi-line live status board (you already have the per-manager spinner and
   log plumbing — this is a natural extension).
5. **JSON/quiet output mode across tools** (`--json` / `UK_OUTPUT=json`) so the
   kit is scriptable and CI-friendly.
6. **Shell completions** (bash/zsh/fish) generated from the tool registry.
7. **`uk search`/fuzzy launcher** in the menu — type to filter the 50-tool list.
8. **First-run onboarding** in `setup.sh` that detects the platform and suggests
   which tools are usable.

My personal recommendation: do **#1 (`uk doctor` + a single-source tool
registry)** first. It's a satisfying "big" project, it immediately pays for
itself by eliminating the phantom-tool class of bugs, and it makes every future
tool cheaper to add (one registration instead of five).
