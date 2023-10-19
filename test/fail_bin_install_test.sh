#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/build.sh

# override functions used
echo() {
  ECHO_CONTENT=("${ECHO_CONTENT[@]}" "$@")
}
exit() {
  EXIT_CODE=$1
}

# TESTS
######################
suite "fail_bin_install"


  test "echos error to user"

    fail_bin_install "node" "1.2.3" "bad version"

    [ "Error installing node 1.2.3: bad version" == "${ECHO_CONTENT[0]}" ]
    [ "1" -eq "$EXIT_CODE" ]



PASSED_ALL_TESTS=true
