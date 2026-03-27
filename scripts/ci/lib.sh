#!/usr/bin/env bash

set -euo pipefail

ci_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ci_project_root="$(cd "${ci_lib_dir}/../.." && pwd)"

export CI_PROJECT_DIR="${CI_PROJECT_DIR:-${ci_project_root}}"
export AMPER_BOOTSTRAP_CACHE_DIR="${AMPER_BOOTSTRAP_CACHE_DIR:-${CI_PROJECT_DIR}/.amper-cache}"

# shellcheck source=./lib/common.sh
source "${ci_lib_dir}/lib/common.sh"
# shellcheck source=./lib/context.sh
source "${ci_lib_dir}/lib/context.sh"
# shellcheck source=./lib/env.sh
source "${ci_lib_dir}/lib/env.sh"
# shellcheck source=./lib/android.sh
source "${ci_lib_dir}/lib/android.sh"
# shellcheck source=./lib/ios.sh
source "${ci_lib_dir}/lib/ios.sh"
