#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Used for wait_for_mongo_* functions
MAX_ATTEMPTS=60
SLEEP_TIME=1

export MONGODB_CONFIG_PATH=/etc/mongod.conf
export MONGODB_PID_FILE=/var/lib/mongodb/mongodb.pid
export MONGODB_KEYFILE_PATH=/var/lib/mongodb/keyfile
export CONTAINER_PORT=27017

# container_addr returns the current container external IP address
function container_addr() {
  echo -n $(cat ${HOME}/.address)
}

# mongo_addr returns the IP:PORT of the currently running MongoDB instance
function mongo_addr() {
  echo -n "$(container_addr):${CONTAINER_PORT}"
}

# cache_container_addr waits till the container gets the external IP address and
# cache it to disk
function cache_container_addr() {
  echo -n "=> Waiting for container IP address ..."
  local i
  for i in $(seq "$MAX_ATTEMPTS"); do
    if ip -oneline -4 addr show up scope global | grep -Eo '[0-9]{,3}(\.[0-9]{,3}){3}' > "${HOME}"/.address; then
      echo " $(mongo_addr)"
      return 0
    fi
    sleep $SLEEP_TIME
  done
  echo "Failed to get Docker container IP address." && exit 1
}

# wait_for_mongo_up waits until the mongo server accepts incomming connections
function wait_for_mongo_up() {
  local mongo_host
  mongo_host="${1-}"
  local mongo_cmd
  mongo_cmd="mongo admin "

  if [ ! -z "${mongo_host}" ]; then
    mongo_cmd+="--host ${mongo_host}:${CONTAINER_PORT} "
  fi

  for i in $(seq $MAX_ATTEMPTS); do
    echo "=> Waiting for MongoDB service startup ${mongo_host} ..."
    set +e
    $mongo_cmd --eval "help" &>/dev/null
    status=$?
    set -e
    if [ $status -eq 0 ]; then
      echo "=> MongoDB service has started"
      return 0
    fi
    sleep $SLEEP_TIME
  done
  echo "=> Giving up: Failed to start MongoDB service!"
  exit 1
}

# wait_for_mongo_down waits until the mongo server is down
function wait_for_mongo_down() {
  for i in $(seq $MAX_ATTEMPTS); do
    echo "=> Waiting for MongoDB service shutdown ..."
    set +e
    mongo admin --eval "help" &>/dev/null
    status=$?
    set -e
    if [ $status -ne 0 ]; then
      echo "=> MongoDB service has stopped"
      return 0
    fi
    sleep $SLEEP_TIME
  done
  echo "=> Giving up: Failed to stop MongoDB service"
  exit 1
}

# endpoints returns list of IP addresses with other instances of MongoDB
# To get list of endpoints, you need to have headless Service named 'mongodb'.
# NOTE: This won't work with standalone Docker container.
function endpoints() {
  service_name=${MONGODB_SERVICE_NAME:-mongodb}
  dig ${service_name} A +search +short 2>/dev/null
}

# build_mongo_config builds the MongoDB replicaSet config used for the cluster
# initialization.
# Takes a list of space-separated member IPs as the first argument.
function build_mongo_config() {
  local current_endpoints
  current_endpoints="$1"
  local members
  members="{ _id: 0, host: \"$(mongo_addr)\"},"
  local member_id
  member_id=1
  local container_addr
  container_addr="$(container_addr)"
  for node in ${current_endpoints}; do
    [ "$node" == container_addr ] && continue
    members+="{ _id: ${member_id}, host: \"${node}:${CONTAINER_PORT}\"},"
    let member_id++
  done
  echo -n "var config={ _id: \"${MONGODB_REPLICA_NAME}\", members: [ ${members%,} ] }"
}

# mongo_initiate initiates the replica set.
# Takes a list of space-separated member IPs as the first argument.
function mongo_initiate() {
  local mongo_wait
  mongo_wait="while (rs.status().startupStatus || (rs.status().hasOwnProperty(\"myState\") && rs.status().myState != 1)) { printjson( rs.status() ); sleep(1000); }; printjson( rs.status() );"
  config=$(build_mongo_config "$1")
  echo "=> Initiating MongoDB replica using: ${config}"
  mongo admin --eval "${config};rs.initiate(config);${mongo_wait}"
}

# get the address of the current primary member
function mongo_primary_member_addr() {
  local rc=0

  endpoints | grep -v "$(container_addr)" |
  (
    while read mongo_node; do
      cmd_output="$(mongo admin -u admin -p "$MONGODB_ADMIN_PASSWORD" --host "$mongo_node:$CONTAINER_PORT" --eval 'print(rs.isMaster().primary)' --quiet || true)"

      # Trying to find IP:PORT in output and filter out error message because mongo prints it to stdout
      ip_and_port_regexp='[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+:[0-9]\+'
      if addr="$(echo "$cmd_output" | grep -x "$ip_and_port_regexp")"; then
        echo -n "$addr"
        exit 0
      fi

      echo >&2 "Cannot get address of primary from $mongo_node node: $cmd_output"
    done

    exit 1
  ) || rc=$?

  if [ $rc -ne 0 ]; then
    echo >&2 "Cannot get address of primary node: after checking all nodes we don't have the address"
    return 1
  fi
}

# mongo_remove removes the current MongoDB from the cluster
function mongo_remove() {
  local primary_addr
  primary_addr="$(mongo_primary_member_addr)"

  local mongo_addr
  mongo_addr="$(mongo_addr)"

  echo "=> Removing ${mongo_addr} on ${primary_addr} ..."
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" \
    --host "${primary_addr}" --eval "rs.remove('${mongo_addr}');" || true
}

# mongo_add advertise the current container to other mongo replicas
function mongo_add() {
  local primary_addr
  primary_addr="$(mongo_primary_member_addr)"

  local mongo_addr
  mongo_addr="$(mongo_addr)"

  echo "=> Adding ${mongo_addr} to ${primary_addr} ..."
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" \
    --host "${primary_addr}" --eval "rs.add('${mongo_addr}');"
}

# run_mongod_supervisor runs the MongoDB replica supervisor that manages
# registration of the new members to the MongoDB replica cluster
function run_mongod_supervisor() {
  ${CONTAINER_SCRIPTS_PATH}/replica_supervisor.sh 2>&1 &
}

# mongo_create_users creates the MongoDB admin user and the database user
# configured by MONGODB_USER
function mongo_create_users() {
  mongo ${MONGODB_DATABASE} --eval "db.addUser({user: '${MONGODB_USER}', pwd: '${MONGODB_PASSWORD}', roles: [ 'readWrite' ]})"

  mongo admin --eval "db.addUser({user: 'admin', pwd: '${MONGODB_ADMIN_PASSWORD}', roles: ['dbAdminAnyDatabase', 'userAdminAnyDatabase' , 'readWriteAnyDatabase','clusterAdmin' ]})"

  touch ${MONGODB_DATADIR}/.mongodb_datadir_initialized
}

# mongo_reset_passwords sets the MongoDB passwords to match MONGODB_PASSWORD
# and MONGODB_ADMIN_PASSWORD
function mongo_reset_passwords() {
  mongo ${MONGODB_DATABASE} --eval "db.changeUserPassword('${MONGODB_USER}', '${MONGODB_PASSWORD}')"
  mongo admin --eval "db.changeUserPassword('admin', '${MONGODB_ADMIN_PASSWORD}')"
}

# setup_keyfile fixes the bug in mounting the Kubernetes 'Secret' volume that
# mounts the secret files with 'too open' permissions.
function setup_keyfile() {
  if [ -z "${MONGODB_KEYFILE_VALUE-}" ]; then
    echo "ERROR: You have to provide the 'keyfile' value in $MONGODB_KEYFILE_VALUE"
    exit 1
  fi
  echo ${MONGODB_KEYFILE_VALUE} > ${MONGODB_KEYFILE_PATH}
  chmod 0600 ${MONGODB_KEYFILE_PATH}
}
