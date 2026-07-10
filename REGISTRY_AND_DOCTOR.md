# Unified registry, `uk doctor`, and phantom-tool cleanup

This document covers the maintenance/refactor pass done on `UtilityKit_edited`.

## 1. Unified tool registry (single source of truth)

Previously the same tool metadata was hand-maintained in **four** places that had
to be kept in sync manually (and had already drifted):

- the `UK_TOOL_PATHS` lazy-loader map,
- the five parallel dashboard arrays (`M_ICONS`, `M_COLORS`, `M_NAMES`,
  `M_DESCS`, `M_ACTIONS`),
- the `run_tool` dispatch cases,
- the help text.

Now there is one authoritative list, `UK_REGISTRY`, near the top of `main.sh`.
Each line fully describes a tool:

```
key | action | icon | color | Display Name | description | menu
```

From it we **derive**:

- `UK_TOOL_PATHS` — built by `uk_registry_build_paths` (paths are always
  `_<key>/_<key>.sh`, so they can't be mistyped or fall out of sync).
- The dashboard menu — `load_all_tools` now loops over `UK_REGISTRY`, resolves
  the color variable name indirectly, and appends the `Setup / Install` launcher
  entry last. The Termux "hide Docker" behavior is preserved.

The `run_tool` dispatch cases stay hand-written because each tool has bespoke
wizard/argument logic — but `uk doctor` now verifies every registry action has a
matching dispatch case, so a missing wiring is caught immediately.

Adding a new tool is now: drop the `_<tool>/` directory in, add **one** line to
`UK_REGISTRY`, add its `run_tool` case, and run `./main.sh doctor`.

## 2. `uk doctor` — integrity checker

New command: `./main.sh doctor` (alias `diagnostics`). It validates:

1. every registry tool has its script on disk,
2. every registry action has a `run_tool` dispatch case,
3. the five derived menu arrays are all the same length,
4. every tool answers `--help` (skip with `--quick`),
5. orphan directories on disk that aren't in the registry.

It prints a clean per-tool report and exits nonzero if any hard problem is
found, so it's usable in CI. This is exactly the check that would have caught the
old phantom-tool bugs automatically.

```bash
./main.sh doctor          # full check
./main.sh doctor --quick  # skip per-tool --help
```

## 3. Phantom-tool cleanup

The removed tools `_log_rotator`, `_zen_mode`, `_clipboard_manager`, and
`_regex_lab` (and the never-routed `logs` command) had references scattered
across the project. All were removed from:

- `main.sh` — loader map (now registry), dispatch cases (`regex`, `zen`), help.
- `tests/smoke_test.sh` — the help/routing command list and the individual
  log-rotator / zen-mode / regex-lab smoke invocations.
- `README.md` — tool table rows, smoke-suite description, tool counts.
- `docs/ROADMAP_STATUS.md` — "Implemented" rows (with a note that they were
  removed).
- `docs/index.html` — the tool catalog cards and the static tool counts.

Legitimate clipboard *helpers* (`uk_copy_to_clipboard` in `lib/uk_common.sh`,
and `_password_gen`'s clipboard copy) were kept — those are real, working
features, not the removed tool.

## 4. Verification

- `bash -n` passes on every `.sh` file.
- `tests/smoke_test.sh` → **PASS=7 FAIL=0** (was PASS=7 FAIL=0 before), including
  two new checks: an Update Managers smoke test and a doctor/registry check.
- `./main.sh doctor` → **63 tools checked, 0 problems, 0 warnings, no orphans**.
- Removed commands (`zen`, `regex`, `clipboard`, `logs`) now correctly report
  "unknown command"; `update` and `doctor` route correctly.
- The dashboard menu renders 64 entries (63 tools + Setup) with colors resolved.
