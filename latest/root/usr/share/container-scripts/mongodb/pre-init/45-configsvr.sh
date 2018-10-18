if [[ "$MONGODB_MODE" == configsvr ]]; then
  mongo_common_args+=" --configsvr"
fi
