# MongoDB Replica Set example

**WARNING:**

**This is only a Proof-Of-Concept example and it is not meant to be used in
production. Use at your own risk.**

## What is a MongoDB replica set?

A cluster of MongoDB servers that implements master-slave replication and automated failover.
MongoDB’s recommended replication strategy.

## Deployment:

To create a MongoDB replica set in OpenShift v3, you can use the example template
included in this repository and create a new deployment right away:

```
$ oc new-app 2.4/examples/replica/mongodb-clustered.json
```

## How does it work?

### Service 'mongodb'

This resource defines a headless Kubernetes Service that serve as an entrypoint
to the MongoDB cluster. The Service endpoints are the Pods created by the
MongoDB replication controller.

Having 'headless' Service means that the `portalIP` attribute of this Service is
set to `None`. This allows to use DNS queries to discover other MongoDB
endpoints from inside the container, by quering the Service name (eg. `dig
mongodb A +short +search`).

### Pod 'mongodb-service'

This pod is responsible for initializing the MongoDB replica set. It runs just
once when the resources are being created for the first time. It also creates
the initial database and users. After the initialization is completed and data
is replicated to other members of the replica set, this pod gives up the
PRIMARY role in the replica set and shutdown.

### DeploymentConfig 'mongodb'

This resource defines the replication controller template that manages the
MongoDB replica set members. Each member starts the MongoDB server without
replication data. Once the member is available, it advertises itself to the
current MongoDB replication set PRIMARY member, which will then add it into the
replication set.
When this member is destroyed, it will also remove itself from the existing
MongoDB replication set.

To add/remove more MongoDB pods to the replica set you can use `oc scale` command.
The following command will scale the MongoDB replication controller up to 4 pods:

```
$ oc scale rc mongodb-1 --replicas=4
```

The provided template will start three MongoDB replicas by default.

## Settings and Security

There are a few environment variables that users need to set in order to create
the MongoDB replica set, all of them have default values.

For the 'mongodb-service' Pod, you have to set following variables:

* `MONGODB_REPLICA_NAME` - name of the replica set (default: `rs0`).
* `MONGODB_SERVICE_NAME` - name of the MongoDB service (default: `mongodb`, used by DNS lookup).
* `MONGODB_ADMIN_PASSWORD` - password for the `admin` user (roles: 'dbAdminAnyDatabase', 'userAdminAnyDatabase', 'readWriteAnyDatabase', 'clusterAdmin') (default: *generated*).
* `MONGODB_DATABASE` - name of the database (default: `userdb`)
* `MONGODB_USER` - the name of the regular MongoDB user (roles: 'readWrite' for `$MONGODB_DATABASE`) (default: *generated*).
* `MONGODB_PASSWORD` - the regular MongoDB user password (default: *generated*).
* `MONGODB_KEYFILE_VALUE` - value for '[keyFile](http://docs.mongodb.org/v2.4/tutorial/generate-key-file/)' file that MongoDB members use for authorization internally (default: *generated*).

All the expressions from which values of the environment variables are generated
are defined in the template parameters.

For the 'mongodb-1' scaled Pods, you have to set following variables (they have to match the variables above):

* `MONGODB_REPLICA_NAME`
* `MONGODB_SERVICE_NAME`
* `MONGODB_ADMIN_PASSWORD`
* `MONGODB_KEYFILE_VALUE`

## Teardown the cluster

For deleting all the created resources use:

```
$ oc delete all --all
```
