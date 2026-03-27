#!/usr/bin/env sh

set -eu

mode="${1:-generic}"

print_log_tail() {
  log_file="$1"

  echo
  echo "===== ${log_file} ====="
  tail -n 200 "$log_file" || true
}

print_fastlane_error_matches() {
  log_file="$1"
  temp_matches="${TMPDIR:-/tmp}/amper-log-grep.$$"

  if grep -E -n "Caused by:|^\\* What went wrong:|^FAILURE: Build failed|Exception|Error" "$log_file" >"${temp_matches}" 2>/dev/null; then
    echo "--- matching error lines ---"
    cat "${temp_matches}"
    echo "--- end matching error lines ---"
  fi

  rm -f "${temp_matches}"
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
