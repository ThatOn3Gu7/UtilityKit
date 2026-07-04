# SSH Tunnel (`tunnel`)

Create, list, kill, and restart SSH port-forwards.

## Usage

```
tunnel create server.com:3000 --local 3000 --user deploy --name api
tunnel list
tunnel list --json
tunnel kill 1
tunnel restart api
```

## Options

| Flag | Meaning |
|------|---------|
| `--local PORT` | Local port (default: same as remote) |
| `--user USER` | SSH user |
| `--key FILE` | SSH identity file |
| `--autossh` | Auto-restart with autossh |
| `--name NAME` | Tunnel name for management |
| `--json` | Machine-readable list output |

Config: `${XDG_CONFIG_HOME:-~/.config}/utilitykit/tunnels.conf`
