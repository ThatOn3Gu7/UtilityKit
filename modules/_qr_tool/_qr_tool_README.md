# QR Tool (`qr`)

Encode text, URLs, Wi-Fi credentials, and vCards into QR codes — render to
terminal ASCII or save as PNG. Decode QR images with `zbarimg` or `pyzbar`.

## Encoders (tried in order)

1. **`qrencode`** — recommended, tiny native binary.
2. **`python3` + `qrcode[pil]`** — pure-Python fallback.

## Decoders (tried in order)

1. **`zbarimg`** (from `zbar-tools`).
2. **`python3` + `pyzbar` + `Pillow`**.

## Install

| Platform | Command |
|----------|---------|
| Debian / Ubuntu | `sudo apt install qrencode zbar-tools` |
| Fedora / RHEL   | `sudo dnf install qrencode zbar`       |
| macOS (Homebrew)| `brew install qrencode zbar`           |
| Termux          | `pkg install qrencode zbar`            |
| Fallback (any)  | `pip install "qrcode[pil]" pyzbar pillow` |

## Usage

```
qr encode  --text "https://example.com"
qr encode  --text "hello world" --out ./qr.png
qr encode  --wifi HomeNet --psk hunter2 --enc WPA
qr encode  --wifi Guest --enc nopass
qr encode  --vcard "Ada Lovelace" --email ada@example.com --phone 555-0100
qr decode  --image ./qr.png
qr decode  --image ./photo.jpg --json
```

### Options

| Flag | Meaning | Default |
|------|---------|---------|
| `--text TXT` | Encode plain text or URL | — |
| `--wifi SSID` | Encode a Wi-Fi login | — |
| `--psk PASS` | Wi-Fi password | empty |
| `--enc WPA\|WEP\|nopass` | Wi-Fi authentication | `WPA` |
| `--hidden` | Mark SSID as hidden | off |
| `--vcard NAME` | Encode a minimal vCard 3.0 | — |
| `--phone`, `--email`, `--org`, `--title` | Extra vCard fields | — |
| `--out FILE` | Write PNG to FILE | terminal |
| `--size SMALL\|LARGE` | Terminal render density | SMALL |
| `--level L\|M\|Q\|H` | Error correction | M |
| `--margin N` | Quiet-zone modules | 2 |
| `--json` | JSON output (decode) | off |
| `--no-color` | Disable ANSI colors | off |

## Wi-Fi payload format

The Wi-Fi payload follows the ZXing convention:

```
WIFI:T:<enc>;S:<ssid>;P:<pass>;H:<hidden>;;
```

Reserved characters (`\`, `;`, `,`, `:`, `"`) in SSID and PSK are escaped
automatically.

## Exit codes

| Code | Meaning |
|------|---------|
| `0`  | Success |
| `1`  | Invalid input / decode found no QR |
| `2`  | No encoder / decoder installed |

## Termux notes

- `qrencode` produces UTF-8 block glyphs that render cleanly in Termux.
- ASCII fallback (`--size LARGE`) is picked automatically when `NO_UNICODE=1`.
- `zbar` needs the camera off during decode; the tool reads image files only.
