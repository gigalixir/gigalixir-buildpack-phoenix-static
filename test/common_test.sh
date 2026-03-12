#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/common.sh

# TESTS
######################
suite "export_mix_env"


  test "defaults to prod when MIX_ENV unset and no env dir"

    unset MIX_ENV
    env_dir=$TEST_DIR/env_no_exist

    export_mix_env

    [ "prod" == "$MIX_ENV" ]

    unset MIX_ENV



  test "reads MIX_ENV from env dir file"

    unset MIX_ENV
    env_dir=$TEST_DIR/env_mix
    mkdir -p $env_dir
    echo -n "staging" > $env_dir/MIX_ENV

    export_mix_env

    [ "staging" == "$MIX_ENV" ]

    rm -rf $env_dir
    unset MIX_ENV



  test "preserves existing MIX_ENV value"

    export MIX_ENV=test
    env_dir=$TEST_DIR/env_mix2
    mkdir -p $env_dir
    echo -n "staging" > $env_dir/MIX_ENV

    export_mix_env

    [ "test" == "$MIX_ENV" ]

    rm -rf $env_dir
    unset MIX_ENV



suite "export_config_vars"


  test "exports vars from env dir"

    env_dir=$TEST_DIR/env_config
    mkdir -p $env_dir
    echo -n "bar" > $env_dir/FOO
    echo -n "world" > $env_dir/HELLO

    export_config_vars

    [ "bar" == "$FOO" ]
    [ "world" == "$HELLO" ]

    rm -rf $env_dir
    unset FOO HELLO



  test "does not export blacklisted vars"

    env_dir=$TEST_DIR/env_blacklist
    mkdir -p $env_dir
    echo -n "/bad/path" > $env_dir/PATH
    echo -n "badgit" > $env_dir/GIT_DIR
    echo -n "ok" > $env_dir/MY_VAR

    OLD_PATH=$PATH
    export_config_vars

    [ "$OLD_PATH" == "$PATH" ]
    [ "ok" == "$MY_VAR" ]

    rm -rf $env_dir
    unset MY_VAR



  test "handles missing env dir gracefully"

    env_dir=$TEST_DIR/env_nonexistent

    export_config_vars

    # should not error, just skip



suite "fix_node_version"


  test "strips v prefix from node version"

    node_version="v14.17.0"

    fix_node_version

    [ "14.17.0" == "$node_version" ]



  test "strips text prefix from node version"

    node_version="node-v16.3.0-beta"

    fix_node_version

    [ "16.3.0" == "$node_version" ]



  test "leaves clean version unchanged"

    node_version="18.12.1"

    fix_node_version

    [ "18.12.1" == "$node_version" ]



  test "handles empty node version"

    node_version=""

    fix_node_version

    [ "" == "$node_version" ]



suite "fix_npm_version"


  test "strips v prefix from npm version"

    npm_version="v8.1.0"

    fix_npm_version

    [ "8.1.0" == "$npm_version" ]



  test "strips text prefix from npm version"

    npm_version="npm-v9.2.0"

    fix_npm_version

    [ "9.2.0" == "$npm_version" ]



  test "leaves clean npm version unchanged"

    npm_version="9.6.7"

    fix_npm_version

    [ "9.6.7" == "$npm_version" ]



suite "load_config"


  test "loads default config when no custom file"

    build_dir=$TEST_DIR/build_load_cfg
    mkdir -p $build_dir

    load_config > /dev/null

    # node_version=latest becomes empty after fix_node_version
    [ "false" == "$clean_cache" ]
    [ "compile" == "$compile" ]
    [ "." == "$phoenix_relative_path" ]

    rm -rf $build_dir



  test "custom config overrides defaults"

    build_dir=$TEST_DIR/build_custom_cfg
    mkdir -p $build_dir
    echo 'node_version=20.0.0' > $build_dir/phoenix_static_buildpack.config
    echo 'clean_cache=true' >> $build_dir/phoenix_static_buildpack.config

    load_config > /dev/null

    [ "20.0.0" == "$node_version" ]
    [ "true" == "$clean_cache" ]

    rm -rf $build_dir



  test "detects assets path when package.json in root"

    build_dir=$TEST_DIR/build_assets_root
    mkdir -p $build_dir
    touch $build_dir/package.json

    load_config > /dev/null

    [ "." == "$assets_path" ]

    rm -rf $build_dir



  test "defaults assets path to assets when no package.json"

    build_dir=$TEST_DIR/build_no_pkg
    mkdir -p $build_dir

    load_config > /dev/null

    [ "assets" == "$assets_path" ]

    rm -rf $build_dir



suite "source_file"


  test "sources file with plain content"

    src_file=$TEST_DIR/source_plain.sh
    echo 'SOURCE_TEST_VAR=hello_world' > $src_file

    source_file $src_file

    [ "hello_world" == "$SOURCE_TEST_VAR" ]

    rm $src_file
    unset SOURCE_TEST_VAR



  test "sanitizes non-printable characters"

    src_file=$TEST_DIR/source_dirty.sh
    printf 'DIRTY_VAR=clean_value\x00\x01\x02' > $src_file

    source_file $src_file

    [ "clean_value" == "$DIRTY_VAR" ]

    rm $src_file
    unset DIRTY_VAR



  test "restores original file after sourcing"

    src_file=$TEST_DIR/source_restore.sh
    printf 'RESTORE_VAR=restored\x00' > $src_file
    original_md5=$(md5sum $src_file | awk '{print $1}')

    source_file $src_file

    after_md5=$(md5sum $src_file | awk '{print $1}')
    [ "$original_md5" == "$after_md5" ]

    rm $src_file
    unset RESTORE_VAR



PASSED_ALL_TESTS=true
