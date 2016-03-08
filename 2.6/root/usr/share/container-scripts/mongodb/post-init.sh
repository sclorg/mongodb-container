# This file prepares environment before mongod exec

# Make sure env variables don't propagate to mongod process
unset MONGODB_USER MONGODB_PASSWORD MONGODB_DATABASE MONGODB_ADMIN_PASSWORD
