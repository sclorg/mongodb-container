# This file sets some basic mongod variables and checks mandatory variables

# mongod config file
export mongod_config_file="/etc/mongod.conf"

# Get options from config file
dbpath=$(get_option "dbpath" ${mongod_config_file})
export dbpath=${dbpath:-$HOME/data}

# Get used port
port=$(get_port ${mongod_config_file})
export port=${port:-27017}

# Add default config file
export mongod_common_args+="-f ${mongod_config_file} "



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
}


# Update config files
if [[ -n "${MONGODB_NOPREALLOC:-}" ]]; then
  update_option noprealloc ${MONGODB_NOPREALLOC} ${mongod_config_file}
fi

if [[ -n "${MONGODB_SMALLFILES:-}" ]]; then
  update_option smallfiles ${MONGODB_SMALLFILES} ${mongod_config_file}
fi

if [[ -n "${MONGODB_QUIET:-}" ]]; then
  update_option quiet ${MONGODB_QUIET} ${mongod_config_file}
fi

# Check compulsory variables
if [[ -z "${MONGODB_USER:-}" || -z "${MONGODB_PASSWORD:-}" || -z "${MONGODB_DATABASE:-}" || -z "${MONGODB_ADMIN_PASSWORD:-}" ]]; then
  # Print container-usage and exit
  usage
  exit 1
fi
