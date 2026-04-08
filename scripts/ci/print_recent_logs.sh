#!/usr/bin/env sh

set -eu

mode="${1:-generic}"
known_d8_kotlin_metadata_pattern="WARNING: D8: Unexpected error during rewriting of Kotlin metadata|WARNING: D8: An error occurred when parsing kotlin metadata"
known_debug_noise_pattern="DEBUG .* Exception on loading scripting plugin"
error_match_pattern="Caused by:|^\\* What went wrong:|^FAILURE: Build failed|^> Task .* FAILED|^Execution failed for task|^error:|Command PhaseScriptExecution failed|Exception in thread|(^|[^[:alnum:]_./-])[[:alnum:]_$.]+(Exception|Error):"

count_known_d8_kotlin_metadata_warnings() {
  log_file="$1"
  grep -E -c "${known_d8_kotlin_metadata_pattern}" "${log_file}" 2>/dev/null || true
}

count_error_matches() {
  log_file="$1"
  temp_matches="${TMPDIR:-/tmp}/amper-log-grep-count.$$"

  grep -E -n "${error_match_pattern}" "${log_file}" >"${temp_matches}" 2>/dev/null || true
  grep -E -v "${known_d8_kotlin_metadata_pattern}|${known_debug_noise_pattern}" "${temp_matches}" 2>/dev/null | wc -l | tr -d ' ' || true
  rm -f "${temp_matches}"
}

print_log_tail() {
  log_file="$1"
  suppressed_count="$(count_known_d8_kotlin_metadata_warnings "${log_file}")"

  echo
  echo "===== ${log_file} ====="
  if [ "${suppressed_count}" -gt 0 ]; then
    echo "--- suppressed ${suppressed_count} known non-fatal D8 Kotlin metadata warnings ---"
    grep -E -v "${known_d8_kotlin_metadata_pattern}" "${log_file}" | tail -n 200 || true
  else
    tail -n 200 "$log_file" || true
  fi
}

print_fastlane_error_matches() {
  log_file="$1"
  temp_matches="${TMPDIR:-/tmp}/amper-log-grep.$$"
  temp_filtered="${TMPDIR:-/tmp}/amper-log-grep-filtered.$$"
  suppressed_count="$(count_known_d8_kotlin_metadata_warnings "${log_file}")"

  grep -E -n "${error_match_pattern}" "$log_file" >"${temp_matches}" 2>/dev/null || true
  grep -E -v "${known_d8_kotlin_metadata_pattern}|${known_debug_noise_pattern}" "${temp_matches}" >"${temp_filtered}" 2>/dev/null || true

  if [ -s "${temp_filtered}" ]; then
    echo "--- matching error lines ---"
    cat "${temp_filtered}"
    echo "--- end matching error lines ---"
  fi

  rm -f "${temp_matches}"
  rm -f "${temp_filtered}"

  if [ "${suppressed_count}" -gt 0 ]; then
    echo "--- suppressed ${suppressed_count} known non-fatal D8 Kotlin metadata warnings ---"
  fi
}

print_build_logs() {
  if [ ! -d build/logs ]; then
    echo "No build/logs directory found."
    return 1
  fi

  find build/logs -type f \( -name "*.stderr" -o -name "*.stdout" -o -name "*.log" \) -print \
    | sort \
    | tail -n 10 \
    | while IFS= read -r log_file; do
        if [ "${mode}" = "fastlane" ]; then
          if [ "$(count_error_matches "${log_file}")" -eq 0 ]; then
            continue
          fi
          print_fastlane_error_matches "${log_file}"
        fi
        print_log_tail "${log_file}"
      done

  return 0
}

print_task_logs() {
  find build/tasks -type f \( -name "xcodebuild.log" -o -name "*.log" \) -print 2>/dev/null \
    | sort \
    | tail -n 10 \
    | while IFS= read -r log_file; do
        print_log_tail "${log_file}"
      done
}

if ! print_build_logs; then
  if [ "${mode}" = "fastlane" ] && [ -d build ]; then
    echo
    echo "Recent files under build/:"
    find build -maxdepth 4 -type f | sort | tail -n 50 || true
  fi
fi

if [ "${mode}" = "amper" ]; then
  print_task_logs
fi
