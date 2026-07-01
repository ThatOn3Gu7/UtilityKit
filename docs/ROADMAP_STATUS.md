# Roadmap status

This document maps the uploaded `idea.md` roadmap into the implemented UtilityKit tool directories.

| Roadmap idea | Implemented directory | Status |
|---|---|---|
| Intelligent `.env` Profile & Secrets Assistant | `_env_manager/` | Implemented |
| Interactive VCS Branch & Artifact Janitor | `_git_sweep/` | Implemented |
| Visual Container & Storage Eraser | `_docker_janitor/` | Implemented |
| Instant Universal Project Starter | `_project_scaffold/` | Implemented |
| Intelligent File Deduplicator | `_duplicate_finder/` | Implemented |
| Visual RAM Hog & Process Terminator | `_process_killer/` | Implemented |
| Local Network Detective & Service Evictor | `_port_inspector/` | Implemented |
| Certificate & DNS Health Detective | `_ssl_checker/` | Implemented |
| Lightweight CLI API Client | `_api_tester/` | Implemented |
| Secure XKCD Passphrase Generator | `_password_gen/` | Implemented |
| Interactive Remote Host Switcher | `_ssh_assistant/` | Implemented |
| Forensic-Grade Secure File Eraser | `_shredder/` | Implemented |
| Batch Image & Video Optimizer | `_media_convert/` | Implemented |
| Automated Markdown Document Polisher | `_markdown_toc/` | Implemented |
| CLI Deep-Work Timer | `_pomodoro/` | Implemented |
| Interactive Console Knowledge Base | `_cheat_sheet/` | Implemented |

## Expanded utility roadmap — implemented

| Roadmap idea | Implemented directory | Status |
|---|---|---|
| Network connectivity diagnostics | `_network_probe/` | Implemented with Termux/minimal fallbacks |
| Cron schedule manager | `_cron_manager/` | Implemented; requires `crontab` backend |
| Per-value dotenv vault | `_dotenv_vault/` | Implemented as gpg-only safety wrapper |
| Disk SMART health checker | `_disk_health/` | Implemented; requires `smartctl` and permissions |
| HTTP service watcher | `_service_watcher/` | Implemented |
| Git repository stats | `_git_stats/` | Implemented |
| Guided backup sync | `_backup_sync/` | Implemented with rsync/cp fallback |
| Weather lookup | `_weather/` | Implemented with cached fallback |
| JSON explorer | `_json_explorer/` | Implemented with Python backend |
| Tmux session helper | `_tmux_session/` | Implemented; requires `tmux` |
| Font preview / inspector | `_font_inspector/` | Implemented as glyph/font inspector |
| Recommended CLI toolbox audit | `_toolbox_bootstrap/` | Implemented |
| Project search | `_project_search/` | Implemented with rg/grep/find fallbacks |
| GitHub helper | `_github_helper/` | Implemented; requires `gh` |
| Link checker | `_link_checker/` | Implemented |
| Log inspector | `_log_inspector/` | Implemented |
| CSV toolkit | `_csv_toolkit/` | Implemented with Python backend |
| Hash tools | `_hash_tools/` | Implemented |
| Archive manager | `_archive_manager/` | Implemented |
| System snapshot | `_system_snapshot/` | Implemented |
| Open files / ports helper | `_open_files/` | Implemented; requires `lsof` for best results |
| Battery doctor | `_battery_doctor/` | Implemented with Termux/Linux/macOS backend detection |
| Release helper | `_release_helper/` | Implemented |
| License helper | `_license_helper/` | Implemented |
| Todo manager | `_todo_manager/` | Implemented |
| Universal package-manager updater | `_update_managers/` | Implemented; live per-command spinner + failure-reason extraction |

## Registry & maintenance

The hub now keeps every tool in a single source of truth (`UK_REGISTRY` in
`main.sh`). The lazy-loader path map and the interactive dashboard menu are both
derived from it, so they cannot drift apart. Run `./main.sh doctor` to verify
the registry against the files on disk, the dispatch cases, menu alignment, and
each tool's `--help`.

Note: the earlier `_log_rotator`, `_zen_mode`, `_clipboard_manager`, and
`_regex_lab` tools were removed from the project; their references have been
cleaned out of the hub, tests, and docs.
