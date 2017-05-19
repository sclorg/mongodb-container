#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# insert_and_wait_for_replication insert data in host and wait all replset members
# applied recent oplog entry
function insert_and_wait_for_replication() {
  local host
  host=$1
  local data
  data=$2

  # Storing document into replset and wait replication to finish
  local script
  script="db.getSiblingDB('test_db').data.insert(${data});
    for (var i = 0; i < 60; i++) {
      var status=rs.status();
      var optime=status.members[0].optime;
      var ok=true;
      for(var j=1; j < status.members.length; j++) {
        if(tojson(optime) != tojson(status.members[j].optime)) {
          ok=false;
        }
      };
      if(ok == true) {
        print('INFO: All members of replicaset are synchronized');
        quit(0);
      }
      sleep(1000);
    }
    print('ERROR: Members of replicaset are not synchronized');
    printjson(rs.status());
    quit(1);"

  mongo admin --host "${host}" -u admin -p "${MONGODB_ADMIN_PASSWORD}" --eval "${script}"
}

# wait_replicaset_members waits till replset has specified number of members
function wait_replicaset_members() {
  local host
  host=$1
  local count
  count=$2

  local script
  script="for (var i = 0; i < 60; i++) {
    var ret = rs.status().members.length;
    if (ret == ${count}) {
      print('INFO: Replicaset has expected number of members');
      quit(0);
    }
    sleep(1000);
  }
  print('ERROR: Wrong count of members in replicaset');
  printjson(rs.status());
  quit(1);"

  mongo admin --host "${host}" -u admin -p "${MONGODB_ADMIN_PASSWORD}" --eval "${script}"
}
