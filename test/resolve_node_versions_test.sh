#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/build.sh

# override functions used
fail_bin_install() {
  failed=true
}

# TESTS
######################
suite "resolve_node_versions"


  test "node version specified with 'vX.Y.Z' format"

    node_version=v20.8.1

    resolve_node_version > /dev/null

    [ "20.8.1" == "$node_version" ]
    [ ! -z "$node_url" ]
    [ ! -z "$node_sha" ]
    ! $failed



  test "unknown node version specified"

    node_version=v0.0.0

    resolve_node_version > /dev/null

    $failed



  test "node version specified with 'X.Y.Z' format"

    node_version=20.8.1

    resolve_node_version > /dev/null

    [ "20.8.1" == "$node_version" ]
    ! $failed



  test "node version specified with 'latest' string"

    node_version=latest

    resolve_node_version > /dev/null

    [ ! -z "$node_version" ]
    [ "latest" != "$node_version" ]
    ! $failed
    LATEST=$node_version



  test "node version specified with empty string"

    node_version=""

    resolve_node_version > /dev/null

    [ ! -z "$node_version" ]
    [ "$LATEST" == "$node_version" ]
    ! $failed



PASSED_ALL_TESTS=true
