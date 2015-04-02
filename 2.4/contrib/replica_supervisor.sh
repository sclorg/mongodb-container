#!/bin/sh
#
# This script registers the current container into MongoDB replica set and
# unregister it when the container is terminated.

source /var/lib/mongodb/common.sh
source /var/lib/mongodb/.bashrc

# Redirect all stdout && stderr into a FIFO pipe
exec 1<&-
exec 2<&-
exec 1<>/tmp/replica_supervisor_log
exec 2>&1

echo "=> Waiting for MongoDB to accept connections ..."
wait_for_mongo_up

if no_endpoints; then
  echo "=> No other endpoints found, initializing empty MongoDB replica set ..."
  mongo_initiate
else
  for node in $(endpoints); do
    mongo_advertise "${node}"
  done
fi

echo "=> MongoDB successfully started"
sleep infinity
