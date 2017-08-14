#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Data directory where MongoDB database files live. The data subdirectory is here
# because mongod.conf lives in /var/lib/mongodb/ and we don't want a volume to
# override it.
export MONGODB_DATADIR=/var/lib/mongodb/data
export CONTAINER_PORT=27017
# Configuration settings.
export MONGODB_QUIET=${MONGODB_QUIET:-true}

MONGODB_CONFIG_PATH=/etc/mongod.conf
MONGODB_KEYFILE_PATH="${HOME}/keyfile"

# Constants used for waiting
readonly MAX_ATTEMPTS=60
readonly SLEEP_TIME=1

# wait_for_mongo_up waits until the mongo server accepts incomming connections
function wait_for_mongo_up() {
  _wait_for_mongo 1 "$@"
}

# wait_for_mongo_down waits until the mongo server is down
function wait_for_mongo_down() {
  _wait_for_mongo 0 "$@"
}

# wait_for_mongo waits until the mongo server is up/down
# $1 - 0 or 1 - to specify for what to wait (0 - down, 1 - up)
# $2 - host where to connect (localhost by default)
function _wait_for_mongo() {
  local operation=${1:-1}
  local message="up"
  if [[ ${operation} -eq 0 ]]; then
    message="down"
  fi

  local mongo_cmd="mongo admin --host ${2:-localhost} "

  local i
  for i in $(seq $MAX_ATTEMPTS); do
    echo "=> ${2:-} Waiting for MongoDB daemon ${message}"
    if ([[ ${operation} -eq 1 ]] && ${mongo_cmd} --eval "quit()" &>/dev/null) || ([[ ${operation} -eq 0 ]] && ! ${mongo_cmd} --eval "quit()" &>/dev/null); then
      echo "=> MongoDB daemon is ${message}"
      return 0
    fi
    sleep ${SLEEP_TIME}
  done
  echo "=> Giving up: MongoDB daemon is not ${message}!"
  return 1
}

# endpoints returns list of IP addresses with other instances of MongoDB
# To get list of endpoints, you need to have headless Service named 'mongodb'.
# NOTE: This won't work with standalone Docker container.
function endpoints() {
  service_name=${MONGODB_SERVICE_NAME:-mongodb}
  dig ${service_name} A +search +short 2>/dev/null
}

# replset_addr return the address of the current replSet
function replset_addr() {
  local current_endpoints
  current_endpoints="$(endpoints)"
  if [ -z "${current_endpoints}" ]; then
    info "Cannot get address of replica set: no nodes are listed in service!"
    info "CAUSE: DNS lookup for '${MONGODB_SERVICE_NAME:-mongodb}' returned no results."
    return 1
  fi
  echo "${MONGODB_REPLICA_NAME}/${current_endpoints//[[:space:]]/,}"
}

# usage prints info about required enviromental variables
# if $1 is passed, prints error message containing $1
# if MEMBER_ID variable is set, prints also info about replication variables
function usage() {
  if [ $# == 1 ]; then
    echo >&2 "error: $1"
  fi

  echo "
You must specify the following environment variables:
  MONGODB_ADMIN_PASSWORD
Optionally you can provide settings for a user with 'readWrite' role:
(Note you MUST specify all three of these settings)
  MONGODB_USER
  MONGODB_PASSWORD
  MONGODB_DATABASE
Optional settings:
  MONGODB_QUIET (default: true)"

  if [[ -v MEMBER_ID ]]; then
    echo "
For replication you must also specify the following environment variables:
  MONGODB_KEYFILE_VALUE
  MONGODB_REPLICA_NAME
Optional settings:
  MONGODB_SERVICE_NAME (default: mongodb)
"
  fi
  echo "
For more information see /usr/share/container-scripts/mongodb/README.md
within the container or visit https://github.com/sclorg/mongodb-container/."

  exit 1
}

# get_matched_files finds file for image extending
function get_matched_files() {
  local custom_dir default_dir
  custom_dir="$1"
  default_dir="$2"
  files_matched="$3"
  find "$default_dir" -maxdepth 1 -type f -name "$files_matched" -printf "%f\n"
  [ -d "$custom_dir" ] && find "$custom_dir" -maxdepth 1 -type f -name "$files_matched" -printf "%f\n"
}

# process_extending_files process extending files in $1 and $2 directories
# - source all *.sh files
#   (if there are files with same name source only file from $1)
function process_extending_files() {
  local custom_dir default_dir
  custom_dir=$1
  default_dir=$2

  while read filename ; do
    echo "=> sourcing $filename ..."
    # Custom file is prefered
    if [ -f $custom_dir/$filename ]; then
      source $custom_dir/$filename
    else
      source $default_dir/$filename
    fi
  done <<<"$(get_matched_files "$custom_dir" "$default_dir" '*.sh' | sort -u)"
}

# info prints a message prefixed by date and time.
function info() {
  printf "=> [%s] %s\n" "$(date +'%a %b %d %T')" "$*"
}
