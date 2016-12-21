MongoDB Docker images
=====================

This repository contains Dockerfiles for MongoDB images for OpenShift.
Users can choose between RHEL and CentOS based images.

For more information about using these images with OpenShift, please see the
official [OpenShift Documentation](https://docs.openshift.org/latest/using_images/db_images/mongodb.html).

Versions
---------------------------------
MongoDB versions currently provided are:
* mongodb-2.6
* mongodb-3.0-upg
* mongodb-3.2

RHEL versions currently supported are:
* RHEL7

CentOS versions currently supported are:
* CentOS7


Installation
---------------------------------
Choose either the CentOS7 or RHEL7 based image:

*  **RHEL7 based image**

	To build a RHEL7 based image, you need to run Docker build on a properly
    subscribed RHEL machine.

	```
	$ git clone https://github.com/openshift/mongodb.git
	$ cd mongodb
	$ make build TARGET=rhel7 VERSION=3.2
	```

*  **CentOS7 based image**

	This image is available on DockerHub. To download it run:

	```
	$ docker pull centos/mongodb-32-centos7
	```

	To build a MongoDB image from scratch run:

	```
	$ git clone https://github.com/openshift/mongodb.git
	$ cd mongodb
	$ make build TARGET=centos7 VERSION=3.2
	```

**Notice: By omitting the `VERSION` parameter, the build/test action will be performed
on all provided versions of MongoDB.**


Usage
---------------------------------

For information about usage of Dockerfile for MongoDB 2.6,
see [usage documentation](2.6/README.md).

For information about usage of Dockerfile for MongoDB 3.0-upg,
see [usage documentation](3.0-upg/README.md).

For information about usage of Dockerfile for MongoDB 3.2,
see [usage documentation](3.2/README.md).

Test
---------------------------------

This repository also provides a test framework which checks basic functionality
of the MongoDB image.

Users can choose between testing MongoDB based on a RHEL or CentOS image.

*  **RHEL based image**

    To test a RHEL7 based MongoDB image, you need to run the test on a properly
    subscribed RHEL machine.

    ```
    $ cd mongodb
    $ make test TARGET=rhel7 VERSION=3.2
    ```

*  **CentOS based image**

    ```
    $ cd mongodb
    $ make test TARGET=centos7 VERSION=3.2
    ```

**Notice: By omitting the `VERSION` parameter, the build/test action will be performed
on all provided versions of MongoDB.**
