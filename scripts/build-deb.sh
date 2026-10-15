#!/usr/bin/env bash
set -euo pipefail

_CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[ -f "$_CI_DIR/ci.env" ] && . "$_CI_DIR/ci.env"

BUNDLE_DIR="${1:?usage: build-deb.sh <bundle-dir> <version> <deb-arch> <output-file>}"
VERSION="${2:?}"
ARCH="${3:?}"
OUT="${4:?}"

PKG=$(mktemp -d)
trap 'rm -rf "$PKG"' EXIT
mkdir -p "$PKG/opt/floof" "$PKG/usr/bin" "$PKG/DEBIAN" \
  "$PKG/usr/share/applications" "$PKG/usr/share/icons/hicolor/512x512/apps"

cp -a "$BUNDLE_DIR/." "$PKG/opt/floof/"
ln -sf /opt/floof/floof "$PKG/usr/bin/floof"
cp packaging/linux/floof.desktop "$PKG/usr/share/applications/"
cp assets/icon_512.png "$PKG/usr/share/icons/hicolor/512x512/apps/floof.png"

cat > "$PKG/DEBIAN/control" <<EOF
Package: floof
Version: $VERSION
Architecture: $ARCH
Maintainer: HttpAnimations
Description: A video client for e926 with a local recommendation engine.
EOF

dpkg-deb --build "$PKG" "$OUT"
echo "built $OUT"
