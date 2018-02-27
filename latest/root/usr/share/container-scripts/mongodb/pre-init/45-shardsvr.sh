if [[ "$MONGODB_MODE" == shardsvr ]]; then
  mongo_common_args+=" --shardsvr"
fi
