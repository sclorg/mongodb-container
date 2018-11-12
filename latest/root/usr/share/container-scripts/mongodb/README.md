MongoDB 3.6 NoSQL Database Server container image
====================

This repository contains Dockerfiles for MongoDB images for general usage and OpenShift.
Users can choose between RHEL and CentOS based images.
The RHEL image is available in the [Red Hat Container Catalog](https://access.redhat.com/containers/#/registry.access.redhat.com/rhscl/mongodb-36-rhel7)
as registry.access.redhat.com/rhscl/mongodb-36-rhel7.
The CentOS image is then available on [Docker Hub](https://hub.docker.com/r/centos/mongodb-36-centos7/)
as centos/mongodb-36-centos7.


Description
-----------

This container image provides a containerized packaging of the MongoDB mongod daemon
and client application. The mongod server daemon accepts connections from clients
and provides access to content from MongoDB databases on behalf of the clients.
You can find more information on the MongoDB project from the project Web site
(https://www.mongodb.com/).


Usage
-----

For this, we will assume that you are using the `rhscl/mongodb-36-rhel7` image.
If you want to set only the mandatory environment variables and store the database
in the `/home/user/database` directory on the host filesystem, execute the following command:

```
$ docker run -d -e MONGODB_USER=<user> -e MONGODB_PASSWORD=<password> -e MONGODB_DATABASE=<database> -e MONGODB_ADMIN_PASSWORD=<admin_password> -v /home/user/database:/var/lib/mongodb/data rhscl/mongodb-36-rhel7
```

If you are initializing the database and it's the first time you are using the
specified shared volume, the database will be created with two users: `admin`
and `MONGODB_USER`. After that the MongoDB daemon will be started. If you are
re-attaching the volume to another container, the creation of the database
user and admin user will be skipped, passwords of users will be changed and
only the MongoDB daemon will be started.


Environment variables and volumes
---------------------------------

The image recognizes the following environment variables that you can set
during initialization by passing `-e VAR=VALUE` to the Docker run command.

**`MONGODB_ADMIN_PASSWORD`**  
       Password for the admin user


Optionally you can provide settings for user with 'readWrite' role.
(Note you MUST specify all three of these settings)

**`MONGODB_USER`**  
       User name for MONGODB account to be created

**`MONGODB_PASSWORD`**  
       Password for the user account

**`MONGODB_DATABASE`**  
       Database name



The following environment variables influence the MongoDB default configuration file.
They are all optional.

**`MONGODB_QUIET (default: true)`**
       Runs MongoDB in a quiet mode that attempts to limit the amount of output.

**`WIREDTIGER_CACHE_SIZE`**
       Size of WiredTiger cache (value for `cache_size` configString option).


You can also set the following mount points by passing the `-v
/host:/container` flag to Docker.

**`/var/lib/mongodb/data`**  
       MongoDB data directory


**Notice: When mounting a directory from the host into the container, ensure
that the mounted directory has the appropriate permissions and that the owner
and group of the directory matches the user UID or name which is running
inside the container.**


MongoDB admin user
---------------------------------

The admin user name is set to `admin` and you have to to specify the password by
setting the `MONGODB_ADMIN_PASSWORD` environment variable.

This user has 'dbAdminAnyDatabase', 'userAdminAnyDatabase',
'readWriteAnyDatabase', 'clusterAdmin' roles (for more information see
[MongoDB
reference](https://docs.mongodb.com/manual/reference/built-in-roles/)).


Optional unprivileged user
---------------------------------

The user with `$MONGODB_USER` name is created in database `$MONGODB_DATABASE`
and you have to to specify the password by setting the `MONGODB_PASSWORD`
environment variable.

This user has only 'readWrite' role in the database.


Changing passwords
---------------------------------

Since passwords are part of the image configuration, the only supported method
to change passwords for the database user (`MONGODB_USER`) and admin user is
by changing the environment variables `MONGODB_PASSWORD` and
`MONGODB_ADMIN_PASSWORD`, respectively.

Changing database passwords directly in MongoDB will cause a mismatch between
the values stored in the variables and the actual passwords. Whenever a
database container starts it will reset the passwords to the values stored in
the environment variables.


Extending image
---------------------------------

This image can be extended using
[source-to-image](https://github.com/openshift/source-to-image).

For example to build customized MongoDB database image `my-mongodb-centos7`
with configuration in `~/image-configuration/` run:

```
$ s2i build ~/image-configuration/ centos/mongodb-36-centos7 my-mongodb-centos7
```

The directory passed to `s2i build` should contain one or more of the
following directories:

----------------------------------------------

##### `mongodb-cfg/`

when running `run-mongod` or `run-mongod-replication` commands contained
`mongod.conf` file is used for `mongod` configuration

~~~~~
- `envsubst` command is run on this file to still allow customization of
  the image using environment variables

- custom configuration file does not affect name of replica set - it has
  to be set in `MONGODB_REPLICA_NAME` environment variable

- it is not possible to configure SSL using custom configuration file
~~~~~

#####  `mongodb-ssl/`

SSL/TLS certificates used to configure MongoDB server SSL/TLS support

**Notice: To allow connections from internal scripts it is required to have `localhost` specified in SAN filed of SSL certificate.**

~~~~~
- `mongodb.pem` - file containing a public key certificate and its
associated private key. See [upstream
documentation](https://docs.mongodb.com/manual/tutorial/configure-ssl/#pem-file)
(encryption of private key is not supported).

- `ca.pem` - optional file containing the root certificate chain from
the Certificate Authority. See [upstream
documentation](https://docs.mongodb.com/manual/tutorial/configure-ssl/#set-up-mongod-and-mongos-with-certificate-validation)
~~~~~

##### `mongodb-pre-init/`

contained shell scripts (`*.sh`) are sourced before `mongod` server is
started

##### `mongodb-init/`

contained shell scripts (`*.sh`) are sourced when `mongod` server is
started for the first time (= datadir is empty)
~~~~~
- `run-mongod` command doesn't have enabled authentication in this phase

- `run-mongod-replication` command has enabled authentication in this phase
~~~~~

##### `mongodb-start/`

same sematics as `mongodb-init/`, except that these scripts are always sourced
(after `mongodb-init/` scripts, if they exist)

these scripts are skipped if `run-mongod-replication` is run with already
initialized data directory

----------------------------------------------

Variables that can be used in the scripts provided to s2i:

~~~~~
- `mongo_common_args` -- contains arguments for the `mongod` server (changing
this can break existing customization scripts, e.g. default scripts)

- `shell_args` -- arguments to mongo shell which should be used with every `mongo`
invocation (e.g. it's used to set parameters for SSL connection). Same as in
internal scripts, `mongo_cmd` function, which uses `shell_args`, can be used.

- `$MEMBER_ID` -- contains 'id' of the container. It is defined only in
scripts for replication (`run-mongod-replication` command) and has different
value for each container in a replicaset cluster. Customization scripts are
run by all containers in replicaset - `MEMBER_ID` can be used to write scripts
which are run only by some container.
~~~~~

During `s2i build` all provided files are copied into `/opt/app-root/src`
directory in the new image. If some configuration files are present in
destination directory, files with the same name are overwritten. Also only one
file with the same name can be used for customization and user provided files
are preferred over default files in `/usr/share/container-scripts/mongodb/`-
so it is possible to overwrite them.

Same configuration directory structure can be used to customize the image
every time the image is started using `docker run`. The directory have to be
mounted into `/opt/app-root/src/` in the image (`-v
./image-configuration/:/opt/app-root/src/`). This overwrites customization
built into the image.


Troubleshooting
---------------
The mongod deamon in the container logs to the standard output, so the log is available in the container log. The log can be examined by running:

    docker logs <container>


See also
--------
Dockerfile and other sources for this container image are available on
https://github.com/sclorg/mongodb-container.
In that repository, Dockerfile for CentOS is called Dockerfile, Dockerfile
for RHEL is called Dockerfile.rhel7.
