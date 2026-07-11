# Backup Sync

Guided, dry-run-first backup wrapper around rsync with safe copy fallback.

## Usage

```bash
bash _backup_sync.sh --help
```

## Cross-platform behavior

All commands are designed to work on Linux, macOS, and Termux/minimal terminals where possible. Optional system dependencies are detected at runtime. If a dependency is unavailable, the tool prints a clear warning and either uses a fallback or skips that feature safely.

