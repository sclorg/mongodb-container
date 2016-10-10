FROM centos:centos7
MAINTAINER SoftwareCollections.org <sclorg@redhat.com>

LABEL io.k8s.description="MongoDB is a scalable, high-performance, open source NoSQL database." \
      io.k8s.display-name="MongoDB 3.2" \
      io.openshift.expose-services="27017:mongodb" \
      io.openshift.tags="database,mongodb,rh-mongodb32"

ENV MONGODB_VERSION=3.2 \
    # Set paths to avoid hard-coding them in scripts.
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

RUN yum install -y centos-release-scl && \
    INSTALL_PKGS="bind-utils gettext iproute rsync tar rh-mongodb32-mongodb rh-mongodb32 rh-mongodb32-mongo-tools" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    mkdir -p /var/lib/mongodb/data && chown -R mongodb.0 /var/lib/mongodb/ /var/opt/rh/rh-mongodb32/lib/mongodb && \
    # Loosen permission bits to avoid problems running container with arbitrary UID
    chmod g+w -R /var/opt/rh/rh-mongodb32/lib/mongodb && \
    chmod -R g+rwx /var/lib/mongodb

VOLUME ["/var/lib/mongodb/data"]

ADD root /

# Container setup
RUN touch /etc/mongod.conf && chown mongodb:0 /etc/mongod.conf && /usr/libexec/fix-permissions /etc/mongod.conf

USER 184
