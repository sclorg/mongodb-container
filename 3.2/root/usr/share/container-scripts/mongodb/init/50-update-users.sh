# update_users creates default users (see usage)
# if users are already created, updates passwords to match
# environment variables
function update_users() {
  js_command="db.system.users.count({'user':'admin', 'db':'admin'})"
  if [ "$(mongo admin --quiet --eval "$js_command")" == "1" ]; then
    echo "=> Admin user is already created. Resetting password ..."
    mongo_reset_admin
  else
    mongo_create_admin
  fi
  if [[ -v CREATE_USER ]]; then
    js_command="db.system.users.count({'user':'${MONGODB_USER}', 'db':'${MONGODB_DATABASE}'})"
    if [ "$(mongo admin --quiet --eval "$js_command")" == "1" ]; then
      echo "=> MONGODB_USER user is already created. Resetting password ..."
      mongo_reset_user
    else
      mongo_create_user
    fi
  fi
}

if ! [[ -v REPLICATION ]]; then
  update_users
fi
