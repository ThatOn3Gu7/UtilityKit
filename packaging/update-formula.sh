#!/usr/bin/env bash
# update-formula.sh — point Formula/utilitykit.rb at a released tag.
# Version: 1.0.0
#
# Usage: bash packaging/update-formula.sh [vX.Y.Z]
#
# Downloads the GitHub source tarball for the given tag (default: v<UK_VERSION>
# from lib/uk_common.sh), computes its sha256, and rewrites the `url` and
# `sha256` lines in Formula/utilitykit.rb. Run this once after pushing a new
# release tag, then commit the formula change.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORMULA="$REPO_ROOT/Formula/utilitykit.rb"
REPO_SLUG='ThatOn3Gu7/UtilityKit'

die() {
  printf 'update-formula: error: %s\n' "$1" >&2
  exit 1
}

[[ -f "$FORMULA" ]] || die "formula not found: $FORMULA"

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  VERSION="$(sed -n "s/^readonly UK_VERSION='\([0-9][0-9.]*\)'.*/\1/p" "$REPO_ROOT/lib/uk_common.sh")"
  [[ -n "$VERSION" ]] || die 'could not read UK_VERSION from lib/uk_common.sh and no tag argument given'
  TAG="v$VERSION"
fi
[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "tag must look like vX.Y.Z (got: $TAG)"

TARBALL_URL="https://github.com/$REPO_SLUG/archive/refs/tags/$TAG.tar.gz"

command -v curl >/dev/null 2>&1 || die 'curl is required'

TMP_TARBALL="$(mktemp)"
cleanup() { rm -f "$TMP_TARBALL"; }
trap cleanup EXIT

printf 'Fetching %s\n' "$TARBALL_URL"
curl -fsSL -o "$TMP_TARBALL" "$TARBALL_URL" ||
  die "download failed — does the tag $TAG exist on GitHub?"

if command -v sha256sum >/dev/null 2>&1; then
  SHA="$(sha256sum "$TMP_TARBALL" | cut -d' ' -f1)"
elif command -v shasum >/dev/null 2>&1; then
  SHA="$(shasum -a 256 "$TMP_TARBALL" | cut -d' ' -f1)"
else
  die 'need sha256sum or shasum on PATH'
fi
[[ "$SHA" =~ ^[0-9a-f]{64}$ ]] || die "computed checksum looks wrong: $SHA"

awk -v url="$TARBALL_URL" -v sha="$SHA" '
  /^  url "/    { print "  url \"" url "\""; next }
  /^  sha256 "/ { print "  sha256 \"" sha "\""; next }
  { print }
' "$FORMULA" >"$FORMULA.tmp"
mv "$FORMULA.tmp" "$FORMULA"

grep -Fq "$SHA" "$FORMULA" || die 'failed to write sha256 into the formula'
grep -Fq "$TARBALL_URL" "$FORMULA" || die 'failed to write url into the formula'

printf 'Updated %s\n' "$FORMULA"
printf '  url    %s\n' "$TARBALL_URL"
printf '  sha256 %s\n' "$SHA"
printf 'Review with "git diff Formula/" and commit when happy.\n'
