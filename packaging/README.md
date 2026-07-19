# Packaging

Everything needed to ship UtilityKit through a package manager instead of
`git clone && bash setup.sh`.

## What lives where

| Path | Purpose |
| --- | --- |
| `../Formula/utilitykit.rb` | Homebrew formula (repo doubles as a tap) |
| `build-termux-deb.sh` | Builds a Termux-installable `.deb` with `dpkg-deb` |
| `update-formula.sh` | Points the formula's `url`/`sha256` at a released tag |
| `../.github/workflows/release.yml` | On `v*` tag push: builds the `.deb`, creates the GitHub Release with assets |

Both packages install the runtime tree (`main.sh`, `lib/`, `modules/`,
`docs/`) plus the `utility` launcher and bash/zsh tab-completions. The
version is always read from `UK_VERSION` in `lib/uk_common.sh` — there is no
second version to keep in sync.

## User-facing install commands

```sh
# Homebrew (macOS / Linux) — the repo itself is the tap
brew tap thaton3gu7/utilitykit https://github.com/ThatOn3Gu7/UtilityKit.git
brew install utilitykit          # tagged release
brew install --HEAD utilitykit   # latest master (works before any release exists)

# Termux — grab the .deb from the latest GitHub Release
curl -fLO https://github.com/ThatOn3Gu7/UtilityKit/releases/latest/download/utilitykit_all.deb
pkg install ./utilitykit_all.deb
```

## Cutting a release

1. Bump `UK_VERSION` in `lib/uk_common.sh`, update `CHANGES.md` and the
   README changelog.
2. Commit, then tag and push: `git tag vX.Y.Z && git push origin vX.Y.Z`.
3. The `Release` workflow builds `utilitykit_X.Y.Z_all.deb` (plus the
   stable-named `utilitykit_all.deb` alias) and publishes the GitHub
   Release. It fails fast if the tag does not match `UK_VERSION`.
4. Run `bash packaging/update-formula.sh vX.Y.Z` locally — it downloads the
   tag tarball, computes the sha256, and rewrites the formula. Commit the
   formula change. `brew upgrade utilitykit` now serves the new version.

## Local builds / testing

```sh
bash packaging/build-termux-deb.sh --out dist   # needs dpkg-deb
dpkg-deb --info dist/utilitykit_*_all.deb
dpkg-deb --contents dist/utilitykit_*_all.deb

# On an actual Termux device
pkg install ./dist/utilitykit_*_all.deb
utility version
pkg uninstall utilitykit
```

`--prefix` (or `TERMUX_PREFIX`) overrides the target prefix if Termux ever
changes it; the default is `/data/data/com.termux/files/usr`.

## Notes

- The launcher name is fixed to `utility` in both packages so the shipped
  tab-completions (which register `utility`) work out of the box. Users who
  want a custom name can still use `setup.sh --launcher-name`.
- Until the first `vX.Y.Z` tag exists, the formula's stable block carries a
  placeholder sha256 — only `brew install --HEAD utilitykit` works.
- `pkg install ./file.deb` resolves the `Depends:` line (bash) like any
  repo package; `Recommends:` (ncurses-utils, git, curl, jq) is advisory.
