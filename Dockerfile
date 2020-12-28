FROM centos:latest

ENV LANG=en_US.UTF-8

# install packages
COPY openvas-docker-setup.sh /openvas-docker-setup.sh
RUN /openvas-docker-setup.sh && rm -f /openvas-docker-setup.sh

# config templates
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

# run the script in build mode.
RUN BUILD=true OV_UPDATE=yes /run.sh

# move lib/gvm to a backup dir, it will be restored at startup.  
# this allows attaching a volume to lib/gvm, and if it is empty 
# we will copy in the data backed into the image.
RUN mv /var/lib/gvm /var/lib/gvm.backup &&\
    mkdir /var/lib/gvm && \
    chown gvm:gvm /var/lib/gvm

CMD /run.sh
EXPOSE 80
