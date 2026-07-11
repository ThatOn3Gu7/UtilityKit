# HTTP Bench (`bench`)

Lightweight HTTP benchmark: N requests, configurable concurrency, reports p50/p95/p99,
RPS, and error rate.

## Backends (tried in order)

1. **hey** — Go-based, best statistics (pip install hey or download binary)
2. **wrk** — C-based, high performance (apt install wrk)
3. **curl** — built-in, always available

## Usage

```
bench https://example.com
bench https://api.example.com -n 200 -c 10
bench https://httpbin.org/post -m POST -d '{"key":"value"}' -H 'Content-Type: application/json'
bench https://example.com -n 1000 -c 50 --json
```

## Options

| Flag | Meaning | Default |
|------|---------|---------|
| `-n, --requests N` | Total requests | 50 |
| `-c, --concurrency N` | Parallel workers | 5 |
| `-m, --method M` | HTTP method | GET |
| `-H, --header H` | Custom header (repeatable) | — |
| `-d, --data DATA` | Request body | — |
| `--timeout SEC` | Per-request timeout | 10 |
| `--keep-alive` | HTTP keep-alive | off |
| `--json` | Machine-readable output | off |

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success (even if errors) |
| `1` | All requests failed |
| `2` | Argument / dependency error |
