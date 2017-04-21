# If user provides own config file use it and do not generate new one
if [ ! -s $MONGODB_CONFIG_PATH ]; then
  # If no configuration is provided use template
  cp ${CONTAINER_SCRIPTS_PATH}/mongodb.conf.template $MONGODB_CONFIG_PATH
fi
[ -r "${APP_DATA}/mongodb-cfg/mongod.conf" ] && MONGODB_CONFIG_PATH="${APP_DATA}/mongodb-cfg/mongod.conf"

# Substitute environment variables in configuration file
TEMP=`mktemp`; cp ${MONGODB_CONFIG_PATH} $TEMP; envsubst > ${MONGODB_CONFIG_PATH} < $TEMP

mongo_common_args+="-f ${MONGODB_CONFIG_PATH}"
