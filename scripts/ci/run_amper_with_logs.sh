#!/usr/bin/env sh

set -eu

if [ "$#" -eq 0 ]; then
  echo "Usage: run_amper_with_logs.sh <amper args...>" >&2
  exit 1
fi

if ./amper "$@"; then
  exit 0
fi

echo
echo "amper failed; printing recent Amper/Xcode logs if present..."
./scripts/ci/print_recent_logs.sh amper

exit 1
