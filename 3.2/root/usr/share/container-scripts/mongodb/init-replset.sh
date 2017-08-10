#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source ${CONTAINER_SCRIPTS_PATH}/common.sh
source ${CONTAINER_SCRIPTS_PATH}/setup_rhmap.sh

# This is a full hostname that will be added to replica set
# (for example, "replica-2.mongodb.myproject.svc.cluster.local")
readonly MEMBER_HOST="$(hostname -f | grep -o mongodb-[1-9])"

# Initializes the replica set configuration.
#
# Arguments:
# - $1: host address[:port]
#
# Uses the following global variables:
# - MONGODB_REPLICA_NAME
# - MONGODB_ADMIN_PASSWORD
function initiate() {
  local host="$1"

  local config="{_id: '${MONGODB_REPLICA_NAME}', members: [{_id: 0, host: '${host}'}]}"

  info "Initiating MongoDB replica using: ${config}"
  mongo --eval "quit(rs.initiate(${config}).ok ? 0 : 1)" --quiet

  info "Waiting for PRIMARY status ..."
  mongo --eval "while (!rs.isMaster().ismaster) { sleep(100); }" --quiet
  
  mongo_create_admin
  #[[ -v CREATE_USER ]] && mongo_create_user "-u admin -p ${MONGODB_ADMIN_PASSWORD}"

  info "Creating MongoDB users ..."

  setUpDatabases "-u admin -p ${MONGODB_ADMIN_PASSWORD}"
  info "Successfully initialized replica set"
}

# Adds a host to the replica set configuration.
#
# Arguments:
# - $1: host address[:port]
#
# Global variables:
# - MONGODB_REPLICA_NAME
# - MONGODB_ADMIN_PASSWORD
function add_member() {

  # add wait for the mongodb-1 service
  wait_for_service mongodb-1
 
  # wait for mongodb daemon to come up 
  wait_for_mongo_up  mongodb-1

  
  local host="$1"
  info "Adding ${host} to replica set ..."

  # give mongodb-1 time to settle
  # sleep 30;

  if ! mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --host "mongodb-1" --eval "while (!rs.add('${host}').ok) { sleep(200); }" --quiet; then
    info "ERROR: couldn't add host to replica set!"
    return 1
  fi

  info "Waiting for PRIMARY/SECONDARY status ..."
  mongo --eval "while (!rs.isMaster().ismaster && !rs.isMaster().secondary) { sleep(200); }" --quiet

  info "Successfully joined replica set"
}

info "Waiting for local MongoDB to accept connections  ..."
wait_for_mongo_up &>/dev/null

if [[ $(mongo --eval 'db.isMaster().setName' --quiet) == "${MONGODB_REPLICA_NAME}" ]]; then
  info "Replica set '${MONGODB_REPLICA_NAME}' already exists, skipping initialization"
  >/tmp/initialized
  exit 0
fi

# StatefulSet pods are named with a predictable name, following the pattern:
#   $(statefulset name)-$(zero-based index)
# MEMBER_ID is computed by removing the prefix matching "*-", i.e.:
#  "mongodb-0" -> "0"
#  "mongodb-1" -> "1"
#  "mongodb-2" -> "2"
readonly MEMBER_ID="${MEMBER_HOST##*-}"

# Initialize replica set only if we're the first member
if [ "${MEMBER_ID}" = '1' ]; then
  initiate "${MEMBER_HOST}"
else
  add_member "${MEMBER_HOST}"
fi

>/tmp/initialized
