file_contents() {
  if test -f $1; then
    echo "$(cat $1)"
  else
    echo ""
  fi
}

load_config() {
  output_line "Loading config..."

  local custom_config_file="${build_dir}/phoenix_static_buildpack.config"

  # Source for default versions file from buildpack first
  source "${build_pack_dir}/phoenix_static_buildpack.config"

  if [ -f $custom_config_file ]; then
    source_file $custom_config_file
  else
    output_line "The config file phoenix_static_buildpack.config wasn't found"
    output_line "Using the default config provided from the Phoenix static buildpack"
  fi

  fix_node_version
  fix_npm_version

  phoenix_dir=$build_dir/$phoenix_relative_path

  output_line "Detecting assets directory"
  if [ -f "$phoenix_dir/$assets_path/package.json" ]; then
    # Check phoenix custom sub-directory for package.json
    output_line "* package.json found in custom directory"
  elif [ -f "$phoenix_dir/package.json" ]; then
    output_line "* package.json found in root directory"
    assets_path=.
  else
    output_line "WARNING: no package.json detected in root nor custom directory"
    output_line "* assuming assets are in /assets"

    assets_path=assets
  fi

  if [ -n "${phoenix_ex}" ]; then
    output_line "Using mix namespace for phoenix tasks from config: ${phoenix_ex}"
  else
    output_line "Detecting mix namespace for phoenix tasks"

    phoenix_ex=phx
    if [ -f "${build_dir}/mix.lock" ]; then
      local phoenix_version=$(elixir lib/phoenix_version.exs "${build_dir}/mix.lock" 2>/dev/null)
      if [ -n "${phoenix_version}" ]; then
        if ! echo -e "${phoenix_version}\n1.3.0" | sort -V | head -n 1 | grep -q "^1.3.0$"; then
          output_line "Detected Phoenix version ${phoenix_version}, which is prior to 1.3.0"
          phoenix_ex=phoenix
        fi
      else
        output_line "WARNING: unable to detect version, assuming 1.3.0 or greater for '${phoenix_version}'"
      fi
    else
      output_line "WARNING: no mix.lock detected, assuming 1.3.0 or greater"
    fi
    output_line "* Using mix namespace '${phoenix_ex}' for phoenix tasks"
  fi

  assets_dir=$phoenix_dir/$assets_path
  output_line "Will use phoenix configuration:"
  output_line "* assets path ${assets_path}"
  output_line "* mix tasks namespace ${phoenix_ex}"

  output_line "Will use the following versions:"
  output_line "* Node ${node_version}"
}

export_config_vars() {
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  if [ -d "$env_dir" ]; then
    output_line "Will export the following config vars:"
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

  output_line "* MIX_ENV=${MIX_ENV}"
}

fix_node_version() {
  node_version=$(echo "${node_version}" | sed 's/[^0-9.]*//g')
}

fix_npm_version() {
  npm_version=$(echo "${npm_version}" | sed 's/[^0-9.]*//g')
}

source_file() {
  local bkup_file=$(mktemp /tmp/buildpack_source_file_bkup.XXXX)

  cp $1 $bkup_file

  # sanitize the file to avoid any non-printable characters
  LC_ALL=C tr -cd '\11\12\15\40-\176' < $bkup_file > $1
  source $1
  mv $bkup_file $1
}
