# 🛠️ Batch File Renamer (`rename-batch.sh`)

A production-ready, transactional terminal script written in pure Bash to safely and recursively adjust file extensions across targeted system directory paths. Optimized specifically for fast execution in specialized low-overhead or sandboxed environments like Termux on Android.

This utility forms a core component of the **[UtilityKit](https://github.com/Thaton3gu7/Utilitykit.git)** scripting ecosystem.

## ✨ Core Highlights

- **Ultra-Fast Scanning Infrastructure:** Utilizes direct GNU `find` field formatting loops and native parameter mappings to eliminate process-forking overhead (`basename`/`stat`).
- **Transactional Rollback Defense:** Traps unexpected terminal interruptions (`Ctrl+C`). If stopped mid-process, it prompts a guided option to reverse all modified operations in inverted order, perfectly restoring your original storage environment.
- **Dynamic Display Layout Budgeting:** Implements an advanced active layout quota window to print a beautifully balanced mix of changes and skips without overrunning the display interface.
- **Safety Exclusion Controls:** Automatically skips mission-critical repository markers, license blocks, configuration profiles, and project lockfiles out of the box.
- **Automated Interactive Setup:** Can be run completely bare without arguments; the script automatically initializes a conversational wizard prompt to guide you through directories and setups.

---

## 🚀 Usage

### Command Line Interface Syntax
```bash
./rename-batch.sh <source_directory> <new_extension> [output_directory] [flags]
```

### Interactive Wizard Fallback
If you execute the script without passing any parameters, it will automatically launch an interactive setup guide inside your terminal:
```bash
./rename-batch.sh
```

## ⚙️ Options & Flags

| Flag | Long Option | Description |
|---|---|---|
| -f | --force, --all | Overrides safety filters to process files normally skipped by configuration/exclusion rules (e.g., README.md, LICENSE). |
| -h | --help | Renders comprehensive help definitions, usage criteria, and code examples. |
| -v | --version | Prints structural tool runtime capabilities, environment configuration status, and version tag. |

## 📝 Practical Examples

```bash
# Example 1: Rename everything in a project directory to .txt format in-place safely
./rename-batch.sh ./ProjectR txt

# Example 2: Target file extensions and copy renamed copies to a backup location
./rename-batch.sh ./ProjectR py /sdcard/StagedBackup

# Example 3: Force configuration modifications on system documentation profiles
./rename-batch.sh . bak --force

# Example 4: Start the conversational step-by-step setup setup guide
./rename-batch.sh
```

## 📊 Terminal & Environment Adaptability

The tool dynamically monitors terminal capabilities on the fly to guarantee seamless operation across different setups:

- **Unicode Matrix Fallback:** Automatically drops complex layout glyph structures down to safe standard ASCII alternative signs if older shell environments or raw terminal configurations are running.
- **Color Stream Inspections:** Checks for active NO_COLOR environment markers or broken TTY stdout pipes to guarantee logging files stay perfectly readable without escape codes cluttering the text.

## ❌ Exit Status Codes

The script provides explicit shell exit returns to make integration into your broader automation flows straightforward:

- **0** — **Success:** All target elements handled perfectly, or everything was skipped cleanly.
- **1** — **Fatal Error:** Missing input values, invalid target directory parameters, or unresolvable access restrictions.
- **2** — **Partial Failure:** The scanning completed, but specific system files threw errors during renaming.
- **130** — **Interrupted:** The user manually killed execution with Ctrl+C (Rollback prompts are handled here).
