# Battery Doctor

Battery and power diagnostics for Linux, macOS, and Termux where available.

## Usage

```bash
bash _battery_doctor.sh --help
```

## Cross-platform behavior

All commands are designed to work on Linux, macOS, and Termux/minimal terminals where possible. Optional system dependencies are detected at runtime. If a dependency is unavailable, the tool prints a clear warning and either uses a fallback or skips that feature safely.

