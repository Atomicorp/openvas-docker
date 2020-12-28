FROM centos:8

ENV LANG=en_US.UTF-8

# configure yum
RUN yum -y install 'dnf-command(config-manager)' && \
    yum config-manager --set-enabled powertools && \
    yum -y install wget epel-release && \
    export NON_INT=1 && wget -q -O - https://updates.atomicorp.com/installers/atomic |sh

# add helpers
RUN  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64" && \
    chmod a+x /usr/local/bin/gosu

RUN wget -O /usr/local/bin/confd "https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64" && \
    chmod a+x /usr/local/bin/confd && \
    mkdir -p /etc/confd/{conf.d,templates}

# update image
RUN yum clean all && yum -y update

# install packages
RUN yum -y install  bzip2 \
                net-tools \
                openssh \
                glibc-langpack-en \
                gnutls-utils \
                python3 \
                postgresql-server \
                postgresql-contrib \
                greenbone-security-assistant \
                OSPd-openvas

## cleanup temp files
RUN rm -rf /var/cache/yum/*

# add config templates
COPY config/templates/* /etc/confd/templates/
COPY config/conf.d/* /etc/confd/conf.d/

# configure dirs for redis
RUN mkdir -p /var/lib/gvm/redis && \
    chown gvm:gvm /var/lib/gvm/redis && \
    mkdir -p /var/log/redis && \
    chown -R gvm:gvm /var/log/redis

# configure dirs for postgres
RUN mkdir -p /var/lib/gvm/pgsql && \
    chown postgres:postgres /var/lib/gvm/pgsql

# add postgres startup scripts
RUN mkdir /docker-entrypoint-initdb.d
COPY postgres_entrypoint.sh /postgres_entrypoint.sh
COPY config/init-gvm-db.sh /docker-entrypoint-initdb.d/init-gvm-db.sh

# add the container startup script
COPY run.sh /run.sh

# run the startup script in build mode.
RUN BUILD=true OV_UPDATE=yes /run.sh

# move lib/gvm to a backup dir, it will be restored at startup.  
# this allows attaching a volume to lib/gvm, and if it is empty 
# we will copy in the data backed into the image.
RUN mv /var/lib/gvm /var/lib/gvm.backup &&\
    mkdir /var/lib/gvm && \
    chown gvm:gvm /var/lib/gvm

CMD /run.sh
EXPOSE 80
