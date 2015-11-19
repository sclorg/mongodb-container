# Print container usage
function usage() {
  echo "You must specify the following environment variables:"
  echo "  MONGODB_REPLICA_NAME"
  echo "  MONGODB_KEYFILE_VALUE"
  echo "Optional variables:"
  echo "  MONGODB_SERVICE_NAME (default: mongodb)"
  echo "MongoDB settings:"
  echo "  MONGODB_NOPREALLOC (default: true)"
  echo "  MONGODB_SMALLFILES (default: true)"
  echo "  MONGODB_QUIET (default: true)"
  exit 1
}


# Update config files
if [ -n "${MONGODB_NOPREALLOC:-}" ]; then
  update_option noprealloc $MONGODB_NOPREALLOC $mongod_config_file
fi

if [ -n "${MONGODB_SMALLFILES:-}" ]; then
  update_option smallfiles $MONGODB_SMALLFILES $mongod_config_file
fi

if [ -n "${MONGODB_QUIET:-}" ]; then
  update_option quiet $MONGODB_QUIET $mongod_config_file
fi

# Check compulsory variables
if [ -z "${MONGODB_REPLICA_NAME:-}" -o -z "${MONGODB_KEYFILE_VALUE:-}" ]; then
  # Print container-usage and exit
  usage
  exit 1
fi

# Cache container IP address
cache_container_addr

# Add parameters for replication
mongod_common_args+=" --oplogSize 64 --replSet ${MONGODB_REPLICA_NAME} "

# Set replication variables
MONGODB_KEYFILE_PATH=/var/lib/mongodb/keyfile
MONGODB_SERVICE_NAME=${MONGODB_SERVICE_NAME:-mongodb}

# Setup keyfile
setup_keyfile
mongod_common_args+=" --keyFile ${MONGODB_KEYFILE_PATH}"
