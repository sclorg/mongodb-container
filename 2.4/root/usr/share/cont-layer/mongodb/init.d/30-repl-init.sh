# build_mongo_config builds the MongoDB replicaSet config used for the cluster
# initialization
function build_mongo_config() {
  local members="{ _id: 0, host: \"$(mongo_addr)\"},"
  local member_id=1
  for node in $(endpoints); do
    members+="{ _id: ${member_id}, host: \"${node}:${port}\"},"
    let member_id++
  done
  echo -n "var config={ _id: \"${MONGODB_REPLICA_NAME}\", members: [ ${members%,} ] }"
}

# mongo_initiate initiate the replica set
function mongo_replica_init() {
  local mongo_wait="while (rs.status().startupStatus || (rs.status().hasOwnProperty(\"myState\") && rs.status().myState != 1)) { printjson( rs.status() ); sleep(1000); }; printjson( rs.status() );"
  local config=$(build_mongo_config)
  echo "=> Initiating MongoDB replica using: ${config}"
  mongo admin --eval "${config};rs.initiate(config);${mongo_wait}"
}

# get the address of the current primary member
function mongo_primary_member_addr() {
  local current_endpoints=$(endpoints)
  local mongo_node="$(echo -n ${current_endpoints} | cut -d ' ' -f 1):${port}"
  echo -n $(mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --host ${mongo_node} --quiet --eval "print(rs.isMaster().primary);")
}

# mongo_remove removes the current MongoDB from the cluster
function mongo_remove() {
  echo "=> Removing $(mongo_addr) on $(mongo_primary_member_addr)"
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" \
    --host $(mongo_primary_member_addr) --eval "rs.remove('$(mongo_addr)');" &>/dev/null || true
}

# mongo_add advertise the current container to other mongo replicas
function mongo_add() {
  echo "=> Adding $(mongo_addr) to $(mongo_primary_member_addr)"
  mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" \
    --host $(mongo_primary_member_addr) --eval "rs.add('$(mongo_addr)');"
}


if [ -n "$MONGODB_REPLICA_INIT" ]; then
  while no_endpoints ; do
    echo -n "=> Waiting for MongoDB endpoints"
    sleep $SLEEP_TIME
  done

  # Let initialize the first member of the cluster
  current_endpoints=$(endpoints)
  echo $(endpoints)
  echo "=> Waiting for all endpoints to accept connections"
  for node in ${current_endpoints}; do
    wait_mongo "UP" ${node}
  done

  echo "=> Initiating the replSet ${MONGODB_REPLICA_NAME} ..."
  mongo_replica_init

: '
    echo "=> Waiting for replication to finish"
    # TODO: Replace this with polling or a Mongo script that will check if all
    #       members of the cluster are now properly replicated (user accounts are
    #       created on all members).
    sleep 10

    # Some commands will force MongoDB client to re-connect. This is not working
    # well in combination with '--eval'. In that case the 'mongo' command will fail
    # with return code 254.
    echo "=> Initiate Pod giving up the PRIMARY role"
    mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --quiet --eval "rs.stepDown(120);" &>/dev/null || true

    # Wait till the new PRIMARY member is elected
    echo "=> Waiting for the new PRIMARY to be elected"
    mongo admin -u admin -p "${MONGODB_ADMIN_PASSWORD}" --quiet --host ${mongo_node} --eval "var done=false;while(done==false){var members=rs.status().members;for(i=0;i<members.length;i++){if(members[i].stateStr=='PRIMARY' && members[i].name!='$(mongo_addr)'){done=true}};sleep(500)};" &>/dev/null

    # Remove the initialization container MongoDB from cluster and shutdown
    echo "=> The new PRIMARY member is $(mongo_primary_member_addr), shutting down current member"
    mongo_remove
'

fi
