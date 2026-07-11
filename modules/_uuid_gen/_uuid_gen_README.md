# UUID Gen (`uuid`)

Generate UUID v4, v7 (time-ordered), ULID, NanoID, short IDs, hex strings,
and snowflake IDs.

## Types

| Type | Example | Default length |
|------|---------|----------------|
| `uuid4` | `f47ac10b-58cc-4372-a567-0e02b2c3d479` | 36 |
| `uuid7` | `018f3a7e-7e3b-7e8c-8a1b-9c0d1e2f3a4b` | 36 |
| `ulid` | `01ARZ3NDEKTSV4RRFFQ69G5FAV` | 26 |
| `nanoid` | `V1StGXR8_Z5jdHi6B-myT` | 21 (configurable) |
| `short` | `a3Bf8K2x` | 8 (configurable) |
| `hex` | `a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6` | 32 (configurable) |
| `snowflake` | `1541815603606036480` | 64-bit int |

## Usage

```
uuid                          # default: one UUID v4
uuid uuid7 --count 5
uuid nanoid --len 16
uuid ulid --count 3 --json
uuid short --upper --count 10 --sep ','
uuid hex --len 64
```

## Options

| Flag | Meaning | Default |
|------|---------|---------|
| `--count N` | Generate N IDs | 1 |
| `--len N` | Custom length (nanoid, short, hex) | type default |
| `--upper` | Uppercase output | lowercase |
| `--sep SEP` | Separator for bulk output | newline |
| `--json` | JSON array output | off |
| `--clip` | Copy first result to clipboard | off |
| `--quiet` | Suppress info | off |
