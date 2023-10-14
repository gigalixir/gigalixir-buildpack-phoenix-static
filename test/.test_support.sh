#!/usr/bin/env bash


ROOT_DIR=$(dirname "$SCRIPT_DIR")
PASSED_ALL_TESTS=false

# make a temp dir for test files/directories
TEST_DIR=$(mktemp -d -t gigalixir-buildpack-phoenix-static_XXXXXXXXXX)
cleanup() {
  rm -rf ${TEST_DIR}
  if $PASSED_ALL_TESTS; then
    echo -e "  \e[0;32mTest Suite PASSED\e[0m"
  else
    echo -e "  \e[0;31mFAILED\e[0m"
  fi
  exit
}
trap cleanup EXIT INT TERM

# create directories for test
assets_dir=${TEST_DIR}/assets_dir
cache_dir=${TEST_DIR}/cache_dir
mkdir -p ${assets_dir} ${cache_dir}


# overridden functions
info() {
  true
}

# helper functions
test() {
  failed=false
  echo "  TEST: $@"
}

suite() {
  failed=false
  echo -e "\e[0;36mSUITE: $@\e[0m"
}
