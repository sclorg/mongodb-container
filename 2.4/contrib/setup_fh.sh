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

