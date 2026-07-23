# AGENTS.md — UtilityKit

A fan-out of independent Bash tools unified by one router (`main.sh`). **CLAUDE.md is the authoritative guide** — read it first. This file captures only the high-signal gotchas that bite agents.

## Commands

```sh
bash main.sh                              # interactive dashboard
bash main.sh <cmd> [args]                 # direct CLI (e.g. bash main.sh port 3000)
bash tests/smoke_test.sh                  # must end PASS=N FAIL=0
bash tests/deep_review_test.sh            # deeper behavioral pass
shellcheck -S error -e SC1091 modules/_<tool>/_<tool>.sh   # matches CI exactly
bash -n modules/_<tool>/_<tool>.sh        # syntax (CI runs this on every *.sh)
```

CI runs: `shellcheck -S error` on **every** `*.sh`, `bash -n`, smoke + deep-review suites, on Linux **and** macOS. A red job blocks merge.

## Architecture facts (easy to get wrong)

- `UK_REGISTRY` (top of `main.sh`) is the **single source of truth**. `UK_TOOL_PATHS`, the menu, and dispatch are all derived from it — never edit them in parallel or they drift.
- `main.sh` **sources** tools; it does not exec them. The `BASH_SOURCE[0] == $0` guard is load-bearing, and `trap`s must be registered inside `<prefix>_main`, never at top level (sourced traps clobber the parent shell's handlers).
- Every script runs under `set -euo pipefail`. Referencing an **unset** variable is fatal. Always give params a default: `${1:-}`, declare `local` vars before `read`, and ensure every `UK_C_*` color exists in **both** the color and the `NO_COLOR`/`NO_UNICODE` branches of `uk_common.sh`.

## Adding a tool — touchpoints

1. `modules/_<tool>/_<tool>.sh` (namespaced `<prefix>_` functions + BASH_SOURCE guard) and `_<tool>_README.md`.
2. `main.sh`: one `UK_REGISTRY` line; a `case` dispatch branch; `run_<tool>_wizard()`; entries in the `M_ICONS/M_COLORS/M_NAMES/M_DESCS/M_ACTIONS` arrays.
3. `tests/smoke_test.sh`: add `<cmd> --help` to `cmds=(...)` and a behavioral case if it has side effects.
4. `docs-site/src/data/tools.ts`: mirror the tool, then `cd docs-site && npm run deploy:docs`.
5. `setup.sh` already globs `modules/_*/`, so no manual edit is usually needed — verify it picked up the new dir.

## Gotchas learned the hard way

- **`awk` default-value syntax:** inside single-quoted awk programs use `$1`, not `${1:-}`. The bash form leaks literally into awk and throws syntax errors. (Found across ~9 tools.)
- **Route collisions:** `UK_REGISTRY` keys are matched in order; an earlier alias (e.g. `watch` → `service_watcher`) shadows a later one. When a CLI command silently hits the wrong tool, check for a duplicate/alias key. (`file_watcher` had to become `fwatch`.)
- **`bash` (not `sh`)** is required — macOS system `bash` is too old; CI `brew install bash` on macOS.
- Docs site (`docs-site/`) is React+Vite, bundled to a single `docs/index.html` via `vite-plugin-singlefile`. Rebuild with `npm run deploy:docs`, not by hand-editing `docs/index.html`.

## Workflow

- Commit prefixes are scoped to the tool: `feat(tool):`, `fix(tool):`, `refactor(tool):`, `docs:`.
- Run `bash main.sh doctor` (full, not `--quick`) before a release to validate `--help` on all tools.
- Do **not** run `git commit`/`git push` unless the user explicitly asks.
