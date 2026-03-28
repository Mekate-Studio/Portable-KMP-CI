#!/usr/bin/env bash

set -euo pipefail

configuration="${1:-}"

if [[ -z "${configuration}" ]]; then
  echo "Usage: run_xcodebuild_with_logs.sh <Debug|Release>" >&2
  exit 1
fi

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
log_dir="${project_root}/build/logs"
derived_data_dir="${project_root}/build/xcode-derived-data"
log_file="${log_dir}/xcodebuild-ios-${configuration}.log"
host_arch="$(uname -m)"
simulator_arch="arm64"

mkdir -p "${log_dir}" "${derived_data_dir}"

if [[ "${host_arch}" == "x86_64" ]]; then
  simulator_arch="x86_64"
fi

cmd=(
  xcodebuild
  -project "${project_root}/ios-app/module.xcodeproj"
  -scheme app
  -configuration "${configuration}"
  -sdk iphonesimulator
  -destination "generic/platform=iOS Simulator"
  -derivedDataPath "${derived_data_dir}"
  ONLY_ACTIVE_ARCH=YES
  ARCHS="${simulator_arch}"
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGNING_REQUIRED=NO
  build
)

if command -v xcbeautify >/dev/null 2>&1; then
  set -o pipefail
  "${cmd[@]}" 2>&1 | tee "${log_file}" | xcbeautify
else
  "${cmd[@]}" 2>&1 | tee "${log_file}"
fi
