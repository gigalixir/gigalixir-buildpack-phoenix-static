#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# override mix command
MIX_ARGS=()
mix() {
  MIX_ARGS=("${MIX_ARGS[@]}" "$@")
}

NPM_ARGS=""
npm() {
  NPM_ARGS="$@"
}

# TESTS
######################
suite "compile"


  test "package.json with deploy script"

    echo '{
  "scripts": {
    "deploy": "echo deploying"
  }
}' > $assets_dir/package.json
    source $SCRIPT_DIR/../compile
    [ "$NPM_ARGS" == "run deploy" ]

    rm $assets_dir/package.json
    NPM_ARGS=""
    MIX_ARGS=()



  test "package.json without deploy script"

    echo '{
  "scripts": {
    "other": "echo deploying"
  }
}' > $assets_dir/package.json
    source $SCRIPT_DIR/../compile
    [ -z "$NPM_ARGS" ]



PASSED_ALL_TESTS=true
