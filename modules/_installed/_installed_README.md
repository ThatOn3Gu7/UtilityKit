# Installed Commands — UtilityKit

List **every installed package** (via your native package manager and every
language-specific package manager found on the system) **and every executable
command discoverable on your `$PATH`**.

## What it detects

- **System managers:** apt, dnf, yum, zypper, pacman, apk, xbps, eopkg,
  emerge, brew, macports, nix, guix
- **App stores:** snap, flatpak, chocolatey, scoop, winget
- **Language ecosystems:** pip, pipx, npm, pnpm, yarn, bun, gem, cargo,
  rustup, go, composer, conda, uv, dotnet, luarocks, opam, tlmgr
- **Tools / plugins:** asdf, gh extensions, kubectl krew

Package detection is best-effort: if a manager's list command is unavailable
or errors out, it is skipped silently. The `$PATH` scan walks every directory
in `$PATH`, collects executable files, de-duplicates by basename, and sorts.

## Usage

```sh
bash main.sh installed                 # packages + PATH commands (default)
bash main.sh installed --packages      # only package managers
bash main.sh installed --commands      # only PATH executables
bash main.sh installed --all --count   # counts only
bash main.sh installed --category language
bash main.sh installed --manager apt,brew,npm
bash main.sh installed --json          # machine-readable summary
bash main.sh installed --export report.txt
```

## Options

| Flag | Description |
|------|-------------|
| `--packages` | List installed packages per detected manager |
| `--commands` | List every executable found in `$PATH` |
| `--all` | Both (default) |
| `--category c1,c2` | Filter: `system`, `apps`, `language`, `tools` |
| `--manager id1,id2` | Only these manager ids |
| `--count` | Show counts instead of full names |
| `--json` | Emit a JSON summary |
| `--export FILE` | Write a plain-text report to `FILE` |
| `--no-color` | Disable ANSI colors |

## Output format

- While each manager's list command runs, a **live spinner** (`◐ ◓ ◑ ◒` on
  UTF-8 terminals, `| / - \` otherwise) shows next to `Querying <manager>`. The
  spinner is disabled automatically when output is not a TTY or when using
  `--json` / `--export`, so machine-readable output stays clean.
- Each detected package is printed as:

  ```
  [ - name → vX ]
  ```

  The version is **forced to a `v` prefix** (`1:2.3.4` becomes `v1:2.3.4`). When
  a manager reports no version (e.g. go binaries, rustup toolchains, asdf
  plugins, gh/krew extensions) only the name is shown:

  ```
  [ - name ]
  ```

- `--json` emits `{"name","version"}` objects per manager (version is `""` when
  unknown).

## Notes

- Read-only: the tool never installs, removes, or modifies anything.
- Output degrades gracefully: colors are stripped when piped or with `NO_COLOR`.
