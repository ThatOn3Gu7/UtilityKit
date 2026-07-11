# _api_tester

A lightweight CLI HTTP client for running one-off requests or saving and replaying reusable request profiles, with timing breakdowns and formatted response output.

---

## Features

- **One-off requests** — fire a quick HTTP request without saving anything
- **Saved profiles** — store named request configurations and replay them later
- **Timing breakdown** — shows DNS, TCP, TTFB, and total time for every request
- **JSON formatting** — pretty-prints JSON responses automatically using `jq` if available
- **Status code coloring** — green for 2xx, yellow for 3xx, red for 4xx/5xx
- **Interactive mode** — running without arguments launches a guided prompt

---

## Usage

```bash
# Interactive mode — choose action and fill in details
bash _api_tester/_api_tester.sh

# One-off GET request
bash _api_tester/_api_tester.sh --method GET --url https://api.example.com/items

# POST with JSON body and header
bash _api_tester/_api_tester.sh --method POST --url https://api.example.com/items \
  --header 'Content-Type: application/json' \
  --body '{"name":"demo"}'

# POST with body from a file
bash _api_tester/_api_tester.sh --method POST --url https://api.example.com/items \
  --header 'Content-Type: application/json' \
  --body-file ./payload.json

# Save a request profile
bash _api_tester/_api_tester.sh --save staging-users \
  --method GET --url https://staging.example.com/users \
  --header 'Authorization: Bearer TOKEN'

# Run a saved profile
bash _api_tester/_api_tester.sh --run staging-users

# Show a saved profile
bash _api_tester/_api_tester.sh --show staging-users

# List all saved profiles
bash _api_tester/_api_tester.sh --list
```

---

## Options

| Option | Description |
|---|---|
| `--method METHOD` | HTTP method (default: `GET`) |
| `--url URL` | Request URL including protocol |
| `--header 'K: V'` | Request header (can be repeated for multiple headers) |
| `--body TEXT` | Request body as inline text |
| `--body-file FILE` | Request body read from a file |
| `--save NAME` | Save the request as a named profile |
| `--run NAME` | Execute a previously saved profile |
| `--show NAME` | Print the contents of a saved profile |
| `--list` | List all saved profile names |
| `-h, --help` | Show usage |

---

## Request output

```
  Request
  ------------------------------------------------
  Method:  GET
  URL:     https://api.example.com/items
  Header:  Authorization: Bearer TOKEN

  Timing
  ------------------------------------------------
  Status:  200
  DNS:     0.012s
  TCP:     0.034s
  TTFB:    0.187s
  Total:   0.201s

  Response body
  ------------------------------------------------
  {
    "items": [
      { "id": 1, "name": "demo" }
    ]
  }
```

---

## Saved profiles

Profiles are stored as plain bash variable files under:

```
~/.local/share/utilitykit/api_profiles/
```

Each profile captures the method, URL, headers, and body so it can be replayed exactly with `--run`.

---

## Requirements

- `curl` — required for all requests
- `jq` — optional, used for JSON pretty-printing

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Missing URL, profile not found, or `curl` not installed |
