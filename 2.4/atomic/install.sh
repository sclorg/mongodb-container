#!/bin/sh

. /usr/share/cont-layer/mongodb/atomic/include.sh

# Make Data Dirs
mkdir -p ${HOST}/${CONFDIR} ${HOST}/${LOGDIR} ${HOST}/${DATADIR}

chown -R mongodb.mongodb "${HOST}/${DATADIR}"
chmod -R 770 "${HOST}/${DATADIR}"

# Install mongod.conf
cp /var/lib/mongodb/mongodb.conf ${HOST}/${CONFDIR}/mongod.conf
echo "logpath=/var/opt/rh/rh-mongodb26/lib/mongodb/mongod.log" >> ${HOST}/${CONFDIR}/mongod.conf

# create container on host
chroot ${HOST} /usr/bin/docker create -v ${DATADIR}:/var/lib/mongodb/data:Z -v ${CONFDIR}/mongod.conf:/etc/mongod.conf -v ${LOGDIR}:/var/opt/rh/rh-mongodb26/log/mongodb --name ${NAME} ${OPT1} ${IMAGE}

# Create and enable systemd unit file for the service
sed -e "s/TEMPLATE/${NAME}/g" /usr/share/cont-layer/mongodb/atomic/template.service > ${HOST}/etc/systemd/system/${NAME}.service
chroot ${HOST} /usr/bin/systemctl enable /etc/systemd/system/${NAME}.service

