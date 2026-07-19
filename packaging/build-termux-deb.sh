#!/usr/bin/env bash
# build-termux-deb.sh — build a Termux-installable .deb of UtilityKit.
# Version: 1.0.0
#
# Produces dist/utilitykit_<version>_all.deb, installable on Termux with:
#   pkg install ./utilitykit_<version>_all.deb
# (or `apt install ./utilitykit_<version>_all.deb`).
#
# The version is read from UK_VERSION in lib/uk_common.sh, so the package
# can never drift from the code it ships. Runs anywhere dpkg-deb exists
# (Termux itself, Debian/Ubuntu CI, macOS via `brew install dpkg`).
set -euo pipefail

PKG_NAME='utilitykit'
LAUNCHER='utility'
TERMUX_PREFIX="${TERMUX_PREFIX:-/data/data/com.termux/files/usr}"
OUT_DIR='dist'
MAINTAINER='ThatOn3Gu7 <https://github.com/ThatOn3Gu7/UtilityKit/issues>'
HOMEPAGE='https://github.com/ThatOn3Gu7/UtilityKit'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage: bash packaging/build-termux-deb.sh [--out DIR] [--prefix PATH]

Options:
  --out DIR      Output directory for the .deb (default: dist)
  --prefix PATH  Target Termux prefix baked into the package
                 (default: /data/data/com.termux/files/usr, or $TERMUX_PREFIX)
  -h, --help     Show this help
USAGE
}

die() {
  printf 'build-termux-deb: error: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --out)
    shift
    [[ -n "${1:-}" ]] || die '--out requires a directory argument'
    OUT_DIR="$1"
    ;;
  --prefix)
    shift
    [[ -n "${1:-}" ]] || die '--prefix requires a path argument'
    TERMUX_PREFIX="$1"
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    die "unknown option: $1 (see --help)"
    ;;
  esac
  shift
done

command -v dpkg-deb >/dev/null 2>&1 ||
  die 'dpkg-deb not found. On Termux it ships with dpkg; on Debian/Ubuntu install dpkg; on macOS: brew install dpkg.'

[[ -f "$REPO_ROOT/main.sh" && -f "$REPO_ROOT/lib/uk_common.sh" ]] ||
  die "repo root not found at $REPO_ROOT (main.sh / lib/uk_common.sh missing)"

# Single source of truth for the version.
VERSION="$(sed -n "s/^readonly UK_VERSION='\([0-9][0-9.]*\)'.*/\1/p" "$REPO_ROOT/lib/uk_common.sh")"
[[ -n "$VERSION" ]] || die "could not read UK_VERSION from lib/uk_common.sh"

STAGING="$(mktemp -d)"
cleanup() { rm -rf "$STAGING"; }
trap cleanup EXIT

APP_DIR="$STAGING$TERMUX_PREFIX/opt/$PKG_NAME"
BIN_DIR="$STAGING$TERMUX_PREFIX/bin"
BASH_COMP_DIR="$STAGING$TERMUX_PREFIX/share/bash-completion/completions"
ZSH_COMP_DIR="$STAGING$TERMUX_PREFIX/share/zsh/site-functions"

mkdir -p "$APP_DIR" "$BIN_DIR" "$BASH_COMP_DIR" "$ZSH_COMP_DIR" "$STAGING/DEBIAN"

# ── Payload ─────────────────────────────────────────────────────────
# Runtime tree only: the router, shared lib, every tool, and the docs.
# tests/, scripts/, docs-site/ and setup.sh are development artifacts and
# stay out of the package.
cp -a "$REPO_ROOT/main.sh" "$APP_DIR/"
cp -a "$REPO_ROOT/lib" "$APP_DIR/lib"
cp -a "$REPO_ROOT/modules" "$APP_DIR/modules"
[[ -d "$REPO_ROOT/docs" ]] && cp -a "$REPO_ROOT/docs" "$APP_DIR/docs"
for f in README.md CHANGES.md LICENSE; do
  [[ -f "$REPO_ROOT/$f" ]] && cp -a "$REPO_ROOT/$f" "$APP_DIR/"
done

# Launcher wrapper. Explicit Termux bash path: works even before
# termux-exec has rewritten /usr/bin/env shebangs.
cat >"$BIN_DIR/$LAUNCHER" <<WRAPPER
#!$TERMUX_PREFIX/bin/bash
exec "$TERMUX_PREFIX/bin/bash" "$TERMUX_PREFIX/opt/$PKG_NAME/main.sh" "\$@"
WRAPPER

# Tab-completions. Both files self-register for the `utility` command;
# the zsh file is #compdef-style so it works from \$fpath as _utility.
cp "$REPO_ROOT/completions/utility.bash" "$BASH_COMP_DIR/$LAUNCHER"
cp "$REPO_ROOT/completions/utility.zsh" "$ZSH_COMP_DIR/_$LAUNCHER"

# Normalize modes: dirs 755, files 644, executables 755.
find "$STAGING" -type d -exec chmod 755 {} +
find "$STAGING" -type f -exec chmod 644 {} +
find "$APP_DIR" -type f -name '*.sh' -exec chmod 755 {} +
chmod 755 "$BIN_DIR/$LAUNCHER"

# ── Control file ────────────────────────────────────────────────────
INSTALLED_SIZE_KB="$(du -sk "$STAGING$TERMUX_PREFIX" | cut -f1)"

cat >"$STAGING/DEBIAN/control" <<CONTROL
Package: $PKG_NAME
Version: $VERSION
Architecture: all
Maintainer: $MAINTAINER
Homepage: $HOMEPAGE
Depends: bash
Recommends: ncurses-utils, git, curl, jq
Installed-Size: $INSTALLED_SIZE_KB
Description: Suite of 51 self-contained Bash terminal tools
 UtilityKit bundles 51 independent Bash tools (port inspector, media
 convert, cache clean, secret scan, ...) behind one router with an
 interactive dashboard, direct CLI routes, and tab-completion.
 Run 'utility' for the dashboard or 'utility help' for all routes.
CONTROL

# ── Build ───────────────────────────────────────────────────────────
mkdir -p "$OUT_DIR"
DEB_PATH="$OUT_DIR/${PKG_NAME}_${VERSION}_all.deb"
# xz keeps the package installable on every apt/dpkg Termux has shipped.
dpkg-deb --root-owner-group -Zxz --build "$STAGING" "$DEB_PATH" >/dev/null

# ── Verify ──────────────────────────────────────────────────────────
dpkg-deb --info "$DEB_PATH" >/dev/null || die 'built package failed dpkg-deb --info'
FILE_COUNT="$(dpkg-deb --contents "$DEB_PATH" | wc -l | tr -d ' ')"
DEB_SIZE="$(du -h "$DEB_PATH" | cut -f1)"

printf 'Built %s (%s, %s entries)\n' "$DEB_PATH" "$DEB_SIZE" "$FILE_COUNT"
printf 'Install on Termux with:  pkg install ./%s\n' "$(basename "$DEB_PATH")"
