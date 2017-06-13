FROM centos:centos7

ENV CONTAINER=docker \
    LANG="en_US.UTF-8" \
    TERM="xterm" \
    HOME=/var/lib/mongodb \
    MONGODB_MAJOR=3 \
    MONGODB_MINOR=4 \
    MONGODB_PATCH=4 \
    CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/mongodb \
    NAMESPACE=rh \
    MONGODB_SRC="https://fastdl.mongodb.org/linux" \
    NSS_SRC="https://dl.fedoraproject.org/pub/epel/7/x86_64/n" \
    NSS_RPM="nss_wrapper-1.1.3-1.el7.x86_64.rpm"

ENV SUMMARY="MongoDB NoSQL database server" \
    DESCRIPTION="MongoDB (from humongous) is a free and open-source \
    cross-platform document-oriented database program. Classified as a NoSQL \
    database program, MongoDB uses JSON-like documents with schemas. This \
    container image contains programs to run mongod server." \
    MONGODB_HOME="/opt/$NAMESPACE/$MONGODB_MAJOR$MONGODB_MINORmongodb" \
    MONGODB_VERSION="$MONGODB_MAJOR.$MONGODB_MINOR" \
# Incantations to enable Software Collections on `bash` and `sh -i`
    ENABLED_COLLECTIONS="$NAMESPACE-mongodb$MONGODB_MAJOR$MONGODB_MINOR" \
    BASH_ENV="$CONTAINER_SCRIPTS_PATH/scl_enable" \
    ENV="$CONTAINER_SCRIPTS_PATH/scl_enable" \
    PROMPT_COMMAND=". $CONTAINER_SCRIPTS_PATH/scl_enable" \
    MONGODB_ARCHIVE="mongodb-linux-x86_64-rhel70-$MONGODB_MAJOR.$MONGODB_MINOR.$MONGODB_PATCH.tgz"

LABEL summary="$SUMMARY" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="MongoDB $MONGODB_VERSION" \
      io.openshift.expose-services="27017:tcp" \
      io.openshift.tags="mongodb" \
      com.redhat.component="$ENABLED_COLLECTIONS-docker" \
      name="centos/mongodb-$MONGODB_MAJOR$MONGODB_MINOR-centos7" \
      version="$MONGODB_VERSION" \
      release="$MONGODB_PATCH" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

# Install MongoDB dependencies
RUN yum -y install --setopt=tsflags=nodocs \
                   bind-utils              \
                   cyrus-sasl              \
                   cyrus-sasl-gssapi       \
                   cyrus-sasl-plain        \
                   gettext                 \
                   lm_sensors-libs         \
                   net-snmp                \
                   net-snmp-agent-libs     \
                   openssl                 \
                   tcp_wrappers-libs       \
# Support arbitrary UIDs - `cmake` and `nss_wrapper` via EPEL
                   cmake                   \
&& rpm -ihv $NSS_SRC/$NSS_RPM              \
&& yum -y clean all \
# Install MongoDB archive
&& mkdir -p $MONGODB_HOME \
&& curl -L $MONGODB_SRC/$MONGODB_ARCHIVE \
| tar -xzf - -C $MONGODB_HOME --strip 1 \
# Remove systemd boot targets - improves container init performance
&& (cd /lib/systemd/system/sysinit.target.wants \
&& for i in *; do [ $i = systemd-tmpfiles-setup.service ] || rm -vf $i; done) \
&& rm -rf /lib/systemd/system/multi-user.target.wants/*      \
          /etc/systemd/system/*.wants/*                      \
          /lib/systemd/system/local-fs.target.wants/*        \
          /lib/systemd/system/sockets.target.wants/*udev*    \
          /lib/systemd/system/sockets.target.wants/*initctl* \
          /lib/systemd/system/basic.target.wants/*           \
          /lib/systemd/system/anaconda.target.wants/*

EXPOSE 27017

ENTRYPOINT ["container-entrypoint"]

VOLUME ["$MONGODB_HOME/data"]

COPY root /

# Create files and directory locations
RUN mkdir -p $HOME/data \
             $HOME/log \
             $HOME/run \
&& touch /etc/mongod.conf \
&& /usr/libexec/fix-permissions $HOME \
                                $MONGODB_HOME \
                                $HOME/data \
                                $HOME/log \
                                $HOME/run \
                                /etc/mongod.conf \
                                $CONTAINER_SCRIPTS_PATH/mongodb.conf.template \
&& ln -s $MONGODB_HOME/bin/* /usr/bin

USER 184

CMD ["run-mongod"]
