# _port_inspector

Find which process is listening on a local TCP port, display network interface information, and optionally terminate the owning process.

---

## Features

- **Port lookup** — identifies the process holding any local TCP port using `lsof` or `ss`
- **Interface summary** — shows active network interfaces and their IP addresses
- **Process termination** — optionally sends `SIGTERM` to the process owning the port
- **Interactive mode** — running without arguments launches a guided prompt
- **Cross-platform** — works on Linux, macOS, and Termux using available system tools

---

## Usage

```bash
# Inspect a port (interactive confirm before kill)
bash _port_inspector/_port_inspector.sh 3000

# Inspect and immediately terminate the owning process
bash _port_inspector/_port_inspector.sh 3000 --kill

# Launch interactive mode (prompts for port number)
bash _port_inspector/_port_inspector.sh
```

---

## Options

| Option | Description |
|---|---|
| `PORT` | The local TCP port number to inspect |
| `--kill` | Terminate the process owning the port without interactive confirmation |
| `-h, --help` | Show usage |

---

## How it works

The tool attempts port inspection in this order:

1. Uses `lsof -nP -iTCP:<port> -sTCP:LISTEN` if available
2. Falls back to `ss -ltnp sport = :<port>` if `lsof` is not installed
3. Extracts the PID from whichever tool succeeded
4. Prompts whether to send `SIGTERM` to that PID (or skips the prompt with `--kill`)

Network interface output uses `ip -brief addr` if available, falling back to `ifconfig`.

---

## Examples

```bash
# Find what is running on port 8080
bash _port_inspector/_port_inspector.sh 8080

# Kill whatever is holding port 5432 (Postgres)
bash _port_inspector/_port_inspector.sh 5432 --kill

# Common ports to inspect
#   3000  →  Node / React dev server
#   5432  →  PostgreSQL
#   6379  →  Redis
#   8080  →  common HTTP alternate
#   8443  →  common HTTPS alternate
```

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success or no process found on that port |
| `1` | Missing required tools (`lsof` and `ss` both unavailable) |
