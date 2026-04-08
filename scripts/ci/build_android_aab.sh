#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
generated_gradle_project="${project_root}/build/tasks/_android-app_buildAndroidRelease/gradle-project"
release_bundle_pattern='*/outputs/bundle/release/*.aab'

resolve_gradle_bin() {
  local gradle_bin="${GRADLE_BIN:-}"

  if [[ -n "${gradle_bin}" ]]; then
    printf '%s\n' "${gradle_bin}"
    return 0
  fi

  gradle_bin="$(find "${HOME}/.gradle/wrapper/dists/gradle-8.14.3-bin" -path '*/gradle-8.14.3/bin/gradle' -type f 2>/dev/null | head -n 1 || true)"
  if [[ -n "${gradle_bin}" ]]; then
    printf '%s\n' "${gradle_bin}"
    return 0
  fi

  gradle_bin="$(command -v gradle || true)"
  printf '%s\n' "${gradle_bin}"
}

find_release_aab() {
  find "${generated_gradle_project}/build" -type f -path "${release_bundle_pattern}" | head -n 1 || true
}

if [[ ! -d "${generated_gradle_project}" ]]; then
  echo "Generated Android Gradle project not found at ${generated_gradle_project}" >&2
  exit 1
fi

export GRADLE_USER_HOME="${GRADLE_USER_HOME:-${project_root}/.gradle-user-home}"
mkdir -p "${GRADLE_USER_HOME}"

if [[ -x /usr/libexec/java_home ]]; then
  preferred_java_home="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
  if [[ -n "${preferred_java_home}" ]]; then
    export JAVA_HOME="${JAVA_HOME:-${preferred_java_home}}"
  else
    export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home)}"
  fi
fi

gradle_bin="$(resolve_gradle_bin)"

if [[ -z "${gradle_bin}" ]]; then
  echo "No Gradle binary found for building the Android App Bundle" >&2
  exit 1
fi

cd "${generated_gradle_project}"

"${gradle_bin}" \
  --no-daemon \
  -p "${generated_gradle_project}" \
  bundleRelease

aab_path="$(find_release_aab)"

if [[ -z "${aab_path}" ]]; then
  echo "No Android App Bundle found after bundleRelease" >&2
  exit 1
fi

echo "Built Android App Bundle: ${aab_path}"
