#!/usr/bin/env bash

set -euo pipefail

ci_prepare_android_job() {
  ci_detect_context
  ci_prepare_workspace
  ci_set_java_home
  ci_resolve_android_sdk_root || true
  ci_bundle_install
  ci_log_android_sdk_env

  (
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/apply_android_version.sh
  )

  if [[ -n "${ANDROID_KEYSTORE_FILE:-}" || -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
    ci_log "Android signing material detected"
    (
      cd "${CI_PROJECT_DIR}"
      ./scripts/ci/write_android_signing_files.sh
    )
  else
    ci_log "Android signing material missing"
  fi
}

ci_prepare_android_promotion_job() {
  ci_prepare_android_job
  export GOOGLE_PLAY_JSON_KEY_FILE="${CI_PROJECT_DIR}/google_play_api_key.json"

  (
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/write_google_play_key.sh "${GOOGLE_PLAY_JSON_KEY_FILE}" >/dev/null
  )
}

ci_cleanup_google_play_key() {
  rm -f "${CI_PROJECT_DIR}/google_play_api_key.json"
}
