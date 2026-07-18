# Termux Widget Shortcuts

Pre-made home-screen widget shortcuts for Termux on Android, written to be
**self-contained** so they actually work when tapped from a widget (no live
terminal, no prompts).

## Why not wrap the UtilityKit tools?

The UtilityKit tools (`_battery_doctor`, `_weather`, `_clipboard_history`,
`_qr_tool`, …) are **interactive**: they prompt for input, check for a TTY,
launch wizards, and expect the full `main.sh` environment plus
`lib/uk_common.sh`. A Termux widget fires a script and shows its output — there
is no interactive session, so those tools can't be driven from a widget tap.
(The earlier attempt to wrap them failed exactly this way: the tool couldn't
be located from the widget's working directory, and even if it could, it would
block waiting for input.)

**Lesson:** widget shortcuts are for small, fire-and-forget tasks. If you want
the full UtilityKit experience, open Termux and run `bash main.sh`.

## Included shortcuts

| Script             | What it does                                              |
| ------------------ | --------------------------------------------------------- |
| `battery_status.sh` | Prints `termux-battery-status` and logs it to a file.   |
| `storage_info.sh`   | Prints internal storage usage + Termux home size.        |
| `toggle_torch.sh`   | Toggles the camera flashlight (Termux:API).              |
| `clipboard_dump.sh` | Saves the current clipboard to a timestamped log file.   |

All depend only on Termux:API builtins (`termux-battery-status`,
`termux-torch`, `termux-clipboard-get`) — install with `pkg install termux-api`.

## Install

```sh
bash termux/install.sh
```

This copies each `*.sh` (except `install.sh`) into `~/.shortcuts/` as a real,
world-readable/executable file. (On unrooted phones running opencode under
proot, files are owned by uid 0; mode `755` lets the Termux app uid read and
run them.)

After installing, place them via: **home screen → Widgets → Termux:Widget**.

## Add your own

Drop any standalone, non-interactive script into `termux/` and re-run
`install.sh`. Keep it dependency-light and avoid prompts/TTY assumptions.
