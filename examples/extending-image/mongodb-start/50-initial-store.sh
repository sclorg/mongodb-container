# Store some initial information into database

# Connect database as optional user
mongo $MONGODB_DATABASE -u $MONGODB_USER -p$MONGODB_PASSWORD --eval "db.constants.insert({author: \"sclorg@redhat.com\"})"

# Connect database as admin user
mongo admin -u admin -p$MONGODB_ADMIN_PASSWORD --eval "db.getSiblingDB(\"$MONGODB_DATABASE\").constants.insert({subject: \"s2i build example\"})"
