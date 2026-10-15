#!/usr/bin/env bash
set -euo pipefail
version="${1:?usage: bump-version.sh <version>}"
sed -i -E "s/^version: .*/version: ${version}+$(git rev-list --count HEAD)/" pubspec.yaml
