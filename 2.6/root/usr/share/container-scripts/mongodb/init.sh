# Source used functions
source ${CONTAINER_SCRIPTS_PATH}/init-functions.sh

mongo_local_args=""

if [ ! -f $dbpath/.mongodb_datadir_initialized  ]; then
  # Create admin user
  if [ -n "${MONGODB_ADMIN_PASSWORD}" ]; then
    # Create admin user
    mongo_create_admin

    # To indicate that database have beed initialized (users are created in it)
    touch $dbpath/.mongodb_datadir_initialized

    # Define credentials
    mongo_local_args+="-u admin -p ${MONGODB_ADMIN_PASSWORD} "
  fi

  # Create specified database user
  if [ -n "${MONGODB_USER}" -a -n "${MONGODB_PASSWORD}" -a -n "${MONGODB_DATABASE}" ]; then
    # Create database user
    mongo_create_user "$mongo_local_args"

    # To indicate that database have beed initialized (users are created in it)
    touch $dbpath/.mongodb_datadir_initialized
  fi
else
  # Ensure passwords match environment variables
  mongo_reset_passwords
fi

if [ -f $dbpath/.mongodb_datadir_initialized ]; then
  # Enable auth
  mongod_common_args+="--auth "
fi
