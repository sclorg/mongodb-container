# MongoDB Replication Example Using a Docker

This [MongoDB replication](https://docs.mongodb.com/manual/replication/) example
uses a [Docker engine](http://docker.com) to run replica set members. This platform
do not provide any deployment automation and it is used mainly for developing and testing.

## Getting Started

You will need an Docker engine where you can run containers. If you want to avoid running all replset members on one host, you can also use [Docker Swarm](https://docs.docker.com/swarm/).

## Example Working Scenarios

This section describes how this example is designed to work.

### Initial Deployment: 3-member Replica Set

To create replica set with three members you can use this script:

```bash
function get_ip() {
    local id="$1" ; shift
    docker inspect --format='{{.NetworkSettings.IPAddress}}' ${id}
}

REPLICATION_ARGS="
-e MONGODB_DATABASE=db
-e MONGODB_USER=user
-e MONGODB_PASSWORD=password
-e MONGODB_ADMIN_PASSWORD=adminPassword
-e MONGODB_REPLICA_NAME=rs0
-e MONGODB_KEYFILE_VALUE=xxxxxxxxxxxx
-e MONGODB_SMALLFILES=true"

docker run -d --name replset0 ${BASE_ARGS} --hostname initialize -e MONGODB_REPLICA_MEMBERS="" $IMAGE_NAME run-mongod-replication
docker run -d --name replset1 ${BASE_ARGS} -e MONGODB_REPLICA_MEMBERS="$(get_ip replset0)" $IMAGE_NAME run-mongod-replication
docker run -d --name replset2 ${BASE_ARGS} -e MONGODB_REPLICA_MEMBERS="$(get_ip replset0) $(get_ip replset1)" $IMAGE_NAME run-mongod-replication
```

`run-mongod-replication` command have to be run in container and in `MONGODB_REPLICA_MEMBERS` environment variable it should contain as much of replica set members addresses as possible.

And later from one of the containers you can also login into MongoDB:

```console
sh-4.2$ mongo $MONGODB_DATABASE -u $MONGODB_USER -p $MONGODB_PASSWORD --host $MONGODB_REPLICA_NAME/localhost
MongoDB shell version: 3.2.6
connecting to: sampledb
rs0:PRIMARY>
```

Note: You can also use host version of mongo shell, but you have to substitute values of environmental variables yourself.

During the lifetime of your deployment, one or more of those members might crash or fail. In this case, replica set member is removed. It some special cases, replica set configuration might not be updated -- see Known Limitations.

**Note**: for production usage, you should maintain as much separation between
members as possible. It is recommended to run containers on different hosts.

### Adding member

To add new member into replica set run:

```bash
docker run -d --name replset3 ${BASE_ARGS} -e MONGODB_REPLICA_MEMBERS="$(get_ip replset0) $(get_ip replset1) $(get_ip replset2)" $IMAGE_NAME run-mongod-replication
```

New containers is created and it connects to the replica set.

### Removing member

To remove member from replica set stop container:

```bash
docker stop replset2
```

The container is removed from replset configuration and terminates.

### Known Limitations

* Adding or removing new members or replica set takes some time (elections, syncing,...), so after your command finished it may take some time until replica set is ready
//TODO  => suggest to use mongo from container and use functions from common.sh
* Initializing container knows only one replica set member address (itself). So if mongod server in this container fails, container can't connect to replica set to remove itself from configuration, so in this case replica set configuration might not be cleaned properly.
