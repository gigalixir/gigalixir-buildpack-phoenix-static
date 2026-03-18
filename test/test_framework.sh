#!/usr/bin/env bash
#
# Shared test framework for gigalixir buildpack repos.
#
# Prerequisites (must be set before sourcing):
#   SCRIPT_DIR  - absolute path to the test/ directory
#   REPO_NAME   - name used in the mktemp template
#

ROOT_DIR=$(dirname "$SCRIPT_DIR")
PASSED_ALL_TESTS=false
ECHO_CONTENT=()

# make a temp dir for test files/directories
TEST_DIR=$(mktemp -d -t "${REPO_NAME}_XXXXXXXXXX")

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
output_stderr() {
  true
}
output_indent() {
  cat > /dev/null
}

# helper functions
test() {
  reset_test
  failed=false
  ECHO_CONTENT=()
  /bin/echo "  TEST: $@"
}

suite() {
  failed=false
  /bin/echo -e "\e[0;36mSUITE: $@\e[0m"
}

reset_test() {
  true
}
