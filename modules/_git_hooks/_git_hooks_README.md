# Git Hooks (`hooks`)

Install, remove, list, and inspect git hook templates.

Configure `.git/hooks/` with managed templates.

## Usage

```
hooks install                   # install all built-in hooks
hooks install pre-commit pre-push  # install specific hooks
hooks remove                    # remove all hooks
hooks list                      # show installed status
hooks list --json               # machine-readable
hooks show pre-commit           # display hook content
hooks init                      # install, no prompts
```

## Built-in Hooks

| Hook | Purpose |
|------|---------|
| `pre-commit` | Lint staged files |
| `prepare-commit-msg` | Prefix branch name |
| `commit-msg` | Reject WIP/fixup/squash |
| `post-commit` | Show commit summary |
| `pre-push` | Run tests |
| `post-checkout` | Log branch switch |
| `post-merge` | Post-merge hook |
| `pre-rebase` | Auto-stash changes |
