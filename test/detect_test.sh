#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# override exit to capture exit codes
exit() {
  EXIT_CODE=$1
}

# override echo to capture output
echo() {
  ECHO_CONTENT=("${ECHO_CONTENT[@]}" "$@")
}

# TESTS
######################
suite "detect"


  test "mix.exs exists outputs Phoenix and exits 0"

    EXIT_CODE=""
    ECHO_CONTENT=()
    touch $TEST_DIR/mix.exs

    source $SCRIPT_DIR/../bin/detect "$TEST_DIR"

    [ "0" -eq "$EXIT_CODE" ]
    [ "Phoenix" == "${ECHO_CONTENT[0]}" ]

    rm $TEST_DIR/mix.exs



  test "no mix.exs exits 1"

    EXIT_CODE=""
    ECHO_CONTENT=()

    source $SCRIPT_DIR/../bin/detect "$TEST_DIR"

    [ "1" -eq "$EXIT_CODE" ]
    [ "${#ECHO_CONTENT[@]}" -eq 0 ]



PASSED_ALL_TESTS=true
