# MongoDB for OpenShift - Docker images

This repository contains Dockerfiles for MongoDB images for OpenShift.
Users can choose between RHEL and CentOS based images.

### Versions

Currently supported version of MongoDB:

* mongodb-2.4

Currently supported version of RHEL:

* RHEL7

Currently supported version of CentOS:

* CentOS7


## Installation
Choose between CentOS7 or RHEL7 based image:

*  **RHEL7 based image**

	To build a rhel7-based image, you need to run Docker build on a properly subscribed RHEL machine.

	```console
	git clone https://github.com/openshift/mongodb.git
	cd mongodb
	make build TARGET=rhel7
	```

*  **CentOS7 based image**

	This image is also available on DockerHub. To download it use:

	```console
	docker pull openshift/mongodb-24-centos7
	```

	To build MongoDB image from scratch use:

	```console
	git clone https://github.com/openshift/mongodb.git
	cd mongodb
	make build
	```

## Usage

### Environment variables

The image recognizes following environment variables that you can set
during initialization, by passing `-e VAR=VALUE` to the Docker run
command.

|    Variable name          |    Description                              |   Default  |
| :------------------------ | -----------------------------------------   | ---------- |
|  `MONGODB_USERNAME`           | User name for MONGODB account to be created |
|  `MONGODB_PASSWORD`       | Password for the user account               |
|  `MONGODB_DATABASE`       | Database name (optional)                    | production |
|  `MONGODB_ADMIN_PASSWORD` | Password for the admin user (optional)      |

You can also set following mount points by passing `-v /host:/container`
flag to Docker.

|  Volume mount point    | Description            |
| :--------------------- | ---------------------- |
|  `/var/lib/mongodb/`   | MongoDB data directory |


### Usage

We will assume that you are using the `openshift/mongodb-24-centos7`
image. Suppose that you want to set only mandatory required environment
variables and store the database in the `/home/user/database`
directory on the host filesystem, you need to execute the following
command:

```console
docker run -d -e MONGODB_USERNAME=<user> -e MONGODB_PASSWORD=<password> -e MONGODB_DATABASE=<database> -v /home/user/database:/var/lib/mongodb openshift/mongodb-24-centos7
```

If you are initializing the database and it's the first time you are using the
specified shared volume, the database will be created, together with database
administrator user and also MongoDB admin user if `MONGODB_ADMIN_PASSWORD`
environment variable is specified. After that the MongoDB daemon will be
started.
If you are re-attaching the volume to another container the creation of the
database user and the admin user will be skipped and only the mongodb
daemon will be started.


### MongoDB admin user
The admin user is not set by default. You can create one by setting
`MONGODB_ADMIN_PASSWORD` environment variable, in which case the admin
user name will be set to `admin`. This process is done upon initializing
the database.


## Note about Software Collections
We use [Software Collections](https://www.softwarecollections.org/) to
install and launch MongoDB. If you want to execute a command inside of a
running container (eg. for debugging), you need to prefix it
with `scl enable mongodb24` command. Some examples:

```console
# Running mongodb commands inside the container
scl enable mongodb24 -- mongo <db_name> -u <username> -p <password>

# Executing a command inside a running container from host
# Note: You will be able to run mongodb commands without invoking the scl commands
docker exec -ti <CONTAINER_ID> scl enable mongodb24 /bin/bash
```

## Test Framework

This repository also provides test framework, which checks basic functionality of the MongoDB image.

User can choose between testing MongoDB based on RHEL or CentOS image.

*  **RHEL based image**

    To test a rhel7-based MongoDB image, you need to run the test on a properly
    subscribed RHEL machine.

    ```
    $ cd mongodb
    $ make test TARGET=rhel7 VERSION=2.4
    ```

*  **CentOS based image**

    ```
    $ cd mongodb
    $ make test VERSION=2.4
    ```

**Notice: By omitting the `VERSION` parameter, the build/test action will be performed
on all of the supported versions of MongoDB.**
