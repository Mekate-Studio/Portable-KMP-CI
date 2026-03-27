#!/usr/bin/env sh

set -eu

module_dir="${1:-android-app}"
keystore_target="${module_dir}/keystore.jks"
properties_target="${module_dir}/keystore.properties"

mkdir -p "$module_dir"

if [ -n "${ANDROID_KEYSTORE_FILE:-}" ]; then
  cp "$ANDROID_KEYSTORE_FILE" "$keystore_target"
elif [ -n "${ANDROID_KEYSTORE_BASE64:-}" ]; then
  printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$keystore_target"
else
  echo "Set ANDROID_KEYSTORE_FILE or ANDROID_KEYSTORE_BASE64" >&2
  exit 1
fi

: "${ANDROID_KEYSTORE_PASSWORD:?ANDROID_KEYSTORE_PASSWORD must be set}"
: "${ANDROID_KEY_ALIAS:?ANDROID_KEY_ALIAS must be set}"
: "${ANDROID_KEY_PASSWORD:?ANDROID_KEY_PASSWORD must be set}"

cat > "$properties_target" <<EOF
storeFile=./$(basename "$keystore_target")
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
keyPassword=${ANDROID_KEY_PASSWORD}
EOF
