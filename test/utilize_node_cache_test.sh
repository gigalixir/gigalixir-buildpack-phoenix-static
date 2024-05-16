#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/build.sh

# override functions used
INFO_OUTPUT=""
info() {
  INFO_OUTPUT="$@"
}

# TESTS
######################
suite "utilize_node_cache"


  test "no cached_sha"

    node_version=20.8.1
    node_download_complete=false
    cached_sha="none"

    utilize_node_cache

    ! $node_download_complete
    [ -z "$INFO_OUTPUT" ]



  test "cached_sha exists, files do not"

    cached_sha="$cache_dir/cached_sha"
    node_filename="node-v20.8.1-linux-x64.tar.gz"
    echo "abcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd  lib/build.sh" > $cached_sha

    utilize_node_cache

    ! $node_download_complete
    [ "$INFO_OUTPUT" == "No cached node found" ]

    INFO_OUTPUT=""



  test "cached_sha exists, cache file exists but mismatched"

    cached_node=$cache_dir/$node_filename
    touch $cached_node

    utilize_node_cache

    ! $node_download_complete
    [ ! -e $cached_node ]
    [ "$INFO_OUTPUT" == "No cached node found" ]

    INFO_OUTPUT=""



  test "package store file exists, but mismatched"

    mkdir -p $store_dir/node
    stored_node=$store_dir/node/$node_filename
    echo "hello there" > $stored_node

    utilize_node_cache

    ! $node_download_complete
    [ ! -e $cached_node ]
    [ "$INFO_OUTPUT" == "No cached node found" ]



  test "package store file exists, and matches"

    cp $stored_node $cached_node
    sha256sum $cached_node > $cached_sha
    rm $cached_node

    utilize_node_cache

    $node_download_complete
    [ -L $cached_node ]
    [ "$INFO_OUTPUT" == "Using node 20.8.1 from package store..." ]

    node_download_complete=false
    rm $cached_node



  test "cache file exists, and matches"

    cp $stored_node $cached_node

    utilize_node_cache

    $node_download_complete
    [ ! -L $cached_node ]
    [ -e $cached_node ]
    [ "$INFO_OUTPUT" == "Using cached node 20.8.1..." ]



PASSED_ALL_TESTS=true
