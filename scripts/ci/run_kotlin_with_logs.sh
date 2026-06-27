#!/usr/bin/env sh

set -eu

if [ "$#" -eq 0 ]; then
  echo "Usage: run_kotlin_with_logs.sh <kotlin args...>" >&2
  exit 1
fi

if ./kotlin "$@"; then
  exit 0
fi

echo
echo "kotlin failed; printing recent Kotlin Toolchain/Xcode logs if present..."
./scripts/ci/print_recent_logs.sh kotlin

exit 1
