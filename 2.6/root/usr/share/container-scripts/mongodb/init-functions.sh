# mongo_create_admin creates the MongoDB admin user with password: MONGODB_ADMIN_PASSWORD
# $1 - login parameters for mongo (optional)
# $2 - host where to connect (localhost by default)
function mongo_create_admin() {
  if [[ -z "${MONGODB_ADMIN_PASSWORD:-}" ]]; then
    echo "=> MONGODB_ADMIN_PASSWORD is not set. Authentication can not be set up."
    exit 1
  fi

  # Set admin password
  set +e
  mongo admin ${1:-} --host ${2:-"localhost"} --eval "db.createUser({user: 'admin', pwd: '${MONGODB_ADMIN_PASSWORD}', roles: ['dbAdminAnyDatabase', 'userAdminAnyDatabase' , 'readWriteAnyDatabase','clusterAdmin' ]});"
  local result=$?
  set -e

  if [[ ${result} -ne 0 ]]; then
    echo "=> Failed to create MongoDB admin user."
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
    echo "=> MONGODB_USER is not set. Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi
  if [[ -z "${MONGODB_PASSWORD:-}" ]]; then
    echo "=> MONGODB_PASSWORD is not set. Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi
  if [[ -z "${MONGODB_DATABASE:-}" ]]; then
    echo "=> MONGODB_DATABASE is not set. Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi

  # Crate database user
  set +e
  mongo admin ${1:-} --host ${2:-"localhost"} --eval "db.getSiblingDB('${MONGODB_DATABASE}').createUser({user: '${MONGODB_USER}', pwd: '${MONGODB_PASSWORD}', roles: [ 'readWrite' ]});"
  local result=$?
  set -e

  if [[ ${result} -ne 0 ]]; then
    echo "=> Failed to create MongoDB user: ${MONGODB_USER}"
    exit 1
  fi
}

# mongo_reset_passwords sets the MongoDB passwords to match MONGODB_PASSWORD
# and MONGODB_ADMIN_PASSWORD
# $1 - login parameters for mongo (optional)
# $2 - host where to connect (localhost by default)
function mongo_reset_passwords() {
  # Reset password of MONGODB_USER
  if [[ -n "${MONGODB_USER:-}" && -n "${MONGODB_PASSWORD:-}" && -n "${MONGODB_DATABASE:-}" ]]; then
    set +e
    mongo ${MONGODB_DATABASE} ${1:-} --host ${2:-"localhost"} --eval "db.changeUserPassword('${MONGODB_USER}', '${MONGODB_PASSWORD}')"
    local result=$?
    set -e

    if [[ ${result} -ne 0 ]]; then
      echo "=> Failed to reset password of MongoDB user: ${MONGODB_USER}"
      exit 1
    fi
  fi

  # Reset password of admin
  if [[ -n "${MONGODB_ADMIN_PASSWORD:-}" ]]; then
    set +e
    mongo admin --eval "db.changeUserPassword('admin', '${MONGODB_ADMIN_PASSWORD}')"
    local result=$?
    set -e

    if [[ ${result} -ne 0 ]]; then
      echo "=> Failed to reset password of MongoDB user: ${MONGODB_USER}"
      exit 1
    fi
  fi
}
