#!/bin/bash

# Used for wait_for_mongo_* functions
MAX_ATTEMPTS=60
SLEEP_TIME=1

export CONTAINER_PORT=$(echo -n $IMAGE_EXPOSE_SERVICES | cut -d ':' -f 1)

function container_addr() {
  echo -n $(cat /var/lib/mongodb/.address)
}

function mongo_addr() {
  echo -n "$(container_addr):${CONTAINER_PORT}"
}

function cache_container_addr() {
  ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/' > /var/lib/mongodb/.address
}

# wait_for_mongo_up waits until the mongo server accepts incomming connections
function wait_for_mongo_up() {
  for i in $(seq $MAX_ATTEMPTS); do
    echo "=> Waiting for confirmation of MongoDB service startup"
    set +e
    mongo admin --eval "help" &>/dev/null
    status=$?
    set -e
    if [ $status -eq 0 ]; then
      echo "=> MongoDB service has started"
      return 0
    fi
    sleep $SLEEP_TIME
  done
  echo "=> Giving up: Failed to start MongoDB service"
  exit 1
}

# wait_for_mongo_up waits until the mongo server is down
function wait_for_mongo_down() {
  for i in $(seq $MAX_ATTEMPTS); do
    echo "=> Waiting till MongoDB service is stopped"
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
  dig mongodb A +search +short 2>/dev/null
}

# no_endpoints returns true if the only endpoint is the current container itself
# or there are no endpoints registred (running as standalone Docker container)
function no_endpoints() {
  [ -z "$(endpoints)" ] && return 0
  [ "$(endpoints)" == "$(container_addr)" ]
}

# deregister removes the current MongoDB from the cluster
function deregister() {
  for node in $(endpoints); do
    echo "=> Removing $(mongo_addr) from replica set"
    mongo admin --host ${node}:${CONTAINER_PORT} --eval "rs.remove(\"$(mongo_addr)\");"
  done
}

# mongo_initiate initiate the replica set
function mongo_initiate() {
  local mongo_wait="while (rs.status().startupStatus || (rs.status().hasOwnProperty(\"myState\") && rs.status().myState != 1)) { printjson( rs.status() ); sleep(1000); }; printjson( rs.status() );"
  local mongo_config="var config={ _id: \"${MONGODB_REPLICA_NAME}\", members: [ { _id: 0, host: \"$(mongo_addr)\" } ] };"
  mongo admin --eval "${mongo_config};rs.initiate(config);${mongo_wait}"
}

# mongo_advertise advertise the current container to other mongo replicas
function mongo_advertise() {
    local node="$1"
    # Skip the current container
    [[ "${node}" == "$(container_addr)" ]] && continue
    echo "=> Advertising new MongoDB node to ${node}"
    mongo admin --host ${node}:${CONTAINER_PORT} --eval "rs.add(\"$(mongo_addr)\");"
}
