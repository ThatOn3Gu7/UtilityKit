# _env_manager

Manage `.env` profiles, validate env syntax, compare `.env` against `.env.example`, and encrypt/decrypt secrets.

Examples:
```bash
bash _env_manager/_env_manager.sh --dir . --compare
bash _env_manager/_env_manager.sh --dir . --profile staging --apply
bash _env_manager/_env_manager.sh --encrypt .env.production
```
