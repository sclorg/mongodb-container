# MongoDB Replica Set example

**WARNING:**

**This is only a Proof-Of-Concept example and it is not ment to be used in any
production. Use at your own risk.**

## What is MongoDB Replica Set?

A cluster of MongoDB servers that implements master-slave replication and automated failover.
MongoDB’s recommended replication strategy.

## Build Docker image:

* `git clone https://github.com/mfojtik/mongodb && cd mongodb`
* `git checkout replica`
* `cd ./2.4 && docker build -t openshift/mongodb-24-centos7:replica .`

## Deployment:

In order to run this Docker image, you need to have the latest version of
OpenShift Origin v3.

* `openshift start --latest-images &> server.log &`
* `osc create -f ./2.4/examples/replica/mongo_controller.json`

## How does it work?

The MongoDB replication controller is set to **1** in this example. Once the Pod
with MongoDB is started, the replica set is initialized (`rs.initiate()`)
and the Pod is elected as the 'master' (as there are no other MongoDB Pods
running, yet).

If you want to add new node to MongoDB replica set, bump the value of 'replicas'
in the Kubernetes Replication Contoller to '2'.
Kubernetes will then launch a new Pod with MongoDB. This time, the MongoDB will
see the existing service endpoint and instead of initializing the new replica
set, it will advertise itself to the other endpoint(s).

The list of endpoints is obtained by the `dig mongodb A +search +short` command.
Since we instructed OpenShift to create the 'headless' Service (`portalIP:
'None'`) we don't need to query the IP addresses but rather use DNS sub-system.

To bump the number of replicas in the Replication Controller, you can use
following command:

```
$ osc update rc mongodb --patch='{ "apiVersion": "v1beta1", "desiredState": { "replicas": 2 }}'
```

## How to test it?

You can play with the number of replicas in the Replication Controller. Use the
command above and change the number of replicas as you want. You can tail the
logs from one of the replica members and see how the new replSet members are
added and removed automatically. The `docker ps` and `docker exec` are your
friends.

## Known issues/bugs/todo:

* Authentication is currently disabled (need to use keyfile instead of
  passwords...)
* Setting the initial number of replicas to >1 will cause race condition
* Stepping the replica number by more than 1 cause the same (most likely)
