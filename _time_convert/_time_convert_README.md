# Time Convert (`time`)

Convert between epoch, ISO 8601, RFC 3339, RFC 2822, and human-readable
timestamps. Also parse cron expressions and compute timezone differences.

## Subcommands

| Command | Description |
|---------|-------------|
| `now` | Current time in all formats |
| `epoch [TS]` | Convert epoch seconds (default: now) |
| `parse TIMESTAMP` | Parse any timestamp → epoch + ISO |
| `cron EXPR` | Show next N cron fire times |
| `tz [ZONE]` | Timezone info or list available zones |
| `diff TS1 TS2` | Duration between two timestamps |

## Usage

```
time now
time epoch 1700000000
time epoch 1700000000 --tz UTC
time parse '2024-01-15T10:30:00Z'
time cron '*/15 * * * *' --count 5
time tz Asia/Tokyo
time diff '2024-01-01' '2024-12-31'
```

## Options

| Flag | Meaning |
|------|---------|
| `--tz TIMEZONE` | Interpret/display in timezone |
| `--count N` | Cron: number of future fires (default 5) |
| `--json` | Machine-readable output |
| `--no-color` | Disable ANSI |

## Dependencies

- `date` (GNU or BSD) — core conversions
- `python3` + `croniter` — cron parsing (`pip install croniter`)
- `python3` + `zoneinfo` — timezone listing (Python 3.9+)
