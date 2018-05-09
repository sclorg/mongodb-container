# Create backup user

js_command="db.createUser({user: '${MONGODB_BACKUP_USER}', pwd: '${MONGODB_BACKUP_PASSWORD}', roles: [ 'readAnyDatabase' ]});"

if ! mongo_cmd --host localhost admin -u admin -p$MONGODB_ADMIN_PASSWORD <<<"$js_command" ; then
  echo >&2 "=> Failed to create MongoDB user: ${MONGODB_BACKUP_USER}"
  exit 1
fi
