#!/usr/bin/env sh

set -eu

MODULE_FILE="${1:-android-app/module.yaml}"
VERSION_CODE="${VERSION_CODE:-}"
VERSION_NAME="${VERSION_NAME:-}"

if [ -z "$VERSION_CODE" ] || [ -z "$VERSION_NAME" ]; then
  echo "VERSION_CODE and VERSION_NAME must be set" >&2
  exit 1
fi

tmp_file="$(mktemp)"
code_updated=0
name_updated=0

while IFS= read -r line; do
  case "$line" in
    *versionCode:*)
      printf '%s\n' "${line%%versionCode:*}versionCode: ${VERSION_CODE}" >> "$tmp_file"
      code_updated=1
      ;;
    *versionName:*)
      printf '%s\n' "${line%%versionName:*}versionName: \"${VERSION_NAME}\"" >> "$tmp_file"
      name_updated=1
      ;;
    *)
      printf '%s\n' "$line" >> "$tmp_file"
      ;;
  esac
done < "$MODULE_FILE"

if [ "$code_updated" -ne 1 ] || [ "$name_updated" -ne 1 ]; then
  rm -f "$tmp_file"
  echo "Could not update versionCode/versionName in module file" >&2
  exit 1
fi

mv "$tmp_file" "$MODULE_FILE"
