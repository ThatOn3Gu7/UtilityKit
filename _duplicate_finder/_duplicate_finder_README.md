# _duplicate_finder

Detect exact duplicate files in a directory tree using a two-stage approach — size comparison first, then content hashing — and optionally delete duplicates or replace them with hardlinks.

---

## Features

- **Two-stage detection** — matches file sizes first to avoid hashing every file, then confirms duplicates by hash
- **Multiple actions** — report only, delete duplicates, or replace duplicates with hardlinks
- **Safe by default** — dry-run preview is shown before any files are modified
- **Version control aware** — automatically skips `.git`, `.hg`, and `.svn` directories
- **Interactive mode** — running without arguments launches a guided prompt

---

## Usage

```bash
# Interactive mode — prompts for directory and action
bash _duplicate_finder/_duplicate_finder.sh

# Report duplicates only (no changes)
bash _duplicate_finder/_duplicate_finder.sh ~/Downloads

# Preview which files would be deleted (dry-run)
bash _duplicate_finder/_duplicate_finder.sh ~/Downloads --delete

# Delete duplicates, keeping the first copy of each
bash _duplicate_finder/_duplicate_finder.sh ~/Downloads --delete --apply

# Replace duplicates with hardlinks to save space
bash _duplicate_finder/_duplicate_finder.sh ~/Downloads --hardlink --apply

# Scan a specific directory
bash _duplicate_finder/_duplicate_finder.sh ~/Pictures --delete --apply
```

---

## Options

| Option | Description |
|---|---|
| `DIR` | Directory to scan (default: `.`) |
| `--delete` | Delete duplicate copies, keeping the first file per hash |
| `--hardlink` | Replace duplicates with hardlinks pointing to the first file |
| `--apply` | Execute the chosen action (dry-run preview if omitted) |
| `-h, --help` | Show usage |

---

## How duplicates are detected

1. Every file under the target directory is scanned and grouped by byte size
2. Files in groups with more than one member are hashed using `sha256sum` (falls back to `shasum -a 256`, then `md5sum`)
3. Files sharing the same hash are confirmed duplicates
4. The first file encountered for each hash is kept — all others are the duplicates

This approach avoids hashing large files unnecessarily, making scans fast even on directories with thousands of files.

---

## Action reference

| Action | Effect on duplicates | Originals |
|---|---|---|
| report | No changes | Untouched |
| delete | Duplicate files are permanently removed | Kept |
| hardlink | Duplicate paths are replaced with hardlinks to the original | Kept, now shared inode |

Hardlinking saves disk space while keeping both file paths accessible. Both paths point to the same data on disk. Editing one will affect the other.

---

## Output preview

```
  Duplicate groups found
  ------------------------------------------------

  Keep:   ~/Downloads/photo.jpg
  Dupe:   ~/Downloads/photo_copy.jpg  (will be removed if applied)

  Keep:   ~/Downloads/report.pdf
  Dupe:   ~/Downloads/report (1).pdf  (will be removed if applied)
```

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Unknown option passed |
