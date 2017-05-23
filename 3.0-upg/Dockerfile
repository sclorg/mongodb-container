FROM centos:centos7
LABEL MAINTAINER SoftwareCollections.org <sclorg@redhat.com>

ENV SUMMARY="MongoDB NoSQL database server" \
    DESCRIPTION="MongoDB is a scalable, high-performance, open source NoSQL database."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="MongoDB 3.0-upg" \
      io.openshift.expose-services="27017:mongodb" \
      io.openshift.tags="database,mongodb,rh-mongodb30upg" \
      com.redhat.component="rh-mongodb30-upg-docker" \
      name="centos/mongodb-30-upg-centos7" \
      version="3.0-upg" \
      release="1"

ENV MONGODB_VERSION=3.0-upg \
    # Set paths to avoid hard-coding them in scripts.
    HOME=/var/lib/mongodb \
    CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/mongodb \
    # Incantations to enable Software Collections on `bash` and `sh -i`.
    ENABLED_COLLECTIONS=rh-mongodb30upg \
    BASH_ENV="\${CONTAINER_SCRIPTS_PATH}/scl_enable" \
    ENV="\${CONTAINER_SCRIPTS_PATH}/scl_enable" \
    PROMPT_COMMAND=". \${CONTAINER_SCRIPTS_PATH}/scl_enable"

EXPOSE 27017

ENTRYPOINT ["container-entrypoint"]
CMD ["run-mongod"]

RUN yum install -y centos-release-scl && \
    INSTALL_PKGS="bind-utils gettext iproute rsync tar v8314 rh-mongodb30upg-mongodb rh-mongodb30upg" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

COPY root /


# Container setup
RUN touch /etc/mongod.conf && \
    mkdir -p ${HOME}/data && \
    # Set owner 'mongodb:0' and 'g+rw(x)' permission - to avoid problems running container with arbitrary UID
    /usr/libexec/fix-permissions /etc/mongod.conf ${CONTAINER_SCRIPTS_PATH}/mongodb.conf.template \
    ${HOME}

VOLUME ["/var/lib/mongodb/data"]

USER 184
