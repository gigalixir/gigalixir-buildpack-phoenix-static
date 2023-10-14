#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/build.sh

# override functions used
install_yarn_deps() {
  true
}
install_npm_deps() {
  true
}
install_bower_deps() {
  true
}

# TESTS
######################
suite "install_and_cache_deps"


  test "no node_modules directory"

    install_and_cache_deps

    [ ! -d $assets_dir/node_modules ]



  test "empty node_modules directory"

    mkdir $cache_dir/node_modules

    install_and_cache_deps

    [ -d $assets_dir/node_modules ]
    [ -z "$(ls -A $assets_dir/node_modules)" ]
    rmdir $assets_dir/node_modules



  test "non-empty node_modules directory"

    mkdir -p $cache_dir/node_modules/some_dir
    touch $cache_dir/node_modules/some_dir/some_file

    install_and_cache_deps

    [ -f $assets_dir/node_modules/some_dir/some_file ]

    rm -rf $assets_dir/node_modules



  test "too many files for wildcard operator"

    for i in {1..1000}; do touch $cache_dir/node_modules/some_file_$i; done

    install_and_cache_deps

    [ -f $assets_dir/node_modules/some_file_1 ]
    [ -f $assets_dir/node_modules/some_file_1000 ]



PASSED_ALL_TESTS=true
