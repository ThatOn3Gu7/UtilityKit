# IP Info (`ipinfo`)

Public + local IP report with reverse DNS, ASN, GeoIP, and WHOIS.

## Sections

- **Local**: hostname, gateway, per-interface IPv4/IPv6/MAC.
- **Public**: IPv4 and (if available) IPv6.
- **Geo**: country, region, city, coords, timezone, ISP, ASN.
- **WHOIS**: registrar, org, netblock range, name servers, dates.

## Data sources

| Purpose | URL |
|---------|-----|
| Public IPv4 | ipinfo.io/ip → ifconfig.co → ifconfig.me → api.ipify.org |
| Public IPv6 | ipv6.icanhazip.com → api64.ipify.org → ifconfig.co |
| GeoIP + ASN | ip-api.com (free tier, ~45 rpm) |
| WHOIS       | local `whois` binary |

## Options

| Flag | Meaning |
|------|---------|
| `TARGET` | IPv4, IPv6, or hostname. Optional. |
| `--local` | Show local interfaces. |
| `--public` | Look up public IP. |
| `--whois` | Include WHOIS. |
| `--geo` | Include GeoIP + ASN (default when target given). |
| `--no-network` | Skip every HTTP call (local-only report). |
| `--timeout SEC` | HTTP timeout per request (default 5). |
| `--json` | JSON output. |
| `--no-color` | Disable ANSI. |

## Defaults

- No target      → `--local --public --geo`
- Target given   → `--geo`
- `--no-network` forces local-only regardless of other flags.

## Examples

```
ipinfo                       # local + public + geo
ipinfo 1.1.1.1               # remote lookup
ipinfo github.com --whois
ipinfo --local --no-network
ipinfo --json > report.json
```

## Dependencies

- `curl` (required for any network lookup)
- `whois` (optional — enables the WHOIS section)
- `python3` (optional — cleaner JSON parsing)
- `ip` / `ifconfig` / `route` / `netstat` (any one enables the local section)
