# mongo_create_admin creates the MongoDB admin user with password: MONGODB_ADMIN_PASSWORD
# $1 - login parameters for mongo (optional)
# $2 - host where to connect (localhost by default)
function mongo_create_admin() {
  if [[ -z "${MONGODB_ADMIN_PASSWORD:-}" ]]; then
    echo >&2 "=> MONGODB_ADMIN_PASSWORD is not set. Authentication can not be set up."
    exit 1
  fi

  # Set admin password
  local js_command="db.createUser({user: 'admin', pwd: '${MONGODB_ADMIN_PASSWORD}', roles: ['dbAdminAnyDatabase', 'userAdminAnyDatabase' , 'readWriteAnyDatabase','clusterAdmin' ]});"

  if ! mongo_cmd --host "localhost" admin ${1:-} <<<"$js_command"; then
    echo >&2 "=> Failed to create MongoDB admin user."
    exit 1
  fi
}

# mongo_create_user creates the MongoDB database user: MONGODB_USER,
# with password: MONGDOB_PASSWORD, inside database: MONGODB_DATABASE
# $1 - login parameters for mongo (optional)
# $2 - host where to connect (localhost by default)
function mongo_create_user() {
  # Ensure input variables exists
  if [[ -z "${MONGODB_USER:-}" ]]; then
    echo >&2 "=> MONGODB_USER is not set. Failed to create MongoDB user"
    exit 1
  fi
  if [[ -z "${MONGODB_PASSWORD:-}" ]]; then
    echo "=> MONGODB_PASSWORD is not set. Failed to create MongoDB user: ${MONGODB_USER}"
    exit >&2 1
  fi
  if [[ -z "${MONGODB_DATABASE:-}" ]]; then
    echo >&2 "=> MONGODB_DATABASE is not set. Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi

  # Create database user
  local js_command="db.getSiblingDB('${MONGODB_DATABASE}').createUser({user: '${MONGODB_USER}', pwd: '${MONGODB_PASSWORD}', roles: [ 'readWrite' ]});"

  if ! mongo_cmd --host "localhost" admin ${1:-} <<<"$js_command"; then
    echo >&2 "=> Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi
}

# mongo_reset_user sets the MongoDB MONGODB_USER's password to match MONGODB_PASSWORD
function mongo_reset_user() {
  if [[ -n "${MONGODB_USER:-}" && -n "${MONGODB_PASSWORD:-}" && -n "${MONGODB_DATABASE:-}" ]]; then
    local js_command="db.changeUserPassword('${MONGODB_USER}', '${MONGODB_PASSWORD}')"
    if ! mongo_cmd --host localhost ${MONGODB_DATABASE} <<<"${js_command}"; then
      echo >&2 "=> Failed to reset password of MongoDB user: ${MONGODB_USER}"
      exit 1
    fi
  fi
}

# mongo_reset_admin sets the MongoDB admin password to match MONGODB_ADMIN_PASSWORD
function mongo_reset_admin() {
  if [[ -n "${MONGODB_ADMIN_PASSWORD:-}" ]]; then
    local js_command="db.changeUserPassword('admin', '${MONGODB_ADMIN_PASSWORD}')"
    if ! mongo_cmd --host localhost admin <<<"${js_command}"; then
      echo >&2 "=> Failed to reset password of MongoDB user: ${MONGODB_USER}"
      exit 1
    fi
  fi
}

# update_users creates default users (see usage)
# if users are already created, updates passwords to match
# environment variables
function update_users() {
  js_command="db.system.users.count({'user':'admin', 'db':'admin'})"
  if [ "$(mongo_cmd --host localhost admin --quiet <<<$js_command)" == "1" ]; then
    info "Admin user is already created. Resetting password ..."
    mongo_reset_admin
  else
    info "Creating MongoDB admin user ..."
    mongo_create_admin
  fi
  if [[ -v CREATE_USER ]]; then
    js_command="db.system.users.count({'user':'${MONGODB_USER}', 'db':'${MONGODB_DATABASE}'})"
    if [ "$(mongo_cmd --host localhost admin --quiet <<<$js_command)" == "1" ]; then
      info "MONGODB_USER user is already created. Resetting password ..."
      mongo_reset_user
    else
      info "Creating MongoDB $MONGODB_USER user ..."
      mongo_create_user
    fi
  fi
}

if ! [[ -v MEMBER_ID ]]; then
  update_users
else
  if [ "${MEMBER_ID}" -eq 0 ]; then
    info "Creating MongoDB users ..."
    mongo_create_admin
    [[ -v CREATE_USER ]] && mongo_create_user "-u admin -p${MONGODB_ADMIN_PASSWORD}"
  fi
fi
