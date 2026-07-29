// Multi-scenario terminal playback scripts for simulated tools.
// Each tool maps to an object of scenarios, each with { label, icon?, desc?, steps[] }.
// Scenario step types: type, line, lines, progress, pause
// Color constants match terminal-shell.css

const D = "uk-dim";
const C = "uk-cyan";
const Y = "uk-yellow";
const R = "uk-red";
const OK = "uk-line";

export const SIM_SCRIPTS = {

  // ──────────────────────────────────────────────
  // C O R E   S U I T E
  // ──────────────────────────────────────────────

  apply_changes: {
    default: {
      label: "Dry-Run",
      icon: "🔍",
      desc: "Default dry-run preview shows planned changes without applying",
      steps: [
        { type: "type", text: "bash main.sh apply /src/updated ./target" },
        { type: "line", text: "Source: /src/updated", cls: D, delay: 200 },
        { type: "line", text: "Target: ./target", cls: D },
        { type: "progress", label: "Scanning source and target trees…", ms: 900 },
        { type: "lines", items: [{ text: "✚ CREATE  modules/_new_tool/_new_tool.sh" }, { text: "↻ UPDATE  lib/uk_common.sh" }, { text: "✖ DELETE  modules/_old_tool/_old_tool.sh" }], stagger: 140 },
        { type: "line", text: "Detected 3 change(s).", cls: D, delay: 200 },
        { type: "line", text: "Dry-run complete — use --apply to execute.", cls: Y },
      ]
    },
    apply_success: {
      label: "Apply Success",
      icon: "✔",
      desc: "Successful apply with backup and verification",
      steps: [
        { type: "type", text: "bash main.sh apply /src/updated ./target --apply --mirror" },
        { type: "line", text: "Source: /src/updated", cls: D, delay: 200 },
        { type: "line", text: "Target: ./target", cls: D },
        { type: "progress", label: "Scanning source and target trees…", ms: 800 },
        { type: "line", text: "Detected 3 change(s).", cls: D, delay: 150 },
        { type: "progress", label: "Creating pre-apply backup archive…", ms: 700 },
        { type: "line", text: "Type APPLY to update the target directory:", cls: D, delay: 300 },
        { type: "type", text: "APPLY", cls: C },
        { type: "progress", label: "Applying 3 change(s)…", ms: 1000 },
        { type: "line", text: "✔ Applied 3 change(s).", cls: OK },
        { type: "line", text: "✔ Verification succeeded: target now matches source.", delay: 250 },
      ]
    },
    apply_failure: {
      label: "Apply Failure",
      icon: "✖",
      desc: "Mid-apply failure triggers rollback prompt",
      steps: [
        { type: "type", text: "bash main.sh apply /src/updated ./target --apply" },
        { type: "progress", label: "Scanning source and target…", ms: 700 },
        { type: "line", text: "Detected 3 change(s).", cls: D, delay: 150 },
        { type: "type", text: "APPLY", delay: 300 },
        { type: "progress", label: "Copying changes…", ms: 600 },
        { type: "line", text: "✖ Error copying ./target/lib/uk_common.sh", cls: R, delay: 200 },
        { type: "line", text: "✖ Verification failed: 1 difference(s) remain.", cls: R },
        { type: "line", text: "Type ROLLBACK to restore target from backup:", cls: Y, delay: 300 },
        { type: "type", text: "ROLLBACK", delay: 400 },
        { type: "progress", label: "Restoring from backup…", ms: 800 },
        { type: "line", text: "✔ Rollback complete — target restored to previous state.", cls: OK },
      ]
    },
    interrupted: {
      label: "Interrupted",
      icon: "⚠",
      desc: "User sends SIGINT during sync operation",
      steps: [
        { type: "type", text: "bash main.sh apply /src/updated ./target --apply" },
        { type: "type", text: "APPLY", delay: 300 },
        { type: "progress", label: "Applying changes…", ms: 500 },
        { type: "line", text: "^C⏎", cls: R, delay: 100 },
        { type: "line", text: "SIGINT received — aborting.", cls: R, delay: 200 },
        { type: "line", text: "⚠ WARNING: Target directory may be in an inconsistent state.", cls: Y },
        { type: "line", text: "Type ROLLBACK to restore from backup or ABORT to leave as-is:", cls: Y, delay: 300 },
        { type: "type", text: "ROLLBACK" },
        { type: "progress", label: "Restoring from backup…", ms: 600 },
        { type: "line", text: "✔ Rollback complete.", cls: OK },
      ]
    },
    interactive_wizard: {
      label: "Interactive",
      icon: "🎛",
      desc: "Launch the arrow-key directory browser wizard",
      steps: [
        { type: "type", text: "bash main.sh apply --interactive" },
        { type: "line", text: "", delay: 100 },
        { type: "line", text: "╭── Step 1: Pick SOURCE directory ──────────────────────╮", cls: C, delay: 200 },
        { type: "lines", items: [{ text: "  ○  /home/user/projects" }, { text: "  ●  /home/user/projects/src" }, { text: "  ○  /home/user/projects/docs" }], stagger: 100 },
        { type: "line", text: "  Using ↑↓ arrows, Enter to confirm", cls: D, delay: 200 },
        { type: "pause", ms: 300 },
        { type: "line", text: "╭── Step 2: Pick TARGET directory ──────────────────────╮", cls: C, delay: 200 },
        { type: "lines", items: [{ text: "  ●  ./deploy" }, { text: "  ○  ./backup" }, { text: "  ○  ~/dest" }], stagger: 100 },
        { type: "line", text: "  Using ↑↓ arrows, Enter to confirm", cls: D, delay: 200 },
        { type: "pause", ms: 300 },
        { type: "line", text: "Apply changes now? [Y/n] y", cls: D },
        { type: "progress", label: "Processing…", ms: 800 },
        { type: "line", text: "✔ Applied 3 change(s).", cls: OK },
      ]
    },
    mirror_sync: {
      label: "Mirror Sync",
      icon: "🔄",
      desc: "Mirror mode deletes target files not present in source",
      steps: [
        { type: "type", text: "bash main.sh apply /src/clean ./target --apply --mirror" },
        { type: "line", text: "Source: /src/clean", cls: D, delay: 200 },
        { type: "line", text: "Target: ./target", cls: D },
        { type: "line", text: "⚠ MIRROR enabled — files in target not in source will be DELETED.", cls: Y, delay: 250 },
        { type: "progress", label: "Scanning…", ms: 800 },
        { type: "lines", items: [{ text: "✚ CREATE  src/readme.md" }, { text: "✖ DELETE  target/old_config.cfg" }, { text: "✖ DELETE  target/legacy_backup/" }], stagger: 140 },
        { type: "line", text: "Type APPLY to mirror target from source:", cls: D, delay: 300 },
        { type: "type", text: "APPLY" },
        { type: "progress", label: "Mirroring…", ms: 1000 },
        { type: "line", text: "✔ Target now mirrors source exactly.", cls: OK },
      ]
    },
    conflict: {
      label: "Git Conflict",
      icon: "🔀",
      desc: "Target has uncommitted git changes preventing apply",
      steps: [
        { type: "type", text: "bash main.sh apply /src/updated ./target --apply" },
        { type: "progress", label: "Scanning…", ms: 600 },
        { type: "line", text: "⚠ Target directory has uncommitted git changes.", cls: Y, delay: 200 },
        { type: "line", text: "  Use --force to apply anyway, or commit/stash first.", cls: D },
        { type: "type", text: "bash main.sh apply /src/updated ./target --apply --force", delay: 300 },
        { type: "progress", label: "Creating pre-apply backup…", ms: 600 },
        { type: "line", text: "✔ Applied 3 change(s).", cls: OK },
        { type: "line", text: "⚠ Restore from backup if the uncommitted changes conflict.", cls: Y, delay: 200 },
      ]
    },
  },

  rename_batch: {
    default: {
      label: "In-Place Rename",
      icon: "✎",
      desc: "Default rename without output directory",
      steps: [
        { type: "type", text: "bash main.sh rename ./src txt" },
        { type: "progress", label: "Scanning files…", ms: 700 },
        { type: "lines", items: [{ text: "readme.md  ──→  readme.txt", cls: C }, { text: "notes.log  ──→  notes.txt", cls: C }, { text: "README.md  (excluded — protected)", cls: Y }], stagger: 160 },
        { type: "line", text: "Proceed with rename? [Y/n] y", cls: D, delay: 300 },
        { type: "progress", label: "Renaming 2 file(s)…", ms: 800 },
        { type: "line", text: "✔ Success: 2   ⚠ Skipped: 1   ✖ Failed: 0", cls: OK },
      ]
    },
    copy_rename: {
      label: "Copy-Rename",
      icon: "📋",
      desc: "Copy files to output dir with new extension",
      steps: [
        { type: "type", text: "bash main.sh rename ./docs md ./rendered" },
        { type: "progress", label: "Scanning files…", ms: 600 },
        { type: "lines", items: [{ text: "guide.txt   ──→  ./rendered/guide.md", cls: C }, { text: "api.txt     ──→  ./rendered/api.md", cls: C }], stagger: 140 },
        { type: "line", text: "Proceed with copy-rename? [Y/n] y", cls: D, delay: 300 },
        { type: "progress", label: "Copying and renaming 2 file(s)…", ms: 900 },
        { type: "line", text: "✔ Copied and renamed 2 file(s) to ./rendered", cls: OK },
      ]
    },
    force_mode: {
      label: "Force Mode",
      icon: "💪",
      desc: "Override safety exclusions with --force flag",
      steps: [
        { type: "type", text: "bash main.sh rename . bak --force" },
        { type: "progress", label: "Scanning files…", ms: 600 },
        { type: "lines", items: [{ text: "README.md   ──→  README.bak", cls: C }, { text: "Makefile    ──→  Makefile.bak", cls: C }, { text: "package.json  ──→  package.json.bak", cls: C }, { text: "index.js    ──→  index.js.bak", cls: C }], stagger: 130 },
        { type: "line", text: "⚠ Force mode active — protected files will be renamed.", cls: Y },
        { type: "line", text: "Proceed? [Y/n] y", cls: D, delay: 300 },
        { type: "progress", label: "Renaming 4 file(s)…", ms: 700 },
        { type: "line", text: "✔ Success: 4   ✖ Failed: 0", cls: OK },
      ]
    },
    partial_failure: {
      label: "Partial Failure",
      icon: "⚠",
      desc: "Some files fail to rename",
      steps: [
        { type: "type", text: "bash main.sh rename ./mix txt" },
        { type: "progress", label: "Scanning files…", ms: 600 },
        { type: "lines", items: [{ text: "data.csv   ──→  data.txt", cls: C }, { text: "notes.md   ──→  notes.txt", cls: C }, { text: "locked.db  ──→  (in use — failed)", cls: R }], stagger: 140 },
        { type: "line", text: "Proceed with rename? [Y/n] y", cls: D, delay: 200 },
        { type: "progress", label: "Renaming…", ms: 700 },
        { type: "line", text: "✔ Success: 2   ✖ Failed: 1", cls: Y },
        { type: "line", text: "Exit code: 2 — partial failure.", cls: D },
      ]
    },
    interrupted_rollback: {
      label: "Interrupted",
      icon: "⚡",
      desc: "Ctrl+C triggers rollback prompt",
      steps: [
        { type: "type", text: "bash main.sh rename ./files txt" },
        { type: "progress", label: "Renaming…", ms: 400 },
        { type: "line", text: "^C⏎", cls: R, delay: 100 },
        { type: "line", text: "Rename interrupted after 1 file(s) processed.", cls: Y, delay: 200 },
        { type: "line", text: "Do you want to roll back these changes? [Y/n] y", cls: D },
        { type: "progress", label: "Rolling back…", ms: 600 },
        { type: "line", text: "✔ Rollback complete — all changes reverted.", cls: OK },
      ]
    },
    interactive_wizard: {
      label: "Interactive",
      icon: "🎛",
      desc: "Interactive directory picker + extension prompt",
      steps: [
        { type: "type", text: "bash main.sh rename -i" },
        { type: "line", text: "", delay: 100 },
        { type: "line", text: "╭── Step 1: Pick source directory ─────────────────╮", cls: C, delay: 200 },
        { type: "lines", items: [{ text: "  ●  ./project" }, { text: "  ○  ./downloads" }, { text: "  ○  ~/Documents" }], stagger: 100 },
        { type: "pause", ms: 200 },
        { type: "line", text: "Enter target extension (e.g. sh, py, txt): md", cls: C, delay: 300 },
        { type: "pause", ms: 200 },
        { type: "line", text: "Press Enter for in-place, or pick output dir:", cls: D },
        { type: "line", text: "  (in-place mode selected)", cls: C, delay: 150 },
        { type: "line", text: "Proceed with in-place rename? [Y/n] y", cls: D },
        { type: "progress", label: "Renaming…", ms: 600 },
        { type: "line", text: "✔ Success: 5 file(s) renamed.", cls: OK },
      ]
    },
  },

  move_in_batch: {
    default: {
      label: "Copy (Default)",
      icon: "📂",
      desc: "Safe copy mode preserves originals",
      steps: [
        { type: "type", text: "bash main.sh move --target ~/Downloads --output ~/Sorted" },
        { type: "progress", label: "Scanning ~/Downloads…", ms: 700 },
        { type: "line", text: "128 files found · 340 MB", cls: D, delay: 150 },
        { type: "line", text: "Proceed with copy 128 file(s)? [Y/n] y", cls: D, delay: 250 },
        { type: "progress", label: "Copying files…", ms: 1200 },
        { type: "line", text: "✔ Success: 126   ⚠ Skipped: 2   ✖ Failed: 0", cls: OK },
      ]
    },
    move_mode: {
      label: "Move Mode",
      icon: "✂",
      desc: "Move (cut) files, no copies left behind",
      steps: [
        { type: "type", text: "bash main.sh move --target ~/Temp --output ~/Archive -m=mv" },
        { type: "progress", label: "Scanning ~/Temp…", ms: 600 },
        { type: "line", text: "47 files found · 23 MB", cls: D, delay: 150 },
        { type: "line", text: "⚠ MOVE mode: originals will be deleted.", cls: Y },
        { type: "line", text: "Proceed with move 47 file(s)? [Y/n] y", cls: D, delay: 250 },
        { type: "progress", label: "Moving files…", ms: 900 },
        { type: "line", text: "✔ Moved 47 file(s) to ~/Archive.", cls: OK },
      ]
    },
    flatten_mode: {
      label: "Flatten",
      icon: "🗂",
      desc: "Strip subdirectory structure, all files to output root",
      steps: [
        { type: "type", text: "bash main.sh move --target ~/Photos --output ~/Flat -f" },
        { type: "progress", label: "Scanning ~/Photos…", ms: 700 },
        { type: "line", text: "312 files found · 1.2 GB", cls: D, delay: 150 },
        { type: "line", text: "⚠ FLATTEN mode: subdirectories will be stripped.", cls: Y },
        { type: "line", text: "Collision prevention: _1, _2 suffixes for duplicates.", cls: D },
        { type: "line", text: "Proceed with flatten-copy 312 file(s)? [Y/n] y", cls: D, delay: 250 },
        { type: "progress", label: "Flattening…", ms: 1100 },
        { type: "line", text: "✔ Flattened 312 file(s) to ~/Flat.", cls: OK },
      ]
    },
    partial_failure: {
      label: "Partial Failure",
      icon: "⚠",
      desc: "Some files fail during transfer",
      steps: [
        { type: "type", text: "bash main.sh move --target ./source --output ./dest -m=mv" },
        { type: "progress", label: "Scanning…", ms: 500 },
        { type: "line", text: "12 files found · 45 MB", cls: D, delay: 150 },
        { type: "line", text: "Proceed? [Y/n] y", cls: D },
        { type: "progress", label: "Moving files…", ms: 600 },
        { type: "line", text: "✖ Failed: locked_file.bin (Permission denied)", cls: R, delay: 200 },
        { type: "line", text: "✔ Moved 11 file(s), 1 failed.", cls: Y },
        { type: "line", text: "Exit code: 2 — partial failure.", cls: D },
      ]
    },
    interactive_wizard: {
      label: "Interactive",
      icon: "🎛",
      desc: "Interactive directory picker for source + destination",
      steps: [
        { type: "type", text: "bash main.sh move -i" },
        { type: "line", text: "", delay: 100 },
        { type: "line", text: "╭── Pick SOURCE directory ──────────────────────────╮", cls: C, delay: 200 },
        { type: "lines", items: [{ text: "  ●  ./data" }, { text: "  ○  ~/Projects" }], stagger: 100 },
        { type: "line", text: "╭── Pick DESTINATION directory ─────────────────────╮", cls: C, delay: 200 },
        { type: "lines", items: [{ text: "  ○  ./backup" }, { text: "  ●  ./archive" }], stagger: 100 },
        { type: "line", text: "Transfer method: cp (copy) or mv (move)? [cp] mv", cls: D, delay: 250 },
        { type: "line", text: "Flatten subdirectory structure? [y/N] n", cls: D },
        { type: "progress", label: "Moving files…", ms: 700 },
        { type: "line", text: "✔ Moved 5 file(s) to ./archive.", cls: OK },
      ]
    },
  },

  cache_clean: {
    default: {
      label: "Dry-Run Scan",
      icon: "🔍",
      desc: "Default scan shows recoverable space without deleting",
      steps: [
        { type: "type", text: "bash main.sh cacheclean" },
        { type: "progress", label: "Scanning environment…", ms: 700 },
        { type: "lines", items: [{ text: "npm      ✔ plugin loaded", cls: C }, { text: "pip      ✔ plugin loaded", cls: C }, { text: "cargo    ✔ plugin loaded", cls: C }, { text: "brew     — (not installed)", cls: D }], stagger: 130 },
        { type: "progress", label: "Scanning caches for orphaned files…", ms: 1100 },
        { type: "line", text: "Total cache scanned: 2.1 GB", cls: D, delay: 200 },
        { type: "line", text: "Total recoverable:   340 MB", cls: OK },
        { type: "line", text: "Orphaned files:      212", cls: C },
      ]
    },
    delete_success: {
      label: "Delete Success",
      icon: "🧹",
      desc: "Auto-confirm deletion reclaims space",
      steps: [
        { type: "type", text: "bash main.sh cacheclean --yes" },
        { type: "progress", label: "Scanning environment…", ms: 600 },
        { type: "lines", items: [{ text: "npm      ✔ plugin loaded", cls: C }, { text: "pip      ✔ plugin loaded", cls: C }, { text: "cargo    ✔ plugin loaded", cls: C }], stagger: 110 },
        { type: "progress", label: "Scanning caches for orphaned files…", ms: 900 },
        { type: "line", text: "Total recoverable: 340 MB from 212 file(s)", cls: D, delay: 150 },
        { type: "progress", label: "Deleting orphaned files…", ms: 1000 },
        { type: "line", text: "✔ Reclaimed 340 MB from 212 file(s)", cls: OK },
        { type: "line", text: "✔ npm cache cleaned (6 packages)", cls: C, delay: 150 },
        { type: "line", text: "✔ pip cache cleaned (12 packages)", cls: C },
      ]
    },
    older_than: {
      label: "Older Than",
      icon: "📅",
      desc: "Filter caches older than N days",
      steps: [
        { type: "type", text: "bash main.sh cacheclean --older-than 90" },
        { type: "progress", label: "Scanning environment…", ms: 600 },
        { type: "lines", items: [{ text: "npm      ✔ plugin loaded", cls: C }, { text: "cargo    ✔ plugin loaded", cls: C }], stagger: 110 },
        { type: "progress", label: "Scanning caches older than 90 days…", ms: 800 },
        { type: "line", text: "Total recoverable: 120 MB from 15 files", cls: D, delay: 200 },
        { type: "line", text: "Delete all orphaned files? [y/N] y", cls: D },
        { type: "line", text: "Are you sure? These files will be permanently deleted. [y/N] y", cls: R },
        { type: "progress", label: "Deleting…", ms: 700 },
        { type: "line", text: "✔ Reclaimed 120 MB from 15 file(s)", cls: OK },
      ]
    },
    failure: {
      label: "Scan Failure",
      icon: "✖",
      desc: "Cache scan encounters an error, refuses deletion",
      steps: [
        { type: "type", text: "bash main.sh cacheclean" },
        { type: "line", text: "✖ Error: Cannot read cache directories.", cls: R, delay: 200 },
        { type: "line", text: "  Permission denied: /root/.cache", cls: D },
        { type: "line", text: "  Run without elevated permissions or check directory access.", cls: Y },
        { type: "line", text: "✖ Cache scan failed — refusing to delete.", cls: R },
      ]
    },
    quiet_mode: {
      label: "Quiet Mode",
      icon: "🔇",
      desc: "Suppressed output shows only final summary",
      steps: [
        { type: "type", text: "bash main.sh cacheclean --yes --quiet" },
        { type: "progress", label: "Scanning…", ms: 600 },
        { type: "progress", label: "Deleting…", ms: 900 },
        { type: "line", text: "✔ Total: 340 MB reclaimed from 212 file(s)", cls: OK, delay: 300 },
      ]
    },
  },

  symlink_manager: {
    default: {
      label: "Dry-Run",
      icon: "🔍",
      desc: "Default dry-run shows what would be linked",
      steps: [
        { type: "type", text: "bash main.sh symlink ~/.dotfiles/.bashrc ~/.bashrc" },
        { type: "line", text: "Source: ~/.dotfiles/.bashrc", cls: D, delay: 200 },
        { type: "line", text: "Target: ~/.bashrc", cls: D },
        { type: "line", text: "Dry-run: use --apply to create symlink.", cls: Y },
      ]
    },
    apply_success: {
      label: "Apply Success",
      icon: "✔",
      desc: "Successful symlink creation with backup",
      steps: [
        { type: "type", text: "bash main.sh symlink ~/.dotfiles/.bashrc ~/.bashrc --apply" },
        { type: "line", text: "Source: ~/.dotfiles/.bashrc", cls: D, delay: 200 },
        { type: "line", text: "Target: ~/.bashrc", cls: D },
        { type: "progress", label: "Creating symlink…", ms: 400 },
        { type: "line", text: "✔ Symbolic link successfully created!", cls: OK },
        { type: "line", text: "  ~/.bashrc → ~/.dotfiles/.bashrc", cls: D },
      ]
    },
    conflict_backup: {
      label: "Conflict + Backup",
      icon: "📦",
      desc: "Target exists, automatically backed up before linking",
      steps: [
        { type: "type", text: "bash main.sh symlink ~/.dotfiles/.nvim ~/.config/nvim --apply" },
        { type: "line", text: "Source: ~/.dotfiles/.nvim", cls: D, delay: 200 },
        { type: "line", text: "Target: ~/.config/nvim", cls: D },
        { type: "line", text: "⚠ Conflict: target exists as a directory.", cls: Y, delay: 200 },
        { type: "progress", label: "Backing up existing target…", ms: 500 },
        { type: "line", text: "Backed up to ~/.config/nvim.20260725_142201.bak", cls: D },
        { type: "progress", label: "Creating symlink…", ms: 400 },
        { type: "line", text: "✔ Symbolic link successfully created!", cls: OK },
      ]
    },
    apply_failure: {
      label: "Apply Failure",
      icon: "✖",
      desc: "Symlink creation fails with rollback attempt",
      steps: [
        { type: "type", text: "bash main.sh symlink /invalid/path ~/target --apply" },
        { type: "line", text: "Source: /invalid/path", cls: D, delay: 150 },
        { type: "line", text: "✖ Source does not exist: /invalid/path", cls: R },
        { type: "line", text: "Error: cannot create symlink — source missing.", cls: Y },
      ]
    },
    interactive: {
      label: "Interactive",
      icon: "🎛",
      desc: "Prompt-driven symlink wizard",
      steps: [
        { type: "type", text: "bash main.sh symlink --apply" },
        { type: "line", text: "", delay: 100 },
        { type: "line", text: "Enter source path:", cls: C, delay: 200 },
        { type: "type", text: "~/.dotfiles/.bashrc" },
        { type: "line", text: "Enter target path:", cls: C, delay: 200 },
        { type: "type", text: "~/.bashrc" },
        { type: "line", text: "Proceed with symlink creation? [y/N]: y", cls: D },
        { type: "progress", label: "Creating symlink…", ms: 400 },
        { type: "line", text: "✔ Symbolic link successfully created!", cls: OK },
      ]
    },
  },

  disk_analyzer: {
    default: {
      label: "Default Scan",
      icon: "📊",
      desc: "Show top 10 largest items in directory",
      steps: [
        { type: "type", text: "bash main.sh disk ~/projects" },
        { type: "progress", label: "Scanning largest items…", ms: 1000 },
        { type: "lines", items: [{ text: "1)  1.2 GB   node_modules/", cls: C }, { text: "2)  480 MB   .git/", cls: C }, { text: "3)  210 MB   dist/", cls: C }, { text: "4)  92 MB    assets/", cls: C }, { text: "5)  40 MB    docs/", cls: C }], stagger: 130 },
        { type: "line", text: "Create a compressed archive of an item above? [number or 0] 0", cls: D, delay: 300 },
      ]
    },
    count_3: {
      label: "Top 3 Only",
      icon: "🔝",
      desc: "Limit results with --count flag",
      steps: [
        { type: "type", text: "bash main.sh disk --count 3 ~/projects" },
        { type: "progress", label: "Scanning top 3 largest items…", ms: 800 },
        { type: "lines", items: [{ text: "1)  1.2 GB   node_modules/", cls: C }, { text: "2)  480 MB   .git/", cls: C }, { text: "3)  210 MB   dist/", cls: C }], stagger: 130 },
        { type: "line", text: "Create a compressed archive? [number or 0] 0", cls: D, delay: 250 },
      ]
    },
    archive_created: {
      label: "Archive Created",
      icon: "📦",
      desc: "User selects an item and creates a tar.gz archive",
      steps: [
        { type: "type", text: "bash main.sh disk ~/projects" },
        { type: "progress", label: "Scanning…", ms: 900 },
        { type: "lines", items: [{ text: "1)  1.2 GB   node_modules/", cls: C }, { text: "2)  480 MB   .git/", cls: C }], stagger: 120 },
        { type: "line", text: "Create a compressed archive? [number or 0] 2", cls: D, delay: 250 },
        { type: "progress", label: "Creating node_modules.tar.gz…", ms: 1200 },
        { type: "line", text: "✔ Created: node_modules.tar.gz (320 MB)", cls: OK },
      ]
    },
    no_items: {
      label: "No Items",
      icon: "🔲",
      desc: "Permission denied or empty directory",
      steps: [
        { type: "type", text: "bash main.sh disk /root/restricted" },
        { type: "progress", label: "Scanning…", ms: 500 },
        { type: "line", text: "No items found (permission denied for some paths).", cls: Y, delay: 200 },
        { type: "line", text: "Try running with appropriate permissions.", cls: D },
      ]
    },
  },

  // ──────────────────────────────────────────────
  // D E V E L O P E R   T O O L S
  // ──────────────────────────────────────────────

  git_sweep: {
    default: {
      label: "Preview",
      icon: "🔍",
      desc: "Preview all sweepable items without applying",
      steps: [
        { type: "type", text: "bash main.sh git --repo ." },
        { type: "progress", label: "Scanning branches and stashes…", ms: 800 },
        { type: "line", text: "Merged local branches:", cls: D, delay: 200 },
        { type: "lines", items: [{ text: "  • feat/login-page", cls: C }, { text: "  • fix/typo-in-readme", cls: C }], stagger: 120 },
        { type: "line", text: "Merged remote branches:", cls: D, delay: 150 },
        { type: "lines", items: [{ text: "  • feat/old-api" }, { text: "  • experiment/v2" }], stagger: 120 },
        { type: "line", text: "Stashes:", cls: D, delay: 150 },
        { type: "line", text: "  • WIP on main: a1b2c3d Fix race condition", cls: C },
        { type: "line", text: "Git objects: 2,314 | Packs: 3", cls: D, delay: 150 },
      ]
    },
    apply_merged: {
      label: "Apply Cleanup",
      icon: "🧹",
      desc: "Delete merged branches and run GC",
      steps: [
        { type: "type", text: "bash main.sh git --repo . --delete-merged-local --gc --apply" },
        { type: "progress", label: "Scanning branches…", ms: 700 },
        { type: "line", text: "Merged local branches:", cls: D, delay: 150 },
        { type: "lines", items: [{ text: "  • feat/login-page", cls: C }, { text: "  • fix/typo-in-readme", cls: C }], stagger: 120 },
        { type: "progress", label: "Deleting merged branches…", ms: 500 },
        { type: "line", text: "✔ Deleted 2 local branches.", cls: OK, delay: 150 },
        { type: "progress", label: "Running git gc --prune=now…", ms: 900 },
        { type: "line", text: "✔ Git objects reduced: 2,314 → 1,887", cls: OK },
      ]
    },
    not_git_repo: {
      label: "Not a Git Repo",
      icon: "✖",
      desc: "Target directory is not a git repository",
      steps: [
        { type: "type", text: "bash main.sh git --repo ~/Downloads" },
        { type: "line", text: "✖ Not a git repository: ~/Downloads", cls: R, delay: 200 },
        { type: "line", text: "Run 'git init' to initialize or point --repo to a git project.", cls: Y },
      ]
    },
    interactive: {
      label: "Interactive",
      icon: "🎛",
      desc: "Step-by-step prompts for each cleanup action",
      steps: [
        { type: "type", text: "bash main.sh git" },
        { type: "progress", label: "Scanning…", ms: 600 },
        { type: "line", text: "Delete merged local branches shown above? [y/N]", cls: D, delay: 200 },
        { type: "type", text: "y", cls: C },
        { type: "line", text: "Delete merged remote branches shown above? [y/N]", cls: D, delay: 200 },
        { type: "type", text: "n" },
        { type: "line", text: "Clear ALL git stashes? [y/N]", cls: D, delay: 200 },
        { type: "type", text: "n" },
        { type: "line", text: "Run git gc --prune=now? [Y/n]", cls: D, delay: 200 },
        { type: "type", text: "y" },
        { type: "line", text: "Apply all selected actions now? [y/N]", cls: D, delay: 200 },
        { type: "type", text: "y" },
        { type: "progress", label: "Processing…", ms: 800 },
        { type: "line", text: "✔ Cleanup complete.", cls: OK },
      ]
    },
  },

  docker_janitor: {
    default: {
      label: "Preview",
      icon: "🔍",
      desc: "Preview all pruneable Docker resources",
      steps: [
        { type: "type", text: "bash main.sh docker" },
        { type: "progress", label: "Checking Docker daemon…", ms: 500 },
        { type: "line", text: "Stopped containers   3", cls: D, delay: 200 },
        { type: "line", text: "Dangling images      7", cls: D },
        { type: "line", text: "Dangling volumes     2", cls: D },
        { type: "line", text: "Docker disk usage: 4.2 GB", cls: D, delay: 150 },
        { type: "line", text: "Recoverable: ~1.8 GB", cls: OK },
      ]
    },
    prune_all: {
      label: "Prune All",
      icon: "🗑",
      desc: "Prune containers, images, and volumes",
      steps: [
        { type: "type", text: "bash main.sh docker --all --apply" },
        { type: "progress", label: "Checking Docker daemon…", ms: 400 },
        { type: "line", text: "Stopped containers   3", cls: D, delay: 150 },
        { type: "line", text: "Dangling images      7", cls: D },
        { type: "line", text: "Dangling volumes     2", cls: D },
        { type: "progress", label: "Pruning containers…", ms: 600 },
        { type: "progress", label: "Pruning images…", ms: 800 },
        { type: "progress", label: "Pruning volumes…", ms: 500 },
        { type: "line", text: "✔ Prune operations completed.", cls: OK },
        { type: "line", text: "✔ Recovered ~1.8 GB.", cls: OK },
      ]
    },
    daemon_unreachable: {
      label: "Daemon Down",
      icon: "✖",
      desc: "Docker daemon is not running or unreachable",
      steps: [
        { type: "type", text: "bash main.sh docker --all" },
        { type: "progress", label: "Checking Docker daemon…", ms: 800 },
        { type: "line", text: "✖ Cannot connect to Docker daemon.", cls: R, delay: 200 },
        { type: "line", text: "  Is the docker daemon running?", cls: Y },
        { type: "line", text: "  Try: systemctl start docker  or  dockerd &", cls: D },
      ]
    },
    interactive: {
      label: "Interactive",
      icon: "🎛",
      desc: "Prompt-driven cleanup selection",
      steps: [
        { type: "type", text: "bash main.sh docker" },
        { type: "progress", label: "Checking Docker daemon…", ms: 400 },
        { type: "line", text: "Stopped containers  3", cls: D, delay: 150 },
        { type: "line", text: "Dangling images     7", cls: D },
        { type: "line", text: "Prune stopped containers? [Y/n]", cls: D, delay: 200 },
        { type: "type", text: "y" },
        { type: "line", text: "Prune dangling images? [Y/n]", cls: D, delay: 200 },
        { type: "type", text: "y" },
        { type: "line", text: "Prune dangling volumes? [y/N]", cls: D, delay: 200 },
        { type: "type", text: "n" },
        { type: "line", text: "Apply all selected operations now? [y/N]", cls: D, delay: 200 },
        { type: "type", text: "y" },
        { type: "progress", label: "Pruning…", ms: 900 },
        { type: "line", text: "✔ Pruned 3 stopped containers, 7 dangling images.", cls: OK },
      ]
    },
  },

  project_scaffold: {
    default: {
      label: "Node CLI",
      icon: "🟢",
      desc: "Generate a Node.js CLI scaffold",
      steps: [
        { type: "type", text: "bash main.sh scaffold --type node-cli --name demo-app --dest ~/projects" },
        { type: "progress", label: "Generating project files…", ms: 700 },
        { type: "lines", items: [{ text: "created  demo-app/package.json", cls: C }, { text: "created  demo-app/index.js", cls: C }, { text: "created  demo-app/Dockerfile", cls: C }, { text: "created  demo-app/.github/workflows/ci.yml", cls: C }], stagger: 140 },
        { type: "line", text: "✔ Generated node-cli scaffold at ~/projects/demo-app", cls: OK },
      ]
    },
    python_flask: {
      label: "Python Flask",
      icon: "🐍",
      desc: "Generate a Python Flask scaffold",
      steps: [
        { type: "type", text: "bash main.sh scaffold --type python-flask --name webapp --dest ." },
        { type: "progress", label: "Generating project files…", ms: 800 },
        { type: "lines", items: [{ text: "created  webapp/app.py", cls: C }, { text: "created  webapp/requirements.txt", cls: C }, { text: "created  webapp/templates/index.html", cls: C }, { text: "created  webapp/static/style.css", cls: C }], stagger: 130 },
        { type: "line", text: "✔ Generated python-flask scaffold at ./webapp", cls: OK },
      ]
    },
    target_exists: {
      label: "Target Exists",
      icon: "⚠",
      desc: "Target directory already exists, needs --force",
      steps: [
        { type: "type", text: "bash main.sh scaffold --type bash --name existing-app --dest ." },
        { type: "progress", label: "Generating project files…", ms: 400 },
        { type: "line", text: "✖ Target 'existing-app' already exists.", cls: R, delay: 200 },
        { type: "line", text: "Use --force to overwrite.", cls: Y },
        { type: "type", text: "bash main.sh scaffold --type bash --name existing-app --dest . --force", delay: 300 },
        { type: "progress", label: "Overwriting…", ms: 600 },
        { type: "lines", items: [{ text: "created  existing-app/main.sh", cls: C }, { text: "created  existing-app/lib/helpers.sh", cls: C }], stagger: 120 },
        { type: "line", text: "✔ Overwrote existing-app with bash scaffold.", cls: OK },
      ]
    },
    interactive_wizard: {
      label: "Interactive",
      icon: "🎛",
      desc: "Prompt-driven scaffold configuration",
      steps: [
        { type: "type", text: "bash main.sh scaffold" },
        { type: "line", text: "Enter scaffold type (bash, python-flask, node-cli, go-service):", cls: C, delay: 200 },
        { type: "type", text: "node-cli" },
        { type: "line", text: "Enter project folder name:", cls: C, delay: 200 },
        { type: "type", text: "my-cli" },
        { type: "line", text: "Enter parent destination directory:", cls: C, delay: 200 },
        { type: "type", text: "./projects" },
        { type: "progress", label: "Generating…", ms: 600 },
        { type: "line", text: "✔ Generated node-cli scaffold at ./projects/my-cli", cls: OK },
      ]
    },
  },

  ssh_assistant: {
    default: {
      label: "List Hosts",
      icon: "📋",
      desc: "Parse and list SSH config hosts",
      steps: [
        { type: "type", text: "bash main.sh ssh" },
        { type: "line", text: "Named hosts found in ~/.ssh/config:", cls: D, delay: 250 },
        { type: "lines", items: [{ text: " 1)  myserver    (ssh myserver)", cls: C }, { text: " 2)  staging     (ssh staging)", cls: C }, { text: " 3)  github      (ssh github)", cls: C }], stagger: 130 },
        { type: "line", text: "Enter host number (or press Enter to quit):", cls: D, delay: 250 },
      ]
    },
    connect_success: {
      label: "Connect Success",
      icon: "🔗",
      desc: "SSH connection to a configured host",
      steps: [
        { type: "type", text: "bash main.sh ssh --connect myserver" },
        { type: "progress", label: "Connecting to myserver…", ms: 600 },
        { type: "line", text: "✔ Connected to myserver (192.168.1.100)", cls: OK, delay: 150 },
        { type: "line", text: "  Authenticated with ed25519 key.", cls: D },
        { type: "line", text: "  Last login: Thu Jul 25 14:22:01 2026", cls: D },
      ]
    },
    copy_id: {
      label: "Copy SSH Key",
      icon: "🔑",
      desc: "Deploy SSH public key to remote host",
      steps: [
        { type: "type", text: "bash main.sh ssh --copy-id staging" },
        { type: "progress", label: "ssh-copy-id to staging…", ms: 800 },
        { type: "line", text: "/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s).", cls: D, delay: 200 },
        { type: "line", text: "/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed.", cls: D },
        { type: "line", text: "✔ Key installed — you can now ssh staging without a password.", cls: OK },
      ]
    },
    add_host: {
      label: "Add Host",
      icon: "➕",
      desc: "Interactive wizard to add a new SSH config entry",
      steps: [
        { type: "type", text: "bash main.sh ssh --add" },
        { type: "line", text: "Enter host alias:", cls: C, delay: 150 },
        { type: "type", text: "my-server" },
        { type: "line", text: "Enter HostName (IP/domain):", cls: C, delay: 150 },
        { type: "type", text: "192.168.1.200" },
        { type: "line", text: "Enter User (default: root):", cls: C, delay: 150 },
        { type: "type", text: "deploy" },
        { type: "line", text: "Enter Port (default: 22):", cls: C, delay: 150 },
        { type: "type", text: "2222" },
        { type: "line", text: "✔ Added host 'my-server' to ~/.ssh/config", cls: OK },
      ]
    },
  },

  github_helper: {
    default: {
      label: "List PRs",
      icon: "🔀",
      desc: "List open pull requests via gh CLI",
      steps: [
        { type: "type", text: "bash main.sh github --prs" },
        { type: "progress", label: "Querying gh CLI…", ms: 600 },
        { type: "lines", items: [{ text: "#142  feat(cache): add bun plugin support", cls: C }, { text: "#139  fix(qr): handle empty wifi passphrase", cls: C }, { text: "#138  docs(readme): update install instructions", cls: C }], stagger: 130 },
        { type: "line", text: "Showing 3 open pull requests.", cls: D, delay: 150 },
      ]
    },
    issues: {
      label: "List Issues",
      icon: "❗",
      desc: "List open issues",
      steps: [
        { type: "type", text: "bash main.sh github --issues" },
        { type: "progress", label: "Querying gh CLI…", ms: 600 },
        { type: "lines", items: [{ text: "#45  Bug: cache clean fails on symlinks", cls: Y }, { text: "#44  Feature request: add dry-run to shredder", cls: C }], stagger: 130 },
      ]
    },
    runs: {
      label: "Workflow Runs",
      icon: "⚙",
      desc: "List recent workflow runs",
      steps: [
        { type: "type", text: "bash main.sh github --runs" },
        { type: "progress", label: "Querying gh CLI…", ms: 700 },
        { type: "lines", items: [{ text: "CI  main  ✓  passed  2m ago", cls: OK }, { text: "Lint  feat/cache  ✓  passed  5m ago", cls: OK }, { text: "Test  main  ✗  failed  12m ago", cls: R }], stagger: 130 },
      ]
    },
    auth_failed: {
      label: "Auth Failed",
      icon: "🔒",
      desc: "GitHub CLI not authenticated",
      steps: [
        { type: "type", text: "bash main.sh github --status" },
        { type: "line", text: "✖ gh CLI not authenticated.", cls: R, delay: 200 },
        { type: "line", text: "  Run 'gh auth login' to authenticate.", cls: Y },
        { type: "line", text: "  Alternatively, set GH_TOKEN or GITHUB_TOKEN.", cls: D },
      ]
    },
  },

  release_helper: {
    default: {
      label: "Dry-Run Tag",
      icon: "🔍",
      desc: "Preview tag creation without applying",
      steps: [
        { type: "type", text: "bash main.sh release --repo . --tag v5.1.0" },
        { type: "progress", label: "Checking git status…", ms: 500 },
        { type: "line", text: "On branch master, working tree clean.", cls: OK, delay: 150 },
        { type: "line", text: "a1b2c3d feat(qr): add wifi payload support", cls: D },
        { type: "line", text: "e4f5g6h fix(ssh): handle missing config", cls: D },
        { type: "line", text: "Would create tag v5.1.0. Use --apply to create it.", cls: Y },
      ]
    },
    apply_tag: {
      label: "Create Tag",
      icon: "🏷",
      desc: "Actually create the git tag",
      steps: [
        { type: "type", text: "bash main.sh release --repo . --tag v5.1.0 --apply" },
        { type: "progress", label: "Checking git status…", ms: 500 },
        { type: "line", text: "On branch master, working tree clean.", cls: OK, delay: 150 },
        { type: "line", text: "a1b2c3d feat(qr): add wifi payload support", cls: D },
        { type: "progress", label: "Creating tag v5.1.0…", ms: 400 },
        { type: "line", text: "✔ Created tag v5.1.0 at a1b2c3d", cls: OK },
      ]
    },
    not_git_repo: {
      label: "Not a Git Repo",
      icon: "✖",
      desc: "Target is not a git repository",
      steps: [
        { type: "type", text: "bash main.sh release --repo ~/Downloads --tag v1.0.0" },
        { type: "line", text: "✖ Not a git repository: ~/Downloads", cls: R, delay: 200 },
        { type: "line", text: "The --repo directory must contain a .git folder.", cls: Y },
      ]
    },
  },

  git_stats: {
    default: {
      label: "Default Stats",
      icon: "📈",
      desc: "Show commit stats for current repo",
      steps: [
        { type: "type", text: "bash main.sh git-stats --repo ." },
        { type: "progress", label: "Analyzing repository…", ms: 900 },
        { type: "line", text: "Commits by author", cls: D, delay: 150 },
        { type: "lines", items: [{ text: "   42   Sahil", cls: C }, { text: "   18   Claude", cls: C }], stagger: 120 },
        { type: "line", text: "Most changed files", cls: D, delay: 200 },
        { type: "lines", items: [{ text: "   9    main.sh", cls: C }, { text: "   6    lib/uk_common.sh", cls: C }, { text: "   4    docs-site/src/App.tsx", cls: D }], stagger: 120 },
        { type: "line", text: "Branches by activity", cls: D, delay: 200 },
        { type: "lines", items: [{ text: "  master    2026-07-25", cls: C }, { text: "  feat/cache  2026-07-24", cls: D }], stagger: 120 },
      ]
    },
    filtered_by_author: {
      label: "Filter by Author",
      icon: "👤",
      desc: "Filter stats by a specific author",
      steps: [
        { type: "type", text: 'bash main.sh git-stats --repo . --author "Sahil" --since "30 days ago"' },
        { type: "progress", label: "Analyzing repository…", ms: 800 },
        { type: "line", text: "Commits by author (filtered)", cls: D, delay: 150 },
        { type: "line", text: "   15   Sahil", cls: C },
        { type: "line", text: "Most changed files (since 30 days ago)", cls: D, delay: 150 },
        { type: "lines", items: [{ text: "   3    modules/_qr_tool/_qr_tool.sh", cls: C }, { text: "   2    main.sh", cls: C }], stagger: 120 },
      ]
    },
    empty_repo: {
      label: "Empty Repo",
      icon: "🔲",
      desc: "No commits found in the repository",
      steps: [
        { type: "type", text: "bash main.sh git-stats --repo ." },
        { type: "progress", label: "Analyzing repository…", ms: 500 },
        { type: "line", text: "No commits found in the specified range.", cls: Y, delay: 200 },
        { type: "line", text: "Try expanding --since or removing --author filters.", cls: D },
      ]
    },
  },

  file_watcher: {
    default: {
      label: "Watch Scripts",
      icon: "👁",
      desc: "Watch .sh files and run a test command",
      steps: [
        { type: "type", text: 'bash main.sh fwatch -p "*.sh" -c "make test"' },
        { type: "line", text: "Watching: .  (inotifywait backend)", cls: D, delay: 250 },
        { type: "line", text: "Command: make test", cls: D },
        { type: "progress", label: "Watching for changes…", ms: 1000 },
        { type: "line", text: "change detected: modules/_qr_tool/_qr_tool.sh", cls: OK, delay: 200 },
        { type: "line", text: "  [output] 12 tests passed", cls: C },
      ]
    },
    polling_backend: {
      label: "Polling Mode",
      icon: "🔄",
      desc: "Use polling backend instead of inotify",
      steps: [
        { type: "type", text: 'bash main.sh fwatch -p "*.py" -c "pytest" --polling 2' },
        { type: "line", text: "Watching: .  (polling backend, interval: 2s)", cls: D, delay: 250 },
        { type: "line", text: "Command: pytest", cls: D },
        { type: "progress", label: "Polling for changes…", ms: 1200 },
        { type: "line", text: "change detected: src/app.py", cls: OK, delay: 200 },
        { type: "line", text: "  [output] 47 tests passed, 2 warnings", cls: C },
      ]
    },
    no_command: {
      label: "Missing Command",
      icon: "✖",
      desc: "No command specified for file watcher",
      steps: [
        { type: "type", text: "bash main.sh fwatch -p '*.sh'" },
        { type: "line", text: "✖ No command specified.", cls: R, delay: 150 },
        { type: "line", text: "  Use -c/--cmd to specify a command to run on change.", cls: Y },
      ]
    },
    interactive_wizard: {
      label: "Interactive",
      icon: "🎛",
      desc: "Prompt-driven file watcher setup",
      steps: [
        { type: "type", text: "bash main.sh fwatch" },
        { type: "line", text: "Watch directory [.]:", cls: C, delay: 150 },
        { type: "type", text: "./src" },
        { type: "line", text: "File pattern glob [all files]:", cls: C, delay: 150 },
        { type: "type", text: "*.js" },
        { type: "line", text: "Command to run on change:", cls: C, delay: 150 },
        { type: "type", text: "npm test" },
        { type: "line", text: "Debounce in seconds [1]:", cls: C, delay: 150 },
        { type: "type", text: "2" },
        { type: "progress", label: "Starting watcher…", ms: 500 },
        { type: "line", text: "✔ Watching ./src for *.js changes → npm test", cls: OK },
      ]
    },
  },

  git_hooks: {
    default: {
      label: "List Hooks",
      icon: "📋",
      desc: "List installed hooks in repository",
      steps: [
        { type: "type", text: "bash main.sh hooks list" },
        { type: "progress", label: "Scanning hooks…", ms: 400 },
        { type: "lines", items: [{ text: "pre-commit     installed", cls: OK }, { text: "commit-msg    not installed", cls: D }, { text: "pre-push      not installed", cls: D }], stagger: 130 },
      ]
    },
    install_success: {
      label: "Install Hooks",
      icon: "📥",
      desc: "Install all hook templates",
      steps: [
        { type: "type", text: "bash main.sh hooks install" },
        { type: "progress", label: "Installing hook templates…", ms: 600 },
        { type: "lines", items: [{ text: "Installed pre-commit", cls: C }, { text: "Installed commit-msg", cls: C }, { text: "Installed pre-push", cls: C }], stagger: 130 },
        { type: "line", text: "✔ Installed 3 hook(s) in .", cls: OK },
      ]
    },
    remove_hooks: {
      label: "Remove Hooks",
      icon: "🗑",
      desc: "Remove all UtilityKit hooks",
      steps: [
        { type: "type", text: "bash main.sh hooks remove" },
        { type: "progress", label: "Removing UtilityKit hooks…", ms: 400 },
        { type: "line", text: "Removed pre-commit", cls: C, delay: 100 },
        { type: "line", text: "Removed pre-push", cls: C },
        { type: "line", text: "✔ Removed 2 UtilityKit hook(s). 1 preserved (not UtilityKit).", cls: OK },
      ]
    },
    show_template: {
      label: "Show Template",
      icon: "📄",
      desc: "Display a hook template's contents",
      steps: [
        { type: "type", text: "bash main.sh hooks show pre-commit" },
        { type: "line", text: "#!/bin/bash", cls: D, delay: 80 },
        { type: "line", text: "# UtilityKit pre-commit hook", cls: D, delay: 80 },
        { type: "line", text: 'echo "Running shellcheck on staged files…"', cls: D, delay: 80 },
        { type: "line", text: 'for f in $(git diff --cached --name-only --diff-filter=ACM | grep -E "\\.(sh|bash)$"); do', cls: D, delay: 80 },
        { type: "line", text: '  shellcheck -S error "$f" || exit 1', cls: D, delay: 80 },
        { type: "line", text: "done", cls: D },
        { type: "line", text: "✔ pre-commit template (22 lines)", cls: OK, delay: 200 },
      ]
    },
  },

  installed: {
    default: {
      label: "All (Default)",
      icon: "📦",
      desc: "List all packages and PATH executables",
      steps: [
        { type: "type", text: "bash main.sh installed --all" },
        { type: "progress", label: "Detecting package managers…", ms: 800 },
        { type: "line", text: "◆ system package managers", cls: D, delay: 150 },
        { type: "line", text: "  [OK] apt (Debian / Ubuntu family) — 370 package(s)", cls: OK },
        { type: "lines", items: [{ text: '    - bash v5.3-2ubuntu1', cls: C }, { text: '    - curl v8.18.0-1ubuntu2.2', cls: C }, { text: '    - git v2.53.0-1ubuntu1', cls: C }], stagger: 60 },
        { type: "line", text: "    … (366 more)", cls: D, delay: 80 },
        { type: "line", text: "◆ language package managers", cls: D, delay: 150 },
        { type: "line", text: "  [OK] pip (Python pip) — 2 package(s)", cls: OK },
        { type: "line", text: "  [OK] npm (Node npm global) — 0 package(s)", cls: D },
        { type: "progress", label: "Counting PATH executables…", ms: 500 },
        { type: "line", text: "▸ PATH executables — 1327 unique command(s)", cls: C, delay: 200 },
        { type: "line", text: "✔ Detected 5 manager(s), 466 total package(s), 1327 command(s)", delay: 250 },
      ]
    },
    packages_only: {
      label: "Packages Only",
      icon: "📦",
      desc: "Only list packages per detected manager",
      steps: [
        { type: "type", text: "bash main.sh installed --packages --count" },
        { type: "progress", label: "Detecting package managers…", ms: 700 },
        { type: "line", text: "▪ apt        370 packages", cls: C, delay: 120 },
        { type: "line", text: "▪ pip        2 packages", cls: C },
        { type: "line", text: "▪ gem        92 packages", cls: C },
        { type: "line", text: "▪ cargo      0 packages", cls: D },
        { type: "line", text: "▪ go         2 packages", cls: C },
        { type: "line", text: "▪ uv         2 packages", cls: C },
        { type: "line", text: "Total: 466 packages across 6 managers", cls: OK, delay: 200 },
      ]
    },
    commands_only: {
      label: "Commands Only",
      icon: "🔧",
      desc: "Only list PATH executables",
      steps: [
        { type: "type", text: "bash main.sh installed --commands --count" },
        { type: "progress", label: "Scanning PATH…", ms: 600 },
        { type: "line", text: "▸ PATH directories: 14", cls: D, delay: 120 },
        { type: "line", text: "▸ Executable commands: 1,327", cls: C },
        { type: "line", text: "▸ Unique commands: 1,042", cls: OK },
      ]
    },
    json_output: {
      label: "JSON Output",
      icon: "📋",
      desc: "Machine-readable JSON summary",
      steps: [
        { type: "type", text: "bash main.sh installed --json" },
        { type: "progress", label: "Detecting package managers…", ms: 700 },
        { type: "lines", items: [{ text: '{', cls: C }, { text: '  "managers": { "apt": 370, "pip": 2, "gem": 92, "cargo": 0, "go": 2, "uv": 2 },', cls: C }, { text: '  "total_packages": 466,', cls: C }, { text: '  "path_commands": 1327', cls: C }, { text: '}', cls: C }], stagger: 100 },
      ]
    },
  },

  ssh_tunnel: {
    default: {
      label: "List Tunnels",
      icon: "📋",
      desc: "List all saved SSH tunnels with status",
      steps: [
        { type: "type", text: "bash main.sh tunnel list" },
        { type: "progress", label: "Reading tunnels…", ms: 400 },
        { type: "line", text: "#  NAME      LOCAL → REMOTE              PID   STATUS", cls: D, delay: 150 },
        { type: "line", text: "1  api       :3000 → server.com:3000    8842  ● active", cls: OK },
        { type: "line", text: "2  db-tunnel :5432 → db.internal:5432  —     ○ stopped", cls: D },
      ]
    },
    create_success: {
      label: "Create Tunnel",
      icon: "🔗",
      desc: "Create a new SSH tunnel",
      steps: [
        { type: "type", text: "bash main.sh tunnel create server.com:3000 --local 3000 --name api" },
        { type: "progress", label: "Establishing SSH tunnel…", ms: 800 },
        { type: "line", text: "✔ Tunnel 'api' (PID 8842): :3000 → server.com:3000", cls: OK },
      ]
    },
    create_failure: {
      label: "Create Failure",
      icon: "✖",
      desc: "Port already in use when creating tunnel",
      steps: [
        { type: "type", text: "bash main.sh tunnel create server.com:3000 --local 3000" },
        { type: "progress", label: "Establishing SSH tunnel…", ms: 600 },
        { type: "line", text: "✖ Port 3000 is already in use.", cls: R, delay: 200 },
        { type: "line", text: "  Choose a different local port or free port 3000.", cls: Y },
      ]
    },
    kill_tunnel: {
      label: "Kill Tunnel",
      icon: "✂",
      desc: "Kill a running SSH tunnel by name",
      steps: [
        { type: "type", text: "bash main.sh tunnel kill api" },
        { type: "progress", label: "Sending SIGTERM to PID 8842…", ms: 400 },
        { type: "line", text: "✔ Tunnel 'api' (PID 8842) terminated.", cls: OK },
      ]
    },
    restart_tunnel: {
      label: "Restart Tunnel",
      icon: "🔄",
      desc: "Restart a stopped SSH tunnel",
      steps: [
        { type: "type", text: "bash main.sh tunnel restart api" },
        { type: "progress", label: "Killing old tunnel…", ms: 300 },
        { type: "progress", label: "Re-establishing tunnel…", ms: 700 },
        { type: "line", text: "✔ Tunnel 'api' restarted (new PID 8901): :3000 → server.com:3000", cls: OK },
      ]
    },
  },

  // ──────────────────────────────────────────────
  // S Y S T E M   &   N E T W O R K
  // ──────────────────────────────────────────────

  port_inspector: {
    default: {
      label: "Port Found",
      icon: "🔍",
      desc: "Find the process holding a port",
      steps: [
        { type: "type", text: "bash main.sh port 3000" },
        { type: "progress", label: "Inspecting port 3000…", ms: 600 },
        { type: "line", text: "COMMAND   PID   USER   TYPE  NODE  NAME", cls: D, delay: 150 },
        { type: "line", text: "node      4521  sahil  IPv4  TCP   *:3000 (LISTEN)", cls: C },
        { type: "line", text: "Terminate PID 4521 holding port 3000? [y/N] n", cls: D, delay: 250 },
      ]
    },
    kill_process: {
      label: "Kill Process",
      icon: "💀",
      desc: "Terminate the process holding a port",
      steps: [
        { type: "type", text: "bash main.sh port 3000 --kill" },
        { type: "progress", label: "Inspecting port 3000…", ms: 400 },
        { type: "line", text: "node  4521  sahil  TCP  *:3000 (LISTEN)", cls: C, delay: 150 },
        { type: "progress", label: "Sending SIGTERM to PID 4521…", ms: 500 },
        { type: "line", text: "✔ Process 4521 terminated. Port 3000 is now free.", cls: OK },
      ]
    },
    port_free: {
      label: "Port Free",
      icon: "✔",
      desc: "No process found on the specified port",
      steps: [
        { type: "type", text: "bash main.sh port 8080" },
        { type: "progress", label: "Inspecting port 8080…", ms: 500 },
        { type: "line", text: "No process found on port 8080.", cls: Y, delay: 200 },
        { type: "line", text: "Port is available for use.", cls: D },
      ]
    },
    invalid_port: {
      label: "Invalid Port",
      icon: "✖",
      desc: "Port number out of valid range",
      steps: [
        { type: "type", text: "bash main.sh port 99999" },
        { type: "line", text: "✖ Invalid port: 99999 (must be 1–65535).", cls: R, delay: 150 },
        { type: "line", text: "Usage: bash _port_inspector.sh PORT [--kill]", cls: D },
      ]
    },
  },

  process_killer: {
    default: {
      label: "Memory View",
      icon: "📊",
      desc: "Show memory overview and top processes",
      steps: [
        { type: "type", text: "bash main.sh proc" },
        { type: "lines", items: [{ text: "RAM    1,823 MB / 7,822 MB  ######------", cls: C }, { text: "Swap     128 MB / 2,048 MB  #-----------", cls: D }], stagger: 150 },
        { type: "line", text: "Top 10 processes by RAM:", cls: D, delay: 200 },
        { type: "lines", items: [{ text: "4521  node    12.4  18.2  1,423 MB   /usr/bin/node app.js", cls: C }, { text: "3892  chrome   8.1   4.2    334 MB   /opt/google/chrome", cls: C }, { text: "1204  firefox  5.3   3.8    214 MB   /usr/lib/firefox", cls: D }], stagger: 120 },
      ]
    },
    kill_success: {
      label: "Kill Success",
      icon: "💀",
      desc: "Send signal to a process and it exits",
      steps: [
        { type: "type", text: "bash main.sh proc --pid 4521 --signal TERM" },
        { type: "lines", items: [{ text: "RAM    1,823 MB / 7,822 MB  ######------", cls: C }, { text: "Swap     128 MB / 2,048 MB  #-----------", cls: D }], stagger: 120 },
        { type: "line", text: "Target process: 4521 node  12.4  18.2", cls: D, delay: 200 },
        { type: "progress", label: "Sending SIGTERM…", ms: 500 },
        { type: "line", text: "✔ Sent SIGTERM to PID 4521 and the process exited.", cls: OK },
      ]
    },
    kill_failure: {
      label: "Kill Failure",
      icon: "✖",
      desc: "Process refuses to terminate",
      steps: [
        { type: "type", text: "bash main.sh proc --pid 4521 --signal KILL" },
        { type: "line", text: "Target process: 4521 node", cls: D, delay: 150 },
        { type: "progress", label: "Sending SIGKILL…", ms: 600 },
        { type: "line", text: "✖ Failed to terminate PID 4521. Permission denied.", cls: R, delay: 200 },
        { type: "line", text: "  Try with sudo or check process ownership.", cls: Y },
      ]
    },
    invalid_pid: {
      label: "Invalid PID",
      icon: "✖",
      desc: "PID does not exist or is invalid",
      steps: [
        { type: "type", text: "bash main.sh proc --pid 99999" },
        { type: "line", text: "✖ PID 99999 does not exist.", cls: R, delay: 150 },
        { type: "line", text: "  Use 'ps aux' or 'pgrep' to find valid PIDs.", cls: Y },
      ]
    },
  },

  battery_doctor: {
    default: {
      label: "Charging",
      icon: "🔌",
      desc: "Battery is charging with top processes",
      steps: [
        { type: "type", text: "bash main.sh battery" },
        { type: "progress", label: "Reading battery status…", ms: 500 },
        { type: "line", text: "percentage: 78%", cls: OK, delay: 150 },
        { type: "line", text: "status: charging", cls: D },
        { type: "line", text: "time to full: 32 minutes", cls: D },
        { type: "line", text: "Top CPU & Memory Processes", cls: D, delay: 200 },
        { type: "lines", items: [{ text: "4521  node    12.4  18.2", cls: C }, { text: "3892  chrome   8.1   4.2", cls: C }, { text: "1204  firefox  5.3   3.8", cls: C }], stagger: 120 },
      ]
    },
    discharging: {
      label: "Discharging",
      icon: "🔋",
      desc: "Battery is discharging (on battery power)",
      steps: [
        { type: "type", text: "bash main.sh battery" },
        { type: "progress", label: "Reading battery status…", ms: 500 },
        { type: "line", text: "percentage: 34%", cls: Y, delay: 150 },
        { type: "line", text: "status: discharging", cls: D },
        { type: "line", text: "time to empty: about 1 hour 12 minutes", cls: D },
        { type: "line", text: "⚠ Battery below 20% at current draw rate.", cls: Y, delay: 200 },
        { type: "lines", items: [{ text: "4521  node    12.4  18.2", cls: C }, { text: "3892  chrome   8.1   4.2", cls: C }], stagger: 100 },
      ]
    },
    no_battery: {
      label: "No Battery",
      icon: "🔲",
      desc: "No battery detected (desktop/server)",
      steps: [
        { type: "type", text: "bash main.sh battery" },
        { type: "progress", label: "Reading battery status…", ms: 500 },
        { type: "line", text: "⚠ No battery detected on this system.", cls: Y, delay: 150 },
        { type: "line", text: "Top CPU & Memory Processes", cls: D, delay: 200 },
        { type: "lines", items: [{ text: "4521  node    12.4  18.2", cls: C }, { text: "3892  chrome   8.1   4.2", cls: C }], stagger: 100 },
      ]
    },
  },

  disk_health: {
    default: {
      label: "Health Check",
      icon: "💾",
      desc: "SMART health check with device attributes",
      steps: [
        { type: "type", text: "bash main.sh disk-health --device /dev/sda" },
        { type: "progress", label: "Querying SMART attributes…", ms: 900 },
        { type: "line", text: "SMART overall-health: PASSED", cls: OK, delay: 150 },
        { type: "line", text: "Power_On_Hours       9,214", cls: D },
        { type: "line", text: "Reallocated_Sectors  0", cls: D },
        { type: "line", text: "Temperature_Celsius  38°C", cls: C },
        { type: "line", text: "Disk: /dev/sda — 512 GB SSD — healthy", cls: OK },
      ]
    },
    test_short: {
      label: "Short Test",
      icon: "🔬",
      desc: "Start a short SMART self-test",
      steps: [
        { type: "type", text: "bash main.sh disk-health --device /dev/sda --test-short" },
        { type: "progress", label: "Starting short SMART self-test…", ms: 600 },
        { type: "line", text: "✔ Short self-test started on /dev/sda.", cls: OK, delay: 150 },
        { type: "line", text: "  Check results in ~2 minutes with --device /dev/sda", cls: D },
      ]
    },
    failing: {
      label: "Failing Disk",
      icon: "⚠",
      desc: "Disk has reallocated sectors or failing health",
      steps: [
        { type: "type", text: "bash main.sh disk-health --device /dev/sdb" },
        { type: "progress", label: "Querying SMART attributes…", ms: 800 },
        { type: "line", text: "SMART overall-health: FAILED", cls: R, delay: 150 },
        { type: "line", text: "Power_On_Hours       14,801", cls: D },
        { type: "line", text: "Reallocated_Sectors  342", cls: R },
        { type: "line", text: "Pending_Sectors      12", cls: R },
        { type: "line", text: "⚠ Disk /dev/sdb is failing. BACK UP DATA IMMEDIATELY.", cls: R },
      ]
    },
    no_smartctl: {
      label: "No smartctl",
      icon: "✖",
      desc: "smartctl not installed on this system",
      steps: [
        { type: "type", text: "bash main.sh disk-health" },
        { type: "line", text: "✖ smartctl not available.", cls: R, delay: 150 },
        { type: "line", text: "  Install smartmontools:", cls: D },
        { type: "line", text: "    apt install smartmontools  (Linux)", cls: C, delay: 80 },
        { type: "line", text: "    brew install smartmontools  (macOS)", cls: C },
      ]
    },
  },

  system_snapshot: {
    default: {
      label: "Default",
      icon: "📸",
      desc: "Collect compact diagnostic summary",
      steps: [
        { type: "type", text: "bash main.sh snapshot" },
        { type: "progress", label: "Collecting diagnostics…", ms: 600 },
        { type: "line", text: "OS: Linux 6.8.0-generic x86_64", cls: D, delay: 150 },
        { type: "line", text: "Platform: linux", cls: D },
        { type: "line", text: "Kernel: 6.8.0-38-generic", cls: D },
        { type: "line", text: "Hostname: dev-machine", cls: D },
        { type: "line", text: "Uptime: 12 days, 4 hours, 32 minutes", cls: D },
        { type: "line", text: "Filesystem  Size  Used Avail Use%", cls: D },
        { type: "line", text: "/dev/sda1   512G  210G  302G  42%", cls: C },
        { type: "line", text: "✔ Snapshot complete.", cls: OK },
      ]
    },
    output_to_file: {
      label: "Save to File",
      icon: "💾",
      desc: "Write snapshot to a file instead of stdout",
      steps: [
        { type: "type", text: "bash main.sh snapshot --output /tmp/sys.txt" },
        { type: "progress", label: "Collecting diagnostics…", ms: 600 },
        { type: "line", text: "OS: Linux 6.8.0-generic x86_64", cls: D, delay: 100 },
        { type: "line", text: "Uptime: 12 days", cls: D },
        { type: "line", text: "Filesystem: 512G total, 210G used, 302G free", cls: D },
        { type: "line", text: "✔ Snapshot written to /tmp/sys.txt", cls: OK },
      ]
    },
  },

  open_files: {
    default: {
      label: "By Port",
      icon: "🔍",
      desc: "Find processes using a TCP port",
      steps: [
        { type: "type", text: "bash main.sh open-files --port 8080" },
        { type: "progress", label: "Querying lsof…", ms: 500 },
        { type: "line", text: "COMMAND  PID  USER  NODE NAME", cls: D, delay: 150 },
        { type: "line", text: "node     4521 sahil TCP  *:8080 (LISTEN)", cls: C },
        { type: "line", text: "chrome   3892 sahil TCP  127.0.0.1:8080→:51752 (ESTABLISHED)", cls: C },
      ]
    },
    by_path: {
      label: "By Path",
      icon: "📂",
      desc: "Find processes using a specific file/directory",
      steps: [
        { type: "type", text: "bash main.sh open-files --path /var/log/syslog" },
        { type: "progress", label: "Querying lsof…", ms: 500 },
        { type: "line", text: "COMMAND  PID   USER  FD   TYPE", cls: D, delay: 150 },
        { type: "line", text: "rsyslog  1024  root  rw   REG   /var/log/syslog", cls: C },
        { type: "line", text: "tail     2201  sahil  r    REG   /var/log/syslog", cls: C },
      ]
    },
    no_results: {
      label: "No Results",
      icon: "🔲",
      desc: "No processes found for the given criteria",
      steps: [
        { type: "type", text: "bash main.sh open-files --port 9999" },
        { type: "progress", label: "Querying lsof…", ms: 400 },
        { type: "line", text: "No processes found using port 9999.", cls: Y, delay: 150 },
      ]
    },
  },

  service_watcher: {
    default: {
      label: "Single Check",
      icon: "🌐",
      desc: "One-shot HTTP health check",
      steps: [
        { type: "type", text: "bash main.sh service https://api.example.com --expect 2xx,3xx" },
        { type: "progress", label: "Checking endpoint…", ms: 700 },
        { type: "line", text: "✔ https://api.example.com code=200 time=0.184s", cls: OK },
      ]
    },
    all_ok: {
      label: "Multi-Check OK",
      icon: "✔",
      desc: "Multiple endpoints all healthy",
      steps: [
        { type: "type", text: "bash main.sh service https://app.example.com https://api.example.com" },
        { type: "progress", label: "Checking 2 endpoints…", ms: 800 },
        { type: "line", text: "✔ https://app.example.com  code=200  time=0.142s", cls: OK, delay: 150 },
        { type: "line", text: "✔ https://api.example.com  code=200  time=0.184s", cls: OK },
        { type: "line", text: "✔ All 2 service(s) healthy.", cls: OK },
      ]
    },
    some_failed: {
      label: "Some Failed",
      icon: "⚠",
      desc: "Some endpoints return errors",
      steps: [
        { type: "type", text: "bash main.sh service https://app.example.com https://down.example.com" },
        { type: "progress", label: "Checking 2 endpoints…", ms: 800 },
        { type: "line", text: "✔ https://app.example.com  code=200  time=0.142s", cls: OK, delay: 150 },
        { type: "line", text: "✖ https://down.example.com  code=503  timeout after 8s", cls: R },
        { type: "line", text: "⚠ 1 of 2 service(s) unhealthy.", cls: Y },
      ]
    },
    interval_loop: {
      label: "Polling Loop",
      icon: "🔄",
      desc: "Continuous monitoring with interval",
      steps: [
        { type: "type", text: "bash main.sh service https://api.example.com --interval 5" },
        { type: "line", text: "Polling every 5s. Press Ctrl+C to stop.", cls: D, delay: 200 },
        { type: "progress", label: "https://api.example.com  200  0.184s  {1}", ms: 600 },
        { type: "progress", label: "https://api.example.com  200  0.172s  {2}", ms: 600 },
        { type: "progress", label: "https://api.example.com  200  0.201s  {3}", ms: 600 },
        { type: "line", text: "^C⏎", cls: R, delay: 100 },
        { type: "line", text: "Stopped after 3 checks.", cls: D },
      ]
    },
  },

  network_probe: {
    default: {
      label: "All Pass",
      icon: "🌐",
      desc: "Ping, DNS, public IP all succeed",
      steps: [
        { type: "type", text: "bash main.sh network github.com --count 4" },
        { type: "progress", label: "Pinging github.com…", ms: 800 },
        { type: "line", text: "4 packets transmitted, 4 received, 0% packet loss", cls: OK, delay: 150 },
        { type: "line", text: "round-trip min/avg/max = 11.2/14.8/19.1 ms", cls: C },
        { type: "progress", label: "Resolving DNS…", ms: 500 },
        { type: "lines", items: [{ text: "A       140.82.112.3", cls: C }, { text: "AAAA     ::1", cls: D }], stagger: 100 },
        { type: "progress", label: "Looking up public IP…", ms: 500 },
        { type: "line", text: "IPv4:  203.0.113.42", cls: OK },
      ]
    },
    packet_loss: {
      label: "Packet Loss",
      icon: "⚠",
      desc: "Some packets lost during ping",
      steps: [
        { type: "type", text: "bash main.sh network unstable.example.com --count 4" },
        { type: "progress", label: "Pinging unstable.example.com…", ms: 1200 },
        { type: "line", text: "4 packets transmitted, 2 received, 50% packet loss", cls: R, delay: 150 },
        { type: "line", text: "round-trip min/avg/max = 42.1/89.3/136.5 ms", cls: Y },
        { type: "progress", label: "Resolving DNS…", ms: 400 },
        { type: "line", text: "A       93.184.216.34", cls: C },
        { type: "line", text: "⚠ Network instability detected — high packet loss.", cls: Y },
      ]
    },
    dns_failure: {
      label: "DNS Failure",
      icon: "✖",
      desc: "DNS resolution fails for the host",
      steps: [
        { type: "type", text: "bash main.sh network nonexistent.domain.test" },
        { type: "progress", label: "Pinging nonexistent.domain.test…", ms: 2000 },
        { type: "line", text: "ping: nonexistent.domain.test: Temporary failure in name resolution", cls: R, delay: 150 },
        { type: "progress", label: "Resolving DNS…", ms: 1000 },
        { type: "line", text: "✖ DNS lookup failed for nonexistent.domain.test", cls: R },
        { type: "line", text: "Check the hostname or your DNS configuration.", cls: Y },
      ]
    },
  },

  tmux_session: {
    default: {
      label: "List Sessions",
      icon: "📋",
      desc: "List all active tmux sessions",
      steps: [
        { type: "type", text: "bash main.sh tmux --list" },
        { type: "progress", label: "Querying tmux server…", ms: 400 },
        { type: "line", text: "●  work         3 windows  attached", cls: OK, delay: 150 },
        { type: "line", text: "○  api-server   1 window   idle", cls: D },
        { type: "line", text: "○  scratch      2 windows  idle", cls: D },
      ]
    },
    create_session: {
      label: "Create Session",
      icon: "➕",
      desc: "Create a new tmux session",
      steps: [
        { type: "type", text: "bash main.sh tmux --new dev" },
        { type: "progress", label: "Creating tmux session 'dev'…", ms: 300 },
        { type: "line", text: "✔ Created tmux session 'dev' (detached).", cls: OK },
      ]
    },
    kill_session: {
      label: "Kill Session",
      icon: "🗑",
      desc: "Kill a tmux session by name",
      steps: [
        { type: "type", text: "bash main.sh tmux --kill scratch" },
        { type: "progress", label: "Killing session 'scratch'…", ms: 300 },
        { type: "line", text: "✔ Killed tmux session 'scratch'.", cls: OK },
      ]
    },
    no_sessions: {
      label: "No Sessions",
      icon: "🔲",
      desc: "No active tmux sessions found",
      steps: [
        { type: "type", text: "bash main.sh tmux --list" },
        { type: "progress", label: "Querying tmux server…", ms: 300 },
        { type: "line", text: "No tmux sessions running.", cls: Y, delay: 150 },
        { type: "line", text: "  Create one with: tmux new -s mysession", cls: D },
      ]
    },
  },

  toolbox_bootstrap: {
    default: {
      label: "All Installed",
      icon: "✔",
      desc: "Most recommended tools are installed",
      steps: [
        { type: "type", text: "bash main.sh toolbox" },
        { type: "progress", label: "Checking 12 recommended CLI tools…", ms: 700 },
        { type: "lines", items: [{ text: "[OK]     fzf", cls: OK }, { text: "[OK]     rg", cls: OK }, { text: "[OK]     fd", cls: OK }, { text: "[OK]     bat", cls: OK }, { text: "[OK]     jq", cls: OK }, { text: "[OK]     curl", cls: OK }, { text: "[OK]     git", cls: OK }, { text: "[OK]     gh", cls: OK }, { text: "[OK]     tmux", cls: OK }], stagger: 100 },
        { type: "line", text: "✔ 9 of 12 tools detected. Your toolbox is in good shape!", cls: OK },
      ]
    },
    some_missing: {
      label: "Some Missing",
      icon: "⚠",
      desc: "Several recommended tools are not installed",
      steps: [
        { type: "type", text: "bash main.sh toolbox" },
        { type: "progress", label: "Checking 12 recommended CLI tools…", ms: 600 },
        { type: "lines", items: [{ text: "[OK]     fzf", cls: OK }, { text: "[OK]     rg", cls: OK }, { text: "[MISSING] fd", cls: R }, { text: "[MISSING] bat", cls: R }, { text: "[OK]     eza", cls: OK }, { text: "[OK]     jq", cls: OK }, { text: "[OK]     curl", cls: OK }, { text: "[OK]     git", cls: OK }, { text: "[MISSING] gh", cls: R }, { text: "[MISSING] tmux", cls: R }, { text: "[MISSING] zoxide", cls: R }, { text: "[MISSING] tldr", cls: R }], stagger: 100 },
        { type: "line", text: "⚠ 4 of 12 tools detected. 8 missing. Consider installing them.", cls: Y },
        { type: "line", text: "  Run bash main.sh toolbox to see install suggestions.", cls: D, delay: 150 },
      ]
    },
  },

  update_managers: {
    default: {
      label: "List Only",
      icon: "📋",
      desc: "Detect and list managers without updating",
      steps: [
        { type: "type", text: "bash main.sh update --list" },
        { type: "progress", label: "Detecting installed package managers…", ms: 900 },
        { type: "lines", items: [{ text: "● System", cls: D }, { text: "  1. apt        Debian/Ubuntu via apt", cls: C }, { text: "● Language", cls: D }, { text: "  2. npm        Node npm globals", cls: C }, { text: "  3. cargo      Cargo binaries", cls: C }], stagger: 120 },
        { type: "line", text: "Detected 3 manager(s).", cls: OK, delay: 200 },
      ]
    },
    update_all: {
      label: "Update All",
      icon: "📥",
      desc: "Non-interactive update of all detected managers",
      steps: [
        { type: "type", text: "bash main.sh update --yes" },
        { type: "progress", label: "Detecting installed package managers…", ms: 700 },
        { type: "line", text: "Updating 3 manager(s)…", cls: D, delay: 200 },
        { type: "progress", label: "[1/3] apt  update && apt  upgrade…", ms: 1500 },
        { type: "line", text: "✔ apt  — 0 upgraded, 0 new, 0 removed.", cls: OK },
        { type: "progress", label: "[2/3] npm  update -g…", ms: 900 },
        { type: "line", text: "✔ npm  — 3 packages updated.", cls: OK },
        { type: "progress", label: "[3/3] cargo  install-update -a…", ms: 800 },
        { type: "line", text: "✔ cargo — 1 crate updated.", cls: OK },
        { type: "line", text: "✔ All 3 manager(s) updated successfully.", cls: OK },
      ]
    },
    some_failed: {
      label: "Some Failed",
      icon: "⚠",
      desc: "One or more managers failed during update",
      steps: [
        { type: "type", text: "bash main.sh update --yes" },
        { type: "progress", label: "Detecting installed package managers…", ms: 600 },
        { type: "progress", label: "[1/3] apt  update…", ms: 1200 },
        { type: "line", text: "✔ apt  — 0 upgraded, 0 new, 0 removed.", cls: OK },
        { type: "progress", label: "[2/3] npm  update -g…", ms: 600 },
        { type: "line", text: "✖ npm  — Error: EACCES: permission denied", cls: R },
        { type: "progress", label: "[3/3] cargo  install-update -a…", ms: 700 },
        { type: "line", text: "✔ cargo — 1 crate updated.", cls: OK },
        { type: "line", text: "⚠ 1 of 3 manager(s) failed. Check logs for details.", cls: Y },
      ]
    },
    interactive_menu: {
      label: "Interactive",
      icon: "🎛",
      desc: "Interactive update selection menu",
      steps: [
        { type: "type", text: "bash main.sh update --interactive" },
        { type: "progress", label: "Detecting installed package managers…", ms: 600 },
        { type: "line", text: "Select an action:", cls: D, delay: 150 },
        { type: "lines", items: [{ text: "1)  Update all managers" }, { text: "2)  Choose managers to update" }, { text: "3)  Toggle dry-run mode" }, { text: "4)  Quit" }], stagger: 100 },
        { type: "line", text: "Choice [1-4]: 1", cls: C, delay: 200 },
        { type: "progress", label: "Updating all managers…", ms: 1200 },
        { type: "line", text: "✔ All 3 manager(s) updated.", cls: OK },
      ]
    },
  },

  // ──────────────────────────────────────────────
  // F I L E S   &   S E C U R I T Y
  // ──────────────────────────────────────────────

  duplicate_finder: {
    default: {
      label: "Report Only",
      icon: "🔍",
      desc: "Scan and report duplicates without deleting",
      steps: [
        { type: "type", text: "bash main.sh dup ~/Downloads" },
        { type: "progress", label: "Grouping files by size, then hashing…", ms: 1000 },
        { type: "line", text: "Duplicate groups found:", cls: D, delay: 200 },
        { type: "lines", items: [{ text: "Group 1 (1.2 MB):", cls: Y }, { text: "  Keep: photo.jpg", cls: C }, { text: "  Dupe: photo_copy.jpg", cls: D }, { text: "Group 2 (240 KB):", cls: Y }, { text: "  Keep: report.pdf", cls: C }, { text: "  Dupe: report (1).pdf", cls: D }], stagger: 120 },
        { type: "line", text: "Total: 2 groups, 2 duplicate files, 1.4 MB reclaimable", cls: D, delay: 200 },
      ]
    },
    delete_success: {
      label: "Delete Success",
      icon: "🧹",
      desc: "Delete duplicates and reclaim space",
      steps: [
        { type: "type", text: "bash main.sh dup ~/Downloads --delete --apply" },
        { type: "progress", label: "Grouping files by size, then hashing…", ms: 900 },
        { type: "line", text: "Keep:   photo.jpg", cls: C, delay: 150 },
        { type: "line", text: "Dupe:   photo_copy.jpg  (will be removed)", cls: Y },
        { type: "line", text: "Keep:   report.pdf", cls: C },
        { type: "line", text: "Dupe:   report (1).pdf  (will be removed)", cls: Y },
        { type: "progress", label: "Deleting duplicates…", ms: 600 },
        { type: "line", text: "✔ Processed 2 duplicate file(s). Reclaimed 1.4 MB.", cls: OK },
      ]
    },
    hardlink: {
      label: "Hardlink",
      icon: "🔗",
      desc: "Replace duplicates with hardlinks to save space",
      steps: [
        { type: "type", text: "bash main.sh dup ~/Downloads --hardlink --apply" },
        { type: "progress", label: "Grouping files by size, then hashing…", ms: 800 },
        { type: "line", text: "Keep:   photo.jpg", cls: C, delay: 150 },
        { type: "line", text: "Dupe:   photo_copy.jpg  (will be hardlinked)", cls: Y },
        { type: "progress", label: "Hardlinking duplicates…", ms: 500 },
        { type: "line", text: "✔ Replaced 2 duplicate(s) with hardlinks.", cls: OK },
        { type: "line", text: "  Logical size: 2.4 MB → Physical size: 1.0 MB", cls: D },
      ]
    },
    no_duplicates: {
      label: "No Dupes",
      icon: "✔",
      desc: "No duplicate files found",
      steps: [
        { type: "type", text: "bash main.sh dup ~/Downloads" },
        { type: "progress", label: "Grouping files by size, then hashing…", ms: 800 },
        { type: "line", text: "No duplicate files found. Your collection is clean!", cls: OK, delay: 200 },
      ]
    },
  },

  archive_manager: {
    default: {
      label: "List Archive",
      icon: "📋",
      desc: "List contents of an archive without extracting",
      steps: [
        { type: "type", text: "bash main.sh archive --list backup.tar.gz" },
        { type: "progress", label: "Reading archive…", ms: 500 },
        { type: "lines", items: [{ text: "drwxr-xr-x  src/", cls: C }, { text: "-rw-r--r--  src/index.js", cls: D }, { text: "-rw-r--r--  src/utils.js", cls: D }, { text: "-rw-r--r--  package.json", cls: D }], stagger: 100 },
        { type: "line", text: "Archive: backup.tar.gz (4 items, 4.2 MB)", cls: D, delay: 150 },
      ]
    },
    create_archive: {
      label: "Create Archive",
      icon: "📦",
      desc: "Create a tar.gz archive from files",
      steps: [
        { type: "type", text: "bash main.sh archive --create backup.tar.gz ./src" },
        { type: "progress", label: "Archiving ./src…", ms: 900 },
        { type: "line", text: "✔ Created backup.tar.gz (4.2 MB)", cls: OK },
      ]
    },
    extract_archive: {
      label: "Extract Archive",
      icon: "📂",
      desc: "Safely extract archive to destination",
      steps: [
        { type: "type", text: "bash main.sh archive --extract backup.tar.gz --dest ./restored" },
        { type: "progress", label: "Validating archive paths…", ms: 500 },
        { type: "progress", label: "Extracting to ./restored…", ms: 700 },
        { type: "line", text: "✔ Extracted 4 items to ./restored", cls: OK },
      ]
    },
    extract_failure: {
      label: "Extract Failed",
      icon: "✖",
      desc: "Archive extraction encounters an error",
      steps: [
        { type: "type", text: "bash main.sh archive --extract corrupt.zip --dest ./out" },
        { type: "progress", label: "Validating archive paths…", ms: 400 },
        { type: "line", text: "✖ Error extracting corrupt.zip: unsupported format or corrupt file.", cls: R, delay: 200 },
        { type: "line", text: "  Try: file corrupt.zip  to check the format.", cls: Y },
      ]
    },
  },

  media_convert: {
    default: {
      label: "Images → WebP",
      icon: "🖼",
      desc: "Batch convert images to WebP format",
      steps: [
        { type: "type", text: "bash main.sh media --kind image --to webp --quality 85 --apply ~/Pictures" },
        { type: "progress", label: "Scanning ~/Pictures…", ms: 500 },
        { type: "line", text: "3 file(s) found.", cls: D, delay: 150 },
        { type: "progress", label: "Converting holiday.jpg → holiday.webp…", ms: 700 },
        { type: "line", text: "✔ Created: converted_image/holiday.webp (320 KB)" },
        { type: "progress", label: "Converting sunset.png → sunset.webp…", ms: 700 },
        { type: "line", text: "✔ Created: converted_image/sunset.webp (1.1 MB)" },
        { type: "line", text: "✔ 2 file(s) converted successfully.", cls: OK },
      ]
    },
    strip_exif: {
      label: "Strip EXIF",
      icon: "🔏",
      desc: "Remove EXIF metadata during conversion",
      steps: [
        { type: "type", text: "bash main.sh media --kind image --to jpg --strip-exif --apply ~/Photos" },
        { type: "progress", label: "Scanning ~/Photos…", ms: 400 },
        { type: "line", text: "2 file(s) found.", cls: D, delay: 150 },
        { type: "progress", label: "Converting + stripping EXIF: photo.jpg…", ms: 600 },
        { type: "line", text: "✔ Created: converted_image/photo.jpg (EXIF stripped)", cls: OK },
        { type: "line", text: "✔ EXIF data removed from 2 file(s).", cls: OK },
      ]
    },
    video_convert: {
      label: "Video Convert",
      icon: "🎬",
      desc: "Batch convert videos to MP4",
      steps: [
        { type: "type", text: "bash main.sh media --kind video --to mp4 --apply ~/Videos" },
        { type: "progress", label: "Scanning ~/Videos…", ms: 400 },
        { type: "line", text: "1 file(s) found.", cls: D, delay: 150 },
        { type: "progress", label: "Converting demo.avi → demo.mp4…", ms: 1800 },
        { type: "line", text: "✔ Created: converted_video/demo.mp4 (24 MB)", cls: OK },
      ]
    },
    dry_run: {
      label: "Dry-Run",
      icon: "🔍",
      desc: "Preview what would be converted without applying",
      steps: [
        { type: "type", text: "bash main.sh media --kind image --to webp ~/Pictures" },
        { type: "progress", label: "Scanning ~/Pictures…", ms: 400 },
        { type: "lines", items: [{ text: "Would convert: holiday.jpg → holiday.webp (quality 82)", cls: C }, { text: "Would convert: sunset.png → sunset.webp (quality 82)", cls: C }], stagger: 130 },
        { type: "line", text: "Dry-run complete. Use --apply to execute conversions.", cls: Y },
      ]
    },
  },

  backup_sync: {
    default: {
      label: "Dry-Run",
      icon: "🔍",
      desc: "Preview changes without copying",
      steps: [
        { type: "type", text: "bash main.sh backup --source ~/Documents --dest /mnt/backup" },
        { type: "progress", label: "Running rsync (dry-run)…", ms: 1300 },
        { type: "lines", items: [{ text: ">f+++++++++ report-2026.pdf", cls: C }, { text: ">f+++++++++ ledger.xlsx", cls: C }, { text: ".d..t...... .", cls: D }], stagger: 150 },
        { type: "line", text: "Dry-run: 214 files would be transferred (1.4 GB).", cls: D, delay: 150 },
        { type: "line", text: "Use --apply to perform the backup.", cls: Y },
      ]
    },
    rsync_success: {
      label: "Sync Success",
      icon: "✔",
      desc: "Full rsync backup completes successfully",
      steps: [
        { type: "type", text: "bash main.sh backup --source ~/Documents --dest /mnt/backup --apply" },
        { type: "progress", label: "Running rsync…", ms: 1400 },
        { type: "lines", items: [{ text: ">f+++++++++ report-2026.pdf", cls: C }, { text: ">f+++++++++ ledger.xlsx", cls: C }], stagger: 130 },
        { type: "line", text: "✔ Sync complete — 214 files, 1.4 GB transferred.", cls: OK },
      ]
    },
    delete_mode: {
      label: "Delete Mode",
      icon: "🗑",
      desc: "Sync with --delete to mirror source exactly",
      steps: [
        { type: "type", text: "bash main.sh backup --source ~/Documents --dest /mnt/backup --apply --delete" },
        { type: "progress", label: "Running rsync with --delete…", ms: 1200 },
        { type: "lines", items: [{ text: ">f+++++++++ report-2026.pdf", cls: C }, { text: "*deleting   old-draft.docx", cls: R }], stagger: 140 },
        { type: "line", text: "✔ Sync complete — 214 copied, 1 deleted.", cls: OK },
      ]
    },
    cp_fallback: {
      label: "CP Fallback",
      icon: "📂",
      desc: "Fallback to cp when rsync is unavailable",
      steps: [
        { type: "type", text: "bash main.sh backup --source ~/Documents --dest /mnt/backup --apply" },
        { type: "line", text: "⚠ rsync not found — falling back to cp.", cls: Y, delay: 200 },
        { type: "progress", label: "Scanning with find…", ms: 600 },
        { type: "progress", label: "Copying 214 files…", ms: 1500 },
        { type: "line", text: "✔ Copied 214 files to /mnt/backup. (Excluded: .git, node_modules)", cls: OK },
      ]
    },
  },

  shredder: {
    default: {
      label: "Dry-Run",
      icon: "🔍",
      desc: "Preview what would be erased without applying",
      steps: [
        { type: "type", text: "bash main.sh shred --passes 3 secret.txt" },
        { type: "line", text: "Method:  shred -n 3 -z -u", cls: D, delay: 200 },
        { type: "line", text: "File:    secret.txt (12 KB)", cls: D },
        { type: "line", text: "Passes:  3", cls: D },
        { type: "line", text: "Dry-run: use --apply to securely erase.", cls: Y },
      ]
    },
    erase_success: {
      label: "Erase Success",
      icon: "💀",
      desc: "Multi-pass secure erase completes",
      steps: [
        { type: "type", text: "bash main.sh shred --passes 7 --apply secret.txt" },
        { type: "line", text: "Method:  shred -n 7 -z -u", cls: D, delay: 200 },
        { type: "progress", label: "Overwriting secret.txt (7 passes)…", ms: 1400 },
        { type: "line", text: "✔ Securely erased: secret.txt", cls: OK },
      ]
    },
    erase_failure: {
      label: "Erase Failure",
      icon: "✖",
      desc: "File cannot be erased (permissions or missing)",
      steps: [
        { type: "type", text: "bash main.sh shred --passes 3 --apply /etc/shadow" },
        { type: "line", text: "✖ Error: Permission denied for /etc/shadow.", cls: R, delay: 150 },
        { type: "line", text: "  Try with sudo or check file permissions.", cls: Y },
      ]
    },
    multi_file: {
      label: "Multiple Files",
      icon: "📂",
      desc: "Securely erase multiple files at once",
      steps: [
        { type: "type", text: "bash main.sh shred --passes 3 --apply secret.txt key.pem token.key" },
        { type: "progress", label: "Overwriting secret.txt (3 passes)…", ms: 800 },
        { type: "line", text: "✔ Securely erased: secret.txt", cls: OK },
        { type: "progress", label: "Overwriting key.pem (3 passes)…", ms: 900 },
        { type: "line", text: "✔ Securely erased: key.pem", cls: OK },
        { type: "progress", label: "Overwriting token.key (3 passes)…", ms: 700 },
        { type: "line", text: "✔ Securely erased: token.key", cls: OK },
        { type: "line", text: "✔ 3 file(s) securely erased.", cls: OK },
      ]
    },
  },

  dotenv_vault: {
    default: {
      label: "Encrypt Key",
      icon: "🔐",
      desc: "Encrypt a .env value with GPG",
      steps: [
        { type: "type", text: "bash main.sh dotenv --file .env --encrypt API_TOKEN --apply" },
        { type: "line", text: "Encrypting value for API_TOKEN with gpg…", cls: D, delay: 300 },
        { type: "progress", label: "Encrypting…", ms: 800 },
        { type: "line", text: "✔ Encrypted API_TOKEN in .env (backup created)", cls: OK },
        { type: "line", text: "  Backup: .env.20260725_142201.bak", cls: D },
      ]
    },
    decrypt: {
      label: "Decrypt All",
      icon: "🔓",
      desc: "Decrypt all ENC:: tokens in a .env file",
      steps: [
        { type: "type", text: "bash main.sh dotenv --file .env --decrypt" },
        { type: "progress", label: "Decrypting tokens…", ms: 700 },
        { type: "lines", items: [{ text: "API_TOKEN=sk_live_abc123…", cls: C }, { text: "DB_PASSWORD=supersecret42", cls: C }], stagger: 150 },
        { type: "line", text: "✔ Decrypted 2 token(s).", cls: OK },
      ]
    },
    dry_run: {
      label: "Dry-Run",
      icon: "🔍",
      desc: "Preview encrypted output without writing",
      steps: [
        { type: "type", text: "bash main.sh dotenv --file .env --encrypt API_TOKEN" },
        { type: "line", text: "Encrypting value for API_TOKEN with gpg…", cls: D, delay: 250 },
        { type: "progress", label: "Encrypting…", ms: 600 },
        { type: "line", text: "Would update: .env", cls: C },
        { type: "line", text: "  API_TOKEN=ENC::<encrypted_value>", cls: D },
        { type: "line", text: "Dry-run: use --apply to write changes.", cls: Y },
      ]
    },
    gpg_missing: {
      label: "GPG Missing",
      icon: "✖",
      desc: "GPG is not installed on the system",
      steps: [
        { type: "type", text: "bash main.sh dotenv --file .env --encrypt API_TOKEN" },
        { type: "line", text: "✖ gpg is required but not found in PATH.", cls: R, delay: 150 },
        { type: "line", text: "  Install gnupg: apt install gnupg  or  brew install gnupg", cls: Y },
      ]
    },
  },

  pdf_toolkit: {
    default: {
      label: "PDF Info",
      icon: "📄",
      desc: "Show PDF metadata and page count",
      steps: [
        { type: "type", text: "bash main.sh pdf info report.pdf" },
        { type: "progress", label: "Analyzing PDF…", ms: 500 },
        { type: "lines", items: [{ text: "File:       report.pdf", cls: D }, { text: "Pages:      42", cls: C }, { text: "PDF version: 1.7", cls: D }, { text: "Encrypted:  No", cls: OK }, { text: "Title:      Annual Report 2026", cls: D }, { text: "Author:     Sahil", cls: D }], stagger: 100 },
      ]
    },
    merge: {
      label: "Merge PDFs",
      icon: "🔗",
      desc: "Merge multiple PDFs into one document",
      steps: [
        { type: "type", text: "bash main.sh pdf merge a.pdf b.pdf c.pdf --output merged.pdf --apply" },
        { type: "progress", label: "Merging PDFs with qpdf…", ms: 800 },
        { type: "line", text: "✔ Merged 3 PDFs (85 pages) into merged.pdf.", cls: OK },
      ]
    },
    compress: {
      label: "Compress PDF",
      icon: "📦",
      desc: "Compress PDF to reduce file size",
      steps: [
        { type: "type", text: "bash main.sh pdf compress large.pdf --output compressed.pdf --apply" },
        { type: "progress", label: "Compressing with Ghostscript…", ms: 1200 },
        { type: "line", text: "✔ Compressed: 24 MB → 6.2 MB", cls: OK },
      ]
    },
    split: {
      label: "Split PDF",
      icon: "✂",
      desc: "Split PDF into individual pages",
      steps: [
        { type: "type", text: "bash main.sh pdf split report.pdf --output pages --apply" },
        { type: "progress", label: "Splitting 42 pages…", ms: 1000 },
        { type: "line", text: "✔ Split 42 pages into ./pages/", cls: OK },
      ]
    },
    interactive_wizard: {
      label: "Interactive",
      icon: "🎛",
      desc: "Prompt-driven PDF action wizard",
      steps: [
        { type: "type", text: "bash main.sh pdf" },
        { type: "line", text: "Action (info, count, merge, split, text, compress, rotate) [info]:", cls: C, delay: 150 },
        { type: "type", text: "info" },
        { type: "line", text: "PDF file:", cls: C, delay: 150 },
        { type: "type", text: "report.pdf" },
        { type: "progress", label: "Analyzing…", ms: 500 },
        { type: "line", text: "Pages: 42 | Version: 1.7 | Title: Annual Report 2026", cls: C },
      ]
    },
  },

  image_tool: {
    default: {
      label: "Image Info",
      icon: "🖼",
      desc: "Show image dimensions, format, size",
      steps: [
        { type: "type", text: "bash main.sh image info photo.jpg" },
        { type: "progress", label: "Analyzing image…", ms: 400 },
        { type: "lines", items: [{ text: "File:     photo.jpg", cls: D }, { text: "Format:   JPEG", cls: D }, { text: "Dimensions: 1920 × 1080", cls: C }, { text: "Size:     1.2 MB", cls: D }], stagger: 100 },
      ]
    },
    resize: {
      label: "Resize Image",
      icon: "📐",
      desc: "Resize image to specific width",
      steps: [
        { type: "type", text: "bash main.sh image resize photo.jpg --width 800 --out resized.jpg --apply" },
        { type: "progress", label: "Resizing with ImageMagick…", ms: 700 },
        { type: "line", text: "✔ Resized: resized.jpg (800×450)", cls: OK },
      ]
    },
    convert: {
      label: "Convert Format",
      icon: "🔄",
      desc: "Convert image to a different format",
      steps: [
        { type: "type", text: "bash main.sh image convert photo.png --format webp --quality 90 --out photo.webp --apply" },
        { type: "progress", label: "Converting with ImageMagick…", ms: 600 },
        { type: "line", text: "✔ Converted: photo.png → photo.webp (2.4 MB → 480 KB)", cls: OK },
      ]
    },
    optimize: {
      label: "Optimize",
      icon: "📦",
      desc: "Compress and optimize image file size",
      steps: [
        { type: "type", text: "bash main.sh image optimize photo.png --quality 85 --apply" },
        { type: "progress", label: "Optimizing with optipng…", ms: 900 },
        { type: "line", text: "✔ Optimized: photo.png (2.4 MB → 1.1 MB, 54% reduction)", cls: OK },
      ]
    },
  },

  project_search: {
    default: {
      label: "Text Search",
      icon: "🔍",
      desc: "Search file contents for a pattern",
      steps: [
        { type: "type", text: "bash main.sh search --text TODO ./src" },
        { type: "progress", label: "Searching with ripgrep…", ms: 600 },
        { type: "lines", items: [{ text: "src/auth.js:42:  // TODO: rotate refresh tokens", cls: C }, { text: "src/db.js:118: // TODO: add index on created_at", cls: C }, { text: "src/api.js:7:   // TODO: add rate limiting", cls: C }], stagger: 130 },
        { type: "line", text: "3 matches found in 3 files.", cls: D, delay: 150 },
      ]
    },
    name_search: {
      label: "Name Search",
      icon: "📁",
      desc: "Search for files by glob pattern",
      steps: [
        { type: "type", text: 'bash main.sh search --name "*.sh" ./modules' },
        { type: "progress", label: "Searching with find…", ms: 500 },
        { type: "lines", items: [{ text: "modules/_qr_tool/_qr_tool.sh", cls: C }, { text: "modules/_weather/_weather.sh", cls: C }, { text: "modules/_cache_clean/_cache_clean.sh", cls: C }], stagger: 100 },
        { type: "line", text: "65 files matched.", cls: D, delay: 150 },
      ]
    },
    no_results: {
      label: "No Results",
      icon: "🔲",
      desc: "No matches found for the pattern",
      steps: [
        { type: "type", text: "bash main.sh search --text FIXME ./src" },
        { type: "progress", label: "Searching…", ms: 400 },
        { type: "line", text: "No matches found.", cls: Y, delay: 150 },
      ]
    },
  },

  // ──────────────────────────────────────────────
  // P R O D U C T I V I T Y
  // ──────────────────────────────────────────────

  log_inspector: {
    default: {
      label: "With Matches",
      icon: "📋",
      desc: "Pattern matches found in log file",
      steps: [
        { type: "type", text: 'bash main.sh log-inspect app.log --pattern "error|warn"' },
        { type: "progress", label: "Scanning log file…", ms: 700 },
        { type: "line", text: "=== Pattern Matches ===", cls: D, delay: 150 },
        { type: "lines", items: [{ text: "2026-07-24 03:14  WARN  cache nearly full", cls: Y }, { text: "2026-07-24 03:15  ERROR connection refused", cls: R }, { text: "2026-07-24 03:16  ERROR timeout in request", cls: R }], stagger: 120 },
        { type: "line", text: "=== Frequency Summary (Top 3) ===", cls: D, delay: 200 },
        { type: "lines", items: [{ text: "  14  connection refused", cls: C }, { text: "   3  timeout in request", cls: C }, { text: "   2  cache nearly full", cls: C }], stagger: 100 },
      ]
    },
    no_matches: {
      label: "No Matches",
      icon: "✔",
      desc: "Pattern found no matches in the log",
      steps: [
        { type: "type", text: 'bash main.sh log-inspect app.log --pattern "critical"' },
        { type: "progress", label: "Scanning log file…", ms: 500 },
        { type: "line", text: "(no matches)", cls: Y, delay: 150 },
        { type: "line", text: "No lines matched the pattern 'critical'.", cls: D },
      ]
    },
    file_not_found: {
      label: "File Not Found",
      icon: "✖",
      desc: "Specified log file does not exist",
      steps: [
        { type: "type", text: 'bash main.sh log-inspect missing.log' },
        { type: "line", text: "✖ Log file not found: missing.log", cls: R, delay: 150 },
        { type: "line", text: "  Check the file path and try again.", cls: Y },
      ]
    },
  },

  ssl_checker: {
    default: {
      label: "Healthy Cert",
      icon: "✔",
      desc: "Certificate is valid with >30 days remaining",
      steps: [
        { type: "type", text: "bash main.sh ssl example.com --port 443" },
        { type: "progress", label: "Fetching certificate…", ms: 800 },
        { type: "line", text: "Subject:  CN=example.com", cls: C, delay: 150 },
        { type: "line", text: "Issuer:   C=US, O=Let's Encrypt, CN=R3", cls: D },
        { type: "line", text: "Days left: 63", cls: OK },
        { type: "progress", label: "Checking DNS records…", ms: 500 },
        { type: "lines", items: [{ text: "A       93.184.216.34", cls: C }, { text: "AAAA    2606:2800:220:1:248:1893:25c8:1946", cls: D }], stagger: 100 },
        { type: "progress", label: "Probing legacy TLS 1.0/1.1…", ms: 700 },
        { type: "line", text: "✔ TLS 1.0 rejected.  ✔ TLS 1.1 rejected.", cls: OK },
      ]
    },
    expiring_soon: {
      label: "Expiring Soon",
      icon: "⚠",
      desc: "Certificate expires within 30 days",
      steps: [
        { type: "type", text: "bash main.sh ssl expiring.example.com" },
        { type: "progress", label: "Fetching certificate…", ms: 700 },
        { type: "line", text: "Subject:  CN=expiring.example.com", cls: C, delay: 150 },
        { type: "line", text: "Issuer:   C=US, O=Let's Encrypt, CN=R3", cls: D },
        { type: "line", text: "Days left: 12", cls: Y },
        { type: "line", text: "⚠ Certificate expires in 12 days. Renew soon!", cls: Y },
      ]
    },
    expired: {
      label: "Expired",
      icon: "✖",
      desc: "Certificate has already expired",
      steps: [
        { type: "type", text: "bash main.sh ssl expired.example.com" },
        { type: "progress", label: "Fetching certificate…", ms: 600 },
        { type: "line", text: "Subject:  CN=expired.example.com", cls: C, delay: 150 },
        { type: "line", text: "Days left: -14 (expired)", cls: R },
        { type: "line", text: "✖ Certificate has EXPIRED. Renew immediately!", cls: R },
      ]
    },
    connection_failed: {
      label: "Conn Failed",
      icon: "✖",
      desc: "Failed to establish TLS connection",
      steps: [
        { type: "type", text: "bash main.sh ssl down.example.com" },
        { type: "progress", label: "Fetching certificate…", ms: 3000 },
        { type: "line", text: "✖ Failed to establish TLS connection to down.example.com:443", cls: R, delay: 150 },
        { type: "line", text: "  Connection timed out.", cls: D },
        { type: "line", text: "  Is the server running and reachable?", cls: Y },
      ]
    },
  },

  font_inspector: {
    default: {
      label: "Glyph Test",
      icon: "🔤",
      desc: "Display terminal glyph support samples",
      steps: [
        { type: "type", text: "bash main.sh font --glyphs" },
        { type: "line", text: "ASCII ABC 123", cls: OK, delay: 150 },
        { type: "line", text: "Box ┌─┐ │ ╰─╯", cls: C },
        { type: "line", text: "Powerline  ", cls: D },
        { type: "line", text: "Nerd Fonts       ", cls: C },
        { type: "line", text: "All glyph samples rendered correctly.", cls: OK, delay: 200 },
      ]
    },
    list_fonts: {
      label: "List Fonts",
      icon: "📋",
      desc: "List available system fonts",
      steps: [
        { type: "type", text: "bash main.sh font --list" },
        { type: "progress", label: "Querying fontconfig…", ms: 400 },
        { type: "lines", items: [{ text: "JetBrains Mono", cls: C }, { text: "Fira Code", cls: C }, { text: "Source Code Pro", cls: C }, { text: "Ubuntu Mono", cls: C }, { text: "Noto Sans Mono", cls: C }], stagger: 100 },
        { type: "line", text: "Showing 5 of 24 installed fonts.", cls: D, delay: 150 },
      ]
    },
    filtered_list: {
      label: "Filtered List",
      icon: "🔍",
      desc: "Filter fonts by name pattern",
      steps: [
        { type: "type", text: "bash main.sh font --list --filter Mono" },
        { type: "progress", label: "Querying fontconfig…", ms: 400 },
        { type: "lines", items: [{ text: "JetBrains Mono", cls: C }, { text: "Ubuntu Mono", cls: C }, { text: "Noto Sans Mono", cls: C }], stagger: 100 },
        { type: "line", text: "Showing 3 fonts matching 'Mono'.", cls: D, delay: 150 },
      ]
    },
  },

  clipboard_history: {
    default: {
      label: "List History",
      icon: "📋",
      desc: "Show clipboard history entries",
      steps: [
        { type: "type", text: "bash main.sh clipboard list" },
        { type: "progress", label: "Reading clipboard history…", ms: 400 },
        { type: "lines", items: [{ text: " 3  ★  API_KEY=sk_live_...          2m ago", cls: Y }, { text: ' 2     git commit -m "fix: race..."  9m ago', cls: C }, { text: " 1     https://utilitykit.dev        1h ago", cls: C }], stagger: 120 },
        { type: "line", text: "Showing 3 entries (max: 200). ★ = pinned.", cls: D, delay: 150 },
      ]
    },
    add_entry: {
      label: "Add Entry",
      icon: "➕",
      desc: "Add a new clipboard entry",
      steps: [
        { type: "type", text: 'bash main.sh clipboard add "git stash pop"' },
        { type: "line", text: "✔ Added to clipboard history.", cls: OK, delay: 200 },
        { type: "type", text: "bash main.sh clipboard list", delay: 400 },
        { type: "line", text: " 4     git stash pop                 just now", cls: C, delay: 100 },
        { type: "lines", items: [{ text: " 3  ★  API_KEY=sk_live_...          2m ago", cls: Y }, { text: ' 2     git commit -m "fix: race..."  9m ago', cls: C }], stagger: 100 },
      ]
    },
    find_entry: {
      label: "Search",
      icon: "🔍",
      desc: "Fuzzy search clipboard history",
      steps: [
        { type: "type", text: "bash main.sh clipboard find API_KEY" },
        { type: "progress", label: "Searching…", ms: 300 },
        { type: "lines", items: [{ text: " 3  ★  API_KEY=sk_live_...          2m ago", cls: Y }], stagger: 100 },
        { type: "line", text: "1 match found.", cls: D, delay: 150 },
      ]
    },
    clear_history: {
      label: "Clear History",
      icon: "🗑",
      desc: "Clear all clipboard history entries",
      steps: [
        { type: "type", text: "bash main.sh clipboard clear" },
        { type: "line", text: "Clear ALL clipboard history? This cannot be undone.", cls: R, delay: 200 },
        { type: "line", text: "Are you sure? [y/N] y", cls: D },
        { type: "progress", label: "Clearing history…", ms: 300 },
        { type: "line", text: "✔ History cleared.", cls: OK },
      ]
    },
    interactive_menu: {
      label: "Interactive",
      icon: "🎛",
      desc: "Interactive clipboard management menu",
      steps: [
        { type: "type", text: "bash main.sh clipboard" },
        { type: "line", text: "Action (list, add, get, show, find, pin, unpin, remove, clear):", cls: C, delay: 150 },
        { type: "type", text: "list" },
        { type: "lines", items: [{ text: " 3  ★  API_KEY=sk_live_...          2m ago", cls: Y }, { text: " 2     git commit -m...             9m ago", cls: C }], stagger: 100 },
        { type: "line", text: "Action: list", cls: D, delay: 150 },
      ]
    },
  },

  yt_download: {
    default: {
      label: "Video Info",
      icon: "ℹ",
      desc: "Show video metadata without downloading",
      steps: [
        { type: "type", text: "bash main.sh ytdl info https://youtube.com/watch?v=demo" },
        { type: "progress", label: "Fetching video metadata…", ms: 900 },
        { type: "lines", items: [{ text: "Title:    Building a Bash Toolkit", cls: C }, { text: "Channel:  UtilityKit", cls: D }, { text: "Duration: 12:34", cls: D }, { text: "Views:    18,204", cls: D }, { text: "Likes:    847", cls: D }], stagger: 120 },
      ]
    },
    audio_extract: {
      label: "Audio Extract",
      icon: "🎵",
      desc: "Download and extract audio as MP3",
      steps: [
        { type: "type", text: "bash main.sh ytdl audio https://youtube.com/watch?v=demo" },
        { type: "progress", label: "Downloading best audio stream…", ms: 2000 },
        { type: "progress", label: "Converting to mp3…", ms: 1000 },
        { type: "line", text: "✔ Download complete: Building a Bash Toolkit.mp3", cls: OK },
      ]
    },
    download_success: {
      label: "Download Video",
      icon: "📥",
      desc: "Full video download with subtitles and thumbnail",
      steps: [
        { type: "type", text: "bash main.sh ytdl download https://youtube.com/watch?v=demo --subs" },
        { type: "progress", label: "Downloading video…", ms: 2500 },
        { type: "progress", label: "Embedding subtitles…", ms: 500 },
        { type: "progress", label: "Embedding thumbnail…", ms: 400 },
        { type: "line", text: "✔ Download complete: Building a Bash Toolkit.mp4", cls: OK },
        { type: "line", text: "  Format: 1080p | Size: 124 MB | Subtitles: embedded", cls: D },
      ]
    },
    interactive_wizard: {
      label: "Interactive",
      icon: "🎛",
      desc: "Full interactive download wizard",
      steps: [
        { type: "type", text: "bash main.sh ytdl https://youtube.com/watch?v=demo" },
        { type: "progress", label: "Fetching info…", ms: 800 },
        { type: "line", text: "Title: Building a Bash Toolkit | Channel: UtilityKit", cls: C, delay: 150 },
        { type: "line", text: "Extract audio only? [y/N] n", cls: D },
        { type: "line", text: "Download subtitles? [Y/n] y", cls: D, delay: 150 },
        { type: "line", text: "Embed thumbnail? [Y/n] y", cls: D },
        { type: "line", text: "Output directory [~/Downloads/YouTube]:", cls: C, delay: 150 },
        { type: "type", text: "./downloads" },
        { type: "line", text: "Proceed with download? [Y/n] y", cls: D },
        { type: "progress", label: "Downloading…", ms: 2000 },
        { type: "line", text: "✔ Download complete: Building a Bash Toolkit.mp4", cls: OK },
      ]
    },
  },

  // ──────────────────────────────────────────────
  // P L A C E H O L D E R S   (real tools need empty entries)
  // ──────────────────────────────────────────────

  json_explorer_cli: {
    default: {
      label: "JSON Explorer",
      icon: "▶",
      desc: "Placeholder — real component handles this",
      steps: [
        { type: "line", text: "Use the live interactive component for JSON.", cls: D },
        { type: "line", text: "This simulation is a placeholder.", cls: D },
      ]
    },
  },
};