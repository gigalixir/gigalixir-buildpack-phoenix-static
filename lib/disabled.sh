#!/usr/bin/env bash

# Name of the environment variable that disables this buildpack.
PHOENIX_STATIC_BUILDPACK_DISABLED_VAR="PHOENIX_STATIC_BUILDPACK__DISABLED"

# Returns success (0) when the given value means the buildpack is disabled.
buildpack_disabled_value() {
  [ "$1" = "1" ] || [ "$1" = "true" ]
}

# Returns success (0) when the disable env var is present in the given env_dir
# and its value disables the buildpack. Heroku-style env_dir: a file named
# after the variable whose contents are the value.
buildpack_disabled_in_env_dir() {
  local env_dir="$1"
  local var_file="${env_dir}/${PHOENIX_STATIC_BUILDPACK_DISABLED_VAR}"

  [ -f "$var_file" ] && buildpack_disabled_value "$(cat "$var_file")"
}
