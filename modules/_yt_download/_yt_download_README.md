# _yt_download

Interactive YouTube (and supported site) video/audio downloader wrapping `yt-dlp`.

Paste a URL, browse all available formats, toggle options like subtitles and thumbnails, and download — all from a guided terminal menu.

---

## Features

- **Full format listing** — runs `yt-dlp -F` and shows every available format code
- **Flexible format selection** — enter any format specifier (`137+140`, `bv*+ba/b`, `best`, etc.)
- **Audio extraction** — download audio-only in mp3, m4a, opus, flac, or aac
- **Subtitles** — auto-download and embed all available subtitle tracks
- **Thumbnails & metadata** — embed into the file for rich player support
- **Playlist support** — toggle between single video and full playlist download
- **Custom output** — choose directory and filename template
- **CLI subcommands** — `list`, `info`, `audio`, `download` for scripting
- **Standalone** — works as `bash _yt_download.sh` or via `main.sh ytdl`

---

## Interactive Wizard

```bash
# Launch the guided menu (no arguments)
bash _yt_download.sh
```
or through the hub:
```bash
bash main.sh ytdl
```

The wizard walks through:
1. URL input
2. Fetches title, channel, duration
3. Displays full format table
4. Prompts for format code(s)
5. Asks about audio-only, subtitles, thumbnails, metadata, playlist
6. Output directory + filename template
7. Summary & confirmation → download

---

## CLI Subcommands

```bash
# List all available formats for a video
bash main.sh ytdl list https://youtube.com/watch?v=...

# Show video metadata
bash main.sh ytdl info https://youtube.com/watch?v=...

# Quick audio download (default mp3)
bash main.sh ytdl audio https://youtube.com/watch?v=...

# Audio with custom format
bash main.sh ytdl audio https://youtube.com/watch?v=... --audio-format opus

# Full download with options
bash main.sh ytdl download https://youtube.com/watch?v=... \
  --format 137+140 \
  --subs \
  --output ~/Videos
```

---

## Download Options

| Option | Default | Description |
|---|---|---|
| `--format CODE` | `bv*+ba/b` | Format specifier (from `list` output) |
| `--audio-only` | off | Extract audio stream only |
| `--audio-format FMT` | `mp3` | Audio codec: mp3, m4a, opus, flac, aac |
| `--subs` | off | Embed all available subtitles |
| `--no-thumb` | off | Skip embedding thumbnail |
| `--no-meta` | off | Skip embedding metadata |
| `--playlist` | off | Download all items in a playlist |
| `--output DIR` | `~/Downloads/YouTube` | Custom output directory |
| `-h, --help` | — | Show help |

---

## Format Specifier Examples

| Value | What it does |
|---|---|
| `best` | Best single-file combined stream |
| `bv*+ba/b` | Best video + best audio, merge; fallback to combined |
| `137+140` | 1080p h264 video + medium m4a audio |
| `137` | 1080p video only (no audio stream) |
| `bestvideo+bestaudio` | Explicit best of each, will merge |
| `worst` | Lowest quality |

See [yt-dlp format selection docs](https://github.com/yt-dlp/yt-dlp#format-selection) for all options.

---

## Requirements

- **yt-dlp** — install via:
  ```bash
  pip install yt-dlp
  brew install yt-dlp       # macOS
  sudo apt install yt-dlp   # Debian/Ubuntu
  ```

---

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success or cancelled by user |
| `1` | Missing `yt-dlp` or download failure |
