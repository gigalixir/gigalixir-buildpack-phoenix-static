info() {
  #echo "`date +\"%M:%S\"`  $*"
  echo "       $*"
}

indent() {
  while read LINE; do
    echo "       $LINE" || true
  done
}

header() {
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
  info "Loading config..."

  local custom_config_file="${build_dir}/phoenix_static_buildpack.config"

  # Source for default versions file from buildpack first
  source "${build_pack_dir}/phoenix_static_buildpack.config"

  if [ -f $custom_config_file ]; then
    source $custom_config_file
  else
    info "The config file phoenix_static_buildpack.config wasn't found"
    info "Using the default config provided from the Phoenix static buildpack"
  fi

  fix_node_version
  fix_npm_version

  phoenix_dir=$build_dir/$phoenix_relative_path

  info "Detecting assets directory"
  if [ -f "$phoenix_dir/$assets_path/package.json" ]; then
    # Check phoenix custom sub-directory for package.json
    info "* package.json found in custom directory"
  elif [ -f "$phoenix_dir/package.json" ]; then
    info "* package.json found in root directory"
    assets_path=.
  else
    info "WARNING: no package.json detected in root nor custom directory"
    info "* assuming assets are in /assets"

    assets_path=assets
  fi

  if [ -n "${phoenix_ex}" ]; then
    info "Using mix namespace for phoenix tasks from config: ${phoenix_ex}"
  else
    info "Detecting mix namespace for phoenix tasks"

    phoenix_ex=phx
    if [ -f "${build_dir}/mix.lock" ]; then
      local phoenix_version=$(elixir lib/phoenix_version.exs "${build_dir}/mix.lock" 2>/dev/null)
      if [ -n "${phoenix_version}" ]; then
        if ! echo -e "${phoenix_version}\n1.3.0" | sort -V | head -n 1 | grep -q "^1.3.0$"; then
          info "Detected Phoenix version ${phoenix_version}, which is prior to 1.3.0"
          phoenix_ex=phoenix
        fi
      else
        info "WARNING: unable to detect version, assuming 1.3.0 or greater for '${phoenix_version}'"
      fi
    else
      info "WARNING: no mix.lock detected, assuming 1.3.0 or greater"
    fi
    info "* Using mix namespace '${phoenix_ex}' for phoenix tasks"
  fi

  assets_dir=$phoenix_dir/$assets_path
  info "Will use phoenix configuration:"
  info "* assets path ${assets_path}"
  info "* mix tasks namespace ${phoenix_ex}"

  info "Will use the following versions:"
  info "* Node ${node_version}"
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
