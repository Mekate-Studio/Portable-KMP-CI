#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

template="compose-multiplatform"
android_package="com.example.kmpci"
shared_caches_root="${AMPER_SHARED_CACHES_ROOT:-}"
amper_cli="${AMPER_CLI:-}"
generated_paths=(
  "amper"
  "amper.bat"
  "project.yaml"
  "android-app"
  "ios-app"
  "shared"
  "jvm-app"
)

usage() {
  cat <<EOF2
Usage: $(basename "$0") [--template <name>] [--android-package <package>] [--shared-caches-root <path>] [--amper <path>]

Deletes and regenerates the Amper-generated app layer in place while preserving
the CI overlay files that make this sample repo publishable.

This refreshes:
  amper
  amper.bat
  project.yaml
  android-app/
  ios-app/
  shared/

Defaults:
  --template ${template}
  --android-package ${android_package}
  --shared-caches-root <default Amper location>
  --amper <repo ./amper wrapper or amper from PATH>
EOF2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      template="${2:?Missing value for --template}"
      shift 2
      ;;
    --android-package)
      android_package="${2:?Missing value for --android-package}"
      shift 2
      ;;
    --shared-caches-root)
      shared_caches_root="${2:?Missing value for --shared-caches-root}"
      shift 2
      ;;
    --amper)
      amper_cli="${2:?Missing value for --amper}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

resolve_amper_cli() {
  if [[ -n "${amper_cli}" ]]; then
    printf '%s\n' "${amper_cli}"
    return
  fi

  if [[ -x "${repo_root}/amper" ]]; then
    printf '%s\n' "${repo_root}/amper"
    return
  fi

  if command -v amper >/dev/null 2>&1; then
    command -v amper
    return
  fi

  printf 'Could not find an Amper CLI. Expected ./amper in the repo root or amper on PATH.\n' >&2
  exit 1
}

purge_generated_paths() {
  local base_dir="$1"
  local path

  for path in "${generated_paths[@]}"; do
    rm -rf "${base_dir:?}/${path}"
  done
}

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/kmp-ci-sample-standalone.XXXXXX")"
generated_dir="${work_dir}/generated"
amper_bin="$(resolve_amper_cli)"

cleanup() {
  rm -rf "${work_dir}"
}

trap cleanup EXIT

mkdir -p "${generated_dir}"

printf 'Generating fresh Amper project with template %s...\n' "${template}"
(
  cd "${generated_dir}"
  if [[ -n "${shared_caches_root}" ]]; then
    "${amper_bin}" --shared-caches-root "${shared_caches_root}" init "${template}"
  else
    "${amper_bin}" init "${template}"
  fi
)

printf 'Trimming generated project to mobile-only layout...\n'
rm -rf \
  "${generated_dir}/jvm-app" \
  "${generated_dir}/shared/src@jvm" \
  "${generated_dir}/shared/test@jvm"

cat > "${generated_dir}/project.yaml" <<EOF2
modules:
  - android-app
  - ios-app
  - shared
EOF2

tmp_file="$(mktemp "${TMPDIR:-/tmp}/shared-module.XXXXXX")"
awk '
  /platforms:/ {
    gsub(/jvm, /, "", $0)
    gsub(/, jvm/, "", $0)
  }
  { print }
' "${generated_dir}/shared/module.yaml" > "${tmp_file}"
mv "${tmp_file}" "${generated_dir}/shared/module.yaml"

tmp_file="$(mktemp "${TMPDIR:-/tmp}/main-activity.XXXXXX")"
sed "s/package hello\\.world/package ${android_package//./\\.}/" \
  "${generated_dir}/android-app/src/MainActivity.kt" > "${tmp_file}"
mv "${tmp_file}" "${generated_dir}/android-app/src/MainActivity.kt"

tmp_file="$(mktemp "${TMPDIR:-/tmp}/android-manifest.XXXXXX")"
sed "s/hello\\.world\\.MainActivity/${android_package//./\\.}.MainActivity/" \
  "${generated_dir}/android-app/src/AndroidManifest.xml" > "${tmp_file}"
mv "${tmp_file}" "${generated_dir}/android-app/src/AndroidManifest.xml"

tmp_file="$(mktemp "${TMPDIR:-/tmp}/android-module.XXXXXX")"
awk -v package_name="${android_package}" '
  { print }
  /^  junit: junit-4$/ && !inserted {
    print "  android:"
    print "    namespace: " package_name
    print "    applicationId: " package_name
    print "    minSdk: 23"
    print "    compileSdk: 36"
    print "    targetSdk: 36"
    print "    # Enable this block when wiring real Android release signing for store"
    print "    # publishing. It is left disabled by default so the sample repo can run its"
    print "    # build/test CI jobs without release secrets."
    print "    # signing:"
    print "    #   enabled: true"
    print "    #   propertiesFile: ./keystore.properties"
    print "    versionCode: 1"
    print "    versionName: \"1.0-local\""
    inserted=1
  }
  END {
    if (!inserted) {
      exit 1
    }
  }
' "${generated_dir}/android-app/module.yaml" > "${tmp_file}"
mv "${tmp_file}" "${generated_dir}/android-app/module.yaml"

printf 'Deleting previously generated app files...\n'
purge_generated_paths "${repo_root}"

printf 'Copying regenerated app files into %s...\n' "${repo_root}"
cp "${generated_dir}/amper" "${repo_root}/amper"
cp "${generated_dir}/amper.bat" "${repo_root}/amper.bat"
cp "${generated_dir}/project.yaml" "${repo_root}/project.yaml"
cp -R "${generated_dir}/android-app" "${repo_root}/android-app"
cp -R "${generated_dir}/ios-app" "${repo_root}/ios-app"
cp -R "${generated_dir}/shared" "${repo_root}/shared"
chmod +x "${repo_root}/amper"

cat > "${repo_root}/android-app/keystore.properties.example" <<EOF2
storeFile=./keystore.jks
storePassword=your-keystore-password
keyAlias=upload
keyPassword=your-key-password
EOF2

mkdir -p "${repo_root}/shared/src@android"
cat > "${repo_root}/shared/src@android/AndroidManifest.xml" <<EOF2
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application android:hasCode="false" />
</manifest>
EOF2

cat > "${repo_root}/shared/proguard-rules.pro" <<EOF2
# Shared Android library module currently ships no custom ProGuard rules.
EOF2

if [[ -f "${repo_root}/fastlane/Appfile" ]]; then
  tmp_file="$(mktemp "${TMPDIR:-/tmp}/appfile.XXXXXX")"
  awk -v package_name="${android_package}" '
    /^package_name\(ENV\.fetch\("ANDROID_PACKAGE_NAME", / {
      print "package_name(ENV.fetch(\"ANDROID_PACKAGE_NAME\", \"" package_name "\"))"
      replaced=1
      next
    }
    { print }
    END {
      if (!replaced) {
        exit 0
      }
    }
  ' "${repo_root}/fastlane/Appfile" > "${tmp_file}"
  mv "${tmp_file}" "${repo_root}/fastlane/Appfile"
fi

printf 'Done. Regenerated app layer in %s\n' "${repo_root}"
