# _markdown_toc

Generate or refresh a table of contents in a markdown file based on its headings, validate relative links, and align pipe tables.

---

## Features

- **TOC generation** — scans headings and inserts a linked table of contents with correct anchor slugs
- **TOC refresh** — if markers already exist in the file the TOC is updated in place without disrupting surrounding content
- **Relative link validation** — checks that every relative link in the file points to an existing file
- **Table alignment** — pads pipe table columns so they line up cleanly
- **Dry-run by default** — previews all changes without writing to the file
- **Interactive mode** — running without arguments launches a guided prompt

---

## Usage

```bash
# Interactive mode — prompts for file and options
bash _markdown_toc/_markdown_toc.sh

# Preview TOC that would be generated (dry-run)
bash _markdown_toc/_markdown_toc.sh README.md

# Insert or refresh TOC and apply
bash _markdown_toc/_markdown_toc.sh README.md --apply

# Apply TOC and validate relative links
bash _markdown_toc/_markdown_toc.sh README.md --apply --check-links

# Apply TOC and align pipe tables
bash _markdown_toc/_markdown_toc.sh README.md --apply --align-tables

# All three operations at once
bash _markdown_toc/_markdown_toc.sh README.md --apply --check-links --align-tables
```

---

## Options

| Option | Description |
|---|---|
| `FILE` | Markdown file to process |
| `--apply` | Write changes to the file (dry-run preview if omitted) |
| `--check-links` | Validate all relative links in the file |
| `--align-tables` | Pad pipe table columns for visual alignment |
| `-h, --help` | Show usage |

---

## TOC markers

The tool uses HTML comment markers to track where the TOC lives in the file:

```markdown
<!-- utilitykit:toc:start -->
- [Features](#features)
- [Usage](#usage)
- [Options](#options)
<!-- utilitykit:toc:end -->
```

On the first run the markers and TOC are inserted automatically after the first `#` heading. On subsequent runs the content between the markers is replaced with a freshly generated TOC.

---

## Anchor slug rules

Heading anchors are generated using the same rules GitHub Markdown uses:

- Converted to lowercase
- Spaces replaced with hyphens
- Non-alphanumeric characters removed
- Leading and trailing hyphens stripped

For example `## My Cool Section!` becomes `#my-cool-section`.

---

## Link validation output

```
  Relative link validation
  ------------------------------------------------
  OK    docs/guide.md
  OK    CONTRIBUTING.md
  MISS  docs/missing-file.md
```

`OK` means the target file exists. `MISS` means it does not — useful for catching broken documentation links before pushing.

---

## Table alignment

Before:

```markdown
| Name | Version | Notes |
|---|---|---|
| bash | 5.2 | required |
| python3 | 3.10 | optional |
```

After `--align-tables`:

```markdown
| Name    | Version | Notes    |
| ------- | ------- | -------- |
| bash    | 5.2     | required |
| python3 | 3.10    | optional |
```

---

## Requirements

- `python3` — used for link validation and table alignment

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | No file specified |
