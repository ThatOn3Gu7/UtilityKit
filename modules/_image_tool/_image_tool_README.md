# Image Tool (`image`)

Resize, convert formats, strip EXIF metadata, optimize file size, and
generate thumbnails.

## Backends

| Subcommand | Required tool | Package |
|------------|---------------|---------|
| info, resize, convert, strip, thumb | `convert`/`magick` | ImageMagick |
| strip | `exiftool` | `apt install libimage-exiftool-perl` |
| PNG optimize | `optipng` | `apt install optipng` |
| JPEG optimize | `jpegoptim` | `apt install jpegoptim` |
| WebP optimize | `cwebp` | `apt install webp` |

## Usage

```
image info photo.jpg
image info photo.jpg --json
image resize photo.jpg --width 800 --out resized.jpg
image convert photo.png --format webp
image strip photo.jpg --out clean.jpg
image optimize photo.png
image thumb photo.jpg --size 200
```

## Options

| Flag | Meaning |
|------|---------|
| `--width N` | Target width (pixels) |
| `--height N` | Target height (pixels) |
| `--percent N` | Resize by percentage |
| `--format FMT` | Target format (png, jpg, webp, gif) |
| `--quality N` | JPEG/WebP quality 1-100 |
| `--size N` | Thumbnail max dimension |
| `--out FILE` | Output path |
| `--json` | Machine-readable output (info only) |
