# cache_container_addr waits till the container gets the external IP address and
# cache it to disk
function cache_container_addr() {
  echo -n "=> Waiting for container IP address ..."
  for i in $(seq $MAX_ATTEMPTS); do
    result=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/')
    if [ ! -z "${result}" ]; then
      echo -n $result > ${HOME}/.address
      echo " $(mongo_addr)"
      return 0
    fi
    sleep $SLEEP_TIME
  done
  echo "Failed to get Docker container IP address." && exit 1
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

# endpoints_deploy returns list of all IP addresses in deployment
function endpoints_deploy() {
  service_name=${MONGODB_SERVICE_NAME:-mongodb}
  dig ${service_name} ${service_name}-deploy A +search +short 2>/dev/null
}

# replset_addr return the address of the current replset
# NOTE: this function hopes that some replset member use standart port
function replset_addr() {
  echo "${MONGODB_REPLICA_NAME}/$(echo $(endpoints) | sed -e 's| |:27017,|g' -e 's|$|:27017|')"
}

# replset_addr return the address of the current replset
# NOTE: this function hopes that some replset member use standart port
function replset_addr_deploy() {
  echo "${MONGODB_REPLICA_NAME}/$(echo $(endpoints_deploy) | sed -e 's| |:27017,|g' -e 's|$|:27017|')"
}

# mongo_wait_primary waits until primary replset member is ready
function mongo_wait_replset() {
  # If there is no PRIMARY yet, rs.isMaster().primary returns "undefined"
  for i in $(seq $MAX_ATTEMPTS); do
    # Test connection to replica set
    local set=$(mongo admin ${1:-} --host $(replset_addr_deploy) --quiet --eval "print(rs.isMaster().setName);" | tail -n 1)
    # If there is no PRIMARY yet, rs.isMaster().primary returns "undefined"
    local primary=$(mongo admin ${1:-} --host $(replset_addr_deploy) --quiet --eval "print(rs.isMaster().primary);" | tail -n 1)
    if [ "${set}" == "$MONGODB_REPLICA_NAME" ] && [ "${primary}" != "undefined" ]; then
      break
    fi
    sleep $SLEEP_TIME
  done

#  mongo admin ${1:-} --host ${2:-$(replset_addr)} --eval "while (rs.status().startupStatus || (rs.status().hasOwnProperty(\"myState\") && rs.status().myState != 1)) { printjson( rs.status() ); sleep(1000); }; printjson( rs.status() );"
}

# mongo_initiate initiates the replica set
function mongo_initiate() {
  config="{ _id: \"${MONGODB_REPLICA_NAME}\", members: [ { _id: 0, host: \"${1:-$(mongo_addr)}\"} ] }"
  echo "=> Initiating MongoDB replica using: ${config}"
  mongo admin --eval "rs.initiate(${config})"
  mongo_wait_replset
}

# mongo_remove removes the current MongoDB from the cluster
function mongo_remove() {
  echo "=> Removing $(mongo_addr) from $(replset_addr_deploy) ..."
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" \
    --host $(replset_addr_deploy) --eval "rs.remove('$(mongo_addr)');" &>/dev/null || true
}

# mongo_add adds the current container to other mongo replicas
function mongo_add() {
  echo "=> Adding $(mongo_addr) to $(replset_addr_deploy) ..."
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" \
    --host $(replset_addr_deploy) --eval "rs.add('$(mongo_addr)');"
}

# setup_keyfile fixes the bug in mounting the Kubernetes 'Secret' volume that
# mounts the secret files with 'too open' permissions.
function setup_keyfile() {
  if [ -z "${MONGODB_KEYFILE_VALUE}" ]; then
    echo "ERROR: You have to provide the 'keyfile' value in ${MONGODB_KEYFILE_VALUE}"
    exit 1
  fi
  echo ${MONGODB_KEYFILE_VALUE} > ${MONGODB_KEYFILE_PATH}
  chmod 0600 ${MONGODB_KEYFILE_PATH}
}

