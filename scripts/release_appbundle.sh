#!/usr/bin/env bash
# Bumps the pubspec.yaml build number and builds a release Android App Bundle.
# Usage: scripts/release_appbundle.sh [--skip-bump]
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if [[ "${1:-}" != "--skip-bump" ]]; then
  echo "Bumping build number in pubspec.yaml..."
  dart run tool/bump_build_number.dart
fi

echo "Building release App Bundle..."
flutter build appbundle --release

echo "Done: build/app/outputs/bundle/release/app-release.aab"
