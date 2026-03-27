#!/usr/bin/env bash

set -euo pipefail

ci_path_add() {
  local candidate="${1:-}"

  if [[ -z "${candidate}" || ! -d "${candidate}" || ! -r "${candidate}" || ! -x "${candidate}" ]]; then
    return 0
  fi

  case ":${CI_EFFECTIVE_PATH:-}:" in
    *":${candidate}:"*) ;;
    *)
      if [[ -n "${CI_EFFECTIVE_PATH:-}" ]]; then
        CI_EFFECTIVE_PATH="${CI_EFFECTIVE_PATH}:${candidate}"
      else
        CI_EFFECTIVE_PATH="${candidate}"
      fi
      ;;
  esac
}

ci_is_android_sdk_dir() {
  local candidate="${1:-}"

  [[ -n "${candidate}" ]] || return 1
  [[ -d "${candidate}" ]] || return 1

  [[ -d "${candidate}/platform-tools" ]] \
    || [[ -d "${candidate}/cmdline-tools" ]] \
    || [[ -d "${candidate}/build-tools" ]]
}

ci_resolve_android_sdk_root() {
  local candidate=""

  for candidate in \
    "${ANDROID_SDK_ROOT:-}" \
    "${ANDROID_HOME:-}" \
    "${HOME:-}/Library/Android/sdk" \
    "${HOME:-}/Library/Android/SDK"
  do
    if [[ -z "${candidate}" ]]; then
      continue
    fi

    if [[ "${candidate}" == *:* ]]; then
      ci_log "Ignoring malformed Android SDK path: ${candidate}"
      continue
    fi

    if ci_is_android_sdk_dir "${candidate}"; then
      export ANDROID_HOME="${candidate}"
      export ANDROID_SDK_ROOT="${candidate}"
      ci_log "Using Android SDK at ${candidate}"
      return 0
    fi
  done

  unset ANDROID_HOME || true
  unset ANDROID_SDK_ROOT || true
  ci_log "Android SDK path not auto-detected"
  return 1
}

ci_configure_path() {
  local ruby_prefix=""
  local entry=""
  local sdk_root=""
  local original_path="${PATH:-}"

  if ci_has_cmd brew; then
    ruby_prefix="$(brew --prefix ruby 2>/dev/null || true)"
  fi

  CI_EFFECTIVE_PATH=""

  ci_path_add "${ruby_prefix:+${ruby_prefix}/bin}"
  ci_path_add /opt/homebrew/opt/ruby/bin
  ci_path_add /usr/local/opt/ruby/bin

  if [[ -n "${JAVA_HOME:-}" ]]; then
    ci_path_add "${JAVA_HOME}/bin"
  fi

  sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
  if [[ -n "${sdk_root}" ]]; then
    ci_path_add "${sdk_root}/cmdline-tools/latest/bin"
    ci_path_add "${sdk_root}/platform-tools"
  fi

  IFS=':' read -r -a ci_original_path_entries <<< "${original_path}"
  for entry in "${ci_original_path_entries[@]}"; do
    ci_path_add "${entry}"
  done

  ci_path_add /opt/homebrew/bin
  ci_path_add /opt/homebrew/sbin
  ci_path_add /usr/local/bin
  ci_path_add /usr/local/sbin
  ci_path_add /usr/bin
  ci_path_add /bin
  ci_path_add /usr/sbin
  ci_path_add /sbin

  export PATH="${CI_EFFECTIVE_PATH}"
  unset CI_EFFECTIVE_PATH

  ci_log "PATH configured"
}

ci_bundle_install() {
  ci_configure_path
  ci_require_cmd ruby
  ci_require_cmd bundle

  ci_log "ruby=$(command -v ruby)"
  ci_log "bundle=$(command -v bundle)"
  ci_log "java=$(command -v java)"
  ruby --version
  bundle --version

  (
    cd "${CI_PROJECT_DIR}"
    bundle install
  )
}

ci_log_android_sdk_env() {
  if [[ -n "${ANDROID_HOME:-}" ]]; then
    ci_log "ANDROID_HOME=${ANDROID_HOME}"
  fi

  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    ci_log "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"
  fi
}
