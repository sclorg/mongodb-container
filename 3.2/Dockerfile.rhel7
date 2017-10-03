FROM rhscl/s2i-core-rhel7

ENV SUMMARY="MongoDB NoSQL database server" \
    DESCRIPTION="MongoDB (from humongous) is a free and open-source \
cross-platform document-oriented database program. Classified as a NoSQL \
database program, MongoDB uses JSON-like documents with schemas. This \
container image contains programs to run mongod server."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="MongoDB 3.2" \
      io.openshift.expose-services="27017:mongodb" \
      io.openshift.tags="database,mongodb,rh-mongodb32" \
      com.redhat.component="rh-mongodb32-docker" \
      name="rhscl/mongodb-32-rhel7" \
      version="3.2" \
      release="1"

ENV MONGODB_VERSION=3.2 \
    # Set paths to avoid hard-coding them in scripts.
    APP_DATA=/opt/app-root/src \
    HOME=/var/lib/mongodb \
    CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/mongodb \
    # Incantations to enable Software Collections on `bash` and `sh -i`.
    ENABLED_COLLECTIONS=rh-mongodb32 \
    BASH_ENV="\${CONTAINER_SCRIPTS_PATH}/scl_enable" \
    ENV="\${CONTAINER_SCRIPTS_PATH}/scl_enable" \
    PROMPT_COMMAND=". \${CONTAINER_SCRIPTS_PATH}/scl_enable"

EXPOSE 27017

ENTRYPOINT ["container-entrypoint"]
CMD ["run-mongod"]

# We need to call 2 (!) yum commands before being able to enable repositories properly
# This is a workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1479388
RUN yum repolist > /dev/null && \
    yum install -y yum-utils && \
    yum-config-manager --disable \* &> /dev/null && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum-config-manager --enable rhel-7-server-rpms && \
    yum-config-manager --enable rhel-7-server-optional-rpms && \
    INSTALL_PKGS="bind-utils gettext iproute rsync tar hostname shadow-utils rh-mongodb32-mongodb rh-mongodb32 rh-mongodb32-mongo-tools groff-base" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all

COPY s2i/bin/ $STI_SCRIPTS_PATH

COPY root /

# Container setup
RUN touch /etc/mongod.conf && \
    mkdir -p ${HOME}/data && \
    # Set owner 'mongodb:0' and 'g+rw(x)' permission - to avoid problems running container with arbitrary UID
    /usr/libexec/fix-permissions /etc/mongod.conf ${CONTAINER_SCRIPTS_PATH}/mongod.conf.template \
    ${HOME} ${APP_DATA}/.. && \
    usermod -a -G root mongodb

VOLUME ["/var/lib/mongodb/data"]

USER 184
