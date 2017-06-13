MongoDB Container
=====================

This repository contains Dockerfiles for building MongoDB images on [OpenShift][1]. Supported [base image][2] GNU/Linux distributions are as follows:

For more information about using these images with OpenShift, please see the
official [OpenShift
Documentation](https://docs.openshift.org/latest/using_images/db_images/mongodb.html).
=======

|         | <center>CentOS</center> | RHEL | Fedora |
| ------- | ----------------------- |----- | ------ |
| 2.6     | 7                       | 7    | -      |
| 3.0-upg | 7                       | 7    | -      |
| 3.2     | 7                       | 7    | 25     |
| 3.4-tar | 7                       | -    | -      |

Building MongoDB Images
---------------------------------

### Overview

The following section describes how to build MongoDB images and their required dependencies.

### Prerequisites

This repository requires [Docker][3] to build the images containing MongoDB. Make sure that the daemon is installed and enabled on your system before you being.

**Notice: RHEL based images require a properly [subscribed][4] system. Don't have a Red Hat subscription? See [Red Hat Enterprise Linux Developer Suite][5].**

### Instructions
1. Clone a copy of the repository locally.

	```bash
	git clone https://github.com/openshift/mongodb.git
	```

2. Change directories with `cd`.

	```bash
	cd mongodb
	```

3. Build image from scratch.

	Fedora

	```bash
	make build TARGET=fedora VERSION=3.2
	```

	RHEL

	```bash
	make build TARGET=rhel7 VERSION=3.2
	```

	CentOS

	```bash
	make build VERSION=3.4-tar
	```

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

This repository also provides a test framework which checks basic
functionality of the MongoDB image.

For information about usage of Dockerfile for MongoDB 3.4-tar,
see [usage documentation](3.4-tar/README.md).

Command Reference
---------------------------------

### make build
Build and test all provided versions of MongoDB.

### make test
Unit test all provided versions of MongoDB.

### make test-openshift
Integration test all provided versions of MongoDB.

#### Options

    ```
    $ cd mongodb
    $ make test TARGET=centos7 VERSIONS=3.2
    ```
```
SKIP_SQUASH : toggle image squashing (default 0)
VERSION     : limit command scope to specific MongoDB version (default all)
TARGET      : limit command scope to specific GNU/Linux distribution (default all)
```

**Notice: By omitting the `VERSIONS` parameter, the build/test action will be
performed on all provided versions of MongoDB.**
=======
Contributing
---------------------------------
If you want to contribute, make sure to follow the [contribution guidelines](CONTRIBUTING.md) when you open issues or submit pull requests.

[1]: https://docs.openshift.org/latest/using_images/db_images/mongodb.html
[2]: https://docs.docker.com/glossary/?term=base%20image
[3]: https://docs.docker.com/engine/installation/
[4]: https://access.redhat.com/solutions/253273
[5]: https://developers.redhat.com/articles/no-cost-rhel-faq/
[6]: https://help.github.com/articles/cloning-a-repository/
