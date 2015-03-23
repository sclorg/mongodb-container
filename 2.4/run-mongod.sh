#!/bin/bash

# For SCL enablement
source /var/lib/mongodb/.bashrc

set -eu

MAX_ATTEMPTS=60
SLEEP_TIME=1

MONGODB_CONFIG_PATH="/opt/openshift/etc/mongodb.conf"

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

# Make sure env variables don't propagate to mongod process.
function unset_env_vars() {
	unset MONGODB_USERNAME MONGODB_PASSWORD MONGODB_DATABASE MONGODB_ADMIN_PASSWORD
}

function create_mongodb_users() {
	# Start MongoDB service with disabled database authentication.
	mongod -f $MONGODB_CONFIG_PATH &

	# Check if the MongoDB daemon is up.
	up_test

	# Create MongoDB database admin, if his password is specified with MONGODB_ADMIN_PASSWORD
	if [ -v MONGODB_ADMIN_PASSWORD ]; then
		echo "=> Creating an admin user with a ${MONGODB_ADMIN_PASSWORD} password in MongoDB"
		mongo admin --eval "db.addUser({user: 'admin', pwd: '$MONGODB_ADMIN_PASSWORD', roles: [ 'dbAdminAnyDatabase', 'userAdminAnyDatabase' , 'readWriteAnyDatabase' ]});"
	fi

	# Create standard user with read/write permissions, in specified database ('production' by default).
	mongo $MONGODB_DATABASE --eval "db.addUser({user: '${MONGODB_USERNAME}', pwd: '${MONGODB_PASSWORD}', roles: [ 'readWrite' ]});"
	mongod -f $MONGODB_CONFIG_PATH --shutdown

	# Create a empty file which indicates that the database users were created.
	touch /var/lib/mongodb/data/.mongodb_users_created

	# Check if the MongoDB daemon is down.
	down_test
}

if [ "$1" = "mongod" ]; then

	if ! [[ -v MONGODB_USERNAME && -v MONGODB_PASSWORD && -v MONGODB_DATABASE ]]; then
		usage
	fi

	if [ ! -f /var/lib/mongodb/data/.mongodb_users_created ]; then
		# Create default MongoDB user and administrator.
		create_mongodb_users
	fi

	unset_env_vars

	# Start MongoDB service with enabled database authentication.
	exec mongod -f $MONGODB_CONFIG_PATH --auth
fi

exec "$@"
