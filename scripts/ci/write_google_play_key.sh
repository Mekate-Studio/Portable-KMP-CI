#!/usr/bin/env sh

set -eu

target_path="${1:-$PWD/google_play_api_key.json}"
source_value="${GOOGLE_PLAY_JSON_KEY:-}"

if [ -z "$source_value" ]; then
  echo "GOOGLE_PLAY_JSON_KEY is not set" >&2
  exit 1
fi

if [ -f "$source_value" ]; then
  cp "$source_value" "$target_path"
else
  printf '%s' "$source_value" > "$target_path"
fi

echo "$target_path"
