#!/bin/bash
#
# This script registers the current container into MongoDB replica set or initiate replSet if $1 == "initiate"

set -o errexit
set -o nounset
set -o pipefail

source ${CONTAINER_SCRIPTS_PATH}/base-functions.sh
source ${CONTAINER_SCRIPTS_PATH}/init-functions.sh
source ${CONTAINER_SCRIPTS_PATH}/replset-functions.sh

wait_mongo "UP"

if [[ "$1" == "initiate" ]]; then
  main_process_id=$2

  # Prepare master
  echo "=> Initiating the replSet ${MONGODB_REPLICA_NAME} ..."

  mongo_initiate

  echo "=> Creating MongoDB users ..."
  mongo_create_admin
  mongo_create_user "-u admin -p ${MONGODB_ADMIN_PASSWORD}"

  # Add one pod to this replSet to be able to address it with mongodb service
  member_addr=$($(endpoints) | head -n 1)
  echo "=> Adding first member ${member_addr} to replSet ..."
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --eval "rs.add('${member_addr}:27017');"

  mongo_wait_replset "-u admin -p ${MONGODB_ADMIN_PASSWORD}" "$(mongo_addr)"

  echo "=> Successfully initialized replSet ..."

  # Wait for at least 3 members
  members=0
  while [ "${members}" -le 3 ] 2>/dev/null; do
    echo "=> Waiting for other replSet members ..."
    sleep ${SLEEP_TIME}
    mongo_wait_replset "-u admin -p ${MONGODB_ADMIN_PASSWORD}"
    members=$(mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --quiet --host "$(replset_addr)" --eval "rs.status().members.length" | tail -n 1)
  done

  # Exit this pod
  kill ${main_process_id}

else
  echo "=> Trying to add this mongod to the replSet ..."
  # Add to the replSet
  mongo_wait_replset "-u admin -p ${MONGODB_ADMIN_PASSWORD}"

  # Add the current container to the replSet
  mongo_add

  echo "=> Successfully added to the replSet ..."

fi
