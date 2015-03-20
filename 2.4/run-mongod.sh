#!/bin/bash

# SCL in CentOS/RHEL 7 doesn't support --exec, we need to do it ourselves
source scl_source enable mongodb24
set -e

MAX_ATTEMPTS=60
SLEEP_TIME=1

function usage() {
	echo "You must specify following environment variables:"
	echo "  \$MONGODB_USERNAME"
	echo "  \$MONGODB_PASSWORD"
	echo "  \$MONGODB_DATABASE"
	echo "  \$MONGODB_ADMIN_PASSWORD - optional"
	exit 1
}

function up_test() {
    for i in $(seq $MAX_ATTEMPTS); do
        echo "=> Waiting for confirmation of MongoDB service startup"
        set +e
        mongo admin --eval "help"
        status=$?
        set -e
        if [ $status -eq 0 ]; then
            echo "=> MongoDB service has started"
            return 0
        fi
        sleep $SLEEP_TIME
    done
    echo "=> Giving up: Failed to start MongoDB service"
    exit 1
}

function down_test() {
    for i in $(seq $MAX_ATTEMPTS); do
        echo "=> Waiting till MongoDB service is stopped"
        set +e
        mongo admin --eval "help"
        status=$?
        set -e
        if [ $status -ne 0 ]; then
            echo "=> MongoDB service has stopped"
            return 0
        fi
        sleep $SLEEP_TIME
    done
    echo "=> Giving up: Failed to stop MongoDB service"
    exit 1
}

function create_mongodb_users() {
	# Start MongoDB service with disabled database authentication.
	mongod -f /opt/openshift/etc/mongodb.conf &

	# Check if the MongoDB daemon is up.
	up_test

	# Make sure env variables don't propagate to mongod process.
	mongo_user="$MONGODB_USERNAME" ; unset MONGODB_USERNAME
	mongo_pass="$MONGODB_PASSWORD" ; unset MONGODB_PASSWORD
	mongo_db="$MONGODB_DATABASE" ; unset MONGODB_DATABASE

	# Create MongoDB database admin, if his password is specified with MONGODB_ADMIN_PASSWORD
	if [ "$MONGODB_ADMIN_PASSWORD" ]; then
		echo "=> Creating an admin user with a ${MONGODB_ADMIN_PASSWORD} password in MongoDB"
		mongo admin --eval "db.addUser({user: 'admin', pwd: '$MONGODB_ADMIN_PASSWORD', roles: [ 'dbAdminAnyDatabase', 'userAdminAnyDatabase' , 'readWriteAnyDatabase' ]});"
		unset MONGODB_ADMIN_PASSWORD
	fi

	# Create standard user with read/write permissions, in specified database ('production' by default).
	mongo $mongo_db --eval "db.addUser({user: '${mongo_user}', pwd: '${mongo_pass}', roles: [ 'readWrite' ]});"
	mongo admin --eval "db.shutdownServer();"

	# Create a empty file which indicates that the database users were created.
	touch /var/lib/mongodb/.mongodb_users_created

	# Check if the MongoDB daemon is down.
	down_test
}

test -z "$MONGODB_USERNAME" && usage
test -z "$MONGODB_PASSWORD" && usage
test -z "$MONGODB_DATABASE" && usage

if [ ! -f /var/lib/mongodb/.mongodb_users_created ]; then
	create_mongodb_users
fi

# Start MongoDB service with enabled database authentication.
exec mongod -f /opt/openshift/etc/mongodb.conf --auth
