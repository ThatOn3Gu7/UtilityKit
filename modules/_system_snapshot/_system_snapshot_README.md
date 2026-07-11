# System Snapshot

Collect a redacted diagnostic summary for support/debugging.

## Usage

```bash
bash _system_snapshot.sh --help
```

## Cross-platform behavior

All commands are designed to work on Linux, macOS, and Termux/minimal terminals where possible. Optional system dependencies are detected at runtime. If a dependency is unavailable, the tool prints a clear warning and either uses a fallback or skips that feature safely.

