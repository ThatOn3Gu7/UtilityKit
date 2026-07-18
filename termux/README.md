# Termux Widget Shortcuts

Pre-made home-screen widget shortcuts for the most mobile-relevant UtilityKit
tools. Tap a widget instead of opening a terminal.

## Included shortcuts

| Script                 | What it does                                              |
| ---------------------- | --------------------------------------------------------- |
| `battery_doctor.sh`    | Battery status + top CPU/MEM processes, held on screen.   |
| `weather.sh`           | Concise current weather (wttr.in) for your default loc.   |
| `clipboard_history.sh` | Lists the 20 most recent clipboard entries.               |
| `qr_scan.sh`           | Snaps a photo and decodes any QR code in it (Termux:API). |

## Install

```sh
bash termux/install.sh
```

This symlinks every `*.sh` in `termux/` into `~/.shortcuts/`. After installing,
the shortcuts appear in the Termux:Widget list — long-press your home screen →
Widgets → Termux:Widget to place them.

## Requirements

- **Termux** on Android with the **Termux:Widget** add-on.
- `qr_scan.sh` additionally needs **Termux:API** (`pkg install termux-api`) and a
  camera permission.
- `weather.sh` reads an optional `UK_TERMUX_WEATHER_LOC` env var to pin a
  location, e.g. `export UK_TERMUX_WEATHER_LOC="Berlin"`.

## How they work

Each script locates the real tool under `../modules/_<tool>/` (relative to this
folder) and runs it with sensible no-prompt arguments, then pipes the output
through `less -F` (or pauses for a tap) so the result stays readable on a phone.
