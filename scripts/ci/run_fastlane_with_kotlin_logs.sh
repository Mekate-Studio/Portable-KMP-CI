#!/usr/bin/env sh

set -eu

lane="${1:?Usage: run_fastlane_with_kotlin_logs.sh <lane>}"
shift || true

if bundle exec fastlane "$lane" "$@"; then
  exit 0
fi

echo
echo "fastlane failed; printing recent Kotlin Toolchain/Gradle logs if present..."
./scripts/ci/print_recent_logs.sh fastlane

exit 1
