MONGODB_KEYFILE_PATH=/var/lib/mongodb/keyfile

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

# container_addr returns the current container external IP address
function container_addr() {
  echo -n $(cat /var/lib/mongodb/.address)
}

# mongo_addr returns the IP:PORT of the currently running MongoDB instance
function mongo_addr() {
  echo -n "$(container_addr):${port}"
}

# cache_container_addr waits till the container gets the external IP address and
# cache it to disk
function cache_container_addr() {
  echo -n "=> Waiting for container IP address"
  for i in $(seq $MAX_ATTEMPTS); do
    result=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/')
    if [ ! -z "${result}" ]; then
      echo -n $result > /var/lib/mongodb/.address
      echo " $(mongo_addr)"
      return 0
    fi
    sleep $SLEEP_TIME
  done
  echo "=> Failed to get Docker container IP address" && exit 1
}

# endpoints returns list of IP addresses with other instances of MongoDB
# To get list of endpoints, you need to have headless Service named 'mongodb'.
# NOTE: This won't work with standalone Docker container.
function endpoints() {
  service_name=${MONGODB_SERVICE_NAME:-mongodb}
  dig ${service_name} A +search +short 2>/dev/null
}

# no_endpoints returns true if the only endpoint is the current container itself
# or there are no endpoints registered (running as standalone Docker container)
function no_endpoints() {
  [ -z "$(endpoints)" ] && return 0
  [ "$(endpoints)" == "$(container_addr)" ]
}

# Shutdown mongod on SIGINT/SIGTERM
function repl_cleanup() {
  # Shut down all nodes
  current_endpoints=$(endpoints)
  echo $(endpoints)
  echo "=> Shutting down all endpoints"
  set +e
  for node in ${current_endpoints}; do
    mongo admin -u admin -p ${ADMIN_PASSWORD} --host ${node} --eval "db.shutdownServer()"
  done
  set -e
}

if [ -n "${MONGODB_REPLICA_NAME}" ]; then
  trap 'repl_cleanup' SIGINT SIGTERM

  setup_keyfile

  # Need to cache the container address for the cleanup
  cache_container_addr

  mongod_common_args+="--oplogSize 64 --replSet ${MONGODB_REPLICA_NAME} --keyFile ${MONGODB_KEYFILE_PATH} "
  mongod_local_args=""
fi
