# _log_rotator

Archive old log files into compressed `.tar.gz` bundles and purge stale archive files that have exceeded a configurable retention period.

---

## Features

- **Log archiving** — packages log files older than a threshold into dated `.tar.gz` archives
- **Archive purging** — removes archive files that have exceeded the retention period
- **Multiple paths** — scan several log directories in a single run with repeated `--path`
- **Dry-run by default** — previews what would be archived and purged without making any changes
- **Custom archive output** — write archives to any directory with `--archive-dir`
- **Interactive mode** — running without arguments launches a guided setup prompt

---

## Usage

```bash
# Interactive mode — prompts for all settings
bash _log_rotator/_log_rotator.sh

# Preview what would be archived (dry-run, no changes)
bash _log_rotator/_log_rotator.sh --path ./logs --older-than 7

# Archive logs older than 7 days and apply
bash _log_rotator/_log_rotator.sh --path ./logs --older-than 7 --apply

# Archive to a custom directory
bash _log_rotator/_log_rotator.sh --path ./logs --older-than 7 --archive-dir ~/log-archives --apply

# Scan multiple directories
bash _log_rotator/_log_rotator.sh --path ./logs --path /var/log/myapp --older-than 14 --apply

# Archive old logs and purge archives older than 90 days
bash _log_rotator/_log_rotator.sh --path ./logs --older-than 7 --purge-older-than 90 --apply
```

---

## Options

| Option | Description |
|---|---|
| `--path DIR` | Log directory to scan (can be repeated for multiple directories) |
| `--older-than DAYS` | Archive log files older than this many days (default: `7`) |
| `--purge-older-than DAYS` | Delete archive files older than this many days (default: `30`) |
| `--archive-dir DIR` | Output directory for archive files (default: UtilityKit state dir) |
| `--apply` | Execute archiving and purging (dry-run if omitted) |
| `-h, --help` | Show usage |

---

## Default log paths

When no `--path` is given and the tool is run non-interactively, it scans these directories automatically if they exist:

- `/var/log`
- `~/.pm2/logs`
- `./logs`

---

## Archive naming

Each archive is named using the source directory basename and a timestamp:

```
logs_20260620_143201.tar.gz
myapp_20260620_143201.tar.gz
```

Archives are written to `~/.local/state/utilitykit/log_archives/` by default, or to the directory specified with `--archive-dir`.

---

## Output preview

```
  ./logs
  ------------------------------------------------
  Files older than 7 day(s) — will be archived:
  • ./logs/app.2026-06-10.log
  • ./logs/error.2026-06-08.log
  Target archive: ~/.local/state/utilitykit/log_archives/logs_20260620_143201.tar.gz

  Purge check — archives older than 30 day(s):
  ------------------------------------------------
  (no stale archives found)
```

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | No log directories found and none specified |
