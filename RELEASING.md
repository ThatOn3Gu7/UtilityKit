# Releasing UtilityKit

Step-by-step guide for cutting a new release. The whole pipeline hangs off
one thing: pushing a `vX.Y.Z` git tag. Everything else is automation.

## How it fits together

```
UK_VERSION in lib/uk_common.sh        ← single source of truth
        │
        ▼
git tag vX.Y.Z  (must match!)         ← you push this
        │
        ▼
.github/workflows/release.yml         ← runs automatically
  ├─ fails if tag != UK_VERSION
  ├─ builds utilitykit_X.Y.Z_all.deb  (Termux package)
  ├─ copies it to utilitykit_all.deb  (stable "latest" name)
  └─ publishes GitHub Release with both files
        │
        ▼
packaging/update-formula.sh vX.Y.Z    ← you run this after
  └─ pins Formula/utilitykit.rb to the new tarball sha256
```

## Step by step

### 1. Bump the version

Edit `lib/uk_common.sh`:

```sh
readonly UK_VERSION='5.11.0'    # was 5.10.0
```

Patch bump (5.10.0 → 5.10.1) for fixes, minor (5.10 → 5.11) for features,
major for breaking changes.

### 2. Update the changelogs

- `CHANGES.md` — add a new `## [5.11.0] - YYYY-MM-DD` section at the top.
- `README.md` — in the `## Changelog` section, add a `**v5.11.0** - current`
  entry and remove `- current` from the previous one.
- `docs-site/src/pages/HomePage.tsx` — bump the hardcoded version badge
  (`v5.10.0 · 65 tools · ...`), then rebuild the site:
  `cd docs-site && npm run deploy:docs` and commit the regenerated
  `docs/index.html`.

### 3. Verify

```sh
bash tests/smoke_test.sh          # must end PASS=N FAIL=0
```

### 4. Commit and get it onto master

```sh
git add lib/uk_common.sh CHANGES.md README.md   # plus whatever else changed
git commit -m "feat(tool): whatever the release contains"
```

Then merge/push to `master` (via PR or direct push — the release tarball
and `brew install --HEAD` both read `master`).

### 5. Tag and push the tag — this triggers the release

```sh
git tag v5.11.0            # on the master commit you want to release
git push origin v5.11.0
```

Watch it run:

```sh
gh run list --workflow=release.yml --limit 1
gh run watch <run-id> --exit-status
```

When green, the release is live at
`https://github.com/ThatOn3Gu7/UtilityKit/releases/tag/v5.11.0` with two
assets: `utilitykit_5.11.0_all.deb` and `utilitykit_all.deb`.

### 6. Pin the Homebrew formula

The formula needs the sha256 of the new source tarball, which only exists
after the tag is on GitHub:

```sh
bash packaging/update-formula.sh v5.11.0
git diff Formula/                 # review: url + sha256 lines changed
git add Formula/utilitykit.rb
git commit -m "chore(release): pin formula to v5.11.0 tarball sha256"
git push origin master
```

Done. `brew upgrade utilitykit` and the Termux one-liner now serve 5.11.0.

### 7. Sanity check (optional but cheap)

```sh
# Termux (on-device):
curl -fsSLO https://github.com/ThatOn3Gu7/UtilityKit/releases/latest/download/utilitykit_all.deb
pkg install ./utilitykit_all.deb
utility version                   # should print the new version
```

## Troubleshooting

**Workflow fails with "Tag vX.Y.Z does not match UK_VERSION"**
You tagged a commit where `lib/uk_common.sh` still has the old version.
Fix: delete the tag, bump properly, re-tag:

```sh
git tag -d v5.11.0
git push origin :refs/tags/v5.11.0    # deletes the remote tag
# fix UK_VERSION, commit, push, then tag again
```

**Need to redo a release entirely**
Delete the GitHub release first, then the tag, then start over:

```sh
gh release delete v5.11.0 --yes
git push origin :refs/tags/v5.11.0
git tag -d v5.11.0
```

**`update-formula.sh` says "does the tag exist on GitHub?"**
The tag isn't pushed yet, or you typo'd it. It must be `vX.Y.Z` exactly.

**Formula still has the placeholder sha**
`brew install utilitykit` (stable) will fail checksum until step 6 is done.
`brew install --HEAD utilitykit` always works regardless.

## Reference

- `packaging/README.md` — deeper detail on both package formats
- `packaging/build-termux-deb.sh` — build the `.deb` locally for testing
- `.github/workflows/release.yml` — the automation itself
