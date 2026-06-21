# _media_convert

Batch convert images and videos to modern formats, optionally stripping EXIF metadata from images and compressing video output using ffmpeg.

---

## Features

- **Image conversion** — converts PNG, JPG, JPEG, and WebP files using ImageMagick or ffmpeg
- **Video conversion** — converts MP4, MOV, MKV, and AVI files using ffmpeg with libx264
- **EXIF stripping** — removes location, camera, and timestamp metadata from images
- **Quality control** — configurable output quality for image conversion
- **Directory scanning** — recursively finds all matching files in a source directory
- **Dry-run by default** — previews conversions without writing any files
- **Interactive mode** — running without arguments launches a guided setup prompt

---

## Usage

```bash
# Interactive mode — prompts for all settings
bash _media_convert/_media_convert.sh

# Preview image conversions (dry-run, no files written)
bash _media_convert/_media_convert.sh --kind image --to webp ~/Pictures

# Convert images to WebP and apply
bash _media_convert/_media_convert.sh --kind image --to webp --apply ~/Pictures

# Convert with EXIF stripping and custom quality
bash _media_convert/_media_convert.sh --kind image --to webp --quality 85 --strip-exif --apply ~/Pictures

# Convert a single image file
bash _media_convert/_media_convert.sh --kind image --to jpg --apply ./photo.png

# Convert videos to MP4
bash _media_convert/_media_convert.sh --kind video --to mp4 --apply ~/Videos

# Write output to a custom directory
bash _media_convert/_media_convert.sh --kind image --to webp --output ~/converted --apply ~/Pictures
```

---

## Options

| Option | Description |
|---|---|
| `PATH...` | Source file or directory to convert |
| `--kind image\|video` | Type of media to convert (default: `image`) |
| `--to FORMAT` | Target format extension (default: `webp` for image, `mp4` for video) |
| `--quality N` | Output quality for images, 1–100 (default: `82`) |
| `--strip-exif` | Strip EXIF metadata from image output |
| `--output DIR` | Directory to write converted files to (default: `./converted_<kind>`) |
| `--apply` | Execute conversions (dry-run preview if omitted) |
| `-h, --help` | Show usage |

---

## Supported formats

### Image input formats
`png`, `jpg`, `jpeg`, `webp`

### Image output formats
| Format | Notes |
|---|---|
| `webp` | Best size/quality ratio, modern browsers and apps |
| `jpg` | Universal compatibility |
| `png` | Lossless, larger file size |

### Video input formats
`mp4`, `mov`, `mkv`, `avi`

### Video output formats
| Format | Notes |
|---|---|
| `mp4` | Widest compatibility, uses libx264 |
| `mkv` | Open container format |

---

## Conversion backends

| Kind | Primary tool | Fallback |
|---|---|---|
| Image | `magick` (ImageMagick) | `ffmpeg` |
| Video | `ffmpeg` | None — required |

Video conversion always requires `ffmpeg`. Image conversion uses ImageMagick when available for better quality control and EXIF stripping support.

---

## Output location

Converted files are written to the output directory using the original filename with the new extension:

```
~/Pictures/holiday.jpg  →  ./converted_image/holiday.webp
~/Videos/demo.mov       →  ./converted_video/demo.mp4
```

Original files are never modified or deleted.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | No source paths given, or required tool not installed |
