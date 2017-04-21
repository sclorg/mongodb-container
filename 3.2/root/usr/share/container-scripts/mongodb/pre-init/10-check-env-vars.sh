# check_env_vars checks environment variables
# if variables to create non-admin user are provided, sets CREATE_USER=1
# if MEMBER_ID variable is set, checks also replication variables
function check_env_vars() {
  local readonly database_regex='^[^/\. "$]*$'

  [[ -v MONGODB_ADMIN_PASSWORD ]] || usage "MONGODB_ADMIN_PASSWORD has to be set."

  if [[ -v MONGODB_USER || -v MONGODB_PASSWORD || -v MONGODB_DATABASE ]]; then
    [[ -v MONGODB_USER && -v MONGODB_PASSWORD && -v MONGODB_DATABASE ]] || usage "You have to set all or none of variables: MONGODB_USER, MONGODB_PASSWORD, MONGODB_DATABASE"

    [[ "${MONGODB_DATABASE}" =~ $database_regex ]] || usage "Database name must match regex: $database_regex"
    [ ${#MONGODB_DATABASE} -le 63 ] || usage "Database name too long (maximum 63 characters)"

    export CREATE_USER=1
  fi

  if [[ -v MEMBER_ID ]]; then
    [[ -v MONGODB_KEYFILE_VALUE && -v MONGODB_REPLICA_NAME ]] || usage "MONGODB_KEYFILE_VALUE and MONGODB_REPLICA_NAME have to be set"
  fi
}

# Can export CREATE_USER=1 to indicate that variables for optional user
# are provided
check_env_vars
