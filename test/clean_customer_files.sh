#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/common.sh
source $SCRIPT_DIR/../lib/build.sh

# TESTS
######################
suite "clean_customer_files"
  build_dir="${SCRIPT_DIR}/config_files/unicode_chars"


  test "config file with unicode characters is cleaned properly"

    load_config > /dev/null

    [ "22.21.0" == "$node_version" ]
    ! $failed


  test "compile file with unicode characters is cleaned properly"

    assets_dir=$(pwd)
    phoenix_dir=$(pwd)

    run_compile > /dev/null

    ! $failed



PASSED_ALL_TESTS=true
