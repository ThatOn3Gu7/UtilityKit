# cacheclean

A beautiful, safe, cross-platform bash CLI tool that intelligently cleans stale
and orphaned cache files from development package managers.

## Features

- **Safe by default**: shows a dry-run preview, lists every file that will be
  deleted, and asks for a second confirmation before any permanent deletion.
- **Targeted scanning**: only inspects known cache directories of detected
  package managers. Never wanders into project folders or scans the whole disk.
- **Modular plugins**: 17 built-in plugins covering language-specific and
  system package managers (npm, yarn, pnpm, bun, pip, cargo, go, gem, composer,
  dotnet, conan, vcpkg, apt, pacman, dnf, brew, apk).
- **Cross-platform**: works on Linux, macOS, Git Bash for Windows, and Android
  (Termux) without root.
- **Portable POSIX-ish bash**: no external dependencies beyond common shell tools
  (`du`, `find`, `wc`, `awk`, optional `stat`).
- **Responsive layout**: switches to a compact card view on narrow/mobile
  terminals and auto-detects terminal width for the best fit.

## Install

```bash
chmod +x cacheclean.sh
ln -s "$PWD/cacheclean.sh" ~/.local/bin/cacheclean
```

Or just run it directly from the repository directory:

```bash
./cacheclean.sh
```

## Usage

```bash
cacheclean                          # dry-run preview + prompt
cacheclean --yes                    # preview, then auto-delete
cacheclean --delete                 # same as --yes
cacheclean --older-than 30 --yes    # delete files older than 30 days
cacheclean --no-color --quiet       # scriptable, colorless, final summary only
cacheclean --debug                  # verbose internal tracing
cacheclean --no-fancy               # force plain ASCII symbols and borders
cacheclean --fancy                  # force emojis + colors (keeps ASCII borders on Termux)
cacheclean --help                   # show all options
```

The tool asks for **two confirmations**: a first prompt after the dry-run
preview, then a second prompt that lists every file that will be deleted.
`--yes` skips both prompts but still shows the file list.

On Termux (Android) the tool defaults to **ASCII borders + emojis** because many
fonts don't render box-drawing glyphs well. Use `--fancy` to keep emojis; on
Termux it will still use ASCII borders unless you also set
`CACHECLEAN_FANCY_BORDERS=1`.

## Writing a plugin

A plugin is a plain bash file in `plugins/` named after the package manager it
handles (e.g., `go.sh`). It must define five functions using the file basename as
a prefix:

```bash
# plugins/go.sh
go_plugin_info() {
  printf 'go|go|🐹\n'          # id|display_name|icon
}

go_detect() {
  command -v go >/dev/null 2>&1
}

go_get_cache_dirs() {
  printf '%s\n' "$HOME/go/pkg/mod/cache"
}

go_scan_cache() {
  local dir
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    if [ ! -d "$dir" ]; then
      cc_emit_err "$dir" "directory not found"
      continue
    fi
    local total_kb
    total_kb=$(cc_du_kb "$dir")
    cc_emit_tot "$dir" "$total_kb"

    while IFS= read -r f; do
      [ -z "$f" ] && continue
      cc_emit_orphan "$dir" "$f" "stale module cache"
    done < <(cc_find_old "$dir" "$CC_OLDER_THAN")
  done < <(go_get_cache_dirs)
}

go_clean_orphans() {
  cc_clean_orphans_from_file "$1"
}
```

The engine provides these helper functions for all plugins:

- `cc_find_old DIR DAYS` — files older than `DAYS` days.
- `cc_find_partial DIR` — incomplete/empty downloads.
- `cc_find_locks DIR` — stale lock files when `lsof` is available.
- `cc_du_kb DIR` — directory size in KiB.
- `cc_file_size FILE` — file size in bytes.
- `cc_emit_tot DIR KB`, `cc_emit_orphan DIR PATH REASON`, `cc_emit_err DIR MSG`.
- `cc_clean_orphans_from_file SCAN_FILE` — generic deletion of recorded orphans.

## License

Public domain / MIT — use, modify, and share freely.
