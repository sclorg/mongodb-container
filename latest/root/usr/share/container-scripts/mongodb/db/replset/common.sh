#!/bin/bash
source ${CONTAINER_SCRIPTS_PATH:-}/db/common.sh

# @public  Checks environmental variables for initializing a mongo replica set
#
function check_repl_env_vars() {
    [[ -v MONGODB_KEYFILE_VALUE && -v MONGODB_REPLICA_NAME ]] || usage "MONGODB_KEYFILE_VALUE and MONGODB_REPLICA_NAME have to be set"
    check_db_env_vars
}
readonly -f check_repl_env_vars

# @public Create either a replica set or add member in the background.
#
# @param  replicaset_init_fn - if this is the first member of the set, call this function to initialize. Init may differ based on what kind of replicaset
# we are creating, for e.g (configserver rs, shard rs)
# @value  MONGODB_REPLICA_NAME
# @value  MEMBER_ID
#
# 05/2017 Marked function as readonly.
function configure_replicaset_mode() {
  local comm="db.isMaster().setName"

  wait_for_mongo_up &>/dev/null

  if [[ "$($MONGO --eval "${comm}" --quiet)" == "${MONGODB_REPLICA_NAME:-}" ]]; then
    log_info "Replica set '${MONGODB_REPLICA_NAME:-}' already exists, skipping initialization"
    >/tmp/initialized
    return 0
  fi

  if [[ "$MEMBER_ID" == "0" ]]; then
    $1
  else
    rs_add
  fi

  >/tmp/initialized
}
readonly -f configure_replicaset_mode

# @public Adds a member to replica set.
#
# @value  MEMBER_HOST
# @value  MONGODB_ADMIN_PASSWORD
# @value  MONGODB_ADMIN_USER
#
function rs_add() {
  local comm="while (!rs.add('$MEMBER_HOST').ok) { sleep(100); }"
  local host
  host=$(endpoint -u "${MONGODB_ADMIN_USER:-}" -p "${MONGODB_ADMIN_PASSWORD:-}")

  log_info "Adding $MEMBER_HOST to replica set"
  if ! $MONGO "${host}" --eval "${comm}" --quiet; then
    log_fail "Couldn't add host to replica set"
    return 1
  fi

  log_info "Waiting for PRIMARY/SECONDARY status"
  $MONGO --eval "while (!rs.isMaster().ismaster && !rs.isMaster().secondary) { sleep(100); }"

  log_pass "Member added to replica set"
}
readonly -f rs_add

# @public Removes a member from replica set.
#
# @value  MEMBER_HOST
# @value  MONGODB_ADMIN_PASSWORD
# @value  MONGODB_ADMIN_USER
#
function rs_remove() {
  local comm="while (!rs.remove('$MEMBER_HOST').ok) { sleep(100); }"
  local host
  host=$(endpoint -u "${MONGODB_ADMIN_USER:-}" -p "${MONGODB_ADMIN_PASSWORD:-}")

  log_info "Removing $MEMBER_HOST from replica set"

  if ! $MONGO "${host}" --eval "${comm}" --quiet; then
    log_fail "Couldn't remove host from replica set"
    return 1
  fi

  log_info "Waiting for PRIMARY/SECONDARY status"
  $MONGO --eval "while (!rs.isMaster().ismaster && !rs.isMaster().secondary) { sleep(100); }"

  log_pass "Member removed from replica set"
}
readonly -f rs_remove
