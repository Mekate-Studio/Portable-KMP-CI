#!/usr/bin/env sh

set -eu

target_path="${1:-$PWD/fastlane/AuthKey.p8}"

mkdir -p "$(dirname "$target_path")"

if [ -n "${APP_STORE_CONNECT_API_KEY_FILE:-}" ]; then
  cp "$APP_STORE_CONNECT_API_KEY_FILE" "$target_path"
elif [ -n "${APP_STORE_CONNECT_API_KEY_BASE64:-}" ]; then
  printf '%s' "$APP_STORE_CONNECT_API_KEY_BASE64" | base64 --decode > "$target_path"
else
  echo "Set APP_STORE_CONNECT_API_KEY_FILE or APP_STORE_CONNECT_API_KEY_BASE64" >&2
  exit 1
fi

chmod 600 "$target_path"

echo "$target_path"
