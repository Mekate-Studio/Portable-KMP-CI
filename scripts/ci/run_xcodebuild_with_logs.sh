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

mkdir -p "${log_dir}" "${derived_data_dir}"

simulator_id="$(
  xcodebuild \
    -project "${project_root}/ios-app/module.xcodeproj" \
    -scheme app \
    -sdk iphonesimulator \
    -showdestinations 2>/dev/null | sed -n '
      /Available destinations for the "app" scheme:/,/Ineligible destinations/ {
        /platform:iOS Simulator/ {
          /name:iPhone/ {
            s/.*id:\([^,}]*\).*/\1/p
            q
          }
        }
      }
    '
)"

if [[ -z "${simulator_id}" ]]; then
  echo "No available iPhone simulator found on this runner" >&2
  exit 1
fi

cmd=(
  xcodebuild
  -project "${project_root}/ios-app/module.xcodeproj"
  -scheme app
  -configuration "${configuration}"
  -sdk iphonesimulator
  -destination "id=${simulator_id}"
  -derivedDataPath "${derived_data_dir}"
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
