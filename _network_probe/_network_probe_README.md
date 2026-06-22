# Network Probe

Connectivity diagnostics for ping, DNS, public IP, download timing, and route tracing.

## Usage

```bash
bash _network_probe.sh --help
```

## Cross-platform behavior

All commands are designed to work on Linux, macOS, and Termux/minimal terminals where possible. Optional system dependencies are detected at runtime. If a dependency is unavailable, the tool prints a clear warning and either uses a fallback or skips that feature safely.

