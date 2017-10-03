# setup_default_datadir checks permissions of mounded directory into default
# data directory MONGODB_DATADIR
function setup_default_datadir() {
  if [ ! -w "$MONGODB_DATADIR" ]; then
    echo >&2 "ERROR: Couldn't write into ${MONGODB_DATADIR}"
    echo >&2 "CAUSE: current user doesn't have permissions for writing to ${MONGODB_DATADIR} directory"
    echo >&2 "DETAILS: current user id = $(id -u), user groups: $(id -G)"
    echo >&2 "DETAILS: directory permissions: $(stat -c '%A owned by %u:%g, SELinux: %C' "${MONGODB_DATADIR}")"
    exit 1
  fi
}

setup_default_datadir
