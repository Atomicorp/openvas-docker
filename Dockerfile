FROM centos:latest
MAINTAINER Support <support@atomicorp.com>

#VOLUME ["/var/lib/openvas"]

ADD run.sh /run.sh
ADD openvas-docker-setup.sh /openvas-docker-setup.sh
ADD config/redis.conf /etc/redis.conf
ADD config/texlive.repo /etc/yum.repos.d/texlive.repo



RUN /openvas-docker-setup.sh && rm -f /openvas-docker-setup.sh

CMD /run.sh
EXPOSE 443
