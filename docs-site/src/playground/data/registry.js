// Registry mirrors UK_REGISTRY in main.sh: key | action | name | description | category
// `real` entries point to a component key resolved in ToolPlayer.jsx
// `sim` entries point to a script key in simScripts.js

export const CATEGORIES = {
  core: { label: 'Core Suite', color: '#06B6D4' },
  dev: { label: 'Developer', color: '#3B82F6' },
  system: { label: 'System', color: '#A855F7' },
  files: { label: 'Files & Security', color: '#F59E0B' },
  productivity: { label: 'Productivity', color: '#10B981' },
};

export const TOOLS = [
  // ── Core Suite ──
  { id: 'apply_changes', cmd: 'apply', name: 'Apply Changes', cat: 'core', desc: 'Directory sync with dry-run preview, backup, and rollback.', kind: 'sim' },
  { id: 'rename_batch', cmd: 'rename', name: 'Batch Rename', cat: 'core', desc: 'Recursively rename or copy-rename files to a new extension.', kind: 'sim' },
  { id: 'move_in_batch', cmd: 'move', name: 'Move in Batch', cat: 'core', desc: 'Bulk copy/move with exclusions and collision-safe renaming.', kind: 'sim' },
  { id: 'cache_clean', cmd: 'cacheclean', name: 'Cache Cleaner', cat: 'core', desc: 'Multi-manager cache cleaner with a 17-plugin system.', kind: 'sim' },
  { id: 'symlink_manager', cmd: 'symlink', name: 'Symlink Manager', cat: 'core', desc: 'Transactional symlink creator with automatic backups.', kind: 'sim' },
  { id: 'disk_analyzer', cmd: 'disk', name: 'Disk Analyzer', cat: 'core', desc: 'Largest-items disk usage explorer with quick archiving.', kind: 'sim' },

  // ── Developer ──
  { id: 'env_manager', cmd: 'env', name: 'Env Manager', cat: 'dev', desc: '.env profile switching, comparison, and encryption.', kind: 'real', component: 'EnvManager' },
  { id: 'git_sweep', cmd: 'git', name: 'Git Sweep', cat: 'dev', desc: 'Merged-branch cleanup, stash purge, repo GC.', kind: 'sim' },
  { id: 'docker_janitor', cmd: 'docker', name: 'Docker Janitor', cat: 'dev', desc: 'Prune stopped containers, dangling images, volumes.', kind: 'sim' },
  { id: 'project_scaffold', cmd: 'scaffold', name: 'Project Scaffold', cat: 'dev', desc: 'Starter project generator for Bash/Python/Node/Go.', kind: 'sim' },
  { id: 'api_tester', cmd: 'api', name: 'API Tester', cat: 'dev', desc: 'One-off HTTP requests or saved/replayable profiles.', kind: 'real', component: 'ApiTester' },
  { id: 'ssh_assistant', cmd: 'ssh', name: 'SSH Assistant', cat: 'dev', desc: 'Parses ~/.ssh/config and connects to named hosts.', kind: 'sim' },
  { id: 'github_helper', cmd: 'github', name: 'GitHub Helper', cat: 'dev', desc: 'Thin wrapper around gh for PRs, issues, runs.', kind: 'sim' },
  { id: 'release_helper', cmd: 'release', name: 'Release Helper', cat: 'dev', desc: 'Git status, recent log, optional tag creation.', kind: 'sim' },
  { id: 'git_stats', cmd: 'git-stats', name: 'Git Stats', cat: 'dev', desc: 'Commit counts by author, most-changed files.', kind: 'sim' },
  { id: 'markdown_toc', cmd: 'toc', name: 'Markdown TOC', cat: 'dev', desc: 'Insert or refresh TOC with anchor slugs.', kind: 'real', component: 'MarkdownToc' },
  { id: 'link_checker', cmd: 'links', name: 'Link Checker', cat: 'dev', desc: 'Validate Markdown local and HTTP links.', kind: 'real', component: 'LinkChecker' },
  { id: 'json_explorer', cmd: 'json', name: 'JSON Explorer', cat: 'dev', desc: 'Pretty-print, inspect, and extract JSON paths.', kind: 'real', component: 'JsonExplorer' },
  { id: 'csv_toolkit', cmd: 'csv', name: 'CSV Toolkit', cat: 'dev', desc: 'Inspect CSV headers and preview rows.', kind: 'real', component: 'CsvToolkit' },
  { id: 'yaml_toolkit', cmd: 'yaml', name: 'YAML Toolkit', cat: 'dev', desc: 'Lint, convert, query, and merge YAML files.', kind: 'real', component: 'YamlToolkit' },
  { id: 'regex_lab', cmd: 'regex', name: 'Regex Lab', cat: 'dev', desc: 'Live regex tester with match & substitution preview.', kind: 'real', component: 'RegexLab' },
  { id: 'http_bench', cmd: 'bench', name: 'HTTP Bench', cat: 'dev', desc: 'HTTP benchmark with p50/p95/p99 & RPS stats.', kind: 'real', component: 'HttpBench' },
  { id: 'file_watcher', cmd: 'fwatch', name: 'File Watcher', cat: 'dev', desc: 'Run a command on file change with glob patterns.', kind: 'sim' },
  { id: 'git_hooks', cmd: 'hooks', name: 'Git Hooks', cat: 'dev', desc: 'Install, remove, list, show git hook templates.', kind: 'sim' },
  { id: 'installed', cmd: 'installed', name: 'Installed Commands', cat: 'dev', desc: 'List every installed package and PATH executable.', kind: 'sim' },
  { id: 'ssh_tunnel', cmd: 'tunnel', name: 'SSH Tunnel', cat: 'dev', desc: 'Create, list, kill, restart SSH port-forwards.', kind: 'sim' },

  // ── System ──
  { id: 'port_inspector', cmd: 'port', name: 'Port Inspector', cat: 'system', desc: 'Find which process owns a local port.', kind: 'sim' },
  { id: 'process_killer', cmd: 'proc', name: 'Process Killer', cat: 'system', desc: 'Inspect memory pressure and terminate processes.', kind: 'sim' },
  { id: 'battery_doctor', cmd: 'battery', name: 'Battery Doctor', cat: 'system', desc: 'Battery and power diagnostics.', kind: 'sim' },
  { id: 'disk_health', cmd: 'disk-health', name: 'Disk Health', cat: 'system', desc: 'SMART health check when smartctl exists.', kind: 'sim' },
  { id: 'system_snapshot', cmd: 'snapshot', name: 'System Snapshot', cat: 'system', desc: 'Compact diagnostic summary of OS and disk.', kind: 'sim' },
  { id: 'open_files', cmd: 'open-files', name: 'Open Files', cat: 'system', desc: 'Find processes using files, directories, or ports.', kind: 'sim' },
  { id: 'service_watcher', cmd: 'service', name: 'Service Watcher', cat: 'system', desc: 'Check HTTP services and response times.', kind: 'sim' },
  { id: 'network_probe', cmd: 'network', name: 'Network Probe', cat: 'system', desc: 'Ping, DNS, public IP, route diagnostics.', kind: 'sim' },
  { id: 'cron_manager', cmd: 'cron', name: 'Cron Manager', cat: 'system', desc: 'List/add/remove crontab entries safely.', kind: 'real', component: 'CronManager' },
  { id: 'tmux_session', cmd: 'tmux', name: 'Tmux Session', cat: 'system', desc: 'List, create, attach, or kill tmux sessions.', kind: 'sim' },
  { id: 'toolbox_bootstrap', cmd: 'toolbox', name: 'Toolbox Audit', cat: 'system', desc: 'Detect recommended CLI tools.', kind: 'sim' },
  { id: 'update_managers', cmd: 'update', name: 'Update Managers', cat: 'system', desc: 'Detect and update every package manager found.', kind: 'sim' },
  { id: 'dns_probe', cmd: 'dns', name: 'DNS Probe', cat: 'system', desc: 'Multi-resolver DNS queries & propagation checks.', kind: 'real', component: 'DnsProbe' },
  { id: 'ip_info', cmd: 'ipinfo', name: 'IP Info', cat: 'system', desc: 'Public/local IP, ASN, GeoIP, WHOIS lookup.', kind: 'real', component: 'IpInfo' },
  { id: 'uuid_gen', cmd: 'uuid', name: 'UUID Gen', cat: 'system', desc: 'Generate UUID v4/v7, ULID, NanoID, short IDs.', kind: 'real', component: 'UuidGen' },
  { id: 'time_convert', cmd: 'time', name: 'Time Convert', cat: 'system', desc: 'Epoch ↔ ISO 8601 ↔ human, cron analyzer.', kind: 'real', component: 'TimeConvert' },

  // ── Files & Security ──
  { id: 'duplicate_finder', cmd: 'dup', name: 'Duplicate Finder', cat: 'files', desc: 'Find exact duplicate files and reclaim space.', kind: 'sim' },
  { id: 'archive_manager', cmd: 'archive', name: 'Archive Manager', cat: 'files', desc: 'List, create, and safely extract archives.', kind: 'sim' },
  { id: 'media_convert', cmd: 'media', name: 'Media Convert', cat: 'files', desc: 'Batch convert images/videos when tools exist.', kind: 'sim' },
  { id: 'backup_sync', cmd: 'backup', name: 'Backup Sync', cat: 'files', desc: 'Dry-run-first backup wrapper with fallbacks.', kind: 'sim' },
  { id: 'shredder', cmd: 'shred', name: 'Shredder', cat: 'files', desc: 'Securely erase sensitive files with fallbacks.', kind: 'sim' },
  { id: 'hash_tools', cmd: 'hash', name: 'Hash Tools', cat: 'files', desc: 'Create checksums for files and directory trees.', kind: 'real', component: 'HashTools' },
  { id: 'dotenv_vault', cmd: 'dotenv', name: 'Dotenv Vault', cat: 'files', desc: 'Encrypt selected .env values with gpg.', kind: 'sim' },
  { id: 'secret_scan', cmd: 'secret', name: 'Secret Scan', cat: 'files', desc: 'Find leaked credentials via regex + entropy.', kind: 'real', component: 'SecretScan' },
  { id: 'qr_tool', cmd: 'qr', name: 'QR Tool', cat: 'files', desc: 'Encode text/URL/Wi-Fi/vCard, decode images.', kind: 'real', component: 'QrTool' },
  { id: 'pdf_toolkit', cmd: 'pdf', name: 'PDF Toolkit', cat: 'files', desc: 'Count pages, merge, split, extract text.', kind: 'sim' },
  { id: 'image_tool', cmd: 'image', name: 'Image Tool', cat: 'files', desc: 'Resize, convert, strip EXIF, optimize images.', kind: 'sim' },
  { id: 'project_search', cmd: 'search', name: 'Project Search', cat: 'files', desc: 'Search project text/files with rg/fd/find.', kind: 'sim' },

  // ── Productivity ──
  { id: 'password_gen', cmd: 'pass', name: 'Password Gen', cat: 'productivity', desc: 'Generate passphrases or random strings.', kind: 'real', component: 'PasswordGen' },
  { id: 'pomodoro', cmd: 'pomodoro', name: 'Pomodoro', cat: 'productivity', desc: 'Run focused work/break cycles.', kind: 'real', component: 'PomodoroTimer' },
  { id: 'cheat_sheet', cmd: 'cheat', name: 'Cheat Sheet', cat: 'productivity', desc: 'Store, search, and show command snippets.', kind: 'real', component: 'CheatSheet' },
  { id: 'todo_manager', cmd: 'todo', name: 'Todo Manager', cat: 'productivity', desc: 'Plain-text tasks with tags and search.', kind: 'real', component: 'TodoManager' },
  { id: 'license_helper', cmd: 'license', name: 'License Helper', cat: 'productivity', desc: 'Detect or generate simple license text.', kind: 'real', component: 'LicenseHelper' },
  { id: 'weather', cmd: 'weather', name: 'Weather', cat: 'productivity', desc: 'Terminal forecast lookup with cache fallback.', kind: 'real', component: 'Weather' },
  { id: 'log_inspector', cmd: 'log-inspect', name: 'Log Inspector', cat: 'productivity', desc: 'Summarize warnings, errors, repeated lines.', kind: 'sim' },
  { id: 'ssl_checker', cmd: 'ssl', name: 'SSL Checker', cat: 'productivity', desc: 'Inspect certificate expiry, DNS, TLS support.', kind: 'sim' },
  { id: 'font_inspector', cmd: 'font', name: 'Font Inspector', cat: 'productivity', desc: 'Check glyph support and list fonts.', kind: 'sim' },
  { id: 'clipboard_history', cmd: 'clipboard', name: 'Clipboard History', cat: 'productivity', desc: 'Persistent clipboard log with pins & search.', kind: 'sim' },
  { id: 'yt_download', cmd: 'ytdl', name: 'YT Download', cat: 'productivity', desc: 'Download YouTube videos via yt-dlp.', kind: 'sim' },
];
