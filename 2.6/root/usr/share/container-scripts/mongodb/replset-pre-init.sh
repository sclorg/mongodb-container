# Add parameters for replication
mongod_common_args+=" --oplogSize 64 --replSet ${MONGODB_REPLICA_NAME} "

# Set replication variables
MONGODB_KEYFILE_PATH=/var/lib/mongodb/keyfile
MONGODB_SERVICE_NAME=${MONGODB_SERVICE_NAME:-mongodb}

# Setup keyfile
setup_keyfile
mongod_common_args+=" --keyFile ${MONGODB_KEYFILE_PATH}"



# Print container usage
function usage() {
  echo "You must specify the following environment variables:"
  echo "  MONGODB_REPLICA_NAME"
  echo "  MONGODB_KEYFILE_VALUE"
  echo "Optional variables:"
  echo "  MONGODB_SERVICE_NAME (default: mongodb)"
  exit 1
}


# Check compulsory variables
if [ -z "${MONGODB_REPLICA_NAME:-}" -o -z "${MONGODB_KEYFILE_VALUE:-}" ]; then
  # Print container-usage and exit
  usage
  exit 1
fi

# Cache container IP address
cache_container_addr
