# _git_sweep

Preview and clean up a Git repository by removing merged branches, clearing stashes, sweeping untracked build artifacts, and compressing object storage with `git gc`.

---

## Features

- **Merged branch detection** — finds fully merged local and remote branches that are safe to delete
- **Stash cleanup** — lists and optionally clears all stashes in the repository
- **Artifact sweep** — previews and removes untracked build files using `git clean -fdx`
- **Object compression** — runs `git gc --prune=now` to compact the repository's object storage
- **Safe by default** — all destructive actions require explicit confirmation before anything is changed
- **Interactive mode** — running without arguments shows a full preview then prompts for each action

---

## Usage

```bash
# Interactive mode — preview everything then choose what to clean
bash _git_sweep/_git_sweep.sh

# Target a specific repository
bash _git_sweep/_git_sweep.sh --repo ~/projects/myapp

# Delete merged local branches only
bash _git_sweep/_git_sweep.sh --repo . --delete-merged-local --apply

# Delete merged local and remote branches
bash _git_sweep/_git_sweep.sh --repo . --delete-merged-local --delete-merged-remote --apply

# Run git gc only
bash _git_sweep/_git_sweep.sh --repo . --gc --apply

# Full sweep — branches, stashes, artifacts, and gc
bash _git_sweep/_git_sweep.sh --repo . --delete-merged-local --clean-artifacts --gc --apply
```

---

## Options

| Option | Description |
|---|---|
| `--repo DIR` | Repository directory to operate on (default: `.`) |
| `--delete-merged-local` | Delete fully merged local branches |
| `--delete-merged-remote` | Delete fully merged remote branches from `origin` |
| `--drop-stashes` | Clear all git stashes |
| `--clean-artifacts` | Remove untracked build files with `git clean -fdx` |
| `--gc` | Run `git gc --prune=now` to compress object storage |
| `--apply` | Execute selected actions (nothing is changed without this flag) |
| `-h, --help` | Show usage |

---

## What qualifies as a merged branch

The tool compares branches against the repository's default branch, which is detected automatically in this order:

1. `origin/HEAD` symbolic ref
2. First match among `main`, `master`, `trunk`
3. Current checked-out branch as fallback

Only branches fully contained in the default branch's history are listed as candidates. The default branch itself, `main`, `master`, and `trunk` are always excluded from deletion regardless of merge status.

---

## Preview output

Running in interactive mode always shows a full preview before any prompts:

```
  Merged local branches
  ------------------------------------------------
  • feat/login-page
  • fix/typo-in-readme

  Merged remote branches
  ------------------------------------------------
  (none found)

  Git stashes
  ------------------------------------------------
  • stash@{0}: WIP on main: abc1234 some message

  Untracked build artifacts preview
  ------------------------------------------------
  • Would remove dist/
  • Would remove node_modules/.cache/
```

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Not a git repository, or unknown option passed |
