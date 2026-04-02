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

if [[ "${host_arch}" == "x86_64" ]]; then
  simulator_arch="x86_64"
fi

mkdir -p "${log_dir}" "${derived_data_dir}"

echo "Using SWIFT_ENABLE_EXPLICIT_MODULES=${SWIFT_ENABLE_EXPLICIT_MODULES:-NO}"
echo "Using simulator architecture=${simulator_arch}"

cmd=(
  xcodebuild
  -project "${project_root}/ios-app/module.xcodeproj"
  -scheme app
  -configuration "${configuration}"
  -destination "generic/platform=iOS Simulator"
  -derivedDataPath "${derived_data_dir}"
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGNING_REQUIRED=NO
  ONLY_ACTIVE_ARCH=YES
  "ARCHS=${simulator_arch}"
  "SWIFT_ENABLE_EXPLICIT_MODULES=${SWIFT_ENABLE_EXPLICIT_MODULES:-NO}"
  build
)

if command -v xcbeautify >/dev/null 2>&1; then
  set -o pipefail
  "${cmd[@]}" 2>&1 | tee "${log_file}" | xcbeautify
else
  "${cmd[@]}" 2>&1 | tee "${log_file}"
fi
