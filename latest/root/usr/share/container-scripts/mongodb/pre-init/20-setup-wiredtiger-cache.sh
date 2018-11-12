# New systems by default use only python3, so select python on runtime
PYTHON=python3
command -v $PYTHON &>/dev/null || PYTHON=python

# setup_wiredtiger_cache checks amount of available RAM (it has to use cgroups in container)
# and if there are any memory restrictions set storage.wiredTiger.engineConfig.configString: cache_size=
# in MONGODB_CONFIG_PATH to upstream default size
# it is intended to update mongod.conf.template, with custom config file it might create conflict
function setup_wiredtiger_cache() {
  local config_file
  config_file=${1:-$MONGODB_CONFIG_PATH}

  if [[ -v WIREDTIGER_CACHE_SIZE ]]; then
    cache_size=${WIREDTIGER_CACHE_SIZE}
  else
    declare $($PYTHON /usr/libexec/cgroup-limits)
    if [[ ! -v MEMORY_LIMIT_IN_BYTES || "${NO_MEMORY_LIMIT:-}" == "true" ]]; then
      return 0;
    fi

    cache_size=$($PYTHON -c "min=256; limit=int(($MEMORY_LIMIT_IN_BYTES / pow(2,20) - 1024) * 0.5); print( min if limit < min else limit)")M
  fi

  echo "storage.wiredTiger.engineConfig.configString: cache_size=${cache_size}" >> ${config_file}

  info "wiredTiger cache_size set to ${cache_size}"
}

setup_wiredtiger_cache ${CONTAINER_SCRIPTS_PATH}/mongod.conf.template
