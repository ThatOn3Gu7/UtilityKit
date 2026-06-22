# Dotenv Vault

Encrypt individual .env values using gpg-backed ENC tokens.

## Usage

```bash
bash _dotenv_vault.sh --help
```

## Cross-platform behavior

All commands are designed to work on Linux, macOS, and Termux/minimal terminals where possible. Optional system dependencies are detected at runtime. If a dependency is unavailable, the tool prints a clear warning and either uses a fallback or skips that feature safely.

