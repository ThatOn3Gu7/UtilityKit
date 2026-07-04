# DNS Probe (`dns`)

Query DNS records across multiple resolvers and compare their answers.

## Modes

- **Standard** — query each requested type once against the chosen resolver(s).
- **Propagation** — query every default public resolver + system resolver,
  group by answer, and flag disagreements. Exits `1` if any type disagrees.
- **JSON** — machine-readable dump of the full query matrix.

## Backends (auto-detected)

`dig` → `drill` → `host`.

Install any of them:

| Platform | Command |
|----------|---------|
| Debian / Ubuntu | `sudo apt install dnsutils` |
| Fedora / RHEL   | `sudo dnf install bind-utils` |
| macOS           | ships with `dig` and `host` |
| Termux          | `pkg install dnsutils` |

## Default resolvers (propagation mode)

| Name       | IP              |
|------------|-----------------|
| cloudflare | 1.1.1.1         |
| google     | 8.8.8.8         |
| quad9      | 9.9.9.9         |
| opendns    | 208.67.222.222  |
| system     | `/etc/resolv.conf` |

## Usage

```
dns example.com
dns example.com --type A,AAAA,MX
dns example.com --resolver 1.1.1.1 --resolver 8.8.4.4 --system
dns example.com --propagation
dns example.com --json > answers.json
```

## Options

| Flag | Meaning | Default |
|------|---------|---------|
| `--type T[,T,...]`  | Record types. `ANY` expands to defaults. | `A,AAAA,MX,TXT,NS,CAA,SOA` |
| `--resolver HOST`   | Query HOST (IP or hostname). Repeatable. | cloudflare |
| `--system`          | Include system resolver.                 | off |
| `--propagation`     | Compare all default resolvers.           | off |
| `--timeout SEC`     | Per-query timeout.                       | 3 |
| `--tries N`         | Retry count per query.                   | 2 |
| `--json`            | JSON output.                             | off |
| `--no-color`        | Disable ANSI.                            | off |

## Exit codes

- `0` success (or propagation consensus).
- `1` propagation disagreement.
- `2` argument or dependency error.
