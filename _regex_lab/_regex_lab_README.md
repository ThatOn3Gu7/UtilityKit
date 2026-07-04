# Regex Lab (`regex`)

Live regex tester: pattern + sample text, prints matches, named captures,
and substitution preview.

## Backends (auto-detected)

1. **perl** — preferred, full PCRE support
2. **grep -P** — fast for simple extraction
3. **python3** — PCRE fallback with capture support

## Usage

```
regex '\\d+' 'hello 42 world 99'
regex -p '\\w+' -f /var/log/syslog
regex -p 'foo(bar)' -s 's/foo(bar)/baz$1/' -t 'foobar qux'
echo 'abc123' | regex -p '[a-z]+' -i
```

## Options

| Flag | Meaning | Default |
|------|---------|---------|
| `-p, --pattern PAT` | Regex pattern | — |
| `-t, --text TEXT` | Sample text (or positional) | — |
| `-f, --file FILE` | Read text from FILE | — |
| `-i, --stdin` | Read text from stdin | — |
| `-s, --sub SUB` | Substitution expression | — |
| `-m, --multiline` | Multiline anchors | off |
| `-c, --case-insensitive` | Case-insensitive | off |
| `--color` | Colorize matches | off |
| `--json` | Machine-readable output | off |
| `--no-color` | Disable ANSI | off |

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Matches found (or substitution applied) |
| `1` | No matches |
| `2` | Argument / dependency error |
