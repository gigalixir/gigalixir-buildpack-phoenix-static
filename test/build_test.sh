#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source files
source $SCRIPT_DIR/../lib/common.sh
source $SCRIPT_DIR/../lib/build.sh

# override node/npm commands for cache_versions tests
node() {
  echo "v20.0.0"
}
npm() {
  echo "9.6.7"
}

# TESTS
######################
suite "cache_versions"


  test "stores node version to cache dir"

    cache_dir=$TEST_DIR/cache_cv
    mkdir -p $cache_dir

    cache_versions

    [ -f $cache_dir/node-version ]
    [ "v20.0.0" == "$(cat $cache_dir/node-version | tr -d '[:space:]')" ]

    rm -rf $cache_dir



  test "stores npm version to cache dir"

    cache_dir=$TEST_DIR/cache_cv2
    mkdir -p $cache_dir

    cache_versions

    [ -f $cache_dir/npm-version ]
    [ "9.6.7" == "$(cat $cache_dir/npm-version | tr -d '[:space:]')" ]

    rm -rf $cache_dir



suite "write_profile"


  test "creates .profile.d directory"

    build_dir=$TEST_DIR/build_wp
    mkdir -p $build_dir
    phoenix_relative_path=.

    write_profile

    [ -d $build_dir/.profile.d ]

    rm -rf $build_dir



  test "creates profile script with correct PATH exports"

    build_dir=$TEST_DIR/build_wp2
    mkdir -p $build_dir
    phoenix_relative_path=.

    write_profile

    [ -f $build_dir/.profile.d/phoenix_static_buildpack_paths.sh ]
    grep -q 'HOME/.heroku/node/bin' $build_dir/.profile.d/phoenix_static_buildpack_paths.sh
    grep -q 'HOME/.heroku/yarn/bin' $build_dir/.profile.d/phoenix_static_buildpack_paths.sh
    grep -q 'node_modules/.bin' $build_dir/.profile.d/phoenix_static_buildpack_paths.sh

    rm -rf $build_dir



  test "uses custom phoenix_relative_path in profile"

    build_dir=$TEST_DIR/build_wp3
    mkdir -p $build_dir
    phoenix_relative_path=apps/my_app

    write_profile

    grep -q 'apps/my_app/node_modules/.bin' $build_dir/.profile.d/phoenix_static_buildpack_paths.sh

    rm -rf $build_dir



suite "setup_phx_envvars"


  test "creates env file with PHX_SERVER default"

    build_dir=$TEST_DIR/build_phx
    mkdir -p $build_dir

    setup_phx_envvars

    [ -f $build_dir/.profile.d/phoenix_static_buildpack_env.sh ]
    grep -q 'PHX_SERVER' $build_dir/.profile.d/phoenix_static_buildpack_env.sh

    rm -rf $build_dir



  test "creates env file with PHX_HOST default"

    build_dir=$TEST_DIR/build_phx2
    mkdir -p $build_dir

    setup_phx_envvars

    grep -q 'PHX_HOST' $build_dir/.profile.d/phoenix_static_buildpack_env.sh
    grep -q 'gigalixirapp.com' $build_dir/.profile.d/phoenix_static_buildpack_env.sh

    rm -rf $build_dir



  test "creates .profile.d directory if missing"

    build_dir=$TEST_DIR/build_phx3
    mkdir -p $build_dir

    setup_phx_envvars

    [ -d $build_dir/.profile.d ]

    rm -rf $build_dir



suite "finalize_node"


  test "calls write_profile when remove_node is false"

    build_dir=$TEST_DIR/build_fn
    mkdir -p $build_dir
    remove_node=false
    phoenix_relative_path=.

    finalize_node

    [ -f $build_dir/.profile.d/phoenix_static_buildpack_paths.sh ]

    rm -rf $build_dir



  test "removes node when remove_node is true"

    build_dir=$TEST_DIR/build_fn2
    heroku_dir=$TEST_DIR/build_fn2/.heroku
    assets_dir=$TEST_DIR/build_fn2/assets
    mkdir -p $heroku_dir/node
    mkdir -p $assets_dir/node_modules
    touch $heroku_dir/node/node_binary
    touch $assets_dir/node_modules/some_module
    remove_node=true

    finalize_node

    [ ! -d $assets_dir/node_modules ]
    [ ! -d $heroku_dir/node ]

    rm -rf $build_dir



suite "load_previous_npm_node_versions"


  test "loads cached npm and node versions"

    cache_dir=$TEST_DIR/cache_prev
    mkdir -p $cache_dir
    echo "9.0.0" > $cache_dir/npm-version
    echo "v18.0.0" > $cache_dir/node-version

    load_previous_npm_node_versions

    [ "9.0.0" == "$(echo $old_npm | tr -d '[:space:]')" ]
    [ "v18.0.0" == "$(echo $old_node | tr -d '[:space:]')" ]

    rm -rf $cache_dir



  test "handles missing cache files"

    cache_dir=$TEST_DIR/cache_prev_empty
    mkdir -p $cache_dir
    unset old_npm old_node

    load_previous_npm_node_versions

    # should not error when files don't exist



suite "cleanup_cache"


  test "cleans cache when clean_cache is true"

    cache_dir=$TEST_DIR/cache_clean
    mkdir -p $cache_dir/node_modules
    mkdir -p $cache_dir/phoenix-static
    mkdir -p $cache_dir/yarn-cache
    echo "v18" > $cache_dir/node-version
    echo "9.0" > $cache_dir/npm-version
    clean_cache=true
    old_node=""
    node_version=""

    cleanup_cache

    [ ! -f $cache_dir/node-version ]
    [ ! -f $cache_dir/npm-version ]
    [ ! -d $cache_dir/phoenix-static ]
    [ ! -d $cache_dir/yarn-cache ]
    [ ! -d $cache_dir/node_modules ]

    rm -rf $cache_dir



  test "preserves cache when clean_cache is false"

    cache_dir=$TEST_DIR/cache_keep
    mkdir -p $cache_dir/node_modules
    echo "v18" > $cache_dir/node-version
    clean_cache=false

    cleanup_cache

    [ -f $cache_dir/node-version ]
    [ -d $cache_dir/node_modules ]

    rm -rf $cache_dir



PASSED_ALL_TESTS=true
