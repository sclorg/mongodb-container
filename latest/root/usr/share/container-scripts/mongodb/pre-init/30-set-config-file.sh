MONGODB_CONFIG=${MONGODB_CONFIG_PATH##*/}

# If user provides own config file use it and do not generate new one
if [ ! -s $MONGODB_CONFIG_PATH ]; then
  # If no configuration is provided use template
  cp ${CONTAINER_SCRIPTS_PATH}/$MONGODB_CONFIG.template $MONGODB_CONFIG_PATH
fi
[ -r "${APP_DATA}/mongodb-cfg/$MONGODB_CONFIG" ] && cp "${APP_DATA}/mongodb-cfg/$MONGODB_CONFIG" $MONGODB_CONFIG_PATH


# Substitute environment variables in configuration file
TEMP=`mktemp`; cp ${MONGODB_CONFIG_PATH} $TEMP; envsubst > ${MONGODB_CONFIG_PATH} < $TEMP

mongo_common_args+="-f ${MONGODB_CONFIG_PATH}"
