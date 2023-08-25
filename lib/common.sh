info() {
  #echo "`date +\"%M:%S\"`  $*"
  echo "       $*"
}

indent() {
  while read LINE; do
    echo "       $LINE" || true
  done
}

head() {
  echo ""
  echo "-----> $*"
}

file_contents() {
  if test -f $1; then
    echo "$(cat $1)"
  else
    echo ""
  fi
}

load_config() {
  phoenix_dir=$build_dir/$phoenix_relative_path

  info "Detecting assets directory"
  if [ -f "$phoenix_dir/$assets_path/package.json" ]; then
    # Check phoenix custom sub-directory for package.json
    info "* package.json found in custom directory"
  elif [ -f "$phoenix_dir/package.json" ]; then
    # Check phoenix root directory for package.json, phoenix 1.2.x and prior
    info "WARNING: package.json detected in root "
    info "* assuming phoenix 1.2.x or prior, please check config file"

    assets_path=.
    phoenix_ex=phoenix
  else
    # Check phoenix custom sub-directory for package.json, phoenix 1.3.x and later
    info "WARNING: no package.json detected in root nor custom directory"
    info "* assuming phoenix 1.3.x and later, please check config file"

    assets_path=assets
    phoenix_ex=phx
  fi

  assets_dir=$phoenix_dir/$assets_path

  info "Loading config..."
  local custom_config_file="${build_dir}/phoenix_static_buildpack.config"
  local asdf_file="${build_dir}/.tool-versions"

  # Source for default versions file from buildpack first
  source "${build_pack_dir}/phoenix_static_buildpack.config"

  if [ -f $asdf_file ]; then
    info "asdf file found, loading"
    load_asdf_config $asdf_file
  fi

  if [ -f $custom_config_file ]; then
    source $custom_config_file
  else
    info "The config file phoenix_static_buildpack.config wasn't found"
    info "Using the default config provided from the Phoenix static buildpack or asdf file"
  fi

  fix_node_version

  # `mix help` does not like to be piped into grep
  local mix_help=$(cd $build_dir && mix help)

  # determine what the phoenix command prefix should be
  if echo $mix_help | grep -q "mix phx\."; then
    phoenix_ex="phx"
  else
    phoenix_ex="phoenix"
  fi

  info "Will use phoenix configuration:"
  info "* assets path ${assets_path}"
  info "* mix tasks namespace ${phoenix_ex}"

  info "Will use the following versions:"
  info "* Node ${node_version}"
}

load_npm_config() {
  local package_file="${assets_dir}/package.json"

  if [ -f $package_file ]; then
    echo "package.json file found, attempting to extract npm version"
    extract_npm_version $package_file
  fi

  fix_npm_version
}

export_config_vars() {
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  if [ -d "$env_dir" ]; then
    info "Will export the following config vars:"
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -vE "$blacklist_regex" &&
      export "$e=$(cat $env_dir/$e)"
      :
    done
  fi
}

export_mix_env() {
  if [ -z "${MIX_ENV}" ]; then
    if [ -d $env_dir ] && [ -f $env_dir/MIX_ENV ]; then
      export MIX_ENV=$(cat $env_dir/MIX_ENV)
    else
      export MIX_ENV=prod
    fi
  fi

  info "* MIX_ENV=${MIX_ENV}"
}

fix_node_version() {
  node_version=$(echo "${node_version}" | sed 's/[^0-9.]*//g')
}

fix_npm_version() {
  npm_version=$(echo "${npm_version}" | sed 's/[^0-9.]*//g')
}

load_asdf_config() {
  local file=$1
  local line

  while IFS= read -r line; do
    if [[ $line == nodejs* ]]; then
      node_version="${line#nodejs }"
      echo "asdf node version found: $node_version"
    fi
  done < "$file"
}

extract_npm_version() {
  local package_file=$1

  set +e
  # if this does not exist in the JSON, an exception is thrown with a failure code, which is why we allow errors in this block
  npm_version=$(node -p -e "require('$package_file').engines.npm" 2>/dev/null)
  set -e

  # check if npm_version is empty
  if [ ! -z "$npm_version" ]; then
    echo "npm version found in package.json: $npm_version"
  else
    echo "WARNING: no npm version found in package.json"
  fi
}