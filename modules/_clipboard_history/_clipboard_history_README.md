# Clipboard History (`clipboard`)

Persistent clipboard history with fuzzy search and pin support. Stores entries
as newline-delimited JSON at
`${XDG_DATA_HOME:-~/.local/share}/utilitykit/clipboard.jsonl`.

## Features

- Add from **arg**, **stdin**, or **current clipboard**.
- List / preview newest first with pinned markers and relative timestamps.
- Copy any entry back to the clipboard (`get N`).
- Pin entries so history trimming won't drop them.
- Case-insensitive regex `find`.
- JSON output on `list`, `find`, `show`.
- Store file is `chmod 600` — treat it like a secret.

## Backends (auto-detected)

| Purpose | Order tried |
|---------|-------------|
| Write   | `wl-copy` → `xclip` → `pbcopy` → `termux-clipboard-set` → `clip.exe` |
| Read    | `wl-paste` → `xclip -o` → `pbpaste` → `termux-clipboard-get` → `powershell Get-Clipboard` |

Missing dependencies degrade gracefully — read/write fall back to printing
to stdout with a warning.

## Usage

```
clipboard add "quick note"
echo "from stdin" | clipboard add
clipboard add                       # pull current OS clipboard
clipboard list
clipboard list --json
clipboard find TODO
clipboard get 1                     # copy newest back to clipboard
clipboard get --last                # same as: get 1
clipboard show 3 --no-clip          # print without touching clipboard
clipboard pin 3
clipboard unpin 3
clipboard remove 5
clipboard clear --force
clipboard path                      # print store path
```

## Options

| Flag        | Meaning                                 |
|-------------|-----------------------------------------|
| `--max N`   | Cap history to `N` (default 200). Pins never trimmed. |
| `--no-clip` | Skip actually writing to the OS clipboard. |
| `--json`    | Machine-readable output (list, find, show). |
| `--quiet`   | Suppress success/info lines. |
| `--force`   | Skip confirmation on `clear`. |

## Termux notes

Install `termux-api` and enable clipboard permission to read/write.
Without it, `add`/`get` still work but only via stdin/print fallback.

## Exit codes

`0` on success; `1` on missing input, out-of-range selector, or store I/O
failure.
