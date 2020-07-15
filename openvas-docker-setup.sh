#!/bin/sh


# set up GSAD config
cat << EOF > /etc/sysconfig/gsad
OPTIONS=""
#
# The address the Greenbone Security Assistant will listen on.
#
GSA_ADDRESS=0.0.0.0
#
# The port the Greenbone Security Assistant will listen on.
#
GSA_PORT=443
EOF

# Proxy optimization
sed -i "s/^mirrorlist/#mirrorlist/g" /etc/yum.repos.d/CentOS-Base.repo 
sed -i "s/^#base/base/g" /etc/yum.repos.d/CentOS-Base.repo 

yum -y install wget
cd /root; NON_INT=1 wget -q -O - https://updates.atomicorp.com/installers/atomic |sh
yum clean all
yum -y update
yum -y install bzip2 useradd net-tools openssh

yum -y install openvas OSPd-nmap OSPd

BUILD=true /run.sh

rm -rf /var/cache/yum/*



