#!/bin/bash
#
# This script registers the current container into MongoDB replica set and
# unregisters it when the container is terminated.

source ${CONTAINER_SCRIPTS_PATH}/base-functions.sh
source ${CONTAINER_SCRIPTS_PATH}/init-functions.sh
source ${CONTAINER_SCRIPTS_PATH}/replset-functions.sh

set -x

wait_mongo "UP"

if [ "$1" == "initiate" ]; then
  # Prepare master
  echo "=> Initiating the replSet ${MONGODB_REPLICA_NAME} ..."

  mongo_initiate

  echo "=> Creating MongoDB users ..."
  mongo_create_admin
  mongo_create_user "-u admin -p $MONGODB_ADMIN_PASSWORD"

  mongo_wait_replset "-u admin -p $MONGODB_ADMIN_PASSWORD"

  echo "=> Successfully initialized replSet ..."

  # Wait for at least 3 members
  members=0
  while [ "$members" -le 3 ] 2>/dev/null || [ $? -ne 1 ] ; do
    echo "=> Waiting for other replSet members ..."
    sleep $SLEEP_TIME
    mongo_wait_replset "-u admin -p $MONGODB_ADMIN_PASSWORD"
    members=$(mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --quiet --host "$(replset_addr_deploy)" --eval "rs.status().members.length" | tail -n 1)
  done

  # Wait till all members finished inital sync
  ok=0
  while [ "$members" -ne "$ok" ]; do
    echo "=> Wait sync finished ..."
    ok=$(mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --quiet --host "$(replset_addr_deploy)" --eval "var members=rs.status().members; var ok=0; for(i in members) {if(members[i].state == 1 || members[i].state == 2 || members[i].state == 7) { ok++} }; print(ok)" | tail -n 1)
    members=$(mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --quiet --host "$(replset_addr_deploy)" --eval "rs.status().members.length" | tail -n 1)
  done

  # Exit this pod
  kill $2

else
  echo "=> Trying to add this mongod to the replSet ..."
  # Add to the replSet
  mongo_wait_replset "-u admin -p $MONGODB_ADMIN_PASSWORD"

  # Add the current container to the replSet
  mongo_add

  echo "=> Successfully added to the replSet ..."

fi
