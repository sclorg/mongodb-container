#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

#----------------------------------------------------
# Verification
#----------------------------------------------------

# @public  Checks base environmental variables necessary for creating a mongo instance
#
function check_db_env_vars() {
  local database_regex='^[^/\. "$]*$'

  [[ -v MONGODB_ADMIN_PASSWORD ]] || usage "MONGODB_ADMIN_PASSWORD has to be set."

  if [[ -v MONGODB_USER || -v MONGODB_PASSWORD || -v MONGODB_DATABASE ]]; then
    [[ -v MONGODB_USER && -v MONGODB_PASSWORD && -v MONGODB_DATABASE ]] || usage "You have to set all or none of variables: MONGODB_USER, MONGODB_PASSWORD, MONGODB_DATABASE"

    [[ "${MONGODB_DATABASE:-}" =~ $database_regex ]] || usage "Database name must match regex: $database_regex"
    [ ${#MONGODB_DATABASE} -le 63 ] || usage "Database name too long (maximum 63 characters)"

    export CREATE_USER=1
  fi
}
readonly -f check_db_env_vars

# @public  Checks permissions of database volume.
#
# @value  MONGODB_DATADIR
#
function check_data_dir() {
  if [ ! -w "${MONGODB_DATADIR:-}" ]; then
    log_fail "Couldn't write into ${MONGODB_DATADIR:-}. User $(id -u) and Group $(id -G) don't have permissions, $(stat -c '%A owned by %u:%g, SELinux = %C' ${MONGODB_DATADIR:-})"
    exit 1
  fi
}
readonly -f check_data_dir

#----------------------------------------------------
# Setup/Configuration
#----------------------------------------------------

# @public Checks available RAM and if sets cache size if there are restrictions.
#
# @value  MONGODB_CONFIG_PATH
# @value  PYTHON
# @param  $1 PATH to MongoDB configuration file.
# @param  NO_MEMORY_LIMIT whether there are RAM restrictions or not
# @param  MEMORY_LIMIT_IN_BYTES cache size of memory limit
#
function setup_wiredtiger_cache() {
  local config_file=${1:-$MONGODB_CONFIG_PATH}
  local cache_size

  declare $(cgroup-limits)

  if [[ ! -v MEMORY_LIMIT_IN_BYTES || "${NO_MEMORY_LIMIT:-}" == "true" ]]; then
    return 0;
  fi

  cache_size=$($PYTHON -c "min=1; limit=int((${MEMORY_LIMIT_IN_BYTES:-} / pow(2,30) - 1) * 0.6); print( min if limit < min else limit)")

  echo "storage.wiredTiger.engineConfig.cacheSizeGB: ${cache_size}" >> ${config_file}

  log_info "WiredTiger CacheSizeGB set to ${cache_size}"
}
readonly -f setup_wiredtiger_cache

# @public Creates key file and sets keyfile permissions.
#
# @value MONGODB_KEYFILE_PATH
# @value MONGODB_CONFIG_PATH
#
function setup_keyfile() {
  local keyfile_dir
  keyfile_dir="$(dirname "$MONGODB_KEYFILE_PATH")"

  if grep -q "^\s*keyFile" $MONGODB_CONFIG_PATH; then
    log_pass "User specific keyFile in config file do not use generated keyFile"
    exit 0
  fi

  if [[ -z "${MONGODB_KEYFILE_VALUE:-}" ]]; then
    log_fail "You have to provide the 'keyfile' value in MONGODB_KEYFILE_VALUE"
    exit 1
  fi

  if [[ ! -w "${keyfile_dir}" ]]; then
    log_fail "Couldn't create $MONGODB_KEYFILE_PATH. User $(id -u) and Group $(id -G) don't have permissions, $(stat -c '%A owned by %u:%g' ${keyfile_dir})"
    exit 1
  fi

  log_info "Creating keyfile"
  echo -e "${MONGODB_KEYFILE_VALUE:-}" > $MONGODB_KEYFILE_PATH

  log_info "Changing keyfile permissions"
  chmod 400 $MONGODB_KEYFILE_PATH
}
readonly -f setup_keyfile

#----------------------------------------------------
# Role-Based Access Control (RBAC)
#----------------------------------------------------

# @public Creates the MongoDB admin user with password.
#
# @value  MONGODB_ADMIN_USER
# @value  MONGODB_ADMIN_PASSWORD
# @value  MONGODB_ADMIN_ROLES
# @param  $1 optional mongo parameters
# @param  $2 host where to connect (default localhost)
#
# 05/2017 Marked function as readonly.
# 05/2017 'root' provides access to the operations and all the resources of the
#         readWriteAnyDatabase, dbAdminAnyDatabase, userAdminAnyDatabase,
#         clusterAdmin roles, restore, and backup roles combined.
# 06/2017 Added 'MONGODB_ADMIN_USER' (default admin).
function mongo_create_admin() {
  local comm="db.getSiblingDB('admin').createUser({
    user: '${MONGODB_ADMIN_USER:-}',
    pwd: '${MONGODB_ADMIN_PASSWORD:-}',
    roles: [ { role: 'root', db: 'admin' } ]
  });"

  if [[ -z "${MONGODB_ADMIN_USER:-}" ]]; then
    log_fail "MONGODB_ADMIN_USER is not set. Couldn't setup authentication"
    exit 1
  fi

  if [[ -z "${MONGODB_ADMIN_PASSWORD:-}" ]]; then
    log_fail "MONGODB_ADMIN_PASSWORD is not set. Couldn't setup authentication"
    exit 1
  fi

  log_info "Creating admin user"
  if ! $MONGO admin ${1:-} --host ${2:-"localhost"} --eval "${comm}"; then
    log_fail "Couldn't create admin user"
    exit 1
  fi
}
readonly -f mongo_create_admin

# @public Resets the MongoDB admin password.
#
# @value  MONGODB_ADMIN_USER
# @value  MONGODB_ADMIN_PASSWORD
# @param  $1 optional mongo parameters
# @param  $2 host where to connect (default localhost)
#
function mongo_reset_admin() {
  local comm="db.changeUserPassword('${MONGODB_ADMIN_USER:-}', '${MONGODB_ADMIN_PASSWORD:-}')"

  if [[ -n "${MONGODB_ADMIN_PASSWORD:-}" ]] && \
     [[ -n "${MONGODB_ADMIN_USER:-}" ]]; then
    log_info "Admin user already exists. Resetting password"
    if ! $MONGO admin --eval "${comm}"; then
      log_fail "Couldn't reset admin user password"
      exit 1
    fi
  fi
}
readonly -f mongo_reset_admin

# @public Creates the MongoDB database user with password.
#
# @value  MONGODB_USER
# @value  MONGDOB_PASSWORD
# @value  MONGODB_DATABASE
# @param  $1 optional mongo parameters
# @param  $2 host where to connect (default localhost)
#
function mongo_create_user() {
  local comm="db.getSiblingDB('${MONGODB_DATABASE:-}').createUser({
    user: '${MONGODB_USER:-}',
    pwd: '${MONGODB_PASSWORD:-}',
    roles: [ { role: 'readWrite', db: '${MONGODB_DATABASE:-}' } ]
  });"

  if [[ -z "${MONGODB_USER:-}" ]]; then
    log_fail "MONGODB_USER is not set. Couldn't create user"
    exit 1
  fi

  if [[ -z "${MONGODB_PASSWORD:-}" ]]; then
    log_fail "MONGODB_PASSWORD is not set. Couldn't create ${MONGODB_USER:-} user"
    exit 1
  fi

  if [[ -z "${MONGODB_DATABASE:-}" ]]; then
    log_fail "MONGODB_DATABASE is not set. Couldn't create ${MONGODB_USER:-} user"
    exit 1
  fi

  log_info "Creating database user"
  if ! $MONGO admin ${1:-} --host ${2:-"localhost"} --eval "${comm}"; then
    log_fail "Couldn't create ${MONGODB_USER:-} user"
    exit 1
  fi
}
readonly -f mongo_create_user

# @public Resets the MongoDB database user password.
#
# @value  MONGODB_USER
# @value  MONGDOB_PASSWORD
# @value  MONGODB_DATABASE
# @param  $1 optional mongo parameters
# @param  $2 host where to connect (default localhost)
#
function mongo_reset_user() {
  local comm="db.changeUserPassword('${MONGODB_USER:-}', '${MONGODB_PASSWORD:-}')"

  if [[ -n "${MONGODB_USER:-}" && -n "${MONGODB_PASSWORD:-}" && -n "${MONGODB_DATABASE:-}" ]]; then
    log_info "Database user already exists. Resetting password"
    if ! $MONGO ${MONGODB_DATABASE:-} --eval "${comm}"; then
      log_fail "Couldn't reset ${MONGODB_USER:-} user password"
      exit 1
    fi
  fi
}
readonly -f mongo_reset_user

#----------------------------------------------------
# Synchronization
#----------------------------------------------------

# @public returns 0 if a a given mongo host is up, 1 otherwise
# $1 is host, or localhost if not specified
function mongo_is_up() {
  local host=${1:-localhost}
  local comm="db.version();"
  $MONGO "${host}" --eval "${comm}" --quiet &> /dev/null
  return $?
}
readonly -f mongo_is_up


# @public Waits until the mongo daemon connection is up.
#
# @param  $@ host where to connect
#
function wait_for_mongo_up() {
  _wait_for_mongo 1 "$@"
}
readonly -f wait_for_mongo_up

# @public Waits until the mongo daemon connection is down.
#
# @param  $@ host where to connect
#
function wait_for_mongo_down() {
  _wait_for_mongo 0 "$@"
}
readonly -f wait_for_mongo_down

# @private Helper method that waits until the mongo daemon is up/down.
#
# @param  $1 desired connection state (default down)
# @param  $2 host where to connect (default localhost)
#
function _wait_for_mongo() {
  local hold=${1:-1}
  local host=${2:-localhost}
  local comm="db.version();"
  local stat

  [[ ${hold} -eq 0 ]] && stat="down" || stat="up"

  for i in $(seq $MAX_ATTEMPTS); do
    log_info "Waiting for ${host} connection"

    if ([[ ${hold} -eq 1 ]] && mongo_is_up "${host}") || \
       ([[ ${hold} -eq 0 ]] && ! mongo_is_up "${host}"); then
      log_pass "Connection is ${stat}"
      return 0
    fi

    sleep $(( i++ ))
  done

  log_fail "Connection is NOT ${stat}"
  return 1
}
readonly -f _wait_for_mongo

# @public Cleanly and safely terminates the MongoDB daemon.
#
function cleanup() {
  # [NOTE] Does not attempt to remove the host from the replica set configuration
	# when it is terminating. That is by design, because, in a StatefulSet, when a
	# pod/container terminates and is restarted by OpenShift, it will always have
	# the same hostname. Removing hosts from the configuration affects replica set
	# elections and can impact the replica set stability.
  # if [[ -n "${MONGODB_REPLICA_NAME:-}" ]]; then
  #   rs_remove
  # fi

  log_info "Shutting down $(hostfqdn)"
  pkill -INT $MONGOD && pkill -INT $MONGOS || :
  wait_for_mongo_down "localhost"
  exit 0
}
readonly -f cleanup

# @public Make sure sensitive environment variables don't propagate.
#
# @value  MONGODB_ADMIN_PASSWORD
# @value  MONGODB_USER
# @value  MONGODB_PASSWORD
# @value  MONGODB_DATABASE
# @value  MONGODB_KEYFILE_VALUE
# @value  MONGODB_REPLICA_NAME
#
function unset_env_vars() {
	unset MONGODB_USER MONGODB_PASSWORD MONGODB_DATABASE MONGODB_ADMIN_PASSWORD MONGODB_ADMIN_USER
}

#----------------------------------------------------
# Networking
#----------------------------------------------------

# @public Returns standard format of the MongoDB connection URI used to connect
#         to a MongoDB database server. It identifies either a hostname, IP
#         address, or UNIX domain socket.
#
# @param  -h <hostname>
# @param  -u <username>
# @param  -p <password>
# @param  -d <database>
#
function endpoint() {
  endpoint_usage() { log_info "usage: ${FUNCNAME[0]} -h <hostname> -u <username> -p <password> -d <database>]" 1>&2; exit 1; }

  local OPTIND opt host user pass creds data uri

  while getopts ":h:u:p:d:" opt; do
    case ${opt} in
      h  ) host=$OPTARG ;;
      u  ) user=$OPTARG ;;
      p  ) pass=$OPTARG ;;
      d  ) data=$OPTARG ;;
      \? ) endpoint_usage ;;
    esac
  done

  shift $((${OPTIND} - 1))

  if [[ -n "${user:-}" ]] && [[ -n "${pass:-}" ]]; then
    creds="${user}:${pass}@"
  elif [[ -n "${user:-}" ]] && [[ -z "${pass:-}" ]]; then
    log_fail "Username provided, but password is not set."
    endpoint_usage
  elif [[ -z "${user:-}" ]] && [[ -n "${pass:-}" ]]; then
    log_fail "Password provided, but username is not set."
    endpoint_usage
  fi

  if [[ -n "${MONGODB_REPLICA_NAME:-}" ]]; then
    if [[ -z "${host:-}" ]]; then
      host=${MONGODB_SERVICE_NAME:-mongodb}
    fi

    uri="$(replset_addr ${host:-})/${data:-}?replicaSet=${MONGODB_REPLICA_NAME:-}"
  else
    if [[ -z "${host:-}" ]]; then
      host=$(hostfqdn)
    fi

    [[ -n "${data:-}" ]] && uri="$(mongo_addr ${host:-})/${data:-}" || uri="$(mongo_addr ${host:-})"
  fi

  echo "mongodb://${creds:-}${uri:-}"
}
readonly -f endpoint

# @public Returns fully qualified domain name (FQDN) of the MongoDB daemon.
#
function hostfqdn() {
  [[ -z "$(type -P hostname &>/dev/null)" ]] \
  && [[ -n "$(hostname -f)" ]] \
  && echo "$(hostname -f)" || echo "localhost"
}
readonly -f hostfqdn

# @public Identifies a server IP address to connect to.
#
# @param  $1 host where to connect
# @return IP address
#
function mongo_addr() {
  local host=${1:-}
  local addr

  if type -P dig &>/dev/null; then
    addr=$(dig ${host} A +search +short 2>/dev/null | sed 's/\.$//g')
  else
    log_fail "Couldn't perform DNS lookup for replica set. DNS lookup utility doesn't exist"
    return 1
  fi

  if [[ -z "${addr:-}" ]]; then
    log_fail "Couldn't perform DNS lookup for replica set. No nodes listed in ${host}"
    return 1
  fi

  if (( $(grep -c . <<< "${addr}") > 1 )); then
    local i=0

    while read -r line; do
      if [[ "${i}" -eq "0" ]]; then
        addr="${line}"
      else
        addr="${line} ${addr}"
      fi

      let "i++"
    done <<< "${addr}"
  fi

  echo "${addr//[[:space:]]/,}"
}
readonly -f mongo_addr

# @public Identifies either a hostnames or IP address or for connections to
#         replica sets.
#
# @param  $1 host where to connect
# @return a hostname or IP address
#
function replset_addr() {
  local host=${1:-}
  local rsid="${HOSTNAME##*-}"
  local ssid="${HOSTNAME%%-*}"
  local addr

  if type -P hostname &>/dev/null; then
    addr=$(dig ${host} A +search +short 2>/dev/null | sed 's/\.$//g')
  else
    log_fail "Couldn't perform DNS lookup for replica set. DNS lookup utility doesn't exist"
    return 1
  fi

  if [[ -z "$(type -P hostname &>/dev/null)" ]] \
     && [[ -n "$(hostname -d)" ]] \
     && [[ "${rsid}" != "${ssid}" ]] \
     && [[ "${rsid}" =~ ^[0-9]+$ ]]; then
    for (( i = ${rsid}; i >= 0; i-- )); do
      fqdn="${ssid}-${i}.$(hostname -d)"

      if [[ "${i}" -eq "${rsid}" ]]; then
        addr="${fqdn}"
      else
        addr="${fqdn} ${addr}"
      fi
    done
  else
    addr=$(mongo_addr "${host}")
  fi

  echo "${addr//[[:space:]]/,}"
}
readonly -f replset_addr

#----------------------------------------------------
# Usage
#----------------------------------------------------

# @public  Prints usage information about required enviroment variables.
#
# @param  $1 system log failure message
#
function usage() {
  if [ $# == 1 ]; then
    log_fail "$1"
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
  MONGODB_ADMIN_USER (default: admin)
  MONGODB_QUIET (default: true)"

  if [[ -v REPLICATION ]]; then
    echo "
    For replication you must also specify the following environment variables:
    MONGODB_KEYFILE_VALUE
    MONGODB_REPLICA_NAME
    Optional settings:
    MONGODB_SERVICE_NAME (default: mongodb)"
  fi
  echo "
  For more information see /usr/share/container-scripts/mongodb/README.md
  within the container or visit https://github.com/sclorgk/mongodb-container/."

  exit 1
}
readonly -f usage

#----------------------------------------------------
# Usage
#----------------------------------------------------

# @public Continuously prints mongodb log messages to stdout. Runs as a background process.
#
function tail_mongodb_log() {
  tail -f "${MONGODB_LOG_PATH}/mongod.log" &
}
readonly -f tail_mongodb_log

#----------------------------------------------------
# Logger
#----------------------------------------------------

# @public System log information message.
#
# @param  $1 message details
function log_info() {
  printf "\xE2\x9E\xA1 [%s INFO] %s\n" "$(date +'%a %b %d %T')" "${1:-}"
}
readonly -f log_info

# @public System log failure message.
#
# @param  $1 message details
#
function log_fail() {
  printf "\xe2\x9c\x98 [%s FAIL] %s\n" "$(date +'%a %b %d %T')" "${1:-}"
}
readonly -f log_fail

# @public System log success message.
#
# @param  $1 message details
#
function log_pass() {
  printf "\xE2\x9C\x94 [%s PASS] %s\n" "$(date +'%a %b %d %T')" "${1:-}"
}
readonly -f log_pass
