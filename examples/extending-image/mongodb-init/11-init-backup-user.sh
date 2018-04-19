# Create backup user

js_command="db.createUser({user: '${MONGODB_BACKUP_USER}', pwd: '${MONGODB_BACKUP_PASSWORD}', roles: [ 'readAnyDatabase' ]});"
if ! mongo admin -u admin -p$MONGODB_ADMIN_PASSWORD --eval "${js_command}"; then
  echo >&2 "=> Failed to create MongoDB user: ${MONGODB_BACKUP_USER}"
  exit 1
fi
