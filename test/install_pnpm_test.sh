#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/build.sh

# Build a fake pnpm >= 11 release tarball at $1 reporting version $2.
# Mirrors the real layout: `pnpm` binary + `dist/` at the tarball root.
make_pnpm_tarball() {
  local out="$1" ver="$2"
  local stage=$(mktemp -d)
  printf '#!/bin/sh\necho %s\n' "$ver" > "$stage/pnpm"
  chmod +x "$stage/pnpm"
  mkdir -p "$stage/dist"
  touch "$stage/dist/pnpm.cjs"
  tar czf "$out" -C "$stage" pnpm dist
  rm -rf "$stage"
}

# Stub curl to model GitHub's actual asset availability:
#   pnpm >= 11 publishes only `pnpm-linux-x64.tar.gz` (a gzipped tarball)
#   pnpm <= 10 publishes only `pnpm-linux-x64` (a raw self-contained binary)
# Any other request 404s, exactly as GitHub would.
curl() {
  local url="" out=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -o) out="$2"; shift 2;;
      http*) url="$1"; shift;;
      *) shift;;
    esac
  done

  local asset="${url##*/}"
  local ver="${url%/*}"; ver="${ver##*/v}"
  local major="${ver%%.*}"

  if [ "$major" -ge 11 ]; then
    if [ "$asset" = "pnpm-linux-x64.tar.gz" ]; then
      make_pnpm_tarball "$out" "$ver"; printf '200'
    else
      printf '404'
    fi
  else
    if [ "$asset" = "pnpm-linux-x64" ]; then
      printf '#!/bin/sh\necho %s\n' "$ver" > "$out"; chmod +x "$out"; printf '200'
    else
      printf '404'
    fi
  fi
}

# silence install messages
echo() { true; }

# TESTS
######################
suite "install_pnpm"


  test "installs pnpm >= 11 from the gzipped tarball asset"

    dir=$TEST_DIR/pnpm_v11
    pnpm_version=11.0.9

    install_pnpm "$dir"

    [ -x "$dir/pnpm" ]
    [ -d "$dir/dist" ]
    [ "11.0.9" == "$("$dir/pnpm" --version)" ]

    rm -rf "$dir"



  test "installs pnpm <= 10 from the raw binary asset"

    dir=$TEST_DIR/pnpm_v10
    pnpm_version=10.4.1

    install_pnpm "$dir"

    [ -x "$dir/pnpm" ]
    [ "10.4.1" == "$("$dir/pnpm" --version)" ]

    rm -rf "$dir"



PASSED_ALL_TESTS=true
