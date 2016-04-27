#!/bin/sh
#
# This script registers the current container into MongoDB replica set and
# unregisters it when the container is terminated.

set -o errexit
set -o nounset
set -o pipefail

source  ${CONTAINER_SCRIPTS_PATH}/common.sh

echo "=> Waiting for local MongoDB to accept connections ..."
wait_for_mongo_up

# NOTE: The `endpoints` function in `common.sh` used to return ephemeral pod
# IPs, but now we have it return a fixed list of host names. Since the list of
# host names is static, we do not need nor want to add/remove new members to the
# replica set configuration as part of a pod lifecycle, therefore we comment out
# the code below.

# set-x
# # Add the current container to the replSet
# mongo_add
