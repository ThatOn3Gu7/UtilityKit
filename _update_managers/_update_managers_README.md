# Update Managers

Detect every package manager installed on the machine (system, app-store,
language, and toolchain managers) and update them all from one place, with a
live spinner that shows the exact sub-command currently running and a concise
"why" message extracted from each manager's output.

Supports 60+ managers including apt, dnf, pacman, brew, winget, choco, scoop,
flatpak, snap, npm, pnpm, yarn, pip, pipx, uv, cargo, gem, go, composer, dotnet,
sdkman, asdf, mise, and many more. Portable Bash 3+; Linux, macOS, BSD,
Windows (Git Bash/MSYS/WSL), and Termux.

## Usage

```bash
# Via the UtilityKit hub
./main.sh update              # rich interactive menu
./main.sh update --list       # detect and list managers, then exit
./main.sh update --yes        # non-interactive: update everything detected
./main.sh update --dry-run    # show what would run, change nothing
./main.sh update --only apt,brew,npm
./main.sh update --skip snap
./main.sh update --help

# Standalone
bash _update_managers.sh --help
```

Aliases in the hub: `update`, `update-managers`, `upgrade`.

## Highlights

- **Live command display** — the spinner flips through each sub-command as it
  runs (e.g. `apt-get update` → `apt-get upgrade -y` → `apt-get autoremove -y`).
- **Smart failure reason** — on failure the most relevant error line is grepped
  from the log and shown under the spinner and in the summary.
- **Isolated failures** — one manager failing never aborts the rest of the batch.
- **Safe privileges** — uses `sudo`/`doas` only when needed; skips elevation on
  Termux.

## Cross-platform behavior

All commands are designed to work on Linux, macOS, and Termux/minimal terminals
where possible. Each manager is detected at runtime; unavailable managers are
simply skipped. When a dependency is missing, the tool prints a clear message
and continues safely.
