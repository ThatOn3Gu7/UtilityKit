export type Category =
  | "Core Suite"
  | "Developer Tools"
  | "System & Network"
  | "Files & Security"
  | "Productivity";

export interface Tool {
  command: string;
  name: string;
  category: Category;
  description: string;
  icon: string;
  options: { flag: string; description: string }[];
  examples: { code: string; label: string }[];
  related: string[];
}

export const CATEGORIES: Category[] = [
  "Core Suite",
  "Developer Tools",
  "System & Network",
  "Files & Security",
  "Productivity",
];

export const CATEGORY_SLUGS: Record<Category, string> = {
  "Core Suite": "core-suite",
  "Developer Tools": "developer-tools",
  "System & Network": "system-network",
  "Files & Security": "files-security",
  Productivity: "productivity",
};

export const SLUG_TO_CATEGORY: Record<string, Category> = {
  "core-suite": "Core Suite",
  "developer-tools": "Developer Tools",
  "system-network": "System & Network",
  "files-security": "Files & Security",
  productivity: "Productivity",
};

const TOOLS_RAW: Omit<Tool, "options" | "examples" | "related">[] = [
  // Core Suite
  {
    command: "apply",
    name: "Apply Changes",
    category: "Core Suite",
    icon: "⟳",
    description:
      "Enterprise-grade directory sync: dry-run preview, backup, apply, verify. Mirror delete, rollback on failure, concurrency locking, audit logging.",
  },
  {
    command: "rename",
    name: "Batch Rename",
    category: "Core Suite",
    icon: "✎",
    description:
      "Recursively rename or copy-rename files to a new extension. Preview budgets, transactional Ctrl+C rollback, safety exclusions for LICENSE/README/lockfiles.",
  },
  {
    command: "move",
    name: "Move in Batch",
    category: "Core Suite",
    icon: "⇄",
    description:
      "Bulk copy or move files with exclusion patterns, optional flattening, collision-safe renaming, and Ctrl+C rollback.",
  },
  {
    command: "cacheclean",
    name: "Cache Cleaner",
    category: "Core Suite",
    icon: "✦",
    description:
      "Multi-manager cache cleaner with a 17-plugin system (npm, pip, cargo, go, gem, apt, brew, etc). Two-confirmation deletion flow.",
  },
  {
    command: "symlink",
    name: "Symlink Manager",
    category: "Core Suite",
    icon: "⌁",
    description:
      "Transactional symlink creator with automatic backup of existing targets. Dry-run by default.",
  },
  {
    command: "disk",
    name: "Disk Analyzer",
    category: "Core Suite",
    icon: "◉",
    description:
      "Largest-items disk usage explorer with optional in-place archive creation. Skips .git and VCS metadata.",
  },
  // Developer Tools
  {
    command: "env",
    name: "Env Manager",
    category: "Developer Tools",
    icon: "⚙",
    description:
      ".env profile switching, key comparison against .env.example, syntax validation, gpg/openssl encrypt/decrypt.",
  },
  {
    command: "git",
    name: "Git Sweep",
    category: "Developer Tools",
    icon: "⎇",
    description:
      "Merged-branch detection, stash cleanup, git clean -fdx artifact sweep, git gc --prune=now. Safe preview before every action.",
  },
  {
    command: "scaffold",
    name: "Project Scaffold",
    category: "Developer Tools",
    icon: "⬡",
    description:
      "Starter project generator for Bash, Python Flask, Node CLI, and Go service stacks. Creates CI workflow, Dockerfile, Makefile, README.",
  },
  {
    command: "api",
    name: "API Tester",
    category: "Developer Tools",
    icon: "⇌",
    description:
      "One-off HTTP requests or saved/replayable profiles. Timing breakdown (DNS, TCP, TTFB, total), jq pretty-print, status-code coloring.",
  },
  {
    command: "ssh",
    name: "SSH Assistant",
    category: "Developer Tools",
    icon: "⌨",
    description:
      "Parses ~/.ssh/config, lists named hosts, connects by number, runs ssh-copy-id. Explains auth-only disconnects from GitHub/GitLab/Bitbucket.",
  },
  {
    command: "github",
    name: "GitHub Helper",
    category: "Developer Tools",
    icon: "◈",
    description:
      "Thin wrapper around gh CLI for auth status, PR list, issue list, and workflow run list.",
  },
  {
    command: "release",
    name: "Release Helper",
    category: "Developer Tools",
    icon: "◆",
    description:
      "Git status, recent commit log, optional tag creation with --apply guard.",
  },
  {
    command: "git-stats",
    name: "Git Stats",
    category: "Developer Tools",
    icon: "▦",
    description:
      "Commit counts by author, most-changed files, branch activity sorted by committer date.",
  },
  {
    command: "toc",
    name: "Markdown TOC",
    category: "Developer Tools",
    icon: "≡",
    description:
      "Insert or refresh TOC using marker comments. Relative link validation. Pipe-table column alignment via Python.",
  },
  {
    command: "links",
    name: "Link Checker",
    category: "Developer Tools",
    icon: "⛓",
    description:
      "Python-backed Markdown link validator. Local relative links by default; optional HTTP/HTTPS live checks.",
  },
  {
    command: "json",
    name: "JSON Explorer",
    category: "Developer Tools",
    icon: "{ }",
    description:
      "Python-backed JSON pretty-print, dot-path extraction, key listing, and structure summary.",
  },
  {
    command: "csv",
    name: "CSV Toolkit",
    category: "Developer Tools",
    icon: "⊞",
    description:
      "Python-backed CSV column header print and row preview with configurable head count.",
  },
  {
    command: "yaml",
    name: "YAML Toolkit",
    category: "Developer Tools",
    icon: "⋮",
    description:
      "Lint, validate, convert between YAML and JSON, extract values by dot-notation key, merge files, pretty-print.",
  },
  {
    command: "hooks",
    name: "Git Hooks",
    category: "Developer Tools",
    icon: "⚡",
    description:
      "Install, remove, list, and inspect git hook templates (pre-commit, commit-msg, pre-push, and more).",
  },
  {
    command: "tunnel",
    name: "SSH Tunnel",
    category: "Developer Tools",
    icon: "⇢",
    description:
      "Create, list, kill, restart persistent SSH port-forwards with config persistence.",
  },
  {
    command: "pdf",
    name: "PDF Toolkit",
    category: "Developer Tools",
    icon: "⎙",
    description:
      "Merge, split by page range, extract text, compress, rotate, count pages.",
  },
  {
    command: "regex",
    name: "Regex Lab",
    category: "Developer Tools",
    icon: ".*",
    description:
      "Live regex tester with match & substitution preview, named captures.",
  },
  {
    command: "bench",
    name: "HTTP Bench",
    category: "Developer Tools",
    icon: "⏱",
    description:
      "Lightweight HTTP benchmark reporting p50/p95/p99, RPS, and error rate.",
  },
  {
    command: "fwatch",
    name: "File Watcher",
    category: "Developer Tools",
    icon: "◎",
    description:
      "Run a command whenever files matching a glob change. Debounce, ignore rules, initial-run flag.",
  },
  // System & Network
  {
    command: "port",
    name: "Port Inspector",
    category: "System & Network",
    icon: "⊕",
    description:
      "Find which process owns a local TCP port via lsof or ss. Interface summary, optional SIGTERM.",
  },
  {
    command: "proc",
    name: "Process Killer",
    category: "System & Network",
    icon: "⊗",
    description:
      "RAM/swap bar chart, top-10 memory consumers, optional SIGTERM/SIGKILL by PID.",
  },
  {
    command: "docker",
    name: "Docker Janitor",
    category: "System & Network",
    icon: "⬡",
    description:
      "Preview and prune stopped containers, dangling images, and orphaned volumes.",
  },
  {
    command: "network",
    name: "Network Probe",
    category: "System & Network",
    icon: "⌖",
    description:
      "Ping, DNS lookup, public IP via curl, route tracing with traceroute/tracepath.",
  },
  {
    command: "cron",
    name: "Cron Manager",
    category: "System & Network",
    icon: "⧖",
    description:
      "List, add (with format validation), and remove crontab entries. Dry-run default.",
  },
  {
    command: "disk-health",
    name: "Disk Health",
    category: "System & Network",
    icon: "♥",
    description:
      "SMART health and attribute report via smartctl. Auto-detects first disk.",
  },
  {
    command: "service",
    name: "Service Watcher",
    category: "System & Network",
    icon: "◉",
    description:
      "HTTP endpoint status and response-time checks. Saved URL profiles, looping interval mode.",
  },
  {
    command: "tmux",
    name: "Tmux Session",
    category: "System & Network",
    icon: "▣",
    description: "Friendly wrapper for tmux list/new/attach/kill.",
  },
  {
    command: "toolbox",
    name: "Toolbox Audit",
    category: "System & Network",
    icon: "⊞",
    description:
      "Audits recommended CLI tools (fzf, rg, fd, bat, jq, gh, zoxide, tldr) and prints status.",
  },
  {
    command: "open-files",
    name: "Open Files",
    category: "System & Network",
    icon: "⌁",
    description:
      "Find processes using files, directories, or ports via lsof.",
  },
  {
    command: "battery",
    name: "Battery Doctor",
    category: "System & Network",
    icon: "⚡",
    description:
      "Battery and power diagnostics for Linux, macOS, and Termux where available.",
  },
  {
    command: "update",
    name: "Update Managers",
    category: "System & Network",
    icon: "↑",
    description:
      "Detect and update 60+ package managers (apt, brew, npm, pip, cargo, winget) with live spinner.",
  },
  {
    command: "dns",
    name: "DNS Probe",
    category: "System & Network",
    icon: "⌖",
    description:
      "Multi-resolver DNS queries and propagation checks across public resolvers.",
  },
  {
    command: "ipinfo",
    name: "IP Info",
    category: "System & Network",
    icon: "⊙",
    description:
      "Public/local IP, reverse DNS, ASN, GeoIP, WHOIS lookup.",
  },
  // Files & Security
  {
    command: "dup",
    name: "Duplicate Finder",
    category: "Files & Security",
    icon: "⊛",
    description:
      "Size-first, hash-second duplicate detection. Report, delete, or replace with hardlinks.",
  },
  {
    command: "ssl",
    name: "SSL Checker",
    category: "Files & Security",
    icon: "🔒",
    description:
      "Certificate expiry, DNS A/AAAA/MX/TXT records, legacy TLS 1.0/1.1 probe.",
  },
  {
    command: "shred",
    name: "Shredder",
    category: "Files & Security",
    icon: "✂",
    description:
      "Multi-pass overwrite using shred or /dev/urandom fallback. Configurable passes.",
  },
  {
    command: "media",
    name: "Media Convert",
    category: "Files & Security",
    icon: "⬡",
    description:
      "Batch image conversion via ImageMagick or ffmpeg. Video conversion via ffmpeg libx264. EXIF stripping.",
  },
  {
    command: "backup",
    name: "Backup Sync",
    category: "Files & Security",
    icon: "⎘",
    description:
      "Dry-run-first backup wrapper around rsync (with --delete support) or cp/find fallback.",
  },
  {
    command: "hash",
    name: "Hash Tools",
    category: "Files & Security",
    icon: "#",
    description:
      "Create and verify checksums for files and directory trees.",
  },
  {
    command: "archive",
    name: "Archive Manager",
    category: "Files & Security",
    icon: "⬡",
    description:
      "List, safely extract (path traversal guard), and create tar.gz or zip archives.",
  },
  {
    command: "dotenv",
    name: "Dotenv Vault",
    category: "Files & Security",
    icon: "⚿",
    description:
      "Encrypt individual .env values into ENC:: tokens using gpg symmetric encryption.",
  },
  {
    command: "secret",
    name: "Secret Scan",
    category: "Files & Security",
    icon: "⊘",
    description:
      "Scans a directory tree for leaked credentials via regex + entropy heuristics, respects .gitignore.",
  },
  {
    command: "image",
    name: "Image Tool",
    category: "Files & Security",
    icon: "⬛",
    description:
      "Resize, convert formats, strip EXIF metadata, optimize file size, generate thumbnails.",
  },
  {
    command: "snapshot",
    name: "System Snapshot",
    category: "Files & Security",
    icon: "⎕",
    description:
      "Collects a redacted diagnostic summary for support/debugging.",
  },
  // Productivity
  {
    command: "pass",
    name: "Password Gen",
    category: "Productivity",
    icon: "⚿",
    description:
      "XKCD-style passphrases from a 37-word list, or random strings from a 72-char charset. Entropy display.",
  },
  {
    command: "cheat",
    name: "Cheat Sheet",
    category: "Productivity",
    icon: "≡",
    description:
      "Personal markdown snippet store with tagging, search, and a persistent interactive loop.",
  },
  {
    command: "pomodoro",
    name: "Pomodoro",
    category: "Productivity",
    icon: "⏲",
    description:
      "Work/break cycle timer with a live progress bar and session log.",
  },
  {
    command: "todo",
    name: "Todo Manager",
    category: "Productivity",
    icon: "☑",
    description:
      "Plain-text TSV task tracker with tags, --done by line number, and --search.",
  },
  {
    command: "weather",
    name: "Weather",
    category: "Productivity",
    icon: "⛅",
    description:
      "Fetches current weather from wttr.in. Caches last result for offline fallback.",
  },
  {
    command: "search",
    name: "Project Search",
    category: "Productivity",
    icon: "⌕",
    description:
      "Text or filename search with rg to grep to find fallback chain.",
  },
  {
    command: "license",
    name: "License Helper",
    category: "Productivity",
    icon: "⚖",
    description:
      "Detects LICENSE*/COPYING* in current directory. Generates MIT or Apache 2.0 text.",
  },
  {
    command: "font",
    name: "Font Inspector",
    category: "Productivity",
    icon: "A",
    description:
      "Terminal glyph sample output. Optional fc-list font enumeration with filter.",
  },
  {
    command: "log-inspect",
    name: "Log Inspector",
    category: "Productivity",
    icon: "⊟",
    description:
      "Grep for errors/warnings/failures with configurable pattern. Top-10 repeated line frequency summary.",
  },
  {
    command: "qr",
    name: "QR Tool",
    category: "Productivity",
    icon: "⬛",
    description:
      "Encode text/URL/Wi-Fi/vCard to QR (PNG or terminal ASCII); decode from image.",
  },
  {
    command: "clipboard",
    name: "Clipboard History",
    category: "Productivity",
    icon: "⎘",
    description:
      "Persistent clipboard history with fuzzy search and pin support.",
  },
  {
    command: "uuid",
    name: "UUID Gen",
    category: "Productivity",
    icon: "⊞",
    description:
      "Generate UUID v4, v7 (time-ordered), ULID, NanoID, short IDs, hex strings, snowflake IDs.",
  },
  {
    command: "time",
    name: "Time Convert",
    category: "Productivity",
    icon: "⧗",
    description:
      "Epoch to ISO 8601 to human conversions. Cron expression to next N fire times. Timezone diff.",
  },
  {
    command: "ytdl",
    name: "YT Download",
    category: "Productivity",
    icon: "▶",
    description:
      "Download YouTube videos via yt-dlp with format selection, subtitles, audio extraction.",
  },
];

// Per-tool options and examples
const TOOL_DETAILS: Record<
  string,
  { options: Tool["options"]; examples: Tool["examples"]; related: string[] }
> = {
  apply: {
    options: [
      { flag: "--src <dir>", description: "Source directory to sync from" },
      { flag: "--dst <dir>", description: "Destination directory to sync into" },
      { flag: "--dry-run", description: "Preview changes without applying them" },
      { flag: "--backup", description: "Create a timestamped backup before applying" },
      { flag: "--mirror", description: "Enable mirror-delete (remove files not in src)" },
      { flag: "--verify", description: "Verify file integrity after apply" },
    ],
    examples: [
      { label: "Preview changes", code: "bash main.sh apply --src ./src --dst ./dst --dry-run" },
      { label: "Apply with backup", code: "bash main.sh apply --src ./src --dst ./dst --backup" },
      { label: "Mirror sync", code: "bash main.sh apply --src ./src --dst ./dst --mirror --verify" },
    ],
    related: ["rename", "move", "backup"],
  },
  rename: {
    options: [
      { flag: "--ext <new>", description: "Target extension to rename files to" },
      { flag: "--copy", description: "Copy-rename instead of in-place rename" },
      { flag: "--dry-run", description: "Preview all renames without making changes" },
      { flag: "--recursive", description: "Recurse into subdirectories" },
    ],
    examples: [
      { label: "Preview rename", code: "bash main.sh rename --ext .md --dry-run" },
      { label: "Copy-rename .txt to .md", code: "bash main.sh rename --ext .md --copy" },
      { label: "Recursive rename", code: "bash main.sh rename --ext .sh --recursive" },
    ],
    related: ["move", "apply", "dup"],
  },
  move: {
    options: [
      { flag: "--src <glob>", description: "Source glob pattern to match files" },
      { flag: "--dst <dir>", description: "Destination directory" },
      { flag: "--exclude <pattern>", description: "Exclusion pattern (repeatable)" },
      { flag: "--flatten", description: "Drop subdirectory structure at destination" },
      { flag: "--copy", description: "Copy files instead of moving them" },
    ],
    examples: [
      { label: "Move all logs", code: "bash main.sh move --src '*.log' --dst ./archive" },
      { label: "Copy with flatten", code: "bash main.sh move --src './src/**/*.ts' --dst ./out --copy --flatten" },
      { label: "Exclude node_modules", code: "bash main.sh move --src './**' --dst ./backup --exclude node_modules" },
    ],
    related: ["rename", "apply", "backup"],
  },
  cacheclean: {
    options: [
      { flag: "--list", description: "List detected caches and their sizes" },
      { flag: "--plugin <name>", description: "Run only a specific cache plugin (npm, pip, cargo, etc.)" },
      { flag: "--dry-run", description: "Show what would be deleted without deleting" },
      { flag: "--all", description: "Clean all detected caches (requires double confirmation)" },
    ],
    examples: [
      { label: "List all caches", code: "bash main.sh cacheclean --list" },
      { label: "Clean npm cache only", code: "bash main.sh cacheclean --plugin npm" },
      { label: "Dry-run all caches", code: "bash main.sh cacheclean --all --dry-run" },
    ],
    related: ["disk", "update", "toolbox"],
  },
  symlink: {
    options: [
      { flag: "--src <path>", description: "Source (link target) path" },
      { flag: "--dst <path>", description: "Destination (link name) path" },
      { flag: "--backup", description: "Backup any existing file at destination before linking" },
      { flag: "--apply", description: "Actually create the link (dry-run is default)" },
    ],
    examples: [
      { label: "Preview link creation", code: "bash main.sh symlink --src ./dotfiles/.bashrc --dst ~/.bashrc" },
      { label: "Create with backup", code: "bash main.sh symlink --src ./dotfiles/.vimrc --dst ~/.vimrc --backup --apply" },
    ],
    related: ["apply", "backup", "move"],
  },
  disk: {
    options: [
      { flag: "--dir <path>", description: "Directory to analyze (default: current)" },
      { flag: "--top <n>", description: "Show top N largest items (default: 20)" },
      { flag: "--archive", description: "Create a compressed archive of the largest items" },
      { flag: "--threshold <size>", description: "Only show items above this size (e.g. 100M)" },
    ],
    examples: [
      { label: "Analyze home directory", code: "bash main.sh disk --dir ~/ --top 20" },
      { label: "Find large files above 500M", code: "bash main.sh disk --dir / --threshold 500M" },
      { label: "Archive large items", code: "bash main.sh disk --dir ./build --archive" },
    ],
    related: ["cacheclean", "disk-health", "dup"],
  },
  env: {
    options: [
      { flag: "--dir <path>", description: "Directory containing .env files (default: .)" },
      { flag: "--compare", description: "Compare active .env against .env.example" },
      { flag: "--switch <profile>", description: "Switch to a named .env profile" },
      { flag: "--validate", description: "Syntax-validate the current .env file" },
      { flag: "--encrypt", description: "Encrypt the .env file with gpg or openssl" },
      { flag: "--decrypt", description: "Decrypt a previously encrypted .env file" },
    ],
    examples: [
      { label: "Compare with example", code: "bash main.sh env --dir . --compare" },
      { label: "Switch profile", code: "bash main.sh env --switch production" },
      { label: "Validate and encrypt", code: "bash main.sh env --validate && bash main.sh env --encrypt" },
    ],
    related: ["dotenv", "secret", "scaffold"],
  },
  git: {
    options: [
      { flag: "--sweep", description: "Remove merged local branches (preview first)" },
      { flag: "--stash-clean", description: "Drop all git stash entries" },
      { flag: "--artifacts", description: "Run git clean -fdx to remove untracked files" },
      { flag: "--gc", description: "Run git gc --prune=now on the repository" },
      { flag: "--apply", description: "Execute actions (dry-run is default)" },
    ],
    examples: [
      { label: "Preview merged branches", code: "bash main.sh git --sweep" },
      { label: "Full cleanup (apply)", code: "bash main.sh git --sweep --stash-clean --gc --apply" },
      { label: "Remove build artifacts", code: "bash main.sh git --artifacts --apply" },
    ],
    related: ["git-stats", "hooks", "release"],
  },
  scaffold: {
    options: [
      { flag: "--lang <stack>", description: "Project stack: bash, flask, node-cli, go-service" },
      { flag: "--name <name>", description: "Project name (used in README and Makefile)" },
      { flag: "--dir <path>", description: "Output directory (default: ./<name>)" },
      { flag: "--ci", description: "Include a GitHub Actions CI workflow" },
      { flag: "--docker", description: "Include a Dockerfile" },
    ],
    examples: [
      { label: "Scaffold a Node CLI project", code: "bash main.sh scaffold --lang node-cli --name my-tool" },
      { label: "Flask app with Docker and CI", code: "bash main.sh scaffold --lang flask --name api --docker --ci" },
      { label: "Go service scaffold", code: "bash main.sh scaffold --lang go-service --name svc" },
    ],
    related: ["git", "hooks", "env"],
  },
  api: {
    options: [
      { flag: "--url <url>", description: "Target URL to request" },
      { flag: "--method <method>", description: "HTTP method: GET, POST, PUT, DELETE (default: GET)" },
      { flag: "--header <k:v>", description: "Add a request header (repeatable)" },
      { flag: "--body <json>", description: "JSON request body" },
      { flag: "--profile <name>", description: "Load a saved request profile" },
      { flag: "--save <name>", description: "Save this request as a named profile" },
      { flag: "--timing", description: "Print DNS, TCP, TTFB, and total timing breakdown" },
    ],
    examples: [
      { label: "Simple GET", code: "bash main.sh api --url https://api.example.com/users --timing" },
      { label: "POST with JSON body", code: "bash main.sh api --url https://api.example.com/users --method POST --body '{\"name\":\"alice\"}'" },
      { label: "Save and replay a profile", code: "bash main.sh api --url https://api.example.com --save myapi\nbash main.sh api --profile myapi" },
    ],
    related: ["bench", "service", "json"],
  },
  ssh: {
    options: [
      { flag: "--list", description: "List all named hosts from ~/.ssh/config" },
      { flag: "--connect <n>", description: "Connect to host by list number" },
      { flag: "--copy-id <host>", description: "Run ssh-copy-id for a named host" },
      { flag: "--test <host>", description: "Test connectivity and auth method" },
    ],
    examples: [
      { label: "List configured hosts", code: "bash main.sh ssh --list" },
      { label: "Connect to host #3", code: "bash main.sh ssh --connect 3" },
      { label: "Copy SSH key to host", code: "bash main.sh ssh --copy-id myserver" },
    ],
    related: ["tunnel", "network", "github"],
  },
  github: {
    options: [
      { flag: "--auth", description: "Check gh CLI authentication status" },
      { flag: "--prs", description: "List open pull requests" },
      { flag: "--issues", description: "List open issues" },
      { flag: "--runs", description: "List recent workflow runs" },
      { flag: "--repo <owner/repo>", description: "Target a specific repository" },
    ],
    examples: [
      { label: "Check auth and list PRs", code: "bash main.sh github --auth && bash main.sh github --prs" },
      { label: "List issues for a repo", code: "bash main.sh github --issues --repo owner/repo" },
      { label: "Check workflow runs", code: "bash main.sh github --runs" },
    ],
    related: ["git", "release", "hooks"],
  },
  release: {
    options: [
      { flag: "--log", description: "Show recent commit log (default: last 10)" },
      { flag: "--status", description: "Show current git status" },
      { flag: "--tag <v>", description: "Create an annotated tag with the given version" },
      { flag: "--apply", description: "Actually push the tag (dry-run by default)" },
    ],
    examples: [
      { label: "Preview release state", code: "bash main.sh release --status --log" },
      { label: "Tag a release", code: "bash main.sh release --tag v1.2.0" },
      { label: "Tag and push", code: "bash main.sh release --tag v1.2.0 --apply" },
    ],
    related: ["git", "github", "git-stats"],
  },
  "git-stats": {
    options: [
      { flag: "--authors", description: "Show commit counts per author" },
      { flag: "--files", description: "Show most frequently changed files" },
      { flag: "--branches", description: "List branches sorted by most recent committer date" },
      { flag: "--since <date>", description: "Limit stats to commits after this date" },
    ],
    examples: [
      { label: "Author commit counts", code: "bash main.sh git-stats --authors" },
      { label: "Most changed files", code: "bash main.sh git-stats --files" },
      { label: "Branch activity", code: "bash main.sh git-stats --branches --since 2024-01-01" },
    ],
    related: ["git", "release", "hooks"],
  },
  toc: {
    options: [
      { flag: "--file <path>", description: "Markdown file to process" },
      { flag: "--apply", description: "Write the updated TOC back to the file" },
      { flag: "--check-links", description: "Validate relative links in the document" },
      { flag: "--align-tables", description: "Normalize pipe-table column widths (requires Python)" },
    ],
    examples: [
      { label: "Preview TOC", code: "bash main.sh toc README.md" },
      { label: "Apply TOC and check links", code: "bash main.sh toc README.md --apply --check-links" },
      { label: "Align tables and apply", code: "bash main.sh toc README.md --apply --align-tables" },
    ],
    related: ["links", "json", "scaffold"],
  },
  links: {
    options: [
      { flag: "--file <path>", description: "Markdown file or directory to scan" },
      { flag: "--http", description: "Also check live HTTP/HTTPS links (slow)" },
      { flag: "--report", description: "Output a structured report of broken links" },
    ],
    examples: [
      { label: "Check local links", code: "bash main.sh links README.md" },
      { label: "Check including HTTP", code: "bash main.sh links docs/ --http" },
      { label: "Save report", code: "bash main.sh links docs/ --http --report > link-report.txt" },
    ],
    related: ["toc", "json", "api"],
  },
  json: {
    options: [
      { flag: "<file>", description: "JSON file to process" },
      { flag: "--get <path>", description: "Extract value at dot-notation path (e.g. .user.name)" },
      { flag: "--keys", description: "List all top-level keys" },
      { flag: "--summary", description: "Print a structure summary (types, depth, array lengths)" },
      { flag: "--pretty", description: "Pretty-print with color (default when output is a tty)" },
    ],
    examples: [
      { label: "Pretty-print a file", code: "bash main.sh json package.json" },
      { label: "Extract a nested value", code: "bash main.sh json data.json --get .user.address.city" },
      { label: "Structure summary", code: "bash main.sh json package.json --summary" },
    ],
    related: ["yaml", "csv", "api"],
  },
  csv: {
    options: [
      { flag: "<file>", description: "CSV file to inspect" },
      { flag: "--headers", description: "Print column headers only" },
      { flag: "--head <n>", description: "Preview the first N rows (default: 10)" },
      { flag: "--delimiter <char>", description: "Field delimiter character (default: ,)" },
    ],
    examples: [
      { label: "Show headers", code: "bash main.sh csv data.csv --headers" },
      { label: "Preview first 20 rows", code: "bash main.sh csv data.csv --head 20" },
      { label: "Tab-delimited file", code: "bash main.sh csv data.tsv --delimiter $'\\t'" },
    ],
    related: ["json", "yaml", "log-inspect"],
  },
  yaml: {
    options: [
      { flag: "<file>", description: "YAML file to process" },
      { flag: "--lint", description: "Lint and validate the YAML file" },
      { flag: "--to-json", description: "Convert YAML to JSON output" },
      { flag: "--get <key>", description: "Extract value by dot-notation key" },
      { flag: "--merge <file2>", description: "Deep-merge another YAML file" },
    ],
    examples: [
      { label: "Lint a YAML file", code: "bash main.sh yaml config.yaml --lint" },
      { label: "Convert to JSON", code: "bash main.sh yaml config.yaml --to-json" },
      { label: "Extract a value", code: "bash main.sh yaml docker-compose.yaml --get .services.web.image" },
    ],
    related: ["json", "csv", "env"],
  },
  hooks: {
    options: [
      { flag: "--list", description: "List all installed git hooks in the current repo" },
      { flag: "--install <hook>", description: "Install a hook template (e.g. pre-commit)" },
      { flag: "--remove <hook>", description: "Remove an installed hook" },
      { flag: "--inspect <hook>", description: "Display the contents of a hook file" },
    ],
    examples: [
      { label: "List installed hooks", code: "bash main.sh hooks --list" },
      { label: "Install pre-commit hook", code: "bash main.sh hooks --install pre-commit" },
      { label: "Inspect commit-msg hook", code: "bash main.sh hooks --inspect commit-msg" },
    ],
    related: ["git", "scaffold", "release"],
  },
  tunnel: {
    options: [
      { flag: "--create", description: "Create a new persistent port-forward tunnel" },
      { flag: "--local <port>", description: "Local port to bind" },
      { flag: "--remote <host:port>", description: "Remote host and port to forward to" },
      { flag: "--via <ssh-host>", description: "SSH host to tunnel through" },
      { flag: "--list", description: "List all saved tunnel configs" },
      { flag: "--kill <name>", description: "Kill a named tunnel by name" },
    ],
    examples: [
      { label: "Create a tunnel", code: "bash main.sh tunnel --create --local 8080 --remote localhost:80 --via myserver" },
      { label: "List tunnels", code: "bash main.sh tunnel --list" },
      { label: "Kill a tunnel", code: "bash main.sh tunnel --kill prod-tunnel" },
    ],
    related: ["ssh", "network", "port"],
  },
  pdf: {
    options: [
      { flag: "--merge <files>", description: "Merge multiple PDF files into one" },
      { flag: "--split <range>", description: "Split PDF by page range (e.g. 1-3,5-7)" },
      { flag: "--text", description: "Extract plain text from PDF" },
      { flag: "--compress", description: "Compress PDF file size" },
      { flag: "--rotate <deg>", description: "Rotate all pages by degrees (90, 180, 270)" },
      { flag: "--pages", description: "Count total pages in PDF" },
    ],
    examples: [
      { label: "Merge PDFs", code: "bash main.sh pdf --merge a.pdf b.pdf c.pdf -o out.pdf" },
      { label: "Extract pages 2-5", code: "bash main.sh pdf --split 2-5 input.pdf" },
      { label: "Extract text", code: "bash main.sh pdf --text report.pdf" },
    ],
    related: ["image", "archive", "media"],
  },
  regex: {
    options: [
      { flag: "--pattern <regex>", description: "Regular expression pattern to test" },
      { flag: "--input <string>", description: "Input string to match against" },
      { flag: "--sub <replacement>", description: "Substitution pattern for replacement preview" },
      { flag: "--captures", description: "Show named and numbered capture groups" },
      { flag: "--file <path>", description: "Run pattern against lines in a file" },
    ],
    examples: [
      { label: "Test a pattern", code: "bash main.sh regex --pattern '^[a-z]+@[a-z]+\\.com$' --input 'user@example.com'" },
      { label: "Substitution preview", code: "bash main.sh regex --pattern '(\\d{4})' --input '2024' --sub '[year: \\1]'" },
      { label: "Match against file", code: "bash main.sh regex --pattern 'ERROR|WARN' --file app.log" },
    ],
    related: ["log-inspect", "search", "secret"],
  },
  bench: {
    options: [
      { flag: "--url <url>", description: "Target URL to benchmark" },
      { flag: "--requests <n>", description: "Total number of requests (default: 100)" },
      { flag: "--concurrency <n>", description: "Concurrent connections (default: 10)" },
      { flag: "--timeout <sec>", description: "Per-request timeout in seconds" },
    ],
    examples: [
      { label: "Quick benchmark", code: "bash main.sh bench --url https://example.com --requests 200" },
      { label: "High concurrency test", code: "bash main.sh bench --url https://api.example.com/health --concurrency 50 --requests 1000" },
    ],
    related: ["api", "service", "network"],
  },
  fwatch: {
    options: [
      { flag: "--glob <pattern>", description: "File glob pattern to watch" },
      { flag: "--cmd <command>", description: "Shell command to run on change" },
      { flag: "--debounce <ms>", description: "Debounce delay in milliseconds (default: 300)" },
      { flag: "--ignore <pattern>", description: "Glob patterns to ignore" },
      { flag: "--initial", description: "Run the command once before watching" },
    ],
    examples: [
      { label: "Rebuild on TS change", code: "bash main.sh fwatch --glob '**/*.ts' --cmd 'npm run build'" },
      { label: "Watch with ignore", code: "bash main.sh fwatch --glob '**/*.go' --cmd 'go test ./...' --ignore '*_test.go'" },
      { label: "Initial run + watch", code: "bash main.sh fwatch --glob '*.sh' --cmd 'bash lint.sh' --initial" },
    ],
    related: ["search", "regex", "git"],
  },
  port: {
    options: [
      { flag: "<port>", description: "TCP port number to inspect" },
      { flag: "--kill", description: "Send SIGTERM to the owning process" },
      { flag: "--interfaces", description: "Show a summary of all listening interfaces" },
    ],
    examples: [
      { label: "Who owns port 3000?", code: "bash main.sh port 3000" },
      { label: "Kill the process on port 8080", code: "bash main.sh port 8080 --kill" },
      { label: "List all listening interfaces", code: "bash main.sh port --interfaces" },
    ],
    related: ["proc", "network", "open-files"],
  },
  proc: {
    options: [
      { flag: "--top <n>", description: "Show top N memory consumers (default: 10)" },
      { flag: "--kill <pid>", description: "Send SIGTERM to the given PID" },
      { flag: "--force", description: "Use SIGKILL instead of SIGTERM" },
      { flag: "--chart", description: "Display RAM/swap bar chart" },
    ],
    examples: [
      { label: "Show memory chart", code: "bash main.sh proc --chart" },
      { label: "Top 20 processes", code: "bash main.sh proc --top 20" },
      { label: "Kill a process", code: "bash main.sh proc --kill 12345" },
    ],
    related: ["port", "open-files", "docker"],
  },
  docker: {
    options: [
      { flag: "--preview", description: "Preview what would be pruned (default)" },
      { flag: "--containers", description: "Prune stopped containers" },
      { flag: "--images", description: "Prune dangling images" },
      { flag: "--volumes", description: "Prune orphaned volumes" },
      { flag: "--all", description: "Prune containers, images, and volumes together" },
      { flag: "--apply", description: "Apply pruning (not just preview)" },
    ],
    examples: [
      { label: "Preview all prunable resources", code: "bash main.sh docker --preview" },
      { label: "Prune stopped containers", code: "bash main.sh docker --containers --apply" },
      { label: "Full prune", code: "bash main.sh docker --all --apply" },
    ],
    related: ["proc", "disk", "network"],
  },
  network: {
    options: [
      { flag: "--ping <host>", description: "Ping a host and report packet loss" },
      { flag: "--dns <host>", description: "DNS lookup for a hostname" },
      { flag: "--ip", description: "Show public IP via curl" },
      { flag: "--trace <host>", description: "Route trace using traceroute or tracepath" },
    ],
    examples: [
      { label: "Ping a host", code: "bash main.sh network --ping google.com" },
      { label: "Show public IP", code: "bash main.sh network --ip" },
      { label: "Trace route", code: "bash main.sh network --trace 8.8.8.8" },
    ],
    related: ["dns", "ipinfo", "port"],
  },
  cron: {
    options: [
      { flag: "--list", description: "List all current crontab entries with indices" },
      { flag: "--add <expr>", description: "Add a new cron entry (validates cron syntax)" },
      { flag: "--remove <n>", description: "Remove entry by line number" },
      { flag: "--dry-run", description: "Show what would change without modifying crontab" },
    ],
    examples: [
      { label: "List crontab entries", code: "bash main.sh cron --list" },
      { label: "Add a daily job", code: "bash main.sh cron --add '0 9 * * * /usr/local/bin/backup.sh'" },
      { label: "Remove entry 3", code: "bash main.sh cron --remove 3" },
    ],
    related: ["service", "pomodoro", "time"],
  },
  "disk-health": {
    options: [
      { flag: "--device <dev>", description: "Specific disk device (e.g. /dev/sda); auto-detects if omitted" },
      { flag: "--report", description: "Print full SMART attribute table" },
      { flag: "--test <type>", description: "Initiate a SMART self-test (short or long)" },
    ],
    examples: [
      { label: "Quick health check", code: "bash main.sh disk-health" },
      { label: "Full SMART report", code: "bash main.sh disk-health --report" },
      { label: "Check specific device", code: "bash main.sh disk-health --device /dev/nvme0n1" },
    ],
    related: ["disk", "snapshot", "battery"],
  },
  service: {
    options: [
      { flag: "--url <url>", description: "URL to check" },
      { flag: "--profile <name>", description: "Load saved URL profile" },
      { flag: "--save <name>", description: "Save the URL as a named profile" },
      { flag: "--interval <sec>", description: "Loop check every N seconds" },
      { flag: "--timeout <sec>", description: "Request timeout in seconds (default: 10)" },
    ],
    examples: [
      { label: "One-off check", code: "bash main.sh service --url https://example.com" },
      { label: "Loop monitoring", code: "bash main.sh service --url https://api.example.com/health --interval 30" },
      { label: "Save and reuse profile", code: "bash main.sh service --url https://example.com --save prod" },
    ],
    related: ["bench", "api", "network"],
  },
  tmux: {
    options: [
      { flag: "--list", description: "List all active tmux sessions" },
      { flag: "--new <name>", description: "Create a new named session" },
      { flag: "--attach <name>", description: "Attach to an existing session" },
      { flag: "--kill <name>", description: "Kill a named session" },
    ],
    examples: [
      { label: "List sessions", code: "bash main.sh tmux --list" },
      { label: "Create a new session", code: "bash main.sh tmux --new work" },
      { label: "Attach to session", code: "bash main.sh tmux --attach work" },
    ],
    related: ["ssh", "tunnel", "proc"],
  },
  toolbox: {
    options: [
      { flag: "--install-missing", description: "Attempt to install missing tools via detected package manager" },
      { flag: "--json", description: "Output audit results as JSON" },
    ],
    examples: [
      { label: "Run audit", code: "bash main.sh toolbox" },
      { label: "Audit as JSON", code: "bash main.sh toolbox --json" },
    ],
    related: ["update", "cacheclean", "snapshot"],
  },
  "open-files": {
    options: [
      { flag: "--path <path>", description: "Find processes using a specific file or directory" },
      { flag: "--port <n>", description: "Find processes using a specific port" },
      { flag: "--pid <n>", description: "List all files opened by a specific PID" },
    ],
    examples: [
      { label: "Who has this file open?", code: "bash main.sh open-files --path /var/log/app.log" },
      { label: "Files on port 80", code: "bash main.sh open-files --port 80" },
      { label: "All files by PID", code: "bash main.sh open-files --pid 1234" },
    ],
    related: ["port", "proc", "network"],
  },
  battery: {
    options: [
      { flag: "--status", description: "Current charge level and charging state" },
      { flag: "--history", description: "Battery usage history (where available)" },
      { flag: "--power", description: "AC adapter and power consumption info" },
    ],
    examples: [
      { label: "Battery status", code: "bash main.sh battery --status" },
      { label: "Power diagnostics", code: "bash main.sh battery --power" },
    ],
    related: ["disk-health", "snapshot", "proc"],
  },
  update: {
    options: [
      { flag: "--list", description: "List detected package managers without updating" },
      { flag: "--manager <name>", description: "Update only a specific package manager" },
      { flag: "--dry-run", description: "Show what would be updated without running" },
    ],
    examples: [
      { label: "Detect package managers", code: "bash main.sh update --list" },
      { label: "Update everything", code: "bash main.sh update" },
      { label: "Update npm only", code: "bash main.sh update --manager npm" },
    ],
    related: ["toolbox", "cacheclean", "docker"],
  },
  dns: {
    options: [
      { flag: "<hostname>", description: "Hostname to resolve" },
      { flag: "--type <type>", description: "Record type: A, AAAA, MX, TXT, NS, CNAME (default: A)" },
      { flag: "--resolvers", description: "Query multiple public resolvers for propagation check" },
      { flag: "--propagation", description: "Check DNS propagation across 8.8.8.8, 1.1.1.1, and others" },
    ],
    examples: [
      { label: "A record lookup", code: "bash main.sh dns example.com" },
      { label: "MX record lookup", code: "bash main.sh dns example.com --type MX" },
      { label: "Propagation check", code: "bash main.sh dns example.com --propagation" },
    ],
    related: ["network", "ipinfo", "ssl"],
  },
  ipinfo: {
    options: [
      { flag: "--public", description: "Show public IP address" },
      { flag: "--local", description: "Show local/private IP addresses" },
      { flag: "--whois <ip>", description: "WHOIS lookup for an IP address" },
      { flag: "--geo <ip>", description: "GeoIP location for an IP address" },
      { flag: "--asn <ip>", description: "ASN info for an IP address" },
    ],
    examples: [
      { label: "Show public IP", code: "bash main.sh ipinfo --public" },
      { label: "GeoIP info", code: "bash main.sh ipinfo --geo 8.8.8.8" },
      { label: "WHOIS lookup", code: "bash main.sh ipinfo --whois 1.1.1.1" },
    ],
    related: ["network", "dns", "ssl"],
  },
  dup: {
    options: [
      { flag: "--dir <path>", description: "Directory to scan for duplicates" },
      { flag: "--report", description: "Print duplicate report without deleting" },
      { flag: "--delete", description: "Delete duplicate files (keeps first occurrence)" },
      { flag: "--hardlink", description: "Replace duplicates with hardlinks" },
      { flag: "--min-size <bytes>", description: "Only consider files above this size" },
    ],
    examples: [
      { label: "Scan for duplicates", code: "bash main.sh dup --dir ~/Downloads --report" },
      { label: "Replace with hardlinks", code: "bash main.sh dup --dir ./assets --hardlink" },
      { label: "Delete large duplicates", code: "bash main.sh dup --dir . --delete --min-size 1048576" },
    ],
    related: ["disk", "hash", "shred"],
  },
  ssl: {
    options: [
      { flag: "<hostname>", description: "Hostname to inspect" },
      { flag: "--expiry", description: "Check certificate expiry date" },
      { flag: "--dns", description: "Check A, AAAA, MX, and TXT records" },
      { flag: "--tls-legacy", description: "Probe for legacy TLS 1.0/1.1 support" },
      { flag: "--chain", description: "Display full certificate chain" },
    ],
    examples: [
      { label: "Full SSL check", code: "bash main.sh ssl example.com" },
      { label: "Expiry only", code: "bash main.sh ssl example.com --expiry" },
      { label: "Legacy TLS probe", code: "bash main.sh ssl example.com --tls-legacy" },
    ],
    related: ["dns", "network", "ipinfo"],
  },
  shred: {
    options: [
      { flag: "<file>", description: "File to securely overwrite and delete" },
      { flag: "--passes <n>", description: "Number of overwrite passes (default: 3)" },
      { flag: "--zero", description: "Add a final zero-fill pass" },
      { flag: "--dry-run", description: "Show what would be shredded without deleting" },
    ],
    examples: [
      { label: "Shred a file", code: "bash main.sh shred secrets.txt" },
      { label: "7-pass shred with zero", code: "bash main.sh shred sensitive.key --passes 7 --zero" },
      { label: "Dry-run preview", code: "bash main.sh shred data.csv --dry-run" },
    ],
    related: ["secret", "hash", "dup"],
  },
  media: {
    options: [
      { flag: "--src <path>", description: "Source file or directory" },
      { flag: "--format <fmt>", description: "Target image format: jpg, png, webp, avif" },
      { flag: "--video-codec <codec>", description: "Video codec: libx264, libx265 (default: libx264)" },
      { flag: "--strip-exif", description: "Remove EXIF metadata from output files" },
      { flag: "--quality <n>", description: "Output quality 1-100" },
    ],
    examples: [
      { label: "Convert images to WebP", code: "bash main.sh media --src ./photos --format webp --strip-exif" },
      { label: "Convert video", code: "bash main.sh media --src input.mp4 --video-codec libx265" },
      { label: "Batch image conversion", code: "bash main.sh media --src ./raw --format jpg --quality 85" },
    ],
    related: ["image", "pdf", "archive"],
  },
  backup: {
    options: [
      { flag: "--src <path>", description: "Source directory to back up" },
      { flag: "--dst <path>", description: "Backup destination path" },
      { flag: "--delete", description: "Pass --delete to rsync (mirror mode)" },
      { flag: "--dry-run", description: "Preview what would be transferred (default)" },
      { flag: "--exclude <pattern>", description: "Exclude pattern (repeatable)" },
    ],
    examples: [
      { label: "Preview backup", code: "bash main.sh backup --src ~/projects --dst /mnt/backup/projects" },
      { label: "Mirror backup", code: "bash main.sh backup --src ~/projects --dst /mnt/backup/projects --delete --apply" },
      { label: "Exclude build dirs", code: "bash main.sh backup --src . --dst /backup --exclude node_modules --exclude .git" },
    ],
    related: ["apply", "symlink", "archive"],
  },
  hash: {
    options: [
      { flag: "<file>", description: "File to hash" },
      { flag: "--algo <algo>", description: "Hash algorithm: md5, sha1, sha256, sha512 (default: sha256)" },
      { flag: "--verify <hash>", description: "Verify file against a known hash" },
      { flag: "--dir <path>", description: "Hash all files in a directory tree" },
      { flag: "--output <file>", description: "Write checksums to a file" },
    ],
    examples: [
      { label: "Hash a file", code: "bash main.sh hash archive.tar.gz" },
      { label: "Verify integrity", code: "bash main.sh hash archive.tar.gz --verify abc123..." },
      { label: "Hash a directory tree", code: "bash main.sh hash --dir ./dist --output checksums.sha256" },
    ],
    related: ["shred", "dup", "archive"],
  },
  archive: {
    options: [
      { flag: "--create <name>", description: "Create an archive from a directory or file list" },
      { flag: "--extract <file>", description: "Extract an archive (path traversal guarded)" },
      { flag: "--list <file>", description: "List contents of an archive without extracting" },
      { flag: "--format <fmt>", description: "Archive format: tar.gz or zip (default: tar.gz)" },
    ],
    examples: [
      { label: "Create a tar.gz", code: "bash main.sh archive --create project.tar.gz ./src" },
      { label: "List archive contents", code: "bash main.sh archive --list project.tar.gz" },
      { label: "Safe extraction", code: "bash main.sh archive --extract package.tar.gz" },
    ],
    related: ["backup", "hash", "disk"],
  },
  dotenv: {
    options: [
      { flag: "--file <path>", description: ".env file to process (default: .env)" },
      { flag: "--encrypt-key <key>", description: "Encrypt the value of a specific key" },
      { flag: "--decrypt-key <key>", description: "Decrypt an ENC:: token value" },
      { flag: "--all", description: "Encrypt all values in the .env file" },
    ],
    examples: [
      { label: "Encrypt a single key", code: "bash main.sh dotenv --encrypt-key DATABASE_URL" },
      { label: "Decrypt a key", code: "bash main.sh dotenv --decrypt-key DATABASE_URL" },
      { label: "Encrypt all values", code: "bash main.sh dotenv --file .env.production --all" },
    ],
    related: ["env", "secret", "hash"],
  },
  secret: {
    options: [
      { flag: "--dir <path>", description: "Directory to scan (default: .)" },
      { flag: "--entropy", description: "Enable entropy-based high-entropy string detection" },
      { flag: "--gitignore", description: "Respect .gitignore rules (default: on)" },
      { flag: "--report <file>", description: "Write findings to a file" },
    ],
    examples: [
      { label: "Scan current project", code: "bash main.sh secret --dir ." },
      { label: "Scan with entropy check", code: "bash main.sh secret --dir . --entropy" },
      { label: "Save report", code: "bash main.sh secret --dir ./src --report findings.txt" },
    ],
    related: ["dotenv", "env", "shred"],
  },
  image: {
    options: [
      { flag: "--src <file>", description: "Source image file or directory" },
      { flag: "--resize <WxH>", description: "Resize to dimensions (e.g. 800x600)" },
      { flag: "--format <fmt>", description: "Convert to format: jpg, png, webp, avif" },
      { flag: "--strip-exif", description: "Remove EXIF metadata" },
      { flag: "--optimize", description: "Optimize file size with minimal quality loss" },
      { flag: "--thumbnail <WxH>", description: "Generate a thumbnail at given dimensions" },
    ],
    examples: [
      { label: "Resize an image", code: "bash main.sh image --src photo.jpg --resize 1920x1080" },
      { label: "Convert and strip EXIF", code: "bash main.sh image --src photo.jpg --format webp --strip-exif" },
      { label: "Generate thumbnails", code: "bash main.sh image --src ./gallery --thumbnail 200x200" },
    ],
    related: ["media", "pdf", "archive"],
  },
  snapshot: {
    options: [
      { flag: "--output <file>", description: "Write snapshot to a file (default: stdout)" },
      { flag: "--redact", description: "Redact sensitive values from output (default: on)" },
      { flag: "--no-network", description: "Skip network interface section" },
    ],
    examples: [
      { label: "Collect diagnostic snapshot", code: "bash main.sh snapshot" },
      { label: "Save to file", code: "bash main.sh snapshot --output diagnostics.txt" },
    ],
    related: ["disk-health", "battery", "toolbox"],
  },
  pass: {
    options: [
      { flag: "--mode <mode>", description: "Generation mode: passphrase or string" },
      { flag: "--words <n>", description: "Number of words for passphrase mode (default: 4)" },
      { flag: "--length <n>", description: "Character length for string mode (default: 24)" },
      { flag: "--count <n>", description: "Generate N passwords at once" },
      { flag: "--entropy", description: "Display entropy in bits alongside the result" },
    ],
    examples: [
      { label: "XKCD-style passphrase", code: "bash main.sh pass --mode passphrase --words 6" },
      { label: "Random string", code: "bash main.sh pass --mode string --length 32" },
      { label: "Batch generation", code: "bash main.sh pass --mode passphrase --count 5 --entropy" },
    ],
    related: ["uuid", "secret", "dotenv"],
  },
  cheat: {
    options: [
      { flag: "--add <tag>", description: "Add a new snippet with a tag" },
      { flag: "--search <query>", description: "Search snippets by keyword" },
      { flag: "--tag <tag>", description: "Filter snippets by tag" },
      { flag: "--list", description: "List all stored snippets" },
      { flag: "--delete <n>", description: "Delete snippet by index" },
    ],
    examples: [
      { label: "Add a snippet", code: "bash main.sh cheat --add git" },
      { label: "Search snippets", code: "bash main.sh cheat --search 'docker prune'" },
      { label: "Filter by tag", code: "bash main.sh cheat --tag networking" },
    ],
    related: ["todo", "search", "log-inspect"],
  },
  pomodoro: {
    options: [
      { flag: "--work <min>", description: "Work session duration in minutes (default: 25)" },
      { flag: "--break <min>", description: "Break duration in minutes (default: 5)" },
      { flag: "--sessions <n>", description: "Number of sessions before long break (default: 4)" },
      { flag: "--log <file>", description: "Append session log to a file" },
    ],
    examples: [
      { label: "Start a standard Pomodoro", code: "bash main.sh pomodoro" },
      { label: "Custom work/break times", code: "bash main.sh pomodoro --work 50 --break 10" },
      { label: "Log sessions to file", code: "bash main.sh pomodoro --log ~/pomodoro.log" },
    ],
    related: ["todo", "time", "cron"],
  },
  todo: {
    options: [
      { flag: "--add <task>", description: "Add a new task" },
      { flag: "--tag <tag>", description: "Tag a task when adding" },
      { flag: "--done <n>", description: "Mark task at line N as done" },
      { flag: "--search <query>", description: "Search tasks by keyword" },
      { flag: "--list", description: "List all tasks (default)" },
      { flag: "--delete <n>", description: "Delete task at line N" },
    ],
    examples: [
      { label: "Add a task", code: "bash main.sh todo --add 'Write release notes' --tag docs" },
      { label: "Mark task as done", code: "bash main.sh todo --done 3" },
      { label: "Search tasks", code: "bash main.sh todo --search 'release'" },
    ],
    related: ["cheat", "pomodoro", "time"],
  },
  weather: {
    options: [
      { flag: "--location <loc>", description: "City name or coordinates (default: auto-detect)" },
      { flag: "--format <fmt>", description: "Output format: default, compact, json" },
      { flag: "--no-cache", description: "Bypass cached result and fetch fresh data" },
    ],
    examples: [
      { label: "Current weather", code: "bash main.sh weather" },
      { label: "Weather for a city", code: "bash main.sh weather --location 'New York'" },
      { label: "Compact output", code: "bash main.sh weather --format compact" },
    ],
    related: ["network", "ipinfo", "time"],
  },
  search: {
    options: [
      { flag: "<query>", description: "Search term or filename pattern" },
      { flag: "--dir <path>", description: "Directory to search in (default: .)" },
      { flag: "--filename", description: "Search by filename instead of content" },
      { flag: "--type <ext>", description: "Limit to files of this extension" },
      { flag: "--ignore <pattern>", description: "Exclude patterns from search" },
    ],
    examples: [
      { label: "Search file contents", code: "bash main.sh search 'TODO' --dir ./src" },
      { label: "Find files by name", code: "bash main.sh search '*.config.ts' --filename" },
      { label: "Type-filtered search", code: "bash main.sh search 'import' --type ts --dir ./src" },
    ],
    related: ["regex", "log-inspect", "cheat"],
  },
  license: {
    options: [
      { flag: "--detect", description: "Detect existing license in the current directory" },
      { flag: "--generate <type>", description: "Generate license text: mit or apache2" },
      { flag: "--author <name>", description: "Author name to embed in generated license" },
      { flag: "--year <year>", description: "Copyright year (default: current year)" },
    ],
    examples: [
      { label: "Detect license", code: "bash main.sh license --detect" },
      { label: "Generate MIT license", code: "bash main.sh license --generate mit --author 'Jane Doe'" },
      { label: "Generate Apache 2.0", code: "bash main.sh license --generate apache2 --author 'Jane Doe' --year 2025" },
    ],
    related: ["scaffold", "github", "release"],
  },
  font: {
    options: [
      { flag: "--sample", description: "Print a glyph/character sample to the terminal" },
      { flag: "--list", description: "Enumerate installed fonts via fc-list" },
      { flag: "--filter <query>", description: "Filter fc-list output by font name" },
    ],
    examples: [
      { label: "Glyph sample", code: "bash main.sh font --sample" },
      { label: "List all fonts", code: "bash main.sh font --list" },
      { label: "Filter fonts", code: "bash main.sh font --list --filter Mono" },
    ],
    related: ["toolbox", "snapshot", "todo"],
  },
  "log-inspect": {
    options: [
      { flag: "--file <path>", description: "Log file to inspect" },
      { flag: "--pattern <regex>", description: "Pattern to match (default: ERROR|WARN|FAIL)" },
      { flag: "--top <n>", description: "Show top N repeated lines (default: 10)" },
      { flag: "--since <time>", description: "Only show entries after this time" },
    ],
    examples: [
      { label: "Inspect a log file", code: "bash main.sh log-inspect --file /var/log/syslog" },
      { label: "Custom pattern", code: "bash main.sh log-inspect --file app.log --pattern 'CRITICAL|FATAL'" },
      { label: "Top repeated errors", code: "bash main.sh log-inspect --file app.log --top 20" },
    ],
    related: ["search", "regex", "service"],
  },
  qr: {
    options: [
      { flag: "--encode <text>", description: "Text or URL to encode as QR code" },
      { flag: "--type <type>", description: "Content type: url, wifi, vcard (default: url)" },
      { flag: "--output <file>", description: "Save QR as PNG (default: terminal ASCII)" },
      { flag: "--decode <file>", description: "Decode a QR code from an image file" },
    ],
    examples: [
      { label: "QR in terminal", code: "bash main.sh qr --encode 'https://example.com'" },
      { label: "Save as PNG", code: "bash main.sh qr --encode 'https://example.com' --output qr.png" },
      { label: "Decode from image", code: "bash main.sh qr --decode qr.png" },
    ],
    related: ["pass", "image", "uuid"],
  },
  clipboard: {
    options: [
      { flag: "--list", description: "List clipboard history entries" },
      { flag: "--search <query>", description: "Fuzzy search clipboard history" },
      { flag: "--pin <n>", description: "Pin entry N to prevent eviction" },
      { flag: "--copy <n>", description: "Copy history entry N back to clipboard" },
      { flag: "--clear", description: "Clear entire clipboard history" },
    ],
    examples: [
      { label: "List history", code: "bash main.sh clipboard --list" },
      { label: "Search history", code: "bash main.sh clipboard --search 'localhost'" },
      { label: "Re-copy entry 3", code: "bash main.sh clipboard --copy 3" },
    ],
    related: ["cheat", "search", "todo"],
  },
  uuid: {
    options: [
      { flag: "--type <type>", description: "ID type: v4, v7, ulid, nanoid, short, hex, snowflake" },
      { flag: "--count <n>", description: "Generate N IDs at once (default: 1)" },
      { flag: "--no-hyphens", description: "Output UUID without hyphen separators" },
    ],
    examples: [
      { label: "UUID v4", code: "bash main.sh uuid --type v4" },
      { label: "Time-ordered UUID v7", code: "bash main.sh uuid --type v7 --count 5" },
      { label: "ULID", code: "bash main.sh uuid --type ulid" },
    ],
    related: ["pass", "hash", "qr"],
  },
  time: {
    options: [
      { flag: "--epoch <n>", description: "Convert Unix epoch timestamp to ISO 8601" },
      { flag: "--iso <datetime>", description: "Convert ISO 8601 datetime to epoch" },
      { flag: "--cron <expr>", description: "Show next N fire times for a cron expression" },
      { flag: "--tz <zone1,zone2>", description: "Show time diff between two timezones" },
      { flag: "--next <n>", description: "Number of cron fire times to show (default: 5)" },
    ],
    examples: [
      { label: "Epoch to ISO", code: "bash main.sh time --epoch 1700000000" },
      { label: "Cron next fires", code: "bash main.sh time --cron '0 9 * * 1-5' --next 5" },
      { label: "Timezone diff", code: "bash main.sh time --tz 'UTC,America/New_York'" },
    ],
    related: ["cron", "pomodoro", "weather"],
  },
  ytdl: {
    options: [
      { flag: "--url <url>", description: "YouTube video or playlist URL" },
      { flag: "--format <fmt>", description: "Format selector (e.g. bestvideo+bestaudio, mp4)" },
      { flag: "--audio-only", description: "Extract audio only (outputs mp3)" },
      { flag: "--subtitles", description: "Download subtitles alongside video" },
      { flag: "--output <tmpl>", description: "Output filename template" },
    ],
    examples: [
      { label: "Download best quality", code: "bash main.sh ytdl --url 'https://youtube.com/watch?v=dQw4w9WgXcQ'" },
      { label: "Audio only", code: "bash main.sh ytdl --url 'https://youtube.com/watch?v=...' --audio-only" },
      { label: "Download with subtitles", code: "bash main.sh ytdl --url 'https://youtube.com/watch?v=...' --subtitles" },
    ],
    related: ["media", "image", "clipboard"],
  },
};

// Merge raw tool data with per-tool details
export const TOOLS: Tool[] = TOOLS_RAW.map((tool) => {
  const details = TOOL_DETAILS[tool.command] ?? {
    options: [
      { flag: "--help", description: "Show full usage information" },
      { flag: "--dry-run", description: "Preview actions without applying changes" },
    ],
    examples: [
      { label: "Run interactively", code: `bash main.sh ${tool.command}` },
      { label: "Show help", code: `bash main.sh ${tool.command} --help` },
    ],
    related: [],
  };
  return { ...tool, ...details };
});

export const TOOLS_BY_COMMAND: Record<string, Tool> = Object.fromEntries(
  TOOLS.map((t) => [t.command, t])
);

export const TOOLS_BY_CATEGORY: Record<Category, Tool[]> = {
  "Core Suite": TOOLS.filter((t) => t.category === "Core Suite"),
  "Developer Tools": TOOLS.filter((t) => t.category === "Developer Tools"),
  "System & Network": TOOLS.filter((t) => t.category === "System & Network"),
  "Files & Security": TOOLS.filter((t) => t.category === "Files & Security"),
  Productivity: TOOLS.filter((t) => t.category === "Productivity"),
};
