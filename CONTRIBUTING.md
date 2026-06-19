# 🤝 Contributing to UtilityKit

First off, thank you for considering contributing to UtilityKit! It's people like you that make this utility suite such an ultra-dependable, delightful tool to use across Linux, macOS, and Termux/Android.

---

## 🏛 Core Architectural Guidelines

When adding a new utility script or modifying an existing one, please follow our established design language and modular entry point patterns. This ensures that `main.sh` can source all tools without polluting the global environment or causing sudden shell exits.

### 1. Modular Subdirectory Structure
Every new utility tool should live in its own dedicated subdirectory. This guarantees self-contained modularity and clear organization:

```text
UtilityKit/
├── _my_new_tool/
│   ├── README.md         # Dedicated documentation for standalone users
│   └── _my_new_tool.sh   # Main executable script
```

### 2. Guarded Main Entry Points
To prevent top-level script execution when sourced into `main.sh`, wrap your script's execution entry point in a beautifully prefixed main function and check `BASH_SOURCE`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Namespace all helper functions
mnt_setup_colors() { ... }

# 2. Main tool entry function
mnt_main() {
  mnt_setup_colors
  # Tool logic here...
}

# 3. Guard top-level execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  mnt_main "$@"
fi
```

### 3. Traps & Safety Under Sourcing
Do **not** register global `trap` handlers at the top level of your script. If your script sets a `trap` for `EXIT` or `SIGINT`, register it **inside** your main entry function (e.g., `mnt_main`). This ensures you do not overwrite the parent shell's interactive traps when your script is sourced by `main.sh`.

### 4. Rich Unicode & Gogh Visuals
We follow a highly professional, semantic visual aesthetic. Use consistent symbols and color prefixes:

- **Success**: `✔` (`C_GREEN`)
- **Error/Fail**: `✖` (`C_RED`)
- **Warning**: `⚠` (`C_YELLOW`)
- **Info/Prompt**: `ℹ` / `❯` (`C_BLUE` / `C_CYAN`)
- **Working/Thinking**: `⚙` / `◆` (`C_BRIGHT_YELLOW`)

Always implement plain ASCII fallbacks for non-Unicode compatible environments or non-interactive pipes.

---

## 💻 Contribution Workflow

1. **Fork the repository** and create your new branch (`git checkout -b feature/add-new-tool`).
2. **Implement your tool** inside a dedicated `_tool_name/` directory.
3. **Verify standalone execution**: `./_tool_name/_tool_name.sh --help`.
4. **Integrate into `main.sh`**:
   - Add your script to `source_scripts()`.
   - Add an interactive wizard helper (`run_tool_name_wizard()`).
   - Add an option to the interactive dashboard menu loop and direct CLI routing.
5. **Update `setup.sh`** to ensure your new subdirectory is included in the installation loop.
6. **Commit beautifully** with semantic commit prefixes (`feat:`, `fix:`, `docs:`, `refactor:`).
7. **Submit your Pull Request!** 🚀
