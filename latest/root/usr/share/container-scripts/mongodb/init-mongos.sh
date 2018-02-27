#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

source ${CONTAINER_SCRIPTS_PATH:-}/common.sh

# @public  Checks environmental variables for mongos
function check_mongos_env_vars() {
    # For triggering proper usage()
    SHARD=1
    [[ -v MONGODB_CONFIG_REPLSET_NAME && -v MONGODB_CONFIG_REPLSET_SERVER ]] || usage "MONGODB_CONFIG_REPLSET_NAME and MONGODB_CONFIG_REPLSET_SERVER have to be set"
    [[ -v MONGODB_REPLSET_NAMES && -v MONGODB_REPLSET_SERVERS ]] || usage "MONGODB_REPLSET_NAMES and MONGODB_REPLSET_SERVERS have to be set"
}
readonly -f check_mongos_env_vars


# @public Adds replica set members to the shard cluster
function configure_mongos() {
    local rs_names=$( echo $MONGODB_REPLSET_NAMES | sed 's/ /,/g' )
    local rs_servers=$( echo $MONGODB_REPLSET_SERVERS | sed 's/ /,/g' )
    IFS=',' rs_names_array=( $rs_names )
    IFS=',' rs_servers_array=( $rs_servers )
    local rs_names_length=${#rs_names_array[@]}
    local rs_servers_length=${#rs_servers_array[@]}
    if [[ rs_names_length -ne rs_servers_length ]]; then
      usage "Number of ReplicaSet names provided does not match the number of ReplicaSet servers provided"
    fi

    for (( i=0; i<$rs_names_length; i++ )); do
      info "Adding shard entry ${rs_names_array[$i]}/${rs_servers_array[$i]}"
      eval "mongo admin -u admin -p ${MONGODB_ADMIN_PASSWORD} --host $(hostname -f) --eval \"sh.addShard('${rs_names_array[$i]}/${rs_servers_array[$i]}')\" --quiet"
    done
}
readonly -f configure_mongos

configure_mongos
