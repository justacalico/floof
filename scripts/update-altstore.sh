#!/usr/bin/env bash
set -euo pipefail

# Rebuild repos/altstore.json for a released version.
# Usage: scripts/update-altstore.sh <tag>
# Needs gh authenticated against GITHUB_REPO and an existing repos/altstore.json.

_CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[ -f "$_CI_DIR/ci.env" ] && . "$_CI_DIR/ci.env"

TAG="${1:?usage: update-altstore.sh <tag>}"
VERSION="${TAG#v}"
GITHUB_REPO="${GITHUB_REPO:?set GITHUB_REPO in scripts/ci.env}"
PROJECT_DIR="${CI_PROJECT_DIR:-$PWD}"
SRC="$PROJECT_DIR/repos/altstore.json"
IPA="https://github.com/$GITHUB_REPO/releases/download/$TAG/floof-ios.ipa"

SIZE=$(gh api "repos/$GITHUB_REPO/releases/tags/$TAG" --jq '.assets[] | select(.name=="floof-ios.ipa") | .size')
[ -n "$SIZE" ] || { echo "no floof-ios.ipa asset on $TAG" >&2; exit 1; }

python3 - "$SRC" "$VERSION" "$IPA" "$SIZE" <<'PY'
import json, sys, datetime
src, version, ipa, size = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
data = json.load(open(src))
versions = data["apps"][0]["versions"]
versions[:] = [v for v in versions if v["version"] != version]
versions.insert(0, {
    "version": version,
    "date": datetime.date.today().isoformat(),
    "downloadURL": ipa,
    "size": size,
    "minOSVersion": "15.0"
})
json.dump(data, open(src, "w"), indent=2, ensure_ascii=False)
open(src, "a").write("\n")
PY

echo "altstore.json updated to $VERSION (size $SIZE)"
