# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common commands

```sh
bash main.sh                       # interactive dashboard
bash main.sh <cmd> [args]          # direct CLI (e.g. `bash main.sh port 3000`)
bash main.sh help                  # list all routes

bash setup.sh --no-menu            # non-interactive install to ~/.local/share/utility
bash tests/smoke_test.sh           # full smoke suite (5 groups, must end PASS=N FAIL=0)
bash tests/deep_review_test.sh     # deeper review pass

# Documentation site (webAPP/)
cd webAPP && npm install           # first time only
cd webAPP && npm run dev           # dev server on :5173 with HMR
cd webAPP && npm run typecheck     # tsc --noEmit
cd webAPP && npm run deploy:docs   # build + copy dist/index.html → docs/index.html
```

There is no separate lint target. Syntax is validated by the `syntax_check` test in `smoke_test.sh`, which runs `bash -n` over every `*.sh` in the tree.

To exercise a single tool in isolation:

```sh
bash modules/_<tool>/_<tool>.sh --help     # standalone (BASH_SOURCE guard fires)
```

## Architecture: one suite, 51 self-contained tools

The repo is a fan-out of independent Bash tools unified by a single router. Understanding three patterns is enough to be productive:

### 1. Tool layout and the BASH_SOURCE guard

Every tool lives in `modules/_<tool>/_<tool>.sh` next to a `_<tool>_README.md`. Each script:

- Defines a short namespaced prefix for *all* its functions (`pi_` for `_port_inspector`, `mc_` for `_media_convert`, `cs_` for `_cheat_sheet`, etc.). The prefix is the tool's API surface inside `main.sh`.
- Wraps its entry point in `<prefix>_main`.
- Guards top-level execution with `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then <prefix>_main "$@"; fi`.

This guard is load-bearing: `main.sh` *sources* tools rather than execing them, so without the guard every tool would run on startup. Likewise, **register `trap` handlers inside `<prefix>_main`, never at the top level** — top-level traps overwrite the parent shell's `EXIT`/`SIGINT` handlers when sourced.

### 2. The router: `main.sh` + lazy loader

`main.sh` holds the `UK_TOOL_PATHS` associative array mapping tool keys → script paths. `uk_load <key>` sources a tool the first time it is needed (idempotent via `UK_TOOL_LOADED`). Each route in the giant `case` in `main.sh` follows the same shape:

```bash
port | port-inspector)
  uk_load port_inspector
  ([[ $# -gt 0 ]] && pi_main "$@" || run_port_wizard)
  ;;
```

`<prefix>_main` is the scripting/CLI path; `run_<tool>_wizard` is the interactive dashboard path. Both must exist for a tool to be fully integrated.

### 3. Shared visuals/helpers: `lib/uk_common.sh`

All tools and `main.sh`/`setup.sh` source `lib/uk_common.sh` for colors, icons, prompts, progress bars, platform detection, and XDG dirs. It uses a load-once guard (`UK_COMMON_SH_LOADED`) so nested sourcing is free. **Do not re-implement colors or icons in a tool** — use `UK_C_*`, `UK_I_*`, `uk_success`, `uk_warn`, `uk_confirm`, `uk_prompt`, `uk_header`, `uk_bar`, etc.

`NO_COLOR=1` and `NO_UNICODE=1` are respected globally; new visual code must keep working when either is set (the smoke tests exercise this).

## Unbound-variable safety (`set -u` is always on)

Every script runs under `set -euo pipefail`, so referencing an **unset** variable is fatal ("unbound variable"). This is the single most common way new code breaks at runtime while passing `bash -n`. Rules:

- **Always give variables a value before use.** For function parameters use `${1:-default}`; for `read` into a var, declare it first (`local key=''`) and/or normalize after (`key="${key:-}"`). A `read` that times out leaves the variable *unset*, not empty.
- **Every color/glyph a tool prints must exist in all branches of `uk_setup_visuals`** (`lib/uk_common.sh`): the color branch AND the no-color/`NO_COLOR`/non-TTY branch must define the *same* full set of `UK_C_*` variables. If you add a new `UK_C_*` reference, add its definition to both branches (the no-color branch assigns empty strings). Do not paper over a missing color with a `:=` default in `main.sh` — fix it in the library so every entry point is safe.
- **UI/drawing helpers must be self-initializing.** A function that draws to the terminal should ensure its own dependencies (glyph set via `ac_init_glyphs`, colors via `uk_setup_visuals`, and any size vars like `inner`/`AC_COLS` with sane defaults) so it cannot crash when called directly instead of via the usual wizard entry point.
- **Verify before declaring done:** run the new path under `bash -u` (not just the normal `bash` the smoke suite uses, which does not propagate `-u` into sourced tool code the same way) and through a real TTY-less/`NO_COLOR` path, and grep the output for `unbound variable`. Also run `bash tests/smoke_test.sh` (its `syntax_check` runs `bash -n` over every `*.sh`).

## Adding a new tool — touchpoints checklist

Because the wiring is spread across several files, adding a tool means editing all of these:

1. `modules/_<tool>/_<tool>.sh` with namespaced functions + BASH_SOURCE guard.
2. `modules/_<tool>/_<tool>_README.md` for standalone users.
3. `main.sh`: add an entry to `UK_TOOL_PATHS`, a `case` branch routing the CLI command, a `run_<tool>_wizard()` for the dashboard, and an entry in the four parallel arrays `M_ICONS` / `M_COLORS` / `M_NAMES` / `M_DESCS` / `M_ACTIONS` in `load_all_tools()` so the tool appears in the arrow-key scroll menu.
4. `tests/smoke_test.sh`: append the CLI command to the `cmds=(...)` array inside `help_check` so `<cmd> --help` is exercised; add a behavioral smoke case if the tool has side effects.
5. `setup.sh` globs tool directories from `modules/_*/`, plus `lib`, `docs`, `tests` at the repo root.
6. `webAPP/src/data/tools.ts` mirrors the tool registry for the documentation site. Add the new tool here (`command`, `name`, `category`, `description`, `icon`, `options`, `examples`, `related`) so it appears on the docs UI, then rebuild with `cd webAPP && npm run deploy:docs`.

## Documentation site — `webAPP/`

React + Vite + Tailwind SPA. Bundles to a single self-contained
`dist/index.html` via `vite-plugin-singlefile`, which is then either published
to GitHub Pages by `.github/workflows/pages.yml` or copied into `docs/index.html`
(and committed) via `npm run deploy:docs`.

- Design tokens are semantic CSS vars in `webAPP/src/index.css` (`--bg`,
  `--text`, `--accent`, ...) with light/dark values under `.dark` on
  `<html>`. New colors go here, not inline in components.
- Theme selection (`system | light | dark`) lives in
  `webAPP/src/components/ThemeProvider.tsx`, persisted in `localStorage`
  under `uk-theme`. An inline script in `index.html` prevents flash of wrong
  theme.
- HashRouter is used so the site works from any subpath without server
  rewrites, which is what makes the single-file bundle portable to GitHub
  Pages, filesystem previews, or a custom domain unchanged.

## Platform notes

`uk_platform` returns `termux | macos | linux`. Tools that depend on a Linux-only daemon (e.g. `_docker_janitor`) should hide themselves from the Termux dashboard rather than fail loudly. Clipboard, notification, and battery helpers in `uk_common.sh` already cascade through wl-copy → xclip → pbcopy → termux-clipboard-set, so prefer those wrappers over rolling new fallback chains.

## `_cache_clean` plugin contract

`modules/_cache_clean/plugins/<manager>.sh` files implement five functions: `<id>_plugin_info`, `<id>_detect`, `<id>_get_cache_dirs`, `<id>_scan_cache`, `<id>_clean_orphans`. Plugins are auto-loaded when their package manager is detected. Helpers available to plugins (`cc_find_old`, `cc_du_kb`, `cc_emit_orphan`, `cc_clean_orphans_from_file`, etc.) are defined in `modules/_cache_clean/_cache_clean.sh`; don't reimplement them.

## Commit style

Semantic prefixes scoped to the tool: `feat(tool):`, `fix(tool):`, `refactor(tool):`, `docs:`. Recent history (`git log --oneline`) is the source of truth for tone.

## Commit workflow — DO NOT COMMIT WITHOUT EXPLICIT APPROVAL

Never run `git commit` or `git push` on your own initiative. Make the code changes, verify them (syntax, smoke/behavioral tests), and then STOP. Wait for the user to explicitly say "commit" (or "commit and push") before creating any commit or pushing to `origin`. The user reviews and approves all changes first.
