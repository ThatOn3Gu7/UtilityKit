# _cheat_sheet

A personal markdown snippet store. Save, tag, list, display, and search short command references or notes directly from the terminal.

---

## Features

- **Add snippets** — save any text as a named markdown file with optional tags
- **List snippets** — show all saved snippet names at a glance
- **Show snippets** — display the full contents of any saved snippet
- **Search snippets** — grep across all saved snippet content and names
- **File input** — import an existing file as a snippet instead of typing inline
- **Interactive mode** — running without arguments launches a persistent menu loop

---

## Usage

```bash
# Add a one-line snippet
bash _cheat_sheet/_cheat_sheet.sh --add docker-logs --text 'docker logs -f app' --tags docker,logs

# Add a snippet from an existing file
bash _cheat_sheet/_cheat_sheet.sh --add my-nginx-conf --file ./nginx.conf --tags nginx,config

# List all saved snippets
bash _cheat_sheet/_cheat_sheet.sh --list

# Show a specific snippet
bash _cheat_sheet/_cheat_sheet.sh --show docker-logs

# Search across all snippets
bash _cheat_sheet/_cheat_sheet.sh --search docker

# Launch interactive menu
bash _cheat_sheet/_cheat_sheet.sh
```

---

## Options

| Option | Description |
|---|---|
| `--add NAME` | Save a new snippet with the given name |
| `--text TEXT` | Snippet content as an inline string |
| `--file FILE` | Import content from an existing file |
| `--tags a,b` | Comma-separated tags stored in the snippet header |
| `--list` | List all saved snippet names |
| `--show NAME` | Display the full contents of a named snippet |
| `--search TERM` | Search all snippets for a term |
| `-h, --help` | Show usage |

---

## Storage location

Snippets are saved as individual markdown files under:

```
~/.local/share/utilitykit/cheat_sheets/
```

Each file is named using a slugified version of the snippet name. Tags are stored in an HTML comment header at the top of each file:

```markdown
<!-- tags: docker,logs -->

docker logs -f app
```

---

## Interactive menu

Running the tool without arguments opens a persistent loop with four actions:

```
  1) List saved snippets     (show all snippet names you have stored)
  2) Add a new snippet       (save a one-liner or short block with tags)
  3) Show a snippet          (display full contents of a saved snippet)
  4) Search snippets         (grep across all saved snippet content)
  q) Return to dashboard
```

The loop stays open after each action until you press `q`, so you can list, show, and search without relaunching the tool each time.

---

## Multi-line snippets

When adding a snippet interactively and you leave the text prompt blank, the tool drops into free-form input mode — type as many lines as you need, then press `Ctrl+D` to save.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Missing required argument or unknown option |
