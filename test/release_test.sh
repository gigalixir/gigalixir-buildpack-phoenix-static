#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# TESTS
######################
suite "release"


  test "outputs valid YAML with addons"

    output=$(bash $SCRIPT_DIR/../bin/release)

    echo "$output" | grep -q "^---$"
    echo "$output" | grep -q "addons:"



  test "outputs empty addons list"

    output=$(bash $SCRIPT_DIR/../bin/release)

    echo "$output" | grep -q "\[\]"



  test "includes phx.server as default web process"

    output=$(bash $SCRIPT_DIR/../bin/release)

    echo "$output" | grep -q "default_process_types:"
    echo "$output" | grep -q "web:"
    echo "$output" | grep -q "mix phx.server"



  test "includes sname server flag"

    output=$(bash $SCRIPT_DIR/../bin/release)

    echo "$output" | grep -q "\-\-sname server"



PASSED_ALL_TESTS=true
