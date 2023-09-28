#!/usr/bin/env bash

set -e

echo "SUITE: install_and_cache_deps"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR=$(dirname "$SCRIPT_DIR")

# make a temp dir for test files/directories
TEST_DIR=$(mktemp -d -t gigalixir-buildpack-phoenix-static_XXXXXXXXXX)
cleanup() {
  rm -rf ${TEST_DIR}
  exit
}
trap cleanup EXIT INT TERM

# create directories for test
assets_dir=${TEST_DIR}/assets_dir
cache_dir=${TEST_DIR}/cache_dir
mkdir -p ${assets_dir} ${cache_dir}

# include source file
source $SCRIPT_DIR/../lib/build.sh

# override functions used
info() {
  true
}
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
echo "  TEST: no node_modules directory"

install_and_cache_deps

[ ! -d $assets_dir/node_modules ]



echo "  TEST: empty node_modules directory"
mkdir $cache_dir/node_modules

install_and_cache_deps

[ -d $assets_dir/node_modules ]
[ -z "$(ls -A $assets_dir/node_modules)" ]
rmdir $assets_dir/node_modules



echo "  TEST: non-empty node_modules directory"
mkdir -p $cache_dir/node_modules/some_dir
touch $cache_dir/node_modules/some_dir/some_file

install_and_cache_deps

[ -f $assets_dir/node_modules/some_dir/some_file ]

rm -rf $assets_dir/node_modules



echo "  TEST: too many files for wildcard operator"
for i in {1..1000}; do touch $cache_dir/node_modules/some_file_$i; done

install_and_cache_deps

[ -f $assets_dir/node_modules/some_file_1 ]
[ -f $assets_dir/node_modules/some_file_1000 ]




echo "  Success"
