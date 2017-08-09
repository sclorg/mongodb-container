MongoDB Docker image
====================

This repository contains MongoDB Dockerfiles for general use and with OpenShift.

Environment variables
---------------------------------

The image recognizes the following default values that you can set during by
passing `-e VAR=VALUE` to the Docker `run` command.

|    Name                    |    Description                   |    Value |
| :------------------------  | ---------------------------------| ---------|
|  `MONGODB_ADMIN_USER`      | Username for 'userAdmin' account | admin    |
|  `MONGODB_ADMIN_PASSWORD`  | Password for 'userAdmin' account | -        |
|  `MONGODB_USER`            | Username for 'readWrite' account | -        |
|  `MONGODB_PASSWORD`        | Password for 'readWrite' account | -        |
|  `MONGODB_DATABASE`        | Database for 'readWrite' account | -        |
|  `MONGODB_QUIET`           | Suppress system log output       | true     |
|  `ADDITIONAL_STARTUP_OPTS` | Additional daemon options        |          |
|    Replica Set <td colspan="2"/>
|  `MONGODB_KEYFILE_VALUE`   | Specific replica set secret      | -        |
|  `MONGODB_REPLICA_NAME`    | Specific replica set name        | -        |
|  `MONGODB_SERVICE_NAME`    | Specific replica set service     | mongodb  |
|    SSL Support <td colspan="2"/>
|   `ENABLE_TLS`             | Turn on TLS encryption           | false    |
|   `SSL_CA_PATH`            | Certificate authority .ca path   |          |
|   `ADDITIONAL_SSL_OPTS`    | Any additional SSL options       |          |
|    Replica Set Support <td colspan="2"/>
|   `MONGODB_KEYFILE_VALUE`  | Keyfile content for replica set authentication | |
|   `MONGODB_REPLICA_NAME`   | Name of the replica set                        | |
|    Shard Router Support <td colspan="2"/>
|    `CONFIG_REPLSET_NAME`   | Replica Set name of the config server  | |
|   `CONFIG_REPLSET_SERVER`  | A single member URI of the config server replica set | |
|   `REPLSET_NAMES`          | Comma delimited names of replica sets apart of shard cluster | |
|   `REPLSET_SERVERS`        | Comma delimited members of each replica set in shard cluster. One from each replica set, in order | |

Usage
---------------------------------

For this, we will assume that you are using the `centos/mongodb-34-tar-centos7`
image.

### Mount volume

The following command initializes a standalone MongoDB instance with two users
and stores the data on the host file system.

```
export DOCKER_ARGS="-e MONGODB_USER=<username> \
                    -e MONGODB_PASSWORD=<password> \
                    -e MONGODB_DATABASE=<database> \
                    -e MONGODB_ADMIN_PASSWORD=<admin_password> \
                    -v /home/user/database:/var/lib/mongodb/data:Z"

docker run -d ${DOCKER_ARGS} --name mdb centos/mongodb-34-tar-centos7
```

If you are re-attaching the volume to another container, the creation of the
database user and admin user will be skipped and only the standalone MongoDB
instance will be started.

**Notice: When mounting data locally, ensure that the mount point has the right
permissions by checking that the owner/group matches the user private group
(UPG) inside the container.**

### Docker entry points

|    Name                   |    Description                   |
| :------------------------ | ---------------------------------|
| `run-standalone`          | Run a standalone, non-replicated instance |
| `run-replset`             | Run a replica set                |
| `run-configsvr`           | Run a configuration server       |
| `run-mongos`              | Run a shard router               |

### OpenShift readiness check

"mongo-is-ready" script is available on the PATH for use to determine that a given server is up, initialized, and ready to receive requests.

### Available OpenShift example templates

https://github.com/jbornemann/mongodb-on-os


### Custom configuration

The following command initializes a standalone MongoDB instance with a
configuration file already stored on the host file system.

```
export DOCKER_ARGS="-e MONGODB_ADMIN_PASSWORD=<admin_password> \
                    -v /home/user/mongod.conf:/etc/mongod.conf:Z"

docker run -d ${DOCKER_ARGS} centos/mongodb-34-tar-centos7
```

**Notice: Custom config file does not affect name of replica set. It has to be
set in `MONGODB_REPLICA_NAME` environment variable.**

### Update credentials

The following commands initializes a standalone MongoDB instance and then resets
the 'userAdmin' account password.

```
export CONTAINER=mongodb-34

export DOCKER_ARGS="-e MONGODB_ADMIN_PASSWORD=<admin_password>"

docker run -d ${DOCKER_ARGS} --name ${CONTAINER} centos/mongodb-34-tar-centos7

docker exec ${CONTAINER} bash -c "-e MONGODB_ADMIN_PASSWORD=<new_admin_password>"

docker restart ${CONTAINER}
```

**Notice: Changing database passwords directly in MongoDB will cause a mismatch
between the values stored in the variables and the actual passwords. Whenever a
database container starts it will reset the passwords to the values stored in
the environment variables.**
