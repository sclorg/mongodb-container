# Wait until everything is properly replicated - before exiting PRIMARY

if [ -n "$MONGODB_REPLICA_INIT" ]; then
  echo "=> Waiting for replication to finish"
  mongo ${mongo_local_args} --eval "var ok=false;while(!ok){ var members=rs.status().members; ok=true; for(i=0;i<members.length;i++){ ok &= (members[0].optime.t == members[i].optime.t && members[0].optime.i == members[i].optime.i) } };"

fi
