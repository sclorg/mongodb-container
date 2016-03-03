# This file contains functions for replSet manipulation

# cache_container_addr waits till the container gets the external IP address and
# cache it to disk
function cache_container_addr() {
  echo -n "=> Waiting for container IP address ..."
  local i
  for i in $(seq ${MAX_ATTEMPTS}); do
    if ip -oneline -4 addr show up scope global | grep -Eo '[0-9]{,3}(\.[0-9]{,3}){3}' | head -n 1 > "${HOME}"/.address; then
      echo " $(mongo_addr)"
      return 0
    fi
    sleep ${SLEEP_TIME}
  done
  echo "Failed to get Docker container IP address."
  exit 1
}

# container_addr returns the current container external IP address
function container_addr() {
  echo -n $(cat ${HOME}/.address)
}

# mongo_addr returns the IP:PORT of the currently running MongoDB instance
function mongo_addr() {
  echo -n "$(container_addr):${port}"
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
  echo "${MONGODB_REPLICA_NAME}/$(echo $(endpoints) | sed -e 's| |:27017,|g' -e 's|$|:27017|')"
}

# mongo_wait_primary waits until primary replset member is ready
# (accepts connection and master is elected)
# $1 - login parameters for mongo (optional)
# $2 - host where to connect (replset_addr by default)
function mongo_wait_replset() {
  # If there is no PRIMARY yet, rs.isMaster().primary returns "undefined"
  local i
  for i in $(seq ${MAX_ATTEMPTS}); do
    # Test connection to replica set
    set +e
    local set_name
    set_name=$(mongo admin ${1:-} --host ${2:-$(replset_addr)} --quiet --eval "rs.isMaster().setName;" | tail -n 1)
    # If there is no PRIMARY yet, rs.isMaster().primary returns "undefined"
    local primary
    primary=$(mongo admin ${1:-} --host ${2:-$(replset_addr)} --quiet --eval "rs.isMaster().primary;" | tail -n 1)
    set -e
    if [[ "${set_name}" == "$MONGODB_REPLICA_NAME" && "${primary}" != "undefined" && -n "${primary}" ]]; then
      break
    fi
    sleep ${SLEEP_TIME}
  done
}

# mongo_initiate initiates the replica set with one member on the current container
function mongo_initiate() {
  local config
  config="{ _id: \"${MONGODB_REPLICA_NAME}\", members: [ { _id: 0, host: \"$(mongo_addr)\"} ] }"
  echo "=> Initiating MongoDB replica using: ${config}"
  mongo admin --eval "rs.initiate(${config})"
  mongo_wait_replset "" "$(mongo_addr)"
}

# mongo_remove removes the current container from the cluster
function mongo_remove() {
  echo "=> Removing $(mongo_addr) from $(replset_addr) ..."
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" \
    --host $(replset_addr) --eval "JSON.stringify(rs.remove('$(mongo_addr)'));" &>/dev/null || true
}

# mongo_add adds the current container to the cluster
function mongo_add() {
  echo "=> Adding $(mongo_addr) to $(replset_addr) ..."
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" \
    --host $(replset_addr) --eval "JSON.stringify(rs.add('$(mongo_addr)'));"
}

# setup_keyfile prepare keyFile for mongod
function setup_keyfile() {
  if [[ -z "${MONGODB_KEYFILE_VALUE-}" ]]; then
    echo "ERROR: You have to provide the 'keyfile' value in MONGODB_KEYFILE_VALUE"
    exit 1
  fi
  echo ${MONGODB_KEYFILE_VALUE} > ${MONGODB_KEYFILE_PATH}
  chmod 0600 ${MONGODB_KEYFILE_PATH}
}

