#!/usr/bin/env bash
set -euo pipefail

_CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
[ -f "$_CI_DIR/ci.env" ] && . "$_CI_DIR/ci.env"

REPO="${GITHUB_REPO:?set GITHUB_REPO in scripts/ci.env}"
SHA="${CI_COMMIT_SHA:-$(git rev-parse HEAD)}"

RUN_ID=""
if [ -f github-run-id.txt ]; then
  RUN_ID=$(tr -d '[:space:]' < github-run-id.txt)
fi
if [ -z "$RUN_ID" ]; then
  RUN_ID=$(gh api --method GET "repos/$REPO/actions/workflows/build.yml/runs" \
    -f "head_sha=$SHA" -f per_page=5 \
    -q '[.workflow_runs[] | select(.conclusion == "success") | .id][0]' 2>/dev/null || true)
fi
if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
  echo "No successful GitHub run found for $SHA" >&2
  exit 1
fi

echo "Downloading pages artifact from run $RUN_ID"
rm -rf public
gh run download "$RUN_ID" -R "$REPO" -n pages -D public
test -f public/index.html

for attempt in 1 2 3; do
  if gh run download "$RUN_ID" -R "$REPO" -n flatpak-merged -D public/flatpak; then
    echo "flatpak repo merged into public/flatpak"
    break
  fi
  echo "flatpak-merged download attempt $attempt failed" >&2
  sleep 10
done

ls public
ls public/flatpak 2>/dev/null || true
