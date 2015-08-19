# mongo_create_admin creates the MongoDB admin user with password: MONGODB_ADMIN_PASSWORD
function mongo_create_admin() {
  if [ -z "${MONGODB_ADMIN_PASSWORD}" ]; then
    echo "=> MONGODB_ADMIN_PASSWORD is not set. Authentication can not be set up."
    exit 1
  fi

  # Set admin password
  set +e
  mongo admin --eval "db.createUser({user: 'admin', pwd: '${MONGODB_ADMIN_PASSWORD}', roles: ['dbAdminAnyDatabase', 'userAdminAnyDatabase' , 'readWriteAnyDatabase','clusterAdmin' ]});"
  result=$?
  set -e

  if [ $result -ne 0 ]; then
    echo "=> Failed to create MongoDB admin user."
    exit 1
  fi
}

# mongo_create_user creates the MongoDB database user: MONGODB_USER, with password: MONGDOB_PASSWORD, inside database: MONGODB_DATABASE
# $1 contains information for mongo shell where and how to connect
function mongo_create_user() {
  # Ensure input variables exists
  if [ -z "${MONGODB_USER}" ]; then
    echo "=> MONGODB_USER is not set. Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi
  if [ -z "${MONGODB_PASSWORD}" ]; then
    echo "=> MONGODB_PASSWORD is not set. Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi
  if [ -z "${MONGODB_DATABASE}" ]; then
    echo "=> MONGODB_DATABASE is not set. Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi

  # Crate database user
  set +e
  mongo ${1} --eval "db.getSiblingDB('${MONGODB_DATABASE}').createUser({user: '${MONGODB_USER}', pwd: '${MONGODB_PASSWORD}', roles: [ 'readWrite' ]});"
  result=$?
  set -e

  if [ $result -ne 0 ]; then
    echo "=> Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi
}

dbpath=${dbpath:-$HOME/data}

if [ ! -f $dbpath/.mongodb_datadir_initialized  ]; then
  # Create admin user
  if [ -n "${MONGODB_ADMIN_PASSWORD}" ]; then
    # Create admin user
    mongo_create_admin

    # To indicate that database have beed initialized (users are created in it)
    touch $dbpath/.mongodb_datadir_initialized

    # Define credentials
    mongo_local_args+="admin -u admin -p ${MONGODB_ADMIN_PASSWORD} "
  fi

  # Create specified database user
  if [ -n "${MONGODB_USER}" -a -n "${MONGODB_PASSWORD}" -a -n "${MONGODB_DATABASE}" ]; then
    # Create database user
    mongo_create_user "$mongo_local_args"

    # To indicate that database have beed initialized (users are created in it)
    touch $dbpath/.mongodb_datadir_initialized
  fi

  if [ -f $dbpath/.mongodb_datadir_initialized ]; then
    # Enable auth
    mongod_common_args+="--auth "
  fi
else
  echo "=> Database directory is already initialized. Skipping creation of users ..."
fi
