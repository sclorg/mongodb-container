#!/usr/bin/env bash

function setUpMbaasDB(){
  echo "=> setting up fh-mbaas db .. ";
  # exit if user exists
  local js_command="db.system.users.count({'user':'${MONGODB_FHMBAAS_USER}'})"
  if [ "$(mongo admin --quiet --eval "$js_command")" == "1" ]; then
    echo "=> ${MONGODB_FHMBAAS_USER} user is already created. No action taken"
  else
    js_command="db.getSiblingDB('${MONGODB_FHMBAAS_DATABASE}').createUser({user: '${MONGODB_FHMBAAS_USER}', pwd: '${MONGODB_FHMBAAS_PASSWORD}', roles: [ 'readWrite' ]})"
    if ! mongo admin ${1:-} --host ${2:-"localhost"} --eval "${js_command}"; then
      echo "=> Failed to create MongoDB user: ${MONGODB_FHMBAAS_USER}"
      exit 1
    fi
  fi
}


function setUpReporting(){
  echo "=> setting up fh-reporting db.. ";

  # exit if user exists
  local js_command="db.system.users.count({'user':'${MONGODB_FHREPORTING_USER}'})"
  if [ "$(mongo admin --quiet --eval "$js_command")" == "1" ]; then
    echo "=> ${MONGODB_FHREPORTING_USER} user is already created. No action taken"
  else
    js_command="db.getSiblingDB('${MONGODB_FHREPORTING_DATABASE}').createUser({user: '${MONGODB_FHREPORTING_USER}', pwd: '${MONGODB_FHREPORTING_PASSWORD}', roles: [ 'readWrite' ]})"
    if ! mongo admin ${1:-} --host ${2:-"localhost"} --eval "${js_command}"; then
      echo "=> Failed to create MongoDB user: ${MONGODB_FHREPORTING_USER}"
      exit 1
    fi
  fi
}

function setUpMetrics(){
  echo "=> setting up fh-metrics db.. ";

  # exit if user exists
  local js_command="db.system.users.count({'user':'${MONGODB_FHMETRICS_USER}'})"
  if [ "$(mongo admin --quiet --eval "$js_command")" == "1" ]; then
    echo "=> ${MONGODB_FHMETRICS_USER} user is already created. No action taken"
  else
    js_command="db.getSiblingDB('${MONGODB_FHMETRICS_DATABASE}').createUser({user: '${MONGODB_FHMETRICS_USER}', pwd: '${MONGODB_FHMETRICS_PASSWORD}', roles: [ 'readWrite' ]})"
    if ! mongo admin ${1:-} --host ${2:-"localhost"} --eval "${js_command}"; then
      echo "=> Failed to create MongoDB user: ${MONGODB_FHMETRICS_USER}"
      exit 1
    fi
  fi
}

function setUpAAA(){
  echo "=> setting up fh-aaa db.. ";

  # exit if user exists
  local js_command="db.system.users.count({'user':'${MONGODB_FHAAA_USER}'})"
  if [ "$(mongo admin --quiet --eval "$js_command")" == "1" ]; then
    echo "=> ${MONGODB_FHAAA_USER} user is already created. No action taken"
  else
    js_command="db.getSiblingDB('${MONGODB_FHAAA_DATABASE}').createUser({user: '${MONGODB_FHAAA_USER}', pwd: '${MONGODB_FHAAA_PASSWORD}', roles: [ 'readWrite' ]})"
    if ! mongo admin ${1:-} --host ${2:-"localhost"} --eval "${js_command}"; then
      echo "=> Failed to create MongoDB user: ${MONGODB_FHAAA_USER}"
      exit 1
    fi
  fi
}

function setUpSupercore(){
  echo "=> setting up fh-SUPERCORE db.. ";

  # exit if user exists
  local js_command="db.system.users.count({'user':'${MONGODB_FHSUPERCORE_USER}'})"
  if [ "$(mongo admin --quiet --eval "$js_command")" == "1" ]; then
    echo "=> ${MONGODB_FHSUPERCORE_USER} user is already created. No action taken"
  else
    js_command="db.getSiblingDB('${MONGODB_FHSUPERCORE_DATABASE}').createUser({user: '${MONGODB_FHSUPERCORE_USER}', pwd: '${MONGODB_FHSUPERCORE_PASSWORD}', roles: [ 'readWrite' ]})"
    if ! mongo admin ${1:-} --host ${2:-"localhost"} --eval "${js_command}"; then
      echo "=> Failed to create MongoDB user: ${MONGODB_FHSUPERCORE_USER}"
      exit 1
    fi
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

  if [[ -v MONGODB_FHAAA_DATABASE && -v MONGODB_FHAAA_USER && -v MONGODB_FHAAA_PASSWORD ]]
  then
      setUpAAA "$@"
  fi

  if [[ -v MONGODB_FHSUPERCORE_DATABASE && -v MONGODB_FHSUPERCORE_USER && -v MONGODB_FHSUPERCORE_PASSWORD ]]
  then
      setUpSupercore "$@"
  fi
}
