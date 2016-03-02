# mongod config file
export mongod_config_file="/etc/mongod.conf"

# Get options from config file
dbpath=$(get_option "dbpath" $mongod_config_file)
export dbpath=${dbpath:-$HOME/data}

# Get used port
port=$(get_port $mongod_config_file)
export port=${port:-27017}

# Add default config file
mongod_common_args+="-f $mongod_config_file "



# Print container usage
function usage() {
  echo "You must specify the following environment variables:"
  echo "  MONGODB_USER"
  echo "  MONGODB_PASSWORD"
  echo "  MONGODB_DATABASE"
  echo "  MONGODB_ADMIN_PASSWORD"
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
if [ -z "${MONGODB_USER:-}" -o -z "${MONGODB_PASSWORD:-}" -o -z "${MONGODB_DATABASE:-}" -o -z "${MONGODB_ADMIN_PASSWORD:-}" ]; then
  # Print container-usage and exit
  usage
  exit 1
fi
