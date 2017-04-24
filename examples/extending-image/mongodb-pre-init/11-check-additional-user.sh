# Check that user credentials for backup is set

[[ -v MONGODB_BACKUP_USER && -v MONGODB_BACKUP_PASSWORD ]] || usage "You have to set all variables for user for doing backup: MONGODB_BACKUP_USER, MONGODB_BACKUP_PASSWORD"
