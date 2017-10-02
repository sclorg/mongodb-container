# Check whether all required variables are set
if ! [ -v NAME -a -v IMAGE -a -v HOST ] ; then
  echo "Environment variables NAME, IMAGE and HOST must be set."
  exit 1
fi

# Define well-known directories and names on the host
DATADIR=${DATADIR:-/var/lib/${NAME}}
CONFDIR=${CONFDIR:-/etc/${NAME}}
LOGDIR=${LOGDIR:-/var/log/${NAME}}

