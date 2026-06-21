# _password_gen

Generate secure XKCD-style passphrases or high-entropy random strings, with entropy estimates and optional clipboard copying.

---

## Features

- **Passphrase mode** — combines random words from a built-in wordlist with a configurable separator
- **String mode** — generates random character strings from a mixed alphanumeric and symbol charset
- **Entropy display** — shows estimated bits of entropy for every generated result
- **Clipboard support** — copies output to clipboard using `wl-copy`, `xclip`, `pbcopy`, or `termux-clipboard-set`
- **Interactive mode** — running without arguments launches a guided prompt

---

## Usage

```bash
# Interactive mode — prompts for mode and settings
bash _password_gen/_password_gen.sh

# Generate a 4-word passphrase (default)
bash _password_gen/_password_gen.sh --mode passphrase

# Generate a 6-word passphrase with underscore separator
bash _password_gen/_password_gen.sh --mode passphrase --words 6 --separator _

# Generate a 32-character random string
bash _password_gen/_password_gen.sh --mode string --length 32

# Generate and copy to clipboard
bash _password_gen/_password_gen.sh --mode passphrase --copy

# Generate a string and copy to clipboard
bash _password_gen/_password_gen.sh --mode string --length 24 --copy
```

---

## Options

| Option | Description |
|---|---|
| `--mode passphrase\|string` | Generator mode (default: `passphrase`) |
| `--words N` | Number of words in passphrase (default: `4`) |
| `--length N` | Character length for string mode (default: `20`) |
| `--separator CHAR` | Word separator for passphrase mode (default: `-`) |
| `--copy` | Copy generated output to clipboard |
| `-h, --help` | Show usage |

---

## Output

```
  ------------------------------------------------
  Generated

  amber-beacon-velvet-prism

  ------------------------------------------------
  Entropy :  ~93.08 bits
  Mode    :  passphrase
  Words   :  4  (separator: -)
  ------------------------------------------------
```

---

## Entropy reference

| Mode | Settings | Entropy |
|---|---|---|
| Passphrase | 4 words | ~93 bits |
| Passphrase | 5 words | ~116 bits |
| Passphrase | 6 words | ~139 bits |
| String | 20 chars | ~123 bits |
| String | 32 chars | ~197 bits |

Entropy is calculated from the wordlist size (37 words) for passphrases and from a 72-character charset for strings.

---

## Clipboard support

The tool tries these clipboard commands in order and uses the first one found:

| Command | Environment |
|---|---|
| `wl-copy` | Wayland |
| `xclip` | X11 |
| `pbcopy` | macOS |
| `termux-clipboard-set` | Termux / Android |
| `clip.exe` | WSL / Windows |

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Unknown option or unsupported mode |
