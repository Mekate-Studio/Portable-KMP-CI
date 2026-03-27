#!/usr/bin/env bash

set -euo pipefail

ci_prepare_ios_job() {
  ci_detect_context
  ci_prepare_workspace
  ci_set_java_home
  ci_resolve_android_sdk_root || true
  ci_configure_path
  ci_require_cmd xcodebuild
  xcodebuild -version
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
