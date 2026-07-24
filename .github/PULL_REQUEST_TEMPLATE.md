<!-- Thanks for the contribution. Use a semantic prefix in your title: feat(tool): / fix(tool): / refactor(tool): / docs: -->

## Summary

<!-- What changed and why. One or two sentences. -->

## Touchpoints checklist (adding or reworking a tool)

- [ ] `_<tool>/_<tool>.sh` with namespaced functions and BASH_SOURCE guard
- [ ] `_<tool>/_<tool>_README.md`
- [ ] `main.sh`: `UK_TOOL_PATHS` entry, `case` branch, `run_<tool>_wizard`, `M_ICONS`/`M_COLORS`/`M_NAMES`/`M_DESCS`/`M_ACTIONS`
- [ ] `tests/smoke.sh`: CLI added to `help_check`, behavioral case if side effects
- [ ] `tests/deep_review_test.sh`: deeper behavioral check added (if applicable)
- [ ] `./setup.sh` runs clean without errors

### Pre-merge Checks

- [ ] `bash main.sh doctor` returns 0 problems
- [ ] `bash tests/smoke.sh` ends `PASS=N FAIL=0`
- [ ] `bash main.sh help` lists the route
- [ ] `bash main.sh <cmd> --help` works
- [ ] Platform notes considered (Termux / Linux / macOS)

## Related issues

<!-- Fixes #123 -->
