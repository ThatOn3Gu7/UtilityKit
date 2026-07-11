# _shredder

Securely erase files by overwriting their contents multiple times before deletion, making recovery significantly harder than a standard `rm`.

---

## Features

- **Multi-pass overwrite** — writes random data over the file contents for each configured pass
- **`shred` integration** — uses the system `shred` command if available for best results
- **Fallback overwrite** — uses `/dev/urandom` overwrite followed by truncation and `rm` when `shred` is not installed
- **Configurable passes** — choose how many overwrite passes to perform
- **Dry-run by default** — previews what would happen without touching any files
- **Interactive mode** — running without arguments launches a guided prompt

---

## Usage

```bash
# Interactive mode — prompts for file, passes, and confirmation
bash _shredder/_shredder.sh

# Preview what would happen (dry-run, no changes)
bash _shredder/_shredder.sh secret.txt

# Securely erase a file with default 3 passes
bash _shredder/_shredder.sh --apply secret.txt

# Erase with 7 passes (DoD standard)
bash _shredder/_shredder.sh --passes 7 --apply secret.txt

# Erase multiple files at once
bash _shredder/_shredder.sh --passes 3 --apply secret.txt credentials.env private.key
```

---

## Options

| Option | Description |
|---|---|
| `FILE...` | One or more files to erase |
| `--passes N` | Number of overwrite passes (default: `3`) |
| `--apply` | Execute secure erasure (dry-run preview if omitted) |
| `-h, --help` | Show usage |

---

## How it works

When `shred` is available:

```bash
shred -n <passes> -z -u <file>
```

This overwrites the file `N` times with random data, then once with zeros (`-z`), then unlinks the file (`-u`).

When `shred` is not available (fallback):

1. Reads the file size in bytes
2. Writes that many bytes of `/dev/urandom` output over the file, repeated for each pass
3. Truncates the file to zero bytes
4. Removes the file with `rm`

---

## Pass reference

| Passes | Standard | Notes |
|---|---|---|
| `1` | Basic | Fast, minimal protection |
| `3` | Default | Good general-purpose choice |
| `7` | DoD 5220.22-M | US Department of Defense standard |
| `35` | Gutmann | Maximum, very slow |

---

## Dry-run output

```
  Dry-run preview
  ------------------------------------------------
  File:    ~/secret.txt
  Method:  shred -n 3 -z -u
  Passes:  3
  (re-run with --apply to permanently erase this file)
```

---

## Important notes

- Secure erasure is most effective on traditional spinning hard drives. On SSDs and flash storage, wear leveling and overprovisioning mean the OS may write data to different physical cells, making full overwrite harder to guarantee at the hardware level.
- This tool erases the file contents and path. It does not wipe filesystem metadata, journal entries, or backup snapshots.
- Once `--apply` is used the file cannot be recovered through normal means. Verify the correct file path before confirming.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | No files specified |
