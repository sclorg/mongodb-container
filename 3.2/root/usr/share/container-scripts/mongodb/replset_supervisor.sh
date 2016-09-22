#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source ${CONTAINER_SCRIPTS_PATH}/common.sh

echo -n "=> Waiting for MongoDB endpoints ..."
current_endpoints=$(endpoints)
while [ -z "${current_endpoints}" ]; do
  sleep 2
  current_endpoints=$(endpoints)
done

echo "${current_endpoints}"

# Let initialize the first member of the cluster
primary_node=$(echo -n "${current_endpoints}" | sort | head -n 1)

# Initiate replicaset and exit
if [[ "${primary_node}" == "$(container_addr)" ]]; then
  echo "=> Waiting for all endpoints to accept connections..."
  for node in ${current_endpoints}; do
    wait_for_mongo_up ${node} &>/dev/null
  done

  echo "=> Waiting for local MongoDB to accept connections ..."
  wait_for_mongo_up &>/dev/null

  echo "=> Initiating the replSet ${MONGODB_REPLICA_NAME} ..."
  # This will perform the 'rs.initiate()' command on the current MongoDB.
  mongo_initiate "${primary_node}"

  echo "=> Creating MongoDB users ..."
  mongo_create_admin
  mongo_create_user "-u admin -p ${MONGODB_ADMIN_PASSWORD}"

  echo "=> Successfully initialized replSet"

# Try to add node into replicaset
else
  echo "=> Waiting for local MongoDB to accept connections ..."
  wait_for_mongo_up
  set -x
  # Add the current container to the replSet
  wait_for_mongo_up "$(replset_addr)"
  mongo_add

fi
