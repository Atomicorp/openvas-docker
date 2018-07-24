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
yum -y install alien bzip2 useradd net-tools openssh texlive-changepage texlive-titlesec  texlive-collection-latexextra

mkdir -p /usr/share/texlive/texmf-local/tex/latex/comment
texhash

yum -y install openvas OSPd-nmap OSPd


wget https://github.com/Arachni/arachni/releases/download/v1.5.1/arachni-1.5.1-0.5.12-linux-x86_64.tar.gz && \
    tar xvf arachni-1.5.1-0.5.12-linux-x86_64.tar.gz && \
    mv arachni-1.5.1-0.5.12 /opt/arachni && \
    ln -s /opt/arachni/bin/* /usr/local/bin/ && \
    rm -rf arachni*


/usr/sbin/greenbone-nvt-sync 
/usr/sbin/greenbone-certdata-sync 
/usr/sbin/greenbone-scapdata-sync 
BUILD=true /run.sh

rm -rf /var/cache/yum/*



