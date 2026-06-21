# _ssl_checker

Fetch TLS certificate metadata for any domain, calculate remaining validity days, run DNS record lookups, and probe for legacy TLS 1.0 and 1.1 support.

---

## Features

- **Certificate inspection** — retrieves subject, issuer, and expiry date via `openssl s_client`
- **Expiry warning** — flags certificates expiring within 30 days and errors on already-expired ones
- **DNS records** — looks up A, AAAA, MX, and TXT records using `dig` or `nslookup`
- **Legacy TLS probe** — tests whether the server still accepts TLS 1.0 or TLS 1.1 connections
- **Custom port support** — works on any port, not just 443
- **Interactive mode** — running without arguments launches a guided prompt

---

## Usage

```bash
# Check a domain on the default HTTPS port
bash _ssl_checker/_ssl_checker.sh example.com

# Check a custom port
bash _ssl_checker/_ssl_checker.sh example.com --port 8443

# Skip DNS checks
bash _ssl_checker/_ssl_checker.sh example.com --no-dns

# Skip legacy TLS probe
bash _ssl_checker/_ssl_checker.sh example.com --no-tls

# Certificate check only (no DNS, no TLS probe)
bash _ssl_checker/_ssl_checker.sh example.com --no-dns --no-tls

# Launch interactive mode
bash _ssl_checker/_ssl_checker.sh
```

---

## Options

| Option | Description |
|---|---|
| `HOST` | Domain or hostname to inspect |
| `--port N` | Port to connect on (default: `443`) |
| `--no-dns` | Skip DNS record lookups |
| `--no-tls` | Skip legacy TLS 1.0 and 1.1 probe |
| `-h, --help` | Show usage |

---

## Output sections

### Certificate details

```
  notBefore=Jan  1 00:00:00 2025 GMT
  notAfter=Jan  1 00:00:00 2026 GMT

Subject:  CN=example.com
Issuer :  C=US, O=Let's Encrypt, CN=R3
Days left: 194
```

The tool colors the days-left value green when healthy, yellow when under 30 days, and red when expired.

### DNS records

```
  DNS records for example.com
  ------------------------------------------------
  A       93.184.216.34
  AAAA    (no record)
  MX      0 .
  TXT     v=spf1 -all
```

### Legacy TLS probe

```
  ✔ TLS 1.0 rejected.
  ✔ TLS 1.1 rejected.
```

A warning is shown if either protocol is still accepted, since both are considered insecure.

---

## Requirements

- `openssl` — required for certificate fetching and TLS probing
- `dig` or `nslookup` — required for DNS lookups (skipped gracefully if neither is available)
- `python3` — used internally to calculate days remaining from the certificate expiry date

---

## Common ports

| Port | Use case |
|---|---|
| `443` | Standard HTTPS |
| `8443` | Alternate HTTPS |
| `465` | SMTPS (email) |
| `993` | IMAPS (email) |
| `5001` | Common local dev HTTPS |

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | `openssl` not installed, connection failed, or certificate already expired |
