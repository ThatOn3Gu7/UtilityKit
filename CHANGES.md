# 📜 Changelog & Release History

All notable changes to the UtilityKit project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.5.0] — 2026-06-19

### ✨ Added
- **Central Dashboard (`main.sh`)**: A gorgeous, highly interactive CLI interface that sources all tools in the suite. Features single-click/number navigation, interactive command wizards, and direct CLI sub-command execution routing (e.g., `./main.sh rename`).
- **Universal Setup Installer (`setup.sh`)**: An elegant, remote-ready installer wizard supporting automated GitHub pipeline cloning (`curl | bash`) and non-interactive custom path flags (`--no-menu`, `--install-dir`, `--bin-dir`).
- **Symlink Manager (`_symlink_manager/_symlink_manager.sh`)**: Fully transactional dotfile and system configuration linking tool with automated timestamped existing target backups.
- **Disk Space Analyzer (`_disk_analyzer/_disk_analyzer.sh`)**: Highly responsive directory storage inspection tool with interactive top-consumer compressed archive packaging (`.tar.gz`).
- **Standardized Project Documentation**: Added complete MIT `LICENSE`, `CONTRIBUTING.md` guidelines, and architectural structure overviews.

### 🔄 Reconciled & Refactored
- Upgraded `_apply_changes/_apply_changes.sh`, `_rename_batch/_rename_batch.sh`, and `_cache_clean/cacheclean.sh` to support modular sourcing without triggering parent shell exits or overriding global traps.
- Standardized directory architecture to modular tool subdirectories (`_apply_changes/`, `_rename_batch/`, `_cache_clean/`, `_symlink_manager/`, `_disk_analyzer/`).
- Incorporated professional semantic styling (Gogh palettes and rich Unicode symbols with plain ASCII fallbacks) across all UI surfaces.

---

## [3.0.3] — Earlier Releases

### 🚀 Existing Suite Capabilities
- Robust, Termux-ready Directory Synchronization script (`_apply_changes.sh`) with adaptive temporary directory fallbacks, pre-flight space checking, and emergency rollback capabilities.
- Advanced Recursive Batch File Renamer (`_rename_batch.sh`) with live progress layout quotas and automatic exclusion rules.
- Cross-Platform System Cache Cleaner (`_cache_clean/cacheclean.sh`) with intelligent multi-package manager orphan detection.
