#!/usr/bin/env bash
source /var/lib/mongodb/common.sh



function setUpMbaasDB(){
  echo "=> setting up fh-mbaas db .. ";
  export MONGODB_DATABASE=${MONGODB_FHMBAAS_DATABASE};
  export MONGODB_USER=${MONGODB_FHMBAAS_USER} #todo bring in from env FH_MBAAS_DB_USER
  export MONGODB_PASSWORD=${MONGODB_FHMBAAS_PASSWORD} #todo bring in from env FH_MBAAS_DB_PASS
  mongo_create_users
}


function setUpReporting(){
  echo "=> setting up fh-reporting db.. ";
  export MONGODB_DATABASE=${MONGODB_FHREPORTING_DATABASE};
  export MONGODB_USER=${MONGODB_FHREPORTING_USER} #todo bring in from env
  export MONGODB_PASSWORD=${MONGODB_FHREPORTING_PASSWORD} #todo bring in from env
  mongo_create_users
}

function setUpMetrics(){
  echo "=> setting up fh-metrics db.. ";
  export MONGODB_DATABASE=${MONGODB_FHMETRICS_DATABASE};
  export MONGODB_USER=${MONGODB_FHMETRICS_USER} #todo bring in from env
  export MONGODB_PASSWORD=${MONGODB_FHMETRICS_PASSWORD} #todo bring in from env
  mongo_create_users
}

function setUpDatabases(){
  echo "=> setting up RHMAP databases";
  if [[ -v MONGODB_FHMBAAS_DATABASE ]]; then
      setUpMbaasDB
  fi
  
  if [[ -v MONGODB_FHREPORTING_DATABASE  ]]; then
      setUpReporting
  fi
  
  if [[ -v MONGODB_FHMETRICS_DATABASE ]]; then
      setUpMetrics
  fi
}