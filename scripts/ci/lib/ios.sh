#!/usr/bin/env bash

set -euo pipefail

ci_prepare_ios_job() {
  ci_detect_context
  ci_prepare_workspace
  ci_set_java_home
  ci_resolve_android_sdk_root || true
  ci_configure_path
  export SWIFT_ENABLE_EXPLICIT_MODULES="${SWIFT_ENABLE_EXPLICIT_MODULES:-NO}"
  local host_arch="$(uname -m)"
  export IOS_SIMULATOR_ARCH="${IOS_SIMULATOR_ARCH:-arm64}"
  if [[ "${host_arch}" == "x86_64" ]]; then
    export IOS_SIMULATOR_ARCH="${IOS_SIMULATOR_ARCH:-x86_64}"
  fi
  ci_require_cmd xcodebuild
  xcodebuild -version
  printf 'Using SWIFT_ENABLE_EXPLICIT_MODULES: %s\n' "${SWIFT_ENABLE_EXPLICIT_MODULES}"
  printf 'Using IOS_SIMULATOR_ARCH: %s\n' "${IOS_SIMULATOR_ARCH}"
  ci_log_android_sdk_env
}

ci_prepare_ios_fastlane_job() {
  ci_prepare_ios_job
  ci_bundle_install
}

ci_prepare_ios_testflight_job() {
  ci_prepare_ios_fastlane_job

  (
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/write_app_store_connect_api_key.sh "${CI_PROJECT_DIR}/fastlane/AuthKey.p8" >/dev/null
  )
}

ci_cleanup_app_store_connect_key() {
  rm -f "${CI_PROJECT_DIR}/fastlane/AuthKey.p8"
}
