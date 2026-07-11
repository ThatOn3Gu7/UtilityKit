# Cron Manager

List, add, and remove user crontab entries with dry-run protection.

## Usage

```bash
bash _cron_manager.sh --help
```

## Cross-platform behavior

All commands are designed to work on Linux, macOS, and Termux/minimal terminals where possible. Optional system dependencies are detected at runtime. If a dependency is unavailable, the tool prints a clear warning and either uses a fallback or skips that feature safely.

