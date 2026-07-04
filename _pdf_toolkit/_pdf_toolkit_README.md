# PDF Toolkit (`pdf`)

Merge, split, extract text, compress, rotate, and inspect PDFs.

## Dependencies

| Tool | Package | Purpose |
|------|---------|---------|
| `qpdf` | `qpdf` | Core operations (recommended) |
| `pdftotext` | `poppler-utils` | Text extraction |
| `gs` | `ghostscript` | Compression |
| `pdfinfo` | `poppler-utils` | Metadata |

## Usage

```
pdf info document.pdf
pdf count document.pdf
pdf merge a.pdf b.pdf --output merged.pdf
pdf split document.pdf --output ./pages/
pdf text document.pdf
pdf compress document.pdf --output compressed.pdf
pdf rotate document.pdf 90
```

## Options

| Flag | Meaning |
|------|---------|
| `--output FILE` | Output path |
| `--pages RANGE` | Page range (e.g. 1-3,5) |
| `--json` | Machine-readable output |
