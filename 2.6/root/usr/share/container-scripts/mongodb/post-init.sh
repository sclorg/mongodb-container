# This file unset environmental variables about MongoDB users

# Make sure env variables don't propagate to mongod process.
function unset_env_vars() {
  unset MONGODB_USER MONGODB_PASSWORD MONGODB_DATABASE MONGODB_ADMIN_PASSWORD
}

unset_env_vars
