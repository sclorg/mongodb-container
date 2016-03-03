# This file contains functions for checking mongod state and manipulating config file

# Default constants
export MAX_ATTEMPTS=90
export SLEEP_TIME=2

# Wait_mongo waits until the mongo server is up/down
# $1 - "UP" or "DOWN" - to specify for what to wait
# $2 - host where to connect (localhost by default)
function wait_mongo() {
  local operation
  operation=-eq
  if [[ "${1:-}" == "DOWN" || "${1:-}" == "down" ]]; then
    operation=-ne
  fi

  local mongo_cmd
  mongo_cmd="mongo admin --host ${2:-localhost} --port $port "

  local i
  for i in $(seq $MAX_ATTEMPTS); do
    echo "=> ${2:-} Waiting for MongoDB daemon ${1:-}"
    set +e
    ${mongo_cmd} --eval "quit()" &>/dev/null
    local status=$?
    set -e
    if [ ${status} ${operation} 0 ]; then
      echo "=> MongoDB daemon is ${1:-}"
      return 0
    fi
    sleep ${SLEEP_TIME}
  done
  echo "=> Giving up: MongoDB daemon is not ${1:-}!"
  return 1
}

# Get value for option in file
# $1 - option name
# $2 - path to config file
function get_option() {
  if [[ -z "${1:-}" || -z "${2:-}" ]]; then
    echo "FAIL. get_option - empty parameter"
    return 1
  elif [[ ! -r "${1:-}" ]]; then
    echo "FAIL. get_option - config file not readable"
    return 1
  fi

  grep "^\s*${1}" ${2} | sed -r -e "s|^\s*${1}\s*=\s*||"
}

# Get port number from config file
# $1 - path to config file
function get_port() {
  if [[ -z "${1:-}"; then
    echo "FAIL. get_port - empty config file path"
    return 1
  elif [[ ! -r "${1:-}" ]]; then
    echo "FAIL. get_port - config file not readable"
    return 1
  fi

  if grep '^\s*port' $1 &>/dev/null; then
    grep '^\s*port' $1 | sed -r -e 's|^\s*port\s*=\s*(\d*)|\1|'
  elif grep '^\s*configsvr' $1 &>/dev/null; then
    echo 27019
  elif grep '^\s*shardsvr' $1 &>/dev/null; then
    echo 27018
  else
    echo ""
  fi
}

# Change value for config option in configuration file
# $1 - option name
# $2 - new value
# $3 - path to config file
function update_option() {
  if [[ -z "${1:-}" || -z "${2:-}" || -z "${3:-}" ]]; then
    echo "FAIL. update_option - empty parameter"
    return 1
  elif [[ ! -r "${3:-}" ]]; then
    echo "FAIL. update_option - config file not readable"
    return 1
  fi

  # Update option in the config file
  sed -r -e "s|^(\s*$1\s*=\s*).*|\1$2|" $3 > ${HOME}/.tmp.conf
  cat ${HOME}/.tmp.conf > $3
  rm ${HOME}/.tmp.conf
}
