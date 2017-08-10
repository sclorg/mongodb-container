FROM rhel7

LABEL io.k8s.description="MongoDB is a scalable, high-performance, open source NoSQL database." \
      io.k8s.display-name="MongoDB 2.4" \
      io.openshift.expose-services="27017:mongodb" \
      io.openshift.tags="database,mongodb,mongodb24"

# Labels consumed by Red Hat build service
LABEL Component="mongodb24" \
      com.redhat.component="openshift-mongodb-docker" \
      name="openshift3/mongodb-24-rhel7" \
      version="2.4" \
      release="1" \
      architecture="x86_64"

ENV MONGODB_VERSION=2.4 \
    # Set paths to avoid hard-coding them in scripts.
    HOME=/var/lib/mongodb \
    CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/mongodb \
    # Incantations to enable Software Collections on `bash` and `sh -i`.
    ENABLED_COLLECTIONS=mongodb24 \
    BASH_ENV="\${CONTAINER_SCRIPTS_PATH}/scl_enable" \
    ENV="\${CONTAINER_SCRIPTS_PATH}/scl_enable" \
    PROMPT_COMMAND=". \${CONTAINER_SCRIPTS_PATH}/scl_enable"

EXPOSE 27017

ENTRYPOINT ["container-entrypoint"]
CMD ["run-mongod"]

RUN yum install -y yum-utils && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum-config-manager --enable rhel-7-server-optional-rpms && \
    INSTALL_PKGS="bind-utils gettext iproute rsync tar v8314 mongodb24-mongodb mongodb24" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    mkdir -p /var/lib/mongodb/data && chown -R mongodb.0 /var/lib/mongodb/ && \
    # Loosen permission bits to avoid problems running container with arbitrary UID
    chmod -R a+rwx /opt/rh/mongodb24/root/var/lib/mongodb && \
    chmod -R g+rwx /var/lib/mongodb

VOLUME ["/var/lib/mongodb/data"]

ADD root /

# Container setup
RUN touch /etc/mongod.conf && chown mongodb:0 /etc/mongod.conf && /usr/libexec/fix-permissions /etc/mongod.conf

USER 184
