#!/usr/bin/env bash

set -euo pipefail

ci_detect_context() {
  local engine build_number build_sha branch default_branch

  if [[ -n "${GITLAB_CI:-}" ]]; then
    engine="gitlab"
    build_number="${CI_PIPELINE_IID:-1}"
    build_sha="${CI_COMMIT_SHORT_SHA:-${CI_COMMIT_SHA:-local}}"
    build_sha="${build_sha:0:8}"
    branch="${CI_COMMIT_BRANCH:-${CI_COMMIT_REF_NAME:-local}}"
    default_branch="${CI_DEFAULT_BRANCH:-${DEFAULT_BRANCH:-main}}"
  elif [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    engine="github"
    build_number="${GITHUB_RUN_NUMBER:-1}"
    build_sha="${GITHUB_SHA:-local}"
    build_sha="${build_sha:0:8}"
    branch="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-local}}"
    default_branch="${GITHUB_DEFAULT_BRANCH:-${DEFAULT_BRANCH:-main}}"
  else
    engine="local"
    build_number="${BUILD_NUMBER:-1}"
    build_sha="${BUILD_SHA:-local}"
    build_sha="${build_sha:0:8}"
    branch="${BUILD_BRANCH:-local}"
    default_branch="${DEFAULT_BRANCH:-main}"
  fi

  export CI_ENGINE="${CI_ENGINE:-$engine}"
  export BUILD_NUMBER="${BUILD_NUMBER:-$build_number}"
  export BUILD_SHA="${BUILD_SHA:-$build_sha}"
  export BUILD_BRANCH="${BUILD_BRANCH:-$branch}"
  export DEFAULT_BRANCH="${DEFAULT_BRANCH:-$default_branch}"
  export IS_DEFAULT_BRANCH="false"

  if [[ "${BUILD_BRANCH}" == "${DEFAULT_BRANCH}" ]]; then
    export IS_DEFAULT_BRANCH="true"
  fi

  export VERSION_CODE="${VERSION_CODE:-$BUILD_NUMBER}"
  export VERSION_SHA="${VERSION_SHA:-$BUILD_SHA}"
  export VERSION_NAME="${VERSION_NAME:-1.0-${VERSION_SHA}}"
  export IOS_BUILD_NUMBER="${IOS_BUILD_NUMBER:-$BUILD_NUMBER}"
  export IOS_VERSION="${IOS_VERSION:-1.0}"

  ci_log "engine=${CI_ENGINE} branch=${BUILD_BRANCH} default_branch=${DEFAULT_BRANCH} build_number=${BUILD_NUMBER} sha=${BUILD_SHA}"
}
