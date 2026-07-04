# File Watcher (`watch`)

Run a command whenever files matching a glob change. Supports inotify (Linux),
fswatch (macOS/Termux), and a polling fallback.

## Usage

```
watch -p '*.sh' -c 'make test'
watch -d ./src -p '*.py' -p '*.js' -c 'npm test' --debounce 2
watch -p '*' --polling 5 -c 'rsync -a . backup/'
watch --initial -c './build.sh' .
```

## Options

| Flag | Meaning | Default |
|------|---------|---------|
| `-p, --pattern GLOB` | Watch pattern (repeatable) | all files |
| `-d, --dir DIR` | Watch directory | `.` |
| `-c, --cmd CMD` | Command | — |
| `-s, --debounce N` | Debounce seconds | 1 |
| `-i, --ignore GLOB` | Ignore pattern | — |
| `-r, --initial` | Run once on start | off |
| `--polling N` | Force polling interval | auto |

## Backends

1. **inotifywait** — Linux (`apt install inotify-tools`)
2. **fswatch** — macOS/Termux (`brew install fswatch`)
3. **poll** — universal fallback (pure bash `find` + `stat`)
