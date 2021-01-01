FROM centos:8

ENV LANG=en_US.UTF-8

# configure yum
RUN yum -y install 'dnf-command(config-manager)' && \
    yum config-manager --set-enabled powertools && \
    yum -y install glibc-langpack-en wget epel-release && \
    export NON_INT=1 && wget -q -O - https://updates.atomicorp.com/installers/atomic |sh

# add helpers
RUN  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64" && \
    chmod a+x /usr/local/bin/gosu

RUN wget -O /usr/local/bin/confd "https://github.com/abtreece/confd/releases/download/v0.17.2/confd-0.17.2-linux-amd64" && \
    chmod a+x /usr/local/bin/confd && \
    mkdir -p /etc/confd/{conf.d,templates}

# update image
RUN yum clean all && yum -y update

# install packages
RUN yum -y install bzip2 \
                supervisor \
                net-tools \
                openssh \
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

#configure dirs for gvm
RUN mkdir -p /var/lib/gvm && \
    chown gvm:gvm /var/lib/gvm && \
    chmod 755 /var/lib/gvm

# add scripts for starting services.
COPY bin/* /usr/local/bin/

# add supervisord configs
COPY config/supervisor/* /etc/supervisord.d/

# add db init script
RUN mkdir /docker-entrypoint-initdb.d
COPY config/init-gvm-db.sh /docker-entrypoint-initdb.d/init-gvm-db.sh

CMD ["supervisord", "-n"]
EXPOSE 80
ENV DATAVOL=/var/lib/gvm
ENV OV_PASSWORD=admin
ENV OV_UPDATE=no
ENV LISTEN_PORT=80
ENV POSTGRES_PASSWORD=openvas
ENV KEY_FILE=${DATAVOL}/private/CA/clientkey.pem
ENV CERT_FILE=${DATAVOL}/CA/clientcert.pem
ENV CA_FILE=${DATAVOL}/CA/cacert.pem
ENV PGDATA=${DATAVOL}/pgsql/data