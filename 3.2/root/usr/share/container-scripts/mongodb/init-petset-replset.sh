#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source "${CONTAINER_SCRIPTS_PATH}/common.sh"

# This is a full hostname that will be added to replica set
# (for example, "replica-2.mongodb.myproject.svc.cluster.local")
readonly MEMBER_HOST="$(hostname -f)"

# Description of possible statuses: https://docs.mongodb.com/manual/reference/replica-states/
readonly WAIT_PRIMARY_STATUS='
  while (rs.status().startupStatus || (rs.status().hasOwnProperty("myState") && rs.status().myState != 1)) {
    printjson(rs.status());
    sleep(1000);
  };
  printjson(rs.status());
'
readonly WAIT_PRIMARY_OR_SECONDARY_STATUS="
  var mbrs;
  while (!mbrs || mbrs.length == 0 || !(mbrs[0].state == 1 || mbrs[0].state == 2)) {
    printjson(rs.status());
    sleep(1000);
    mbrs = rs.status().members.filter(function(el) {
      return el.name.indexOf(\"${MEMBER_HOST}:\") > -1;
    });
  };
  print(mbrs[0].stateStr);
"

# Outputs available endpoints (hostnames) to stdout.
# This also includes hostname of the current pod.
#
# Uses the following global variables:
# - MONGODB_SERVICE_NAME (optional, defaults to 'mongodb')
function find_endpoints() {
  local service_name="${MONGODB_SERVICE_NAME:-mongodb}"

  # Extract host names from lines like this: "10 33 0 mongodb-2.mongodb.myproject.svc.cluster.local."
  dig "${service_name}" SRV +search +short | cut -d' ' -f4 | rev | cut -c2- | rev
}

# TODO: unify this and `mongo_initiate` from common.sh
# Initializes the replica set configuration. It is safe to call this function if
# a replica set is already configured.
#
# Arguments:
# - $1: host address[:port]
#
# Uses the following global variables:
# - MONGODB_REPLICA_NAME
# - MONGODB_ADMIN_PASSWORD
# - WAIT_PRIMARY_STATUS
function initiate() {
  local host="$1"

  if mongo --eval "quit(db.isMaster().setName == '${MONGODB_REPLICA_NAME}' ? 0 : 1)" --quiet; then
    info "Replica set '${MONGODB_REPLICA_NAME}' already exists, skipping initialization"
    return
  fi

  local config="{_id: '${MONGODB_REPLICA_NAME}', members: [{_id: 0, host: '${host}'}]}"

  info "Initiating MongoDB replica using: ${config}"
  mongo admin --eval "rs.initiate(${config});${WAIT_PRIMARY_STATUS}" --quiet

  info "Creating MongoDB users ..."
  mongo_create_admin
  mongo_create_user "-u admin -p ${MONGODB_ADMIN_PASSWORD}"

  info "Successfully initialized replica set"
}

# Adds a host to the replica set configuration. It is safe to call this function
# if the host is already in the configuration.
#
# Arguments:
# - $1: host address[:port]
#
# Global variables:
# - MAX_ATTEMPTS
# - SLEEP_TIME
# - MONGODB_REPLICA_NAME
# - MONGODB_ADMIN_PASSWORD
# - WAIT_PRIMARY_OR_SECONDARY_STATUS
function add_member() {
  local host="$1"
  info "Adding ${host} to replica set ..."

  local script
  script="
    for (var i = 0; i < ${MAX_ATTEMPTS}; i++) {
      var ret = rs.add('${host}');
      if (ret.ok) {
        quit(0);
      }
      // ignore error if host is already in the configuration
      if (ret.code == 103) {
        quit(0);
      }
      sleep(${SLEEP_TIME});
    }
    printjson(ret);
    quit(1);
  "

  # TODO: replace this with a call to `replset_addr` from common.sh, once it returns host names.
  local endpoints
  endpoints="$(find_endpoints | paste -s -d,)"

  if [ -z "${endpoints}" ]; then
    info "ERROR: couldn't add host to replica set!"
    info "CAUSE: DNS lookup for '${MONGODB_SERVICE_NAME:-mongodb}' returned no results."
    return 1
  fi

  local replset_addr
  replset_addr="${MONGODB_REPLICA_NAME}/${endpoints}"

  if ! mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --host "${replset_addr}" --eval "${script}" --quiet; then
    info "ERROR: couldn't add host to replica set!"
    return 1
  fi

  info "Successfully added to replica set"
  info "Waiting for PRIMARY/SECONDARY status ..."

  local rs_status_out
  rs_status_out="$(mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --host "${replset_addr}" --eval "${WAIT_PRIMARY_OR_SECONDARY_STATUS}" --quiet || :)"

  if ! echo "${rs_status_out}" | grep -xqs '\(SECONDARY\|PRIMARY\)'; then
    info "ERROR: failed waiting for PRIMARY/SECONDARY status. Command output was:"
    echo "${rs_status_out}"
    echo "==> End of the error output <=="
    return 1
  fi

  info "Successfully joined replica set"
}

info "Waiting for local MongoDB to accept connections on ${MEMBER_HOST} ..."
# connect using the host to ensure networking is working, otherwise
# the add_member call will fail.
wait_for_mongo_up ${MEMBER_HOST} &>/dev/null

# PetSet pods are named with a predictable name, following the pattern:
#   $(petset name)-$(zero-based index)
# MEMBER_ID is computed by removing the prefix matching "*-", i.e.:
#  "mongodb-0" -> "0"
#  "mongodb-1" -> "1"
#  "mongodb-2" -> "2"
readonly MEMBER_ID="${HOSTNAME##*-}"

# Initialize replica set only if we're the first member
if [ "${MEMBER_ID}" = '0' ]; then
  initiate "${MEMBER_HOST}"
else
  add_member "${MEMBER_HOST}"
fi
