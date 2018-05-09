# Store some initial information into database

# Connect database as optional user
mongo_cmd --host localhost $MONGODB_DATABASE -u $MONGODB_USER -p$MONGODB_PASSWORD <<<"db.constants.insert({author: \"sclorg@redhat.com\"})"

# Connect database as admin user
mongo_cmd --host localhost admin -u admin -p$MONGODB_ADMIN_PASSWORD <<<"db.getSiblingDB(\"$MONGODB_DATABASE\").constants.insert({subject: \"s2i build example\"})"
