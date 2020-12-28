#!/bin/sh

yum -y install 'dnf-command(config-manager)'
yum config-manager --set-enabled powertools
yum -y install wget epel-release
cd /root;
export NON_INT=1
wget -q -O - https://updates.atomicorp.com/installers/atomic |sh
yum clean all
yum -y update
yum -y install  bzip2 \
                net-tools \
                openssh \
                glibc-langpack-en \
                gnutls-utils \
                python3 \
                postgresql-server \
                postgresql-contrib \
                greenbone-security-assistant \
                OSPd-openvas

wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.12/gosu-amd64"
chmod a+x /usr/local/bin/gosu

wget -O /usr/local/bin/confd "https://github.com/kelseyhightower/confd/releases/download/v0.16.0/confd-0.16.0-linux-amd64"
chmod a+x /usr/local/bin/confd
mkdir -p /etc/confd/{conf.d,templates}

rm -rf /var/cache/yum/*



