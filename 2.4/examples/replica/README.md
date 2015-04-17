# MongoDB Replica Set example

**WARNING:**

**This is only a Proof-Of-Concept example and it is not ment to be used in any
production. Use at your own risk.**

## What is MongoDB Replica Set?

A cluster of MongoDB servers that implements master-slave replication and automated failover.
MongoDB’s recommended replication strategy.

## Deployment:

In order to run this Docker image, you need to have the latest version of
OpenShift Origin v3.

* `openshift start --latest-images &> server.log &`
* `osc create -f ./2.4/examples/replica/mongo_controller.json`

## How does it work?

### Service 'mongodb'

This resource defines a headless Kubernetes Service that serve as an entrypoint
to the MongoDB cluster. The Service endpoints are the Pods created by the
MongoDB replication controller.
Having 'headless' Service means that the `portalIP` attribute of this Service is
set to `None`. This allows to use DNS queries to discover endpoints of the
service from inside the container, by quering the Service name (eg. `dig mongodb
A +short +search`).

### Secret 'mongo-keyfile'

The Secret resource defines the MongoDB 'keyFile[1](http://docs.mongodb.org/manual/tutorial/generate-key-file)' file that MongoDB members use for authorization internally.
Using keyFile will make the communication more secure.

**WARNING**: The provided `mongo_controller.json` file contains the base64 encoded keyFile, but it is highly recommended to generate your own private file.

### Pod 'mongo-service'

This Pod serves as an replSet initialization member. Inside the
'initiate_replica.sh' command is ran, which will wait for all members created by
the ReplicationController to become available and then creates the initial
MongoDB replica set. This set is then distributed to all members.
This Pod is a 'run-once' Pod, which means that once the replSet is initialized
that the members receive the replication data, this Pod is destroyed.

### ReplicationController 'mongo'

This resource defines the PodTemplate of the MongoDB replica member. Each member
is started as a MongoDB server without replication data. Once the member is up,
the container will advertise this member to the MongoDB replica PRIMARY member
and add it into the cluster.
When this member is removed, the container, before it exits will properly remove
the member from existing MongoDB cluster.

To add/remove more MongoDB pods to replica set you can use following command:

```
$ osc update rc mongo --patch='{ "apiVersion": "v1beta1", "desiredState": { "replicas": 4 }}'
```

The provided `mongo_controller.json` example will start three MongoDB replica by
default.

## Settings and Security

There are few environment variables that users need to set in order to create
the MongoDB replSet:

For the 'mongo-service' Pod, you have to set following variables:

* `MONGODB_REPLICA_NAME` - the name of the replSet (`rs0`).
* `MONGODB_SERVICE_NAME` - the name of the MongoDB Service (used to DNS lookup, default: 'mongodb')
* `MONGODB_ADMIN_PASSWORD` - the password for the 'admin' user.
* `MONGODB_USER` - the name of the regular MongoDB user
* `MONGODB_PASSWORD` - the regular MongoDB user password

For the 'mongo' PodTemplate, you have to set following variables (they have to
match the variables above):

* `MONGODB_REPLICA_NAME`
* `MONGODB_SERVICE_NAME`
* `MONGODB_ADMIN_PASSWORD`

Optionally you can set `MONGODB_DATABASE` (it defaults to `MONGODB_USER`).
