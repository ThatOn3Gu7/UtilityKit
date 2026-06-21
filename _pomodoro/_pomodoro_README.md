# _pomodoro

A colorful terminal focus timer based on the Pomodoro Technique. Alternates between work and break blocks for a configurable number of cycles, displays a live progress bar during each block, and logs completed sessions to a persistent file.

---

## Features

- **Configurable cycles** — set custom work duration, break duration, and number of cycles
- **Live progress bar** — color-coded bar updates every second during work and break blocks
- **Session logging** — completed work cycles are appended to a persistent log file
- **Bell and vibration** — plays a terminal bell at the end of each block, with Termux vibration support
- **Seconds mode** — use `--unit seconds` for quick testing without waiting full minutes
- **Interactive mode** — running without arguments launches a guided setup prompt

---

## Usage

```bash
# Standard 25/5 Pomodoro, 4 cycles
bash _pomodoro/_pomodoro.sh

# Custom work/break/cycles
bash _pomodoro/_pomodoro.sh --work 50 --break 10 --cycles 2

# Silent mode (no bell or vibration)
bash _pomodoro/_pomodoro.sh --no-bell

# Quick test run using seconds instead of minutes
bash _pomodoro/_pomodoro.sh --work 5 --break 2 --cycles 2 --unit seconds --no-bell

# Launch interactive setup prompt
bash _pomodoro/_pomodoro.sh
```

---

## Options

| Option | Description |
|---|---|
| `--work N` | Work block duration (default: `25`) |
| `--break N` | Break block duration (default: `5`) |
| `--cycles N` | Number of work/break cycles to run (default: `4`) |
| `--unit minutes\|seconds` | Time unit for durations (default: `minutes`) |
| `--no-bell` | Disable terminal bell and Termux vibration |
| `-h, --help` | Show usage |

---

## Progress bar

During each block the timer prints a live updating line:

```
◆ Work focus       23s  ████████████------------
☕ Break time        4s  ██████████████████------
```

Work blocks display in green, break blocks in cyan. The bar fills from left to right as time passes.

---

## Session log

Completed work cycles are logged automatically to:

```
~/.local/state/utilitykit/pomodoro.log
```

Each entry includes a timestamp and the cycle number:

```
2026-06-20 14:32:01 | completed work cycle 1
2026-06-20 14:58:44 | completed work cycle 2
```

---

## Pomodoro technique reference

| Style | Work | Break | Cycles |
|---|---|---|---|
| Classic | 25 min | 5 min | 4 |
| Long focus | 50 min | 10 min | 2 |
| Ultradian | 90 min | 20 min | 2 |
| Quick test | 5 sec | 2 sec | 3 |

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | All cycles completed successfully |
| `1` | Unknown option passed |
