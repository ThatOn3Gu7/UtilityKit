# _zen_mode

A collection of full-screen terminal screensavers including Matrix-style binary rain, Conway's Game of Life, and an ASCII wave animation. Runs for a configurable duration and exits cleanly on `Ctrl+C`.

---

## Features

- **Three modes** — matrix rain, Game of Life simulation, and flowing wave pattern
- **Configurable duration** — runs for any number of seconds then exits automatically
- **Color output** — each mode uses a distinct color scheme matching its theme
- **Early exit** — press `Ctrl+C` at any time to stop immediately
- **Interactive mode** — running without arguments prompts for mode and duration

---

## Usage

```bash
# Interactive mode — prompts for mode and duration
bash _zen_mode/_zen_mode.sh

# Run the wave screensaver for 30 seconds
bash _zen_mode/_zen_mode.sh --mode waves --duration 30

# Run the matrix screensaver for 60 seconds
bash _zen_mode/_zen_mode.sh --mode matrix --duration 60

# Run Conway's Game of Life for 20 seconds
bash _zen_mode/_zen_mode.sh --mode life --duration 20

# Quick preview of each mode
bash _zen_mode/_zen_mode.sh --mode waves --duration 5
bash _zen_mode/_zen_mode.sh --mode matrix --duration 5
bash _zen_mode/_zen_mode.sh --mode life --duration 5
```

---

## Options

| Option | Description |
|---|---|
| `--mode matrix\|life\|waves` | Screensaver mode to run (default: `waves`) |
| `--duration N` | How many seconds to run before exiting (default: `10`) |
| `-h, --help` | Show usage |

---

## Mode reference

### waves
A flowing ASCII wave pattern that scrolls across the terminal. Uses magenta coloring. Lightweight and works in any terminal size.

```
                *           *
      *                           *
           *         *
  *                       *
```

### matrix
Fills the terminal with random characters from a binary-style charset, refreshing rapidly to simulate the Matrix digital rain effect. Uses green coloring.

```
01<>/*01<>/*01<>
*+-01<>/*+-01<>
<>/*+-01<>/*+-0
```

### life
Runs Conway's Game of Life on an 18×48 grid, starting from a random initial state. Each generation is computed and rendered until the duration expires. Requires `python3`.

```
█ █  █   █ █
 █ █ █ █  █
█   █   █ █
```

---

## Requirements

- `python3` — required for the `life` mode only
- `tput` — used to detect terminal dimensions (falls back to 80×24 if unavailable)

---

## Notes

- `_zen_mode` is intentionally hidden from the main dashboard menu and is only available as a direct CLI command via `bash main.sh zen`
- The animation refresh rate is fixed at approximately 8 frames per second for `matrix` and `waves`, and slightly slower for `life` due to the generation computation
- Terminal resizing mid-animation may cause visual artifacts — restart the tool after resizing for best results

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Duration elapsed and screensaver exited normally |
| `1` | Unknown mode or option passed |
| `130` | Interrupted by `Ctrl+C` |
