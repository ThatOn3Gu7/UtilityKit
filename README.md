# 🛠 UtilityKit

<p align="center">
  <img src="https://img.shields.io/badge/Bash-4.4%2B-22C55E?style=flat-square&logo=gnu-bash&logoColor=white" alt="Bash 4.4+">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Termux-06B6D4?style=flat-square" alt="Platforms">
  <img src="https://img.shields.io/badge/License-MIT-3B82F6?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/UI-Antigravity%20%2F%20Gogh%20Visuals-D946EF?style=flat-square" alt="UI Theme">
</p>

**UtilityKit** is an ultra-robust, modular collection of cross-platform Bash utility scripts designed to automate everyday developer operations like batch file renaming, sophisticated directory synchronization, intelligent cache cleanup, symlink management, and disk space analysis.

Everything is stitched together with a gorgeous, highly interactive CLI dashboard (`main.sh`) and an automated setup wizard (`setup.sh`) that makes installation and system integration seamless.

---

## 🎯 Purpose & Vision

The core goal of UtilityKit is to replace scattered, fragile one-off automation snippets with highly dependable, beautifully visualized terminal tools. Whether you are working on a high-powered Linux server, macOS workstation, or an Android mobile environment via Termux, UtilityKit provides identical high-fidelity behavior.

### ✨ What's Inside:
1. **Directory Synchronization (`_apply_changes/_apply_changes.sh`)**: An enterprise-grade sync tool with adaptive temp directory resolution, non-fatal concurrency locking, disk space pre-flight checks, and emergency automated rollback.
2. **Batch File Renamer (`_rename_batch/_rename_batch.sh`)**: Recursively rename (or copy and rename) files across directory trees with conflict resolution and live progress summaries.
3. **Intelligent Cache Cleaner (`_cache_clean/cacheclean.sh`)**: Cross-platform package manager cache inspection and safe cleanup with older-than time thresholds.
4. **Symlink Manager (`_symlink_manager/_symlink_manager.sh`)**: Safely create and manage dotfile/config symlinks with automatic timestamped backups of existing target structures.
5. **Disk Storage Analyzer (`_disk_analyzer/_disk_analyzer.sh`)**: Instantly inspect top storage consumers in any directory and quickly package them into compressed `.tar.gz` archives.

---

## 🚀 Getting Started

### 🌐 Remote One-Liner Installation
You can install UtilityKit directly from the repository using our interactive setup wizard:

```bash
curl -sSL https://raw.githubusercontent.com/ThatOn3Gu7/UtilityKit/main/setup.sh | bash
```

To install non-interactively with default paths (`~/.local/share/utility` and launcher `utility`):
```bash
curl -sSL https://raw.githubusercontent.com/ThatOn3Gu7/UtilityKit/main/setup.sh | bash -s -- --no-menu
```

### 💻 Local Clone & Install
```bash
git clone https://github.com/ThatOn3Gu7/UtilityKit.git
cd UtilityKit
bash setup.sh
```

---

## 🖥 Usage Dashboard

Once installed, simply type your configured launcher command (default is `utility`) from anywhere in your terminal:

```bash
utility
```

This opens the interactive **UtilityKit Central Hub**, allowing you to pick any tool with single-key or numbered navigation.

### ⚡ Direct CLI Execution Routing
You can also bypass the menu and execute specific tools directly:

```bash
utility apply       # Launch Apply Changes (Directory Sync)
utility rename      # Launch Batch File Renamer
utility cacheclean  # Launch Intelligent Cache Cleaner
utility symlink     # Launch Symlink Manager
utility disk        # Launch Disk Space & Directory Analyzer
utility setup       # Re-run Setup / Configuration
utility help        # Print CLI routing documentation
```

You can append `--help` to any sub-command for detailed argument guides (e.g., `utility rename --help`).

---

## 🏗 Recommended Future Project Directory Structure

As UtilityKit grows, we recommend adopting a clean, highly organized folder architecture. While currently existing top-level prefixed scripts (`_rename_batch.sh`, etc.) are fully supported for backwards compatibility, migrating future additions to a dedicated `scripts/` directory ensures maximum maintainability:

```text
UtilityKit/
├── scripts/                  # 📂 Future and migrated utility scripts
│   ├── apply_changes/        # Complete modular tool folders
│   │   ├── apply_changes.sh
│   │   └── README.md
│   ├── batch_rename/
│   │   └── batch_rename.sh
│   ├── cache_clean/
│   ├── disk_analyzer/
│   └── symlink_manager/
├── docs/                     # 📚 Extended user and developer documentation
│   ├── THEMES.md
│   └── ROADMAP.md
├── main.sh                   # ⚡ Interactive Hub / Dashboard Entry Point
├── setup.sh                  # 📦 Universal Installer Script
├── README.md                 # 📖 Main Project Readme
├── CONTRIBUTING.md           # 🤝 Contribution & Script Creation Guide
├── CHANGES.md                # 📜 Changelog / Release History
└── LICENSE                   # ⚖️ MIT License
```

---

## 💡 Ideas for Future Utility Scripts

Here are some small, incredibly useful automation scripts that fit perfectly into the UtilityKit vision:

1. **`_env_switcher.sh` (Local Environment Manager)**
   - Automatically load, decrypt, or swap `.env` files for different development tiers (staging, prod, local) with syntax validation.
2. **`_git_cleaner.sh` (VCS Branch & Stash Janitor)**
   - Prune merged local/remote Git branches, clean up old stashes, and compress interactive repositories.
3. **`_docker_flush.sh` (Container Cleanup Janitor)**
   - Safely prune dangling Docker images, stopped containers, and unused volumes with interactive selection.
4. **`_network_quick.sh` (Port & Service Inspector)**
   - Instantly show listening ports, active local IP addresses, and verify DNS resolutions or SSL certificates.
5. **`_ssh_manager.sh` (SSH Config & Key Assistant)**
   - Interactive selector for SSH hosts parsed from `~/.ssh/config` or quick SSH key pairing/generation.

---

## 🤝 Contributing & License

We welcome additions, enhancements, and bug fixes! Please review our [CONTRIBUTING.md](CONTRIBUTING.md) for precise code style guidelines and entry point architecture.

This project is open-source and licensed under the [MIT License](LICENSE).
