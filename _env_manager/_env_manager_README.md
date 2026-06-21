# _env_manager

Manage `.env` profiles, validate environment file syntax, compare active keys against an example file, and encrypt or decrypt secret files using `gpg` or `openssl`.

---

## Features

- **Profile switching** — copy any `.env.<profile>` file over your active `.env` in one step
- **Syntax validation** — scan an env file line by line and flag any malformed `key=value` entries
- **Key comparison** — diff your active `.env` against `.env.example` to find missing or extra keys
- **Encryption** — encrypt secret files using `gpg -c` (preferred) or `openssl aes-256-cbc` fallback
- **Decryption** — decrypt `.gpg` or `.enc` files back to plaintext
- **Interactive mode** — running the tool without arguments launches a guided menu

---

## Usage

```bash
# Compare active .env against .env.example
bash _env_manager/_env_manager.sh --dir . --compare

# Validate syntax of the active .env
bash _env_manager/_env_manager.sh --dir . --validate

# Validate a specific file
bash _env_manager/_env_manager.sh --validate .env.production

# Switch to a named profile (copies .env.staging -> .env)
bash _env_manager/_env_manager.sh --dir . --profile staging --apply

# Dry-run profile switch (preview only, no copy)
bash _env_manager/_env_manager.sh --dir . --profile staging

# Encrypt a secret file
bash _env_manager/_env_manager.sh --encrypt .env.production

# Decrypt a previously encrypted file
bash _env_manager/_env_manager.sh --decrypt .env.production.gpg

# Launch interactive menu
bash _env_manager/_env_manager.sh
```

---

## Options

| Option | Description |
|---|---|
| `--dir DIR` | Project directory containing `.env` files (default: `.`) |
| `--profile NAME` | Profile name to inspect or switch to (e.g. `local`, `staging`, `production`) |
| `--apply` | Actually copy the selected profile to `.env` (default is dry-run) |
| `--compare` | Compare active `.env` keys against `.env.example` |
| `--validate [FILE]` | Validate syntax of FILE, or active `.env` if no file given |
| `--encrypt FILE` | Encrypt FILE using `gpg` or `openssl` |
| `--decrypt FILE` | Decrypt a `.gpg` or `.enc` file |
| `--active FILE` | Override the active env filename (default: `.env`) |
| `--example FILE` | Override the example env filename (default: `.env.example`) |
| `-h, --help` | Show usage |

---

## Profile conventions

The tool expects profile files to follow the `.env.<name>` naming convention inside the project directory:

```text
project/
├── .env               ← active file (loaded by your app)
├── .env.example       ← reference file checked in to version control
├── .env.local         ← local development overrides
├── .env.staging       ← staging environment values
└── .env.production    ← production values (encrypt before committing)
```

Switching to a profile with `--apply` copies the selected file over `.env`. Without `--apply` the tool performs a dry-run and shows what would happen.

---

## Encryption backends

The tool tries `gpg` first and falls back to `openssl` if `gpg` is not available:

- `gpg -c` produces a `.gpg` file using symmetric passphrase encryption
- `openssl enc -aes-256-cbc -pbkdf2` produces a `.enc` file

Decryption automatically detects the file extension and uses the matching backend.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Missing file, invalid profile, or encryption/decryption failure |
