# _process_killer

Display a live memory and swap usage overview, list the top processes by memory consumption, and optionally send a signal to terminate a specific process by PID.

---

## Features

- **Memory overview** — shows RAM and swap usage with a color-coded progress bar
- **Top process list** — displays the 10 highest memory-consuming processes with PID, user, CPU, and memory columns
- **Process termination** — sends `SIGTERM` or `SIGKILL` to any PID you specify
- **Exit confirmation** — reports whether the process actually stopped after the signal was sent
- **Interactive mode** — running without arguments shows the overview then prompts for a PID

---

## Usage

```bash
# Interactive mode — show memory overview and prompt for a PID
bash _process_killer/_process_killer.sh

# Inspect only, no termination
bash _process_killer/_process_killer.sh

# Terminate a specific PID with SIGTERM (default)
bash _process_killer/_process_killer.sh --pid 1234

# Terminate a specific PID with SIGKILL
bash _process_killer/_process_killer.sh --pid 1234 --signal KILL
```

---

## Options

| Option | Description |
|---|---|
| `--pid PID` | PID of the process to terminate |
| `--signal TERM\|KILL` | Signal to send (default: `TERM`) |
| `-h, --help` | Show usage |

---

## Signal reference

| Signal | Effect | When to use |
|---|---|---|
| `TERM` | Polite stop — process can clean up before exiting | Always try this first |
| `KILL` | Forced immediate stop — cannot be ignored or caught | Only if TERM has no effect |

---

## Memory overview

```
  Memory overview
  ------------------------------------------------
  RAM    1,823 MB / 7,822 MB  ######------
  Swap     128 MB / 2,048 MB  #-----------
```

RAM usage is shown in green, swap in cyan. The bar fills proportionally to current usage.

---

## Top process list

```
  Top processes by memory
  ------------------------------------------------
  PID      USER         %CPU   %MEM   COMMAND
  3421     sahil        12.4   18.2   node
  1892     sahil         0.1    9.7   chrome
  4103     root          0.0    4.1   java
```

---

## Process termination output

When a PID is provided the tool describes the target process before sending the signal, then confirms whether it exited:

```
  Target process: 3421 sahil  12.4  18.2 node
  ✔ Sent SIGTERM to PID 3421 and the process exited.
```

If the process is still running after the signal:

```
  ⚠ Signal sent, but PID 3421 is still running.
```

In that case re-run with `--signal KILL` to force-stop it.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success or inspection only |
| `1` | PID does not exist or is not visible to the current user |
