MongoDB container images
========================

MongoDB 3.6 status: [![Docker Repository on Quay](https://quay.io/repository/centos7/mongodb-36-centos7/status "Docker Repository on Quay")](https://quay.io/repository/centos7/mongodb-36-centos7)

This repository contains Dockerfiles for MongoDB images for OpenShift.
Users can choose between RHEL, Fedora and CentOS based images.

For more information about using these images with OpenShift, please see the
official [OpenShift Documentation](https://docs.okd.io/latest/using_images/db_images/mongodb.html).

For more information about contributing, see
[the Contribution Guidelines](https://github.com/sclorg/welcome/blob/master/contribution.md).
For more information about concepts used in these container images, see the
[Landing page](https://github.com/sclorg/welcome).


Versions
--------
MongoDB versions currently provided are:
* [MongoDB 3.6](latest)

RHEL versions currently supported are:
* RHEL7

CentOS versions currently supported are:
* CentOS7


Installation
------------
Choose either the CentOS7 or RHEL7 based image:

*  **RHEL7 based image**

    This image is available in the [Red Hat Container Catalog](https://access.redhat.com/containers#/registry.access.redhat.com/rhscl/mongodb-36-rhel7). To download it run:

    ```
    $ docker pull registry.access.redhat.com/rhscl/mongodb-36-rhel7
    ```

    To build a RHEL7 based image, you need to run Docker build on a properly
    subscribed RHEL machine.

    ```
    $ git clone https://github.com/sclorg/mongodb-container.git
    $ cd mongodb-container
    $ git submodule update --init
    $ make build TARGET=rhel7 VERSIONS=3.6
    ```

*  **CentOS7 based image**

    This image is available on DockerHub. To download it run:

    ```
    $ docker pull quay.io/centos7/mongodb-36-centos7
    ```

    To build a MongoDB image from scratch run:

    ```
    $ git clone https://github.com/sclorg/mongodb-container.git
    $ cd mongodb-container
        $ git submodule update --init
    $ make build TARGET=centos7 VERSIONS=3.6
    ```

**Notice: By omitting the `VERSIONS` parameter, the build/test action will be
performed on all provided versions of MongoDB.**


Usage
-----

For information about usage of Dockerfile for MongoDB 3.6,
see [usage documentation](latest/).

Test
----

This repository also provides a test framework which checks basic
functionality of the MongoDB image.

Users can choose between testing MongoDB based on a RHEL or CentOS image.

*  **RHEL based image**

    To test a RHEL7 based MongoDB image, you need to run the test on a properly
    subscribed RHEL machine.

    ```
    $ cd mongodb-container
    $ git submodule update --init
    $ make test TARGET=rhel7 VERSIONS=3.6
    ```

*  **CentOS based image**

    ```
    $ cd mongodb-container
    $ git submodule update --init
    $ make test TARGET=centos7 VERSIONS=3.6
    ```

**Notice: By omitting the `VERSIONS` parameter, the build/test action will be
performed on all provided versions of MongoDB.**
