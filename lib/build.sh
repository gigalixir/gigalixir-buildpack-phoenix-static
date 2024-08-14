cleanup_cache() {
  if [ $clean_cache = true ]; then
    info "clean_cache option set to true."
    info "Cleaning out cache contents"
    rm -rf $cache_dir/npm-version
    rm -rf $cache_dir/node-version
    rm -rf $cache_dir/phoenix-static
    rm -rf $cache_dir/yarn-cache
    rm -rf $cache_dir/node_modules
    cleanup_old_node
  fi
}

load_previous_npm_node_versions() {
  if [ -f $cache_dir/npm-version ]; then
    old_npm=$(<$cache_dir/npm-version)
  fi
  if [ -f $cache_dir/npm-version ]; then
    old_node=$(<$cache_dir/node-version)
  fi
}

# on success, node_version will be in X.Y.Z format, node_url and node_sha will be set
# on failure, this will exit non-zero
resolve_node_version() {
  echo "Resolving node version $node_version..."
  
  local base_url="https://nodejs.org/dist"
  local lookup_url=""

  case $node_version in
    ""|latest)
      lookup_url="${base_url}/latest/"
      ;;
    v*)
      lookup_url="${base_url}/${node_version}/"
      ;;
    *)
      lookup_url="${base_url}/v${node_version}/"
      ;;
  esac

  local node_file=""
  if node_file=$(curl --silent --get --retry 5 --retry-max-time 15 $lookup_url | grep -oE  '"node-v[0-9]+.[0-9]+.[0-9]+-linux-x64.tar.gz"')
  then
    node_version=$(echo "$node_file" | sed -E 's/.*node-v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    node_url="${base_url}/v${node_version}/${node_file//\"/}"
  else
    fail_bin_install node $node_version "Unable to resolve version"
  fi

  # set the cache locations
  cached_node=$cache_dir/node-v$node_version-linux-x64.tar.gz
  cached_sha=$cache_dir/SHA256SUM-node-v$node_version

  # get the corresponding checksum
  local sha_url=${lookup_url}SHASUMS256.txt
  node_sha=$(curl --silent --get --retry 5 --retry-max-time 15 $sha_url | grep -E "node-v${node_version}-linux-x64.tar.gz" | awk '{print $1}')
  if [ ! -z "$node_sha" ]; then
    echo "$node_sha ${cached_node}" > $cached_sha
  fi
}

# fails if node tar is missing, sha file is missing, or sha doesn't match
validate_cached_node() {
  if [ -e $cached_sha ]; then
    if sha256sum -c $cached_sha; then
      download_complete=true
    fi
  fi
}

download_node() {
  local download_complete=false
  local code=""

  validate_cached_node
  if $download_complete; then
    info "Using cached node ${node_version}..."
  else

    # three attempts to download the file successfully
    for ii in {2..0}; do
      if ! $download_complete; then
        echo "Downloading node $node_version..."
        if code=$(curl "$node_url" -L --silent --fail --retry 5 --retry-max-time 15 -o ${cached_node} --write-out "%{http_code}"); then

          if [ "$code" == "200" ]; then

            # validate download if we have a SHA256 checksum for the version
            if [ -e "$cached_sha" ]; then
              echo "Validating node $node_version (${node_sha})..."

              validate_cached_node
              if $download_complete; then
                echo "Download complete"
                download_complete=true
                break
              else
                echo "Mismatched checksum for node $node_version"
              fi
            else
              echo "Download complete"
              download_complete=true
              break
            fi
          fi

        else
          code=-1
        fi

        # notify user of retry
        echo "Failed node download: $code"
        rm -f ${cached_node}
        if [ "$ii" -eq "0" ]; then
          echo "Exhausted download attempts"
        else
          echo "Retrying download of node"
        fi
      fi
    done
  fi
  $download_complete
}

cleanup_old_node() {
  local old_node_dir=$cache_dir/node-$old_node-linux-x64.tar.gz

  # Note that $old_node will have a format of "v5.5.0" while $node_version
  # has the format "5.6.0"

  if [ $clean_cache = true ] || [ $old_node != v$node_version ] && [ -f $old_node_dir ]; then
    info "Cleaning up old Node $old_node"
    rm $old_node_dir

    local bower_components_dir=$cache_dir/bower_components

    if [ -d $bower_components_dir ]; then
      rm -rf $bower_components_dir
    fi
  fi
}

install_node() {
  local node_dir=$heroku_dir/node
  local tmp_node_dir="/tmp/node-v$node_version-linux-x64"

  for ii in {2..0}; do
    echo "Installing Node $node_version..."
    rm -rf $tmp_node_dir
    if tar xzf ${cached_node} -C /tmp; then
      break
    else
      if [ "$ii" -eq "0" ]; then
        echo "Failed to install node"
        false
      else
        echo "Failed installation... retrying"
      fi
    fi
  done

  if [ -d $node_dir ]; then
    echo " !     Error while installing Node $node_version."
    echo "       Please remove any prior buildpack that installs Node."
    exit 1
  else
    mkdir -p $node_dir
    # Move node (and npm) into .heroku/node and make them executable
    mv ${tmp_node_dir}/* $node_dir
    chmod +x $node_dir/bin/*
    PATH=$node_dir/bin:$PATH
  fi
}

install_npm() {
  # Optionally bootstrap a different npm version
  if [ ! $npm_version ] || [[ `npm --version` == "$npm_version" ]]; then
    info "Using default npm version `npm --version`"
  else
    info "Downloading and installing npm $npm_version (replacing version `npm --version`)..."
    cd $build_dir
    npm install --unsafe-perm --quiet -g npm@$npm_version 2>&1 >/dev/null | indent
  fi
}

install_yarn() {
  local dir="$1"

  if [ ! $yarn_version ]; then
    echo "Downloading and installing yarn lastest..."
    local download_url="https://yarnpkg.com/latest.tar.gz"
  else
    echo "Downloading and installing yarn $yarn_version..."
    local download_url="https://yarnpkg.com/downloads/$yarn_version/yarn-v$yarn_version.tar.gz"
  fi

  local code=$(curl "$download_url" -L --silent --fail --retry 5 --retry-max-time 15 -o /tmp/yarn.tar.gz --write-out "%{http_code}")
  if [ "$code" != "200" ]; then
    echo "Unable to download yarn: $code" && false
  fi
  rm -rf $dir
  mkdir -p "$dir"
  # https://github.com/yarnpkg/yarn/issues/770
  if tar --version | grep -q 'gnu'; then
    tar xzf /tmp/yarn.tar.gz -C "$dir" --strip 1 --warning=no-unknown-keyword
  else
    tar xzf /tmp/yarn.tar.gz -C "$dir" --strip 1
  fi
  chmod +x $dir/bin/*
  PATH=$dir/bin:$PATH
  echo "Installed yarn $(yarn --version)"
}

install_pnpm() {
  local dir="$1"

  if [ ! $pnpm_version ]; then
    echo "Error: Please specify the pnpm_version variable."
    return 1
  fi

  echo "Downloading and installing pnpm $pnpm_version..."
  local download_url="https://github.com/pnpm/pnpm/releases/download/v$pnpm_version/pnpm-linux-x64"

  local code=$(curl -w "%{http_code}" -L "$download_url" --silent --fail --retry 5 --retry-max-time 15 -o /tmp/pnpm --write-out "%{http_code}")
  if [ "$code" != "200" ]; then
    echo "Unable to download pnpm: $code" && return 1
  fi
  mkdir -p "$dir"
  mv /tmp/pnpm "$dir/pnpm"
  chmod +x "$dir/pnpm"
  PATH=$dir:$PATH
  echo "Installed pnpm $(pnpm --version)"
}

install_and_cache_deps() {
  if [ -d "$assets_dir" ]; then
    cd $assets_dir

    if [ -d $cache_dir/node_modules ]; then
      info "Loading node modules from cache"
      mkdir node_modules
      if [ -z $(find $cache_dir/node_modules -maxdepth 0 -empty) ]; then
        rsync -a $cache_dir/node_modules/ node_modules/
      fi
    fi

    info "Installing node modules"
    if [ -f "$assets_dir/yarn.lock" ]; then
      mkdir -p $assets_dir/node_modules
      install_yarn_deps
    elif [ -f "$assets_dir/pnpm-lock.yaml" ]; then
      install_pnpm_deps
    elif [ -f "$assets_dir/package.json" ]; then
      install_npm_deps
    fi

    if [ -d node_modules ]; then
      info "Caching node modules"
      cp -R node_modules $cache_dir
    fi

    PATH=$assets_dir/node_modules/.bin:$PATH

    install_bower_deps
  fi
}

install_npm_deps() {
  npm prune | indent
  npm install --quiet --unsafe-perm --userconfig $build_dir/npmrc 2>&1 | indent
  npm rebuild 2>&1 | indent
  npm --unsafe-perm prune 2>&1 | indent
}

install_yarn_deps() {
  yarn install --check-files --cache-folder $cache_dir/yarn-cache --pure-lockfile 2>&1
}

install_pnpm_deps() {
  pnpm install --frozen-lockfile --store-dir $cache_dir/pnpm-store 2>&1
}

install_bower_deps() {
  cd $assets_dir
  local bower_json=bower.json

  if [ -f $bower_json ]; then
    info "Installing and caching bower components"

    if [ -d $cache_dir/bower_components ]; then
      mkdir -p bower_components
      cp -r $cache_dir/bower_components/* bower_components/
    fi
    bower install
    cp -r bower_components $cache_dir
  fi
}

compile() {
  cd $phoenix_dir
  PATH=$build_dir/.platform_tools/erlang/bin:$PATH
  PATH=$build_dir/.platform_tools/elixir/bin:$PATH

  run_compile
}

run_compile() {
  local custom_compile="${build_dir}/${compile}"

  cd $phoenix_dir

  has_clean=$(mix help "${phoenix_ex}.digest.clean" 1>/dev/null 2>&1; echo $?)

  if [ $has_clean = 0 ]; then
    mkdir -p $cache_dir/phoenix-static
    info "Restoring cached assets"
    mkdir -p priv
    rsync -a -v --ignore-existing $cache_dir/phoenix-static/ priv/static
  fi

  cd $assets_dir

  if [ -f $custom_compile ]; then
    info "Running custom compile"
    source $custom_compile 2>&1 | indent
  else
    info "Running default compile"
    source ${build_pack_dir}/${compile} 2>&1 | indent
  fi

  cd $phoenix_dir

  if [ $has_clean = 0 ]; then
    info "Caching assets"
    rsync -a --delete -v priv/static/ $cache_dir/phoenix-static
  fi
}

cache_versions() {
  info "Caching versions for future builds"
  echo `node --version` > $cache_dir/node-version
  echo `npm --version` > $cache_dir/npm-version
}

finalize_node() {
  if [ $remove_node = true ]; then
    remove_node
  else
    write_profile
  fi
}

write_profile() {
  info "Creating runtime environment"
  mkdir -p $build_dir/.profile.d
  local export_line="export PATH=\"\$HOME/.heroku/node/bin:\$HOME/.heroku/yarn/bin:\$HOME/bin:\$HOME/$phoenix_relative_path/node_modules/.bin:\$PATH\""
  echo $export_line >> $build_dir/.profile.d/phoenix_static_buildpack_paths.sh
}

remove_node() {
  info "Removing node and node_modules"
  rm -rf $assets_dir/node_modules
  rm -rf $heroku_dir/node
}

fail_bin_install() {
  local bin="$1"
  local version="$2"
  local reason="$3"

  echo "Error installing ${bin} ${version}: ${reason}"
  exit 1
}

setup_phx_envvars() {
  info "Setting up Phoenix environment variables"
  mkdir -p $build_dir/.profile.d

  local phoenix_env_file=$build_dir/.profile.d/phoenix_static_buildpack_env.sh

  echo "export PHX_SERVER=\${PHX_SERVER:-true}" >> $phoenix_env_file
  echo "export PHX_HOST=\${PHX_HOST:=\${APP_NAME}.gigalixirapp.com}" >> $phoenix_env_file
}
