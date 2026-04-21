#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
log_dir="${project_root}/build/logs"
derived_data_dir="${project_root}/build/xcode-derived-data-cli-tests"
log_file="${log_dir}/xcodebuild-ios-tests.log"
workspace_path="${project_root}/ios-app/module.xcodeproj/project.xcworkspace"
workspace_contents_path="${workspace_path}/contents.xcworkspacedata"
project_path="${project_root}/ios-app/module.xcodeproj"

mkdir -p "${log_dir}" "${derived_data_dir}"

echo "Using KOTLIN_IOS_BUILDER=${KOTLIN_IOS_BUILDER:-gradle}"
echo "Using GRADLE_USER_HOME=${GRADLE_USER_HOME:-${project_root}/.gradle-user-home}"
echo "Using SWIFT_ENABLE_EXPLICIT_MODULES=${SWIFT_ENABLE_EXPLICIT_MODULES:-NO}"

simulator_udid="$(
  xcrun simctl list devices available --json | ruby -rjson -e '
    data = JSON.parse(STDIN.read)
    device = data.fetch("devices").values.flatten.find do |entry|
      entry["isAvailable"] && entry["name"].start_with?("iPhone")
    end
    abort("No available iPhone simulator found") unless device
    puts device["udid"]
  '
)"

cmd=(xcodebuild)

if [[ -f "${workspace_contents_path}" ]]; then
  echo "Using Xcode workspace=${workspace_path}"
  cmd+=(-workspace "${workspace_path}")
else
  echo "Using Xcode project=${project_path} (workspace metadata missing)"
  cmd+=(-project "${project_path}")
fi

cmd+=(
  -scheme app
  -configuration Debug
  -destination "platform=iOS Simulator,id=${simulator_udid}"
  -derivedDataPath "${derived_data_dir}"
  "SWIFT_ENABLE_EXPLICIT_MODULES=${SWIFT_ENABLE_EXPLICIT_MODULES:-NO}"
  test
)

if command -v xcbeautify >/dev/null 2>&1; then
  set -o pipefail
  "${cmd[@]}" 2>&1 | tee "${log_file}" | xcbeautify
else
  "${cmd[@]}" 2>&1 | tee "${log_file}"
fi
