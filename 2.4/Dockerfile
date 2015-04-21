FROM centos:centos7
MAINTAINER  Jakub Hadvig <jhadvig@redhat.com>

# MongoDB image for OpenShift.
#
# Volumes:
#  * /var/lib/mongodb/data - Datastore for MongoDB
# Environment:
#  * $MONGODB_USER - Database user name
#  * $MONGODB_PASSWORD - User's password
#  * $MONGODB_DATABASE - Name of the database to create
#  * $MONGODB_ADMIN_PASSWORD - Password of the MongoDB Admin

# Image metadata
ENV MONGODB_VERSION         2.4  
ENV IMAGE_DESCRIPTION       MongoDB 2.4
ENV IMAGE_TAGS              mongodb,mongodb24
ENV IMAGE_EXPOSE_SERVICES   27017:mongodb

EXPOSE 27017

# This image must forever use UID 184 for mongodb user and GID 998 for the
# mongodb group, so our volumes are safe in the future. This should *never*
# change, the last test is there to make sure of that.
# Due to the https://bugzilla.redhat.com/show_bug.cgi?id=1206151,
# the whole /var/lib/mongodb/ dir has to be chown-ed.
RUN yum install -y epel-release && \
    rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum -y --setopt=tsflags=nodocs install \
    https://www.softwarecollections.org/en/scls/rhscl/v8314/epel-7-x86_64/download/rhscl-v8314-epel-7-x86_64.noarch.rpm \
    https://www.softwarecollections.org/en/scls/rhscl/mongodb24/epel-7-x86_64/download/rhscl-mongodb24-epel-7-x86_64.noarch.rpm && \
    yum install -y --setopt=tsflags=nodocs bind-utils gettext v8314 mongodb24-mongodb mongodb24 && \
    yum clean all && \
    mkdir -p /var/lib/mongodb/data && chown -R mongodb.mongodb /var/lib/mongodb/ && \
    test "$(id mongodb)" = "uid=184(mongodb) gid=998(mongodb) groups=998(mongodb)"

COPY run-mongod.sh /usr/local/bin/
COPY contrib /var/lib/mongodb/

# Due to the https://bugzilla.redhat.com/show_bug.cgi?id=1206151,
# the .bashrc has to be copied to the wrong $HOME dir, so when using
# 'docker exec -it openshift/mongodb-24-centos7 /bin/bash' the mongodb
# collection is enabled automatically.
COPY contrib/.bashrc /opt/rh/mongodb24/root/var/lib/mongodb/

VOLUME ["/var/lib/mongodb/data"]

USER mongodb

ENTRYPOINT ["run-mongod.sh"]
CMD ["mongod"]
