#!/usr/bin/env bash

function setUpMbaasDB(){
  echo "=> setting up fh-mbaas db .. ";
  local js_command="db.getSiblingDB('${MONGODB_FHMBAAS_DATABASE}').createUser({user: '${MONGODB_FHMBAAS_USER}', pwd: '${MONGODB_FHMBAAS_PASSWORD}', roles: [ 'readWrite' ]})"
  if ! mongo admin ${1:-} --host ${2:-"localhost"} --eval "${js_command}"; then
      echo "=> Failed to create MongoDB user: ${MONGODB_FHMBAAS_USER}"
      exit 1
  fi
}


function setUpReporting(){
  echo "=> setting up fh-reporting db.. ";
  local js_command="db.getSiblingDB('${MONGODB_FHREPORTING_DATABASE}').createUser({user: '${MONGODB_FHREPORTING_USER}', pwd: '${MONGODB_FHREPORTING_PASSWORD}', roles: [ 'readWrite' ]})"
  if ! mongo admin ${1:-} --host ${2:-"localhost"} --eval "${js_command}"; then
      echo "=> Failed to create MongoDB user: ${MONGODB_FHREPORTING_USER}"
      exit 1
  fi
}

function setUpMetrics(){
  echo "=> setting up fh-metrics db.. ";
  local js_command="db.getSiblingDB('${MONGODB_FHMETRICS_DATABASE}').createUser({user: '${MONGODB_FHMETRICS_USER}', pwd: '${MONGODB_FHMETRICS_PASSWORD}', roles: [ 'readWrite' ]})"
  if ! mongo admin ${1:-} --host ${2:-"localhost"} --eval "${js_command}"; then
      echo "=> Failed to create MongoDB user: ${MONGODB_FHMETRICS_USER}"
      exit 1
  fi
}

function setUpDatabases(){
  echo "=> setting up RHMAP databases";
  if [[ -v MONGODB_FHMBAAS_DATABASE && -v MONGODB_FHMBAAS_USER && -v MONGODB_FHMBAAS_PASSWORD ]]
  then
      setUpMbaasDB "$@"
  fi

  if [[ -v MONGODB_FHREPORTING_DATABASE  && -v MONGODB_FHREPORTING_USER && -v MONGODB_FHREPORTING_PASSWORD ]]
  then
      setUpReporting "$@"
  fi

  if [[ -v MONGODB_FHMETRICS_DATABASE  && -v MONGODB_FHMETRICS_USER && -v MONGODB_FHMETRICS_PASSWORD ]]
  then
      setUpMetrics "$@"
  fi
}
