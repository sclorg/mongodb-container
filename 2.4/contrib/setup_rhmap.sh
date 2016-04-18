#!/usr/bin/env bash

function setUpMbaasDB(){
  echo "=> setting up fh-mbaas db .. ";
  mongo ${MONGODB_FHMBAAS_DATABASE} --eval \
        "db.addUser({user: '${MONGODB_FHMBAAS_USER}', pwd: '${MONGODB_FHMBAAS_PASSWORD}', roles: [ 'readWrite' ]})"
}


function setUpReporting(){
  echo "=> setting up fh-reporting db.. ";
  mongo ${MONGODB_FHREPORTING_DATABASE} --eval \
        "db.addUser({user: '${MONGODB_FHREPORTING_USER}', pwd: '${MONGODB_FHREPORTING_PASSWORD}', roles: [ 'readWrite' ]})"
}

function setUpMetrics(){
  echo "=> setting up fh-metrics db.. ";
  mongo ${MONGODB_FHMETRICS_DATABASE} --eval \
        "db.addUser({user: '${MONGODB_FHMETRICS_USER}', pwd: '${MONGODB_FHMETRICS_PASSWORD}', roles: [ 'readWrite' ]})"
}

function setUpDatabases(){
  echo "=> setting up RHMAP databases";
  if [[ -v MONGODB_FHMBAAS_DATABASE && -v MONGODB_FHMBAAS_USER && -v MONGODB_FHMBAAS_PASSWORD ]]
  then
      setUpMbaasDB
  fi

  if [[ -v MONGODB_FHREPORTING_DATABASE  && -v MONGODB_FHREPORTING_USER && -v MONGODB_FHREPORTING_PASSWORD ]]
  then
      setUpReporting
  fi

  if [[ -v MONGODB_FHMETRICS_DATABASE  && -v MONGODB_FHMETRICS_USER && -v MONGODB_FHMETRICS_PASSWORD ]]
  then
      setUpMetrics
  fi

  mongo admin --eval "db.addUser({user: 'admin', pwd: '${MONGODB_ADMIN_PASSWORD}', roles: ['dbAdminAnyDatabase', 'userAdminAnyDatabase' , 'readWriteAnyDatabase','clusterAdmin' ]})"

  touch /var/lib/mongodb/data/.mongodb_datadir_initialized
}
