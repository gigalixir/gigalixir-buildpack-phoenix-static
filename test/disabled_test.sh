#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/disabled.sh

env_dir=${TEST_DIR}/env_dir
mkdir -p ${env_dir}
var_file=${env_dir}/PHOENIX_STATIC_BUILDPACK__DISABLED

# TESTS
######################
suite "disabled"


  test "buildpack_disabled_value true for '1'"

    buildpack_disabled_value "1"



  test "buildpack_disabled_value true for 'true'"

    buildpack_disabled_value "true"



  test "buildpack_disabled_value false for other values"

    ! buildpack_disabled_value "false"
    ! buildpack_disabled_value "0"
    ! buildpack_disabled_value ""
    ! buildpack_disabled_value "yes"



  test "buildpack_disabled_in_env_dir false when file absent"

    rm -f $var_file
    ! buildpack_disabled_in_env_dir "$env_dir"



  test "buildpack_disabled_in_env_dir true when file holds '1'"

    printf '1' > $var_file
    buildpack_disabled_in_env_dir "$env_dir"
    rm -f $var_file



  test "buildpack_disabled_in_env_dir true when file holds 'true'"

    printf 'true' > $var_file
    buildpack_disabled_in_env_dir "$env_dir"
    rm -f $var_file



  test "buildpack_disabled_in_env_dir false when file holds other value"

    printf 'false' > $var_file
    ! buildpack_disabled_in_env_dir "$env_dir"
    rm -f $var_file



PASSED_ALL_TESTS=true
