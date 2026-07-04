# YAML Toolkit (`yaml`)

Lint, validate, convert between YAML and JSON, extract values by dot-notation
key, merge files, and pretty-print.

## Backends (tried in order)

1. **yq** (Go version) — full-featured, recommended
2. **python3 + PyYAML** — pip install pyyaml

## Usage

```
yaml lint config.yaml
yaml tojson config.yaml
yaml toyml data.json
yaml get config.yaml database.host
yaml keys config.yaml
yaml pretty config.yaml
yaml merge base.yaml overlay.yaml
```

## Options

| Flag | Meaning | Default |
|------|---------|---------|
| `--indent N` | Indentation spaces | 2 |
| `--json` | Machine-readable output | off |
| `--no-color` | Disable ANSI | off |

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `lint` | Validate YAML syntax |
| `tojson` | Convert YAML to JSON |
| `toyml` | Convert JSON to YAML |
| `get FILE KEY` | Extract value by dot-notation |
| `merge BASE OVERLAY` | Deep-merge overlay into base |
| `keys` | List top-level keys |
| `pretty` | Pretty-print formatted YAML |

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Validation failure or missing key |
| `2` | No backend available / argument error |
