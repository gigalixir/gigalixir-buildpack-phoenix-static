#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/.test_support.sh

# include source file
source $SCRIPT_DIR/../lib/build.sh

# bin/compile runs under `errexit` *and* `pipefail`, and that combination is what
# turned a failed lookup into a build that aborted with no output at all. Keep both
# on here so a regression fails the suite instead of hiding behind a relaxed shell.
set -o errexit
set -o pipefail

# no waiting between retries
node_lookup_delay=0

# the framework silences log output, but these tests assert on what actually
# reaches the build log, so put the real implementation back
output_line() {
  echo "       $1"
}

# override functions used
fail_bin_install() {
  failed=true
  FAIL_REASON="$3"
  return 1
}

# Stub nodejs.org. LISTING_STATUS and SHASUMS_STATUS model what each endpoint
# returns. Every request is logged to CURL_LOG so tests can count retries, a file
# rather than a variable because fetch_url calls curl inside a command
# substitution and a subshell's variables die with it.
CURL_LOG=$TEST_DIR/curl_calls

curl() {
  local url=""
  while [ $# -gt 0 ]; do
    case "$1" in
      http*) url="$1";;
    esac
    shift
  done

  echo "$url" >> $CURL_LOG

  case "$url" in
    */SHASUMS256.txt)
      case "$SHASUMS_STATUS" in
        # the published checksum file, one line per asset
        ok)
          echo "1111111111111111111111111111111111111111111111111111111111111111  node-v${SERVED_VERSION}-linux-x64.tar.xz"
          echo "2222222222222222222222222222222222222222222222222222222222222222  node-v${SERVED_VERSION}-linux-x64.tar.gz"
          ;;
        # a CDN edge still serving the previous release's checksums
        stale)
          echo "3333333333333333333333333333333333333333333333333333333333333333  node-v0.0.1-linux-x64.tar.gz"
          ;;
        # 200 with an empty body
        empty) true;;
        # 404 or a transport error, with --fail curl exits non-zero
        error) return 22;;
      esac
      ;;
    *)
      case "$LISTING_STATUS" in
        ok)
          echo "<a href=\"/dist/latest/node-v${SERVED_VERSION}-linux-arm64.tar.gz\">node-v${SERVED_VERSION}-linux-arm64.tar.gz</a>"
          echo "<a href=\"/dist/latest/node-v${SERVED_VERSION}-linux-x64.tar.gz\">node-v${SERVED_VERSION}-linux-x64.tar.gz</a>"
          ;;
        # a listing with no hrefs, as some mirrors serve
        unqualified)
          echo "<a href=\"node-v${SERVED_VERSION}-linux-x64.tar.gz\">node-v${SERVED_VERSION}-linux-x64.tar.gz</a>"
          ;;
        # fails the first attempt, serves the listing on the retry
        flaky)
          if [ 1 -eq $(grep -c -F -x -- "$url" $CURL_LOG) ]; then
            return 22
          fi
          echo "<a href=\"/dist/latest/node-v${SERVED_VERSION}-linux-x64.tar.gz\">node-v${SERVED_VERSION}-linux-x64.tar.gz</a>"
          ;;
        error) return 22;;
      esac
      ;;
  esac
}

# reset the fake nodejs.org before each test
reset_test() {
  SERVED_VERSION=20.8.1
  LISTING_STATUS=ok
  SHASUMS_STATUS=ok
  FAIL_REASON=""
  node_url=""
  node_sha=""
  rm -f $CURL_LOG
  rm -f $cache_dir/SHA256SUM-node-*
}

# count the requests made to a given url
curl_calls_to() {
  grep -c -F -x -- "$1" $CURL_LOG || true
}

# TESTS
######################
suite "resolve_node_versions"


  test "node version specified with 'vX.Y.Z' format"

    node_version=v20.8.1

    resolve_node_version > /dev/null

    [ "20.8.1" == "$node_version" ]
    [ "https://nodejs.org/dist/latest/node-v20.8.1-linux-x64.tar.gz" == "$node_url" ]
    [ "2222222222222222222222222222222222222222222222222222222222222222" == "$node_sha" ]
    [ ! -z "$cached_node" ]
    [ ! -z "$cached_sha" ]
    [ -e $cached_sha ]
    ! $failed



  test "node version specified with 'X.Y.Z' format"

    node_version=20.8.1

    resolve_node_version > /dev/null

    [ "20.8.1" == "$node_version" ]
    ! $failed



  test "node version specified with 'latest' string"

    SERVED_VERSION=26.6.0
    node_version=latest

    resolve_node_version > /dev/null

    [ "26.6.0" == "$node_version" ]
    ! $failed



  test "node version specified with empty string"

    SERVED_VERSION=26.6.0
    node_version=""

    resolve_node_version > /dev/null

    [ "26.6.0" == "$node_version" ]
    ! $failed



  test "listing without a fully qualified href"

    LISTING_STATUS=unqualified
    node_version=20.8.1

    resolve_node_version > /dev/null

    [ "https://nodejs.org/dist/v20.8.1/node-v20.8.1-linux-x64.tar.gz" == "$node_url" ]
    ! $failed



  test "unknown node version specified"

    LISTING_STATUS=error
    node_version=v0.0.0

    resolve_node_version > /dev/null 2>&1 || true

    $failed
    echo "$FAIL_REASON" | grep -q "https://nodejs.org/dist/v0.0.0/"



  test "version lookup is retried before failing"

    LISTING_STATUS=error
    node_version=v0.0.0

    resolve_node_version > /dev/null 2>&1 || true

    [ 3 -eq $(curl_calls_to "https://nodejs.org/dist/v0.0.0/") ]
    $failed



  test "unavailable checksum fails with an error message"

    SHASUMS_STATUS=error
    node_version=20.8.1

    resolve_node_version > /dev/null 2>&1 || true

    $failed
    echo "$FAIL_REASON" | grep -q "https://nodejs.org/dist/v20.8.1/SHASUMS256.txt"
    [ ! -e $cached_sha ]



  test "checksum lookup is retried before failing"

    SHASUMS_STATUS=error
    node_version=20.8.1

    resolve_node_version > /dev/null 2>&1 || true

    [ 3 -eq $(curl_calls_to "https://nodejs.org/dist/v20.8.1/SHASUMS256.txt") ]
    $failed



  test "checksums for another version fail rather than install unverified"

    SHASUMS_STATUS=stale
    node_version=20.8.1

    resolve_node_version > /dev/null 2>&1 || true

    [ -z "$node_sha" ]
    [ ! -e $cached_sha ]
    $failed



  test "empty checksum response fails rather than install unverified"

    SHASUMS_STATUS=empty
    node_version=20.8.1

    resolve_node_version > /dev/null 2>&1 || true

    [ -z "$node_sha" ]
    $failed



  # fetch_url's stdout is the response body its caller captures, so a retry notice
  # logged there would vanish from the build log and splice itself into the content
  test "retry notices reach the build log without corrupting the response"

    LISTING_STATUS=flaky
    node_version=20.8.1

    resolve_node_version > $TEST_DIR/build_log 2>&1

    grep -q "Failed to fetch https://nodejs.org/dist/v20.8.1/ (attempt 1 of 3)" $TEST_DIR/build_log
    [ "https://nodejs.org/dist/latest/node-v20.8.1-linux-x64.tar.gz" == "$node_url" ]
    [ 2 -eq $(curl_calls_to "https://nodejs.org/dist/v20.8.1/") ]
    ! $failed



PASSED_ALL_TESTS=true
