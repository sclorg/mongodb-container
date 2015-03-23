FROM centos:centos7

# MongoDB image for OpenShift.
#
# Volumes:
#  * /var/lib/mongodb/ - Datastore for MongoDB
# Environment:
#  * $MONGODB_USERNAME - Database user name
#  * $MONGODB_PASSWORD - User's password
#  * $MONGODB_DATABASE - Name of the database to create
#  * $MONGODB_ADMIN_PASSWORD - Password of the MongoDB Admin

# Image metadata
ENV MONGODB_VERSION         2.4  
ENV IMAGE_DESCRIPTION       MongoDB 2.4
ENV IMAGE_TAGS              mongodb,mongodb24
ENV IMAGE_EXPOSE_SERVICES   27017:mongodb

MAINTAINER  Jakub Hadvig <jhadvig@redhat.com>
EXPOSE 27017

RUN yum install -y epel-release && \
    rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum -y --setopt=tsflags=nodocs install \
    https://www.softwarecollections.org/en/scls/rhscl/v8314/epel-7-x86_64/download/rhscl-v8314-epel-7-x86_64.noarch.rpm \
    https://www.softwarecollections.org/en/scls/rhscl/mongodb24/epel-7-x86_64/download/rhscl-mongodb24-epel-7-x86_64.noarch.rpm && \
    yum install -y --setopt=tsflags=nodocs v8314 mongodb24-mongodb mongodb24 && \
    yum clean all

COPY run-mongod.sh /usr/local/bin/
COPY contrib /opt/openshift/

WORKDIR /opt/openshift

VOLUME ["/var/lib/mongodb/"]

ENTRYPOINT ["run-mongod.sh"]
