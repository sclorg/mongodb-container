FROM rhscl/s2i-core-rhel7

ENV SUMMARY="MongoDB NoSQL database server" \
    DESCRIPTION="MongoDB (from humongous) is a free and open-source \
cross-platform document-oriented database program. Classified as a NoSQL \
database program, MongoDB uses JSON-like documents with schemas. This \
container image contains programs to run mongod server."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="MongoDB 3.6" \
      io.openshift.expose-services="27017:mongodb" \
      io.openshift.tags="database,mongodb,rh-mongodb36" \
      com.redhat.component="rh-mongodb36-container" \
      name="rhscl/mongodb-36-rhel7" \
      usage="docker run -d -e MONGODB_ADMIN_PASSWORD=my_pass rhscl/mongodb-36-rhel7" \
      version="1" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#rhel" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

ENV MONGODB_VERSION=3.6 \
    # Set paths to avoid hard-coding them in scripts.
    APP_DATA=/opt/app-root/src \
    HOME=/var/lib/mongodb \
    CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/mongodb \
    # Incantations to enable Software Collections on `bash` and `sh -i`.
    ENABLED_COLLECTIONS=rh-mongodb36 \
    BASH_ENV="\${CONTAINER_SCRIPTS_PATH}/scl_enable" \
    ENV="\${CONTAINER_SCRIPTS_PATH}/scl_enable" \
    PROMPT_COMMAND=". \${CONTAINER_SCRIPTS_PATH}/scl_enable"

EXPOSE 27017

ENTRYPOINT ["container-entrypoint"]
CMD ["run-mongod"]

RUN yum install -y yum-utils && \
    prepare-yum-repositories rhel-server-rhscl-7-rpms && \
    INSTALL_PKGS="bind-utils gettext iproute rsync tar hostname rh-mongodb36-mongodb rh-mongodb36 rh-mongodb36-mongo-tools rh-mongodb36-syspaths groff-base" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*'

COPY s2i/bin/ $STI_SCRIPTS_PATH

COPY root /

# Container setup
RUN : > /etc/mongod.conf && \
    mkdir -p ${HOME}/data && \
    # Set owner 'mongodb:0' and 'g+rw(x)' permission - to avoid problems running container with arbitrary UID
    /usr/libexec/fix-permissions /etc/mongod.conf ${CONTAINER_SCRIPTS_PATH}/mongod.conf.template \
    ${HOME} ${APP_DATA}/.. && \
    usermod -a -G root mongodb && \
    rpm-file-permissions

VOLUME ["/var/lib/mongodb/data"]

USER 184
