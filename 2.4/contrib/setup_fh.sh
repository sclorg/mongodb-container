#!/usr/bin/env bash
source /var/lib/mongodb/common.sh



function setUpMbaasDB(){
  echo "=> setting up fh-mbaas db .. ";
  export MONGODB_DATABASE="fh-mbaas";
  export MONGODB_USER="u-mbaas" #todo bring in from env FH_MBAAS_DB_USER
  export MONGODB_PASSWORD="password" #todo bring in from env FH_MBAAS_DB_PASS
  mongo_create_users
}


function setUpReporting(){
  echo "=> setting up fh-reporting db.. ";
  export MONGODB_DATABASE="fh-reporting";
  export MONGODB_USER="u-reports" #todo bring in from env
  export MONGODB_PASSWORD="password" #todo bring in from env
  mongo_create_users
}

