#!/usr/bin/env bash

set -o pipefail

REPO_NAME="gigalixir-buildpack-phoenix-static"
source "$(dirname "${BASH_SOURCE[0]}")/test_framework.sh"

build_pack_dir="${ROOT_DIR}"

# create directories for test
assets_dir=${TEST_DIR}/assets_dir
cache_dir=${TEST_DIR}/cache_dir
mkdir -p ${assets_dir} ${cache_dir}
