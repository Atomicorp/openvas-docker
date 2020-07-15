FROM centos:latest
MAINTAINER Support <support@atomicorp.com>

ADD run.sh /run.sh
ADD openvas-docker-setup.sh /openvas-docker-setup.sh
ADD config/redis.conf /etc/redis.conf
ADD config/openvassd.conf /etc/openvas/openvassd.conf
ADD config/greenbone-nvt-sync.conf /etc/openvas/greenbone-nvt-sync.conf
RUN /openvas-docker-setup.sh && rm -f /openvas-docker-setup.sh

CMD /run.sh
EXPOSE 80
