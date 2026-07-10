# UtilityKit test report

Last verified: 2026-07-09
Verified against the final packaged working tree.

Follow-up Termux UX fixes were re-smoke-tested after dashboard, wizard, and interactive-loop changes.

## Automated suite

Command executed:

```bash
bash tests/smoke_test.sh
```

Result:

- PASS=7
- FAIL=0

## What the smoke suite covers

### Syntax and routing
- `bash -n` across every shell script in the repository
- `main.sh help`
- `setup.sh --help`
- direct `main.sh <command> --help` coverage for all routed tools

### Core tool behavior
- apply changes sync with `--apply --yes --mirror`
- batch rename copy-mode workflow
- symlink manager backup/link creation flow
- disk analyzer non-destructive scan path
- cache cleaner help/entrypoint compatibility

### Roadmap tool behavior
- env manager compare + validate flow
- git sweep preview against a temporary repository
- project scaffold generation
- duplicate finder destructive apply path
- log rotator archival flow
- process killer signal path
- port inspector against a temporary local server
- SSL checker help path
- API tester against a temporary local HTTP server
- password generator
- SSH assistant against a temporary SSH config
- shredder secure deletion path
- media converter help path
- markdown TOC generation + link check + table alignment
- pomodoro short-duration execution
- cheat sheet add/search flow
- zen mode short-duration execution

## Additional installer validation

A manual install smoke test was also run:

```bash
bash setup.sh --no-menu --install-dir <temp>/install --bin-dir <temp>/bin --no-path
<temp>/bin/utility help
```

Validated:
- launcher wrapper creation
- installation of all `_*/` tool directories
- installation of `lib/`, `docs/`, and `tests/`
- direct launcher routing to the new dashboard
