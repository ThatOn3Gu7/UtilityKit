# Secret Scan (`secret`)

Scan a directory tree for leaked credentials. Combines a curated regex ruleset
with optional Shannon-entropy detection for generic high-entropy blobs.

## Design

- **Repo-aware**: when the target is inside a git worktree, files are
  enumerated via `git ls-files --cached --others --exclude-standard`, so
  `.gitignore`d paths are skipped automatically. Disable with
  `--no-gitignore`.
- **Non-repo mode**: falls back to `find`, honouring a default block-list
  (`.git`, `node_modules`, `__pycache__`, `dist`, `build`, `.venv`, `venv`,
  `target`, `.next`, `.cache`, `coverage`).
- **CI-friendly**: exits `1` when findings exist, `0` when clean, `2` for
  argument or dependency errors.
- **Redacted preview**: matches are printed as `XXXX••••••XXXX` — the raw
  secret is preserved only in `--json` output.

## Detectors

| Rule | Description |
|------|-------------|
| `aws-access-key`      | `AKIA…` (20 chars) |
| `aws-secret-key`      | Contextual 40-char base64 blob near `secret`/`access` |
| `github-token`        | `ghp_ / ghs_ / ghr_ / gho_ / ghu_ …` |
| `github-pat`          | New-style `github_pat_…` PATs |
| `github-oauth`        | `ghs_…` OAuth tokens |
| `slack-token`         | `xoxb-`, `xoxa-`, `xoxp-`, `xoxr-`, `xoxs-` |
| `slack-webhook`       | `https://hooks.slack.com/services/…` |
| `discord-webhook`     | `https://discord(app).com/api/webhooks/…` |
| `google-api-key`      | `AIza…` (39 chars) |
| `stripe-key`          | `sk_/pk_/rk_ live/test …` |
| `jwt`                 | Three base64 segments separated by dots |
| `private-key-block`   | `-----BEGIN … PRIVATE KEY-----` blocks |
| `generic-hex-secret`  | `secret/token/password/api_key = <32+ hex>` |
| `generic-b64-secret`  | `secret/token/password/api_key = <40+ base64>` |
| `dotenv-live-value`   | `.env*` files with non-placeholder assignments |
| `high-entropy-blob`   | Shannon entropy ≥ `--entropy-min` (default 4.5) |

## Options

| Flag | Meaning | Default |
|------|---------|---------|
| `--path P`         | Add a scan target (repeatable) | `.` |
| `--json`           | Emit findings as JSON lines    | off |
| `--no-entropy`     | Skip entropy pass              | off |
| `--entropy-min N`  | Minimum entropy threshold      | `4.5` |
| `--entropy-len N`  | Minimum blob length            | `20` |
| `--max-bytes N`    | Skip larger files              | `1048576` |
| `--no-gitignore`   | Ignore `git ls-files` filter   | off |
| `--include GLOB`   | Whitelist glob (repeatable)    | — |
| `--exclude GLOB`   | Blacklist glob (repeatable)    | see below |
| `--context N`      | Chars of context around match  | 40 |
| `--quiet`          | Only print summary             | off |
| `--no-color`       | Disable ANSI                   | off |

## Dependencies

- `grep` (with `-P` PCRE preferred, falls back to `-E`)
- `git` (optional — enables `.gitignore` respect)
- `python3` (optional — enables entropy scoring)
- `find` for non-git enumeration

Everything else degrades gracefully.

## Examples

```
secret                                # scan CWD
secret ./src ./scripts
secret --json > findings.jsonl
secret --no-entropy --exclude '*/vendor/*'
secret --entropy-min 5.0 --entropy-len 32
```

## Exit codes

| Code | Meaning |
|------|---------|
| `0`  | No findings |
| `1`  | Findings present |
| `2`  | Argument or dependency error |
