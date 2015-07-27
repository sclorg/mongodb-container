#!/bin/sh

. /usr/share/cont-layer/mongodb/atomic/include.sh

chroot ${HOST} /usr/bin/systemctl disable ${NAME}.service
chroot ${HOST} /usr/bin/systemctl stop ${NAME}.service
rm -f ${HOST}/etc/systemd/system/${NAME}.service

# Remove config file
rm -f ${HOST}/${CONFDIR}/mongod.conf
