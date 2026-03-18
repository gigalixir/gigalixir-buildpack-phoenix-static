#!/usr/bin/env bash

set -o pipefail   # don't ignore exit codes when piping output

ROOT_DIR=$(dirname "$SCRIPT_DIR")
PASSED_ALL_TESTS=false
build_pack_dir="${ROOT_DIR}"

# make a temp dir for test files/directories
TEST_DIR=$(mktemp -d -t gigalixir-buildpack-phoenix-static_XXXXXXXXXX)
ECHO_CONTENT=()
cleanup() {
  rm -rf ${TEST_DIR}
  if $PASSED_ALL_TESTS; then
    /bin/echo -e "  \e[0;32mTest Suite PASSED\e[0m"
  else
    /bin/echo -e "  \e[0;31mFAILED\e[0m"
  fi
  exit
}
trap cleanup EXIT INT TERM

# create directories for test
assets_dir=${TEST_DIR}/assets_dir
cache_dir=${TEST_DIR}/cache_dir
mkdir -p ${assets_dir} ${cache_dir}


# stub output functions to suppress noise in tests
output_section() {
  true
}
output_line() {
  true
}
output_warning() {
  true
}
output_indent() {
  cat > /dev/null
}

# helper functions
test() {
  failed=false
  ECHO_CONTENT=()
  /bin/echo "  TEST: $@"
}

suite() {
  failed=false
  /bin/echo -e "\e[0;36mSUITE: $@\e[0m"
}
