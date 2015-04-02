#!/bin/bash

# For SCL enablement
source /var/lib/mongodb/common.sh
source /var/lib/mongodb/.bashrc

set -eu

# Data directory where MongoDB database files live. The data subdirectory is here
# because .bashrc and mongodb.conf both live in /var/lib/mongodb/ and we don't want a
# volume to override it.
export MONGODB_DATADIR=/var/lib/mongodb/data

# Configuration settings.
export MONGODB_NOPREALLOC=${MONGODB_NOPREALLOC:-true}
export MONGODB_SMALLFILES=${MONGODB_SMALLFILES:-true}
export MONGODB_QUIET=${MONGODB_QUIET:-true}
export MONGODB_CONFIG_PATH=/var/lib/mongodb/mongodb.conf
export MONGODB_PID_FILE=/var/lib/mongodb/mongodb.pid

function usage() {
  echo "You must specify following environment variables:"
  echo "  \$MONGODB_USERNAME"
  echo "  \$MONGODB_PASSWORD"
  echo "  \$MONGODB_DATABASE"
  echo "Optional variables:"
  echo "  \$MONGODB_ADMIN_PASSWORD"
  echo "MongoDB settings:"
  echo "  \$MONGODB_NOPREALLOC (default: true)"
  echo "  \$MONGODB_SMALLFILES (default: true)"
  echo "  \$MONGODB_QUIET (default: false)"
  exit 1
}

# Make sure env variables don't propagate to mongod process.
function unset_env_vars() {
  unset MONGODB_USERNAME MONGODB_PASSWORD MONGODB_DATABASE MONGODB_ADMIN_PASSWORD
}

function create_mongodb_users() {
  # Start MongoDB service with disabled database authentication.
  mongod -f $MONGODB_CONFIG_PATH --noprealloc --smallfiles --oplogSize 64 &

  # Check if the MongoDB daemon is up.
  wait_for_mongo_up

  # Create MongoDB database admin, if his password is specified with MONGODB_ADMIN_PASSWORD
  if [ -v MONGODB_ADMIN_PASSWORD ]; then
    echo "=> Creating an admin user with a ${MONGODB_ADMIN_PASSWORD} password in MongoDB"
    mongo admin --eval "db.addUser({user: 'admin', pwd: '$MONGODB_ADMIN_PASSWORD', roles: [ 'dbAdminAnyDatabase', 'userAdminAnyDatabase' , 'readWriteAnyDatabase', 'clusterAdmin' ]});"
  fi

  # Create standard user with read/write permissions, in specified database ('production' by default).
  mongo $MONGODB_DATABASE --eval "db.addUser({user: '${MONGODB_USERNAME}', pwd: '${MONGODB_PASSWORD}', roles: [ 'readWrite' ]});"
  mongod -f $MONGODB_CONFIG_PATH --shutdown

  # Create a empty file which indicates that the database users were created.
  touch /var/lib/mongodb/data/.mongodb_users_created

  # Check if the MongoDB daemon is down.
  wait_for_mongo_down
}

function cleanup() {
  if [ ! -z "${MONGODB_REPLICA_NAME-}" ]; then
    deregister && sleep 5
  fi
  echo "=> Shutting down MongoDB server ..."
  kill -2 $(cat ${MONGODB_PID_FILE})
  wait_for_mongo_down
  exit 0
}

cache_container_addr

# Generate config file for MongoDB
envsubst < ${MONGODB_CONFIG_PATH}.template > $MONGODB_CONFIG_PATH

if [ "$1" = "mongod" ]; then
  if ! [[ -v MONGODB_USERNAME && -v MONGODB_PASSWORD && -v MONGODB_DATABASE ]]; then
    usage
  fi

  if [ ! -f /var/lib/mongodb/data/.mongodb_users_created ]; then
    # Create default MongoDB user and administrator.
    create_mongodb_users
  fi

  unset_env_vars

  mongo_cmd_args="-f $MONGODB_CONFIG_PATH --noprealloc --smallfiles --oplogSize 64"

  if [ ! -z "${MONGODB_REPLICA_NAME-}" ]; then
    mongo_cmd_args+=" --replSet ${MONGODB_REPLICA_NAME}"
    ( mkfifo /tmp/replica_supervisor_log && cat /tmp/replica_supervisor_log ) &
    /var/lib/mongodb/replica_supervisor.sh &
    trap 'cleanup' SIGINT SIGTERM
    mongod $mongo_cmd_args & mongo_pid=$!
    wait $mongo_pid
  else
    # FIXME: MongoDB replica set currently does not support authentication as
    # the server wont start with --auth enabled. This have to be investigated.
    mongo_cmd_args+=" --auth"
    exec mongod $mongo_cmd_args
  fi


else
  exec $@
fi
