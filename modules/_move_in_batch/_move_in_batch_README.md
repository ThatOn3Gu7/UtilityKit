# 📦 Batch File Mover (`_move_in_batch.sh`)

A production-ready, interactive terminal script written in pure Bash to safely copy or move files in bulk from a target directory to an output directory. Supports exclusion patterns, directory flattening, collision-safe renaming, and a full-colour interactive preview with live progress feedback.

This utility forms a core component of the **[UtilityKit](https://github.com/Thaton3gu7/Utilitykit.git)** scripting ecosystem.

## ✨ Core Highlights

- **Safe by Default:** Uses `cp` (copy) as the default transfer method. Originals are never touched unless you explicitly opt into `mv` mode with `--method=mv`.
- **Flatten Mode:** The `--flatten` / `-f` flag strips away all subdirectory nesting — every file lands directly in the output root, one by one, with automatic collision renaming (`_1`, `_2`, …).
- **Smart Exclusion Grouping:** Directory-level exclusions like `.git` or `node_modules` are displayed as a single compact entry (`.git (42 files excluded)`) rather than flooding the preview with every file inside them.
- **Interactive Preview & Confirmation:** Before anything happens, you see a colour-coded preview of what will be transferred, what will be skipped, and a `[Y/n]` prompt to proceed.
- **Live Progress Bar:** In-place animated progress with colour transitions (cyan → yellow → green) and a per-file label so you always know the script is working.
- **Ctrl+C Rollback:** Interrupt mid-operation and the script offers to reverse all changes, restoring the output directory to its original state.
- **Sourced or Executed:** Run standalone (`bash _move_in_batch.sh …`) or source it into another script (`source _move_in_batch.sh` then call `move_in_batch …`).
- **Terminal-Aware:** Detects `NO_COLOR`, dumb terminals, and Termux — falls back to plain ASCII when Unicode or ANSI isn't available.

---

## 🚀 Usage

### Command Line Interface

```bash
bash _move_in_batch.sh -t <target> -o <output> [flags]
```

### Sourced Mode

```bash
source _move_in_batch.sh
move_in_batch -t <target> -o <output> [flags]
```

---

## ⚙️ Options & Flags

| Flag | Long Option | Description |
|---|---|---|
| `-t` | `--target` | Source directory to scan for files **(required)** |
| `-o` | `--output` | Destination directory to place files into **(required)** |
| `-e` | `--exclude` | Extensions or patterns to skip (e.g. `.git` `.md` `.tmp`). Directory-level patterns (`.git`, `node_modules`) are grouped in the preview. |
| `-f` | `--flatten` | Strip all subdirectory structure. Every file lands directly in the output root. Collisions are auto-resolved with `_1`, `_2` suffixes. |
| `-m` | `--method` | Transfer method: `cp` (copy, **default**) or `mv` (move/destructive). Invalid values fall back to `cp` with a warning. |
| `-h` | `--help` | Print the full help guide with usage examples. |
| `-v` | `--version` | Print version, Bash version, and terminal capability status. |

---

## 📝 Practical Examples

```bash
# Example 1: Safe copy, excluding .md and .git, preserving folder structure
bash _move_in_batch.sh -t ~/Projects/MyApp -o ~/Backup -e .md .git

# Example 2: Move files and flatten all subdirectories into one flat output
bash _move_in_batch.sh -t ~/Downloads -o ~/Sorted -f -m=mv

# Example 3: Long-form flags, copy mode, exclude common noise
bash _move_in_batch.sh --target ~/src --output ~/out --method=cp --exclude .git node_modules .log

# Example 4: Flatten a directory but keep originals (copy mode is default)
bash _move_in_batch.sh -t ~/Music/Unsorted -o ~/Music/Flat -f
```

---

## 📊 Terminal & Environment Adaptability

The tool dynamically monitors terminal capabilities to guarantee seamless operation across different setups:

- **Unicode Fallback:** Automatically drops complex glyphs (📁, ✔, ↯) to plain ASCII alternatives (`[D]`, `[OK]`, `|>`) when the terminal doesn't support Unicode.
- **Colour Stream Detection:** Respects `NO_COLOR` environment markers and non-TTY stdout pipes to keep log files clean and readable.
- **Mobile-Ready:** Tested on Termux for Android with limited terminal width and restricted ANSI support.

---

## ❌ Exit Status Codes

| Code | Meaning |
|---|---|
| **0** | Success — all files transferred, or all were skipped cleanly. |
| **1** | Fatal error — missing required arguments, invalid directory, or unknown flag. |
| **2** | Partial failure — some files failed during transfer, but others succeeded. |
| **130** | Interrupted by user (`Ctrl+C`). Rollback is offered before exit. |

---

## 🔗 Related Tools

| Tool | Description |
|---|---|
| [`_rename_batch`](https://github.com/Thaton3gu7/UtilityKit/tree/master/_rename_batch) | Recursive batch file renamer / copy-renamer |
| [`_apply_changes`](https://github.com/Thaton3gu7/UtilityKit/tree/master/_apply_changes) | Safe directory synchronization with rollback |
| [`_symlink_manager`](https://github.com/Thaton3gu7/UtilityKit/tree/master/_symlink_manager) | Transactional symlink helper with backups |
| [`_shredder`](https://github.com/Thaton3gu7/UtilityKit/tree/master/_shredder) | Secure erase wrapper using `shred` or overwrite fallback |