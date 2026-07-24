# 🤝 Contributing to UtilityKit

First off, thank you for considering contributing to UtilityKit! It's people like you that make this utility suite such an ultra-dependable, delightful tool to use across Linux, macOS, and Termux/Android.

---

## 🏛 Core Architectural Guidelines

When adding a new utility script or modifying an existing one, please follow our established design language and modular entry point patterns. This ensures that `main.sh` can source all tools without polluting the global environment or causing sudden shell exits.

### 1. Modular Subdirectory Structure
Every new utility tool should live in its own dedicated subdirectory. This guarantees self-contained modularity and clear organization:

```text
UtilityKit/
├── _my_new_tool/
│   ├── README.md         # Dedicated documentation for standalone users
│   └── _my_new_tool.sh   # Main executable script
```

### 2. Guarded Main Entry Points
To prevent top-level script execution when sourced into `main.sh`, wrap your script's execution entry point in a beautifully prefixed main function and check `BASH_SOURCE`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Namespace all helper functions
mnt_setup_colors() { ... }

# 2. Main tool entry function
mnt_main() {
  mnt_setup_colors
  # Tool logic here...
}

# 3. Guard top-level execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  mnt_main "$@"
fi
```

### 3. Traps & Safety Under Sourcing
Do **not** register global `trap` handlers at the top level of your script. If your script sets a `trap` for `EXIT` or `SIGINT`, register it **inside** your main entry function (e.g., `mnt_main`). This ensures you do not overwrite the parent shell's interactive traps when your script is sourced by `main.sh`.

### 4. Rich Unicode & Gogh Visuals
We follow a highly professional, semantic visual aesthetic. Use consistent symbols and color prefixes:

- **Success**: `✔` (`C_GREEN`)
- **Error/Fail**: `✖` (`C_RED`)
- **Warning**: `⚠` (`C_YELLOW`)
- **Info/Prompt**: `ℹ` / `❯` (`C_BLUE` / `C_CYAN`)
- **Working/Thinking**: `⚙` / `◆` (`C_BRIGHT_YELLOW`)

Always implement plain ASCII fallbacks for non-Unicode compatible environments or non-interactive pipes.

---

## 🛡 Safe-by-Default Write/Delete Convention

Any tool that **mutates the filesystem or system state** (writes, overwrites, moves,
deletes, or sends signals) must protect the user by default. The established pattern
across UtilityKit is **dry-run-by-default**: the tool shows a preview of what *would*
happen and only performs the change when the user explicitly opts in via `--apply`, a
`--delete`/explicit flag, or a `[y/N]` confirmation prompt. Never mutate user data on
the first invocation without a preview.

When you add or modify a tool that writes or deletes, follow the nearest existing
example (`_apply_changes`, `_cache_clean`, `_duplicate_finder`, `_docker_janitor`,
`_shredder`, `_symlink_manager`, `_backup_sync`, `_git_sweep`, `_media_convert`,
`_markdown_toc`, `_env_manager`, `_dotenv_vault`, `_cron_manager`, `_release_helper`,
`_update_managers`). These ship the pattern already; reuse their flag names
(`--apply`, `--dry-run`, `MODE="dry-run"`) for consistency.

### Write/Delete Tool Safety Matrix

| Tool | Writes / Deletes | Default mode | Opt-in to mutate |
| --- | --- | --- | --- |
| `_apply_changes` | copies/overwrites/mirrors dirs | dry-run | `--apply` |
| `_cache_clean` | deletes orphaned cache files | preview only | `--delete` or confirm prompts |
| `_duplicate_finder` | deletes/hardlinks duplicates | report | `--apply` (after `--delete`/`--hardlink`) |
| `_docker_janitor` | prunes containers/images/volumes | dry-run preview | `--apply` |
| `_shredder` | secure-erases files | dry-run preview | `--apply` |
| `_symlink_manager` | creates symlinks, backs up targets | dry-run | `--apply` (or `-y` to skip confirm) |
| `_backup_sync` | rsync copy, optional `--delete` | dry-run (rsync `--dry-run`) | `--apply` |
| `_git_sweep` | `git clean -fdx`, branch cleanup | preview only | `--apply` |
| `_media_convert` | writes converted media | dry-run preview | `--apply` |
| `_markdown_toc` | rewrites Markdown TOC | dry-run preview | `--apply` |
| `_env_manager` | copies `.env.<profile>` → `.env` | dry-run preview | `--apply` |
| `_dotenv_vault` | writes encrypted `.env` | dry-run preview | `--apply` |
| `_cron_manager` | adds/removes cron entries | dry-run | `--apply` |
| `_release_helper` | creates git tag | dry-run preview | `--apply` |
| `_update_managers` | runs package-manager upgrades | dry-run | `--dry-run` off via `-y`/`--yes` |
| `_rename_batch` | renames/moves files | interactive `[Y/n]` + rollback | confirm at prompt |
| `_move_in_batch` | copies/moves files | interactive `[Y/n]` + rollback | confirm at prompt |
| `_image_tool` | resize/convert/strip/optimize/thumb | dry-run preview | `--apply` |
| `_pdf_toolkit` | merge/split/compress/rotate | dry-run preview | `--apply` |
| `_cheat_sheet` | writes/deletes snippet file | `[y/N]` confirm | confirm at prompt |
| `_todo_manager` | appends/edits own TSV store | implicit (owns its data) | n/a (append-only tracker) |
| `_process_killer` | sends signal to a PID | target shown, then signal | confirm via explicit `--pid` + run |
| `_archive_manager` | extract/create archives | unsafe-path guarded extract | n/a (new output paths) |

Tools that only **read** data (e.g. `_disk_analyzer`, `_log_inspector`,
`_secret_scan`, `_json_explorer`, `_csv_toolkit`, `_yaml_toolkit` info, `_git_stats`)
need no opt-in gate. Tools that manage their *own* private state files (e.g.
`_todo_manager`, `_clipboard_history`, `_password_gen`) are exempt because they do not
touch user-supplied paths unexpectedly.

---

## 💻 Contribution Workflow

1. **Fork the repository** and create your new branch (`git checkout -b feature/add-new-tool`).
2. **Implement your tool** inside a dedicated `_tool_name/` directory.
3. **Verify standalone execution**: `./_tool_name/_tool_name.sh --help`.
4. **Integrate into `main.sh`**:
   - Add your script to `source_scripts()`.
   - Add an interactive wizard helper (`run_tool_name_wizard()`).
   - Add an option to the interactive dashboard menu loop and direct CLI routing.
5. **Update `setup.sh`** to ensure your new subdirectory is included in the installation loop.
6. **Verify locally before pushing:**
   # 2. Functional smoke test + static analysis
   bash tests/smoke.sh        # PASS=N FAIL=0
   bash tests/deep_review_test.sh  # PASS=N FAIL=0
   shellcheck -S error modules/_<tool>/_<tool>.sh
7. **Commit beautifully** with semantic commit prefixes (`feat(tool):`, `fix(tool):`, `docs:`, `refactor:`).
8. **Submit your Pull Request!** The `.github/workflows/ci.yml` pipeline
   runs ten jobs (shellcheck, syntax on Ubuntu + macOS, smoke on Ubuntu +
    macOS, deep review, route coverage, standalone `--help` sweep, NO_COLOR
    audit, installer smoke, gitleaks). Any red job blocks merge — fix locally
    and push again rather than skipping checks.

---

## 🔖 Project-Wide Version Policy

UtilityKit is a **single project**, not a collection of independently versioned
scripts. The canonical version lives in one place:

```bash
lib/uk_common.sh  →  readonly UK_VERSION='X.Y.Z'
```

This `UK_VERSION` is the version of the **whole suite** — `main.sh`, the library,
every `modules/_*/` tool, and the docs bundle. It is surfaced by `main.sh --version`
and stamped into the bundled docs.

**When to bump it:** a significant change to *any* script in the repo bumps this
single project version. You do **not** need a per-file `VERSION=` marker to justify a
bump — the absence of such a marker never means "leave the version alone". Judge the
bump by the *size and impact* of the change:

| Change size | Bump | Example |
| --- | --- | --- |
| Bug fix / small tweak (< ~20 lines, no behavior shift) | patch `X.Y.Z → X.Y.(Z+1)` | typo fix, log wording |
| New feature / meaningful refactor / behavior change | minor `X.Y.Z → X.(Y+1).0` | new tool, dry-run-by-default rollout |
| Breaking change / incompatible CLI or output | major `(X+1).0.0` | removed flag, changed return codes |

**Process — documenting a bump is mandatory:** whenever `UK_VERSION` is bumped, the
change **must** be recorded in **two** places before the commit is considered complete:

1. **`CHANGES.md`** — add a dated `## [X.Y.Z] - YYYY-MM-DD` entry at the top with
   `### Added` / `### Changed` / `### Fixed` / `### Security` subsections as
   appropriate, summarizing *what* changed and *why* the version moved.
2. **`README.md` → `## Changelog`** — add a matching one-line **`vX.Y.Z`** entry
   (mark the newest as `- current`, and drop the `current` tag from the previous one)
   giving a brief, user-facing reason the version was bumped.

Leaving either place undocumented is a release blocker — CI's standalone sweep and the
`doctor` integrity check treat a version bump without matching changelog entries as
incomplete. Do **not** scatter version strings across individual tool files; keep the
single source of truth in `lib/uk_common.sh`.
