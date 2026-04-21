#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./lib.sh
source "${script_dir}/lib.sh"

job_name="${1:-}"

if [[ -z "${job_name}" ]]; then
  printf 'Usage: %s <job-name>\n' "$0" >&2
  exit 1
fi

shift || true

case "${job_name}" in
  android-build-debug)
    ci_prepare_android_job
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/run_fastlane_with_amper_logs.sh buildDebug "$@"
    ;;
  android-build-release)
    ci_prepare_android_job
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/run_fastlane_with_amper_logs.sh buildRelease "$@"
    ;;
  android-test)
    ci_prepare_android_job
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/run_fastlane_with_amper_logs.sh test "$@"
    ;;
  ios-build-debug)
    ci_prepare_ios_job
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/run_xcodebuild_with_logs.sh Debug "$@"
    ;;
  ios-test)
    ci_prepare_ios_job
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/run_xcode_tests_with_logs.sh "$@"
    ;;
  ios-build-release)
    ci_prepare_ios_job
    cd "${CI_PROJECT_DIR}"
    ./scripts/ci/run_xcodebuild_with_logs.sh Release "$@"
    ;;
  ios-archive-release)
    trap ci_cleanup_app_store_connect_key EXIT
    ci_prepare_ios_fastlane_job
    cd "${CI_PROJECT_DIR}"
    bundle exec fastlane ios buildRelease "$@"
    ;;
  ios-testflight)
    trap ci_cleanup_app_store_connect_key EXIT
    ci_prepare_ios_testflight_job
    cd "${CI_PROJECT_DIR}"
    bundle exec fastlane ios uploadTestFlight "$@"
    ;;
  publish-internal)
    trap ci_cleanup_google_play_key EXIT
    ci_prepare_android_promotion_job
    cd "${CI_PROJECT_DIR}"
    bundle exec fastlane internal "$@"
    ;;
  promote-alpha)
    trap ci_cleanup_google_play_key EXIT
    ci_prepare_android_promotion_job
    cd "${CI_PROJECT_DIR}"
    bundle exec fastlane promote_internal_to_alpha "$@"
    ;;
  promote-beta)
    trap ci_cleanup_google_play_key EXIT
    ci_prepare_android_promotion_job
    cd "${CI_PROJECT_DIR}"
    bundle exec fastlane promote_alpha_to_beta "$@"
    ;;
  promote-production)
    trap ci_cleanup_google_play_key EXIT
    ci_prepare_android_promotion_job
    cd "${CI_PROJECT_DIR}"
    bundle exec fastlane promote_beta_to_production "$@"
    ;;
  *)
    printf 'Unknown CI job: %s\n' "${job_name}" >&2
    printf 'Supported jobs:\n' >&2
    printf '  %s\n' \
      android-build-debug \
      android-build-release \
      android-test \
      ios-build-debug \
      ios-test \
      ios-build-release \
      ios-archive-release \
      ios-testflight \
      publish-internal \
      promote-alpha \
      promote-beta \
      promote-production >&2
    exit 1
    ;;
esac
