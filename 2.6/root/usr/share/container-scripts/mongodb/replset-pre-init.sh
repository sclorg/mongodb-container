# This file sets some basic mongod replication variables and checks mandatory replication variables

# Print container usage
function usage() {
  echo "You must specify the following environment variables:"
  echo "  MONGODB_REPLICA_NAME"
  echo "  MONGODB_KEYFILE_VALUE"
  echo "Optional variables:"
  echo "  MONGODB_SERVICE_NAME (default: mongodb)"
}


# Check compulsory variables
if [[ -z "${MONGODB_REPLICA_NAME:-}" || -z "${MONGODB_KEYFILE_VALUE:-}" ]]; then
  # Print container-usage and exit
  usage
  exit 1
fi



# Add parameters for replication
export mongod_common_args+=" --oplogSize 64 --replSet ${MONGODB_REPLICA_NAME} "

# Set replication variables
MONGODB_KEYFILE_PATH=/var/lib/mongodb/keyfile
MONGODB_SERVICE_NAME=${MONGODB_SERVICE_NAME:-mongodb}

# Setup keyfile
setup_keyfile
export mongod_common_args+=" --keyFile ${MONGODB_KEYFILE_PATH}"

# Cache container IP address
cache_container_addr
