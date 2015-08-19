# OpenShift specific configuration

if [ -n "$MONGODB_NOPREALLOC" ]; then
  update_option noprealloc $MONGODB_NOPREALLOC $mongod_config_file
fi

if [ -n "$MONGODB_SMALLFILES" ]; then
  update_option smallfiles $MONGODB_SMALLFILES $mongod_config_file
fi

if [ -n "$MONGODB_QUIET" ]; then
  update_option quiet $MONGODB_QUIET $mongod_config_file
  update_option quiet $MONGODB_QUIET $mongos_config_file
fi

if [ -z "${MONGODB_USER}" -o -z "${MONGODB_PASSWORD}" -o -z "${MONGODB_DATABASE}" -o -z "${MONGODB_ADMIN_PASSWORD}" ] && ( [ -z ${MONGODB_REPLICA_NAME} ] || [ -n "${MONGODB_REPLICA_NAME}" -a -n "${MONGODB_REPLICA_INIT}" ]); then
  # Print container-usage and exit
  container-usage
  exit 1
fi
