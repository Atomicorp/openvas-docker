#!/bin/bash
set -x 

# generate config files from templates.
confd -onetime -backend env

# make sure datavol has correct permissions.
chown gvm:gvm ${DATAVOL}
chmod 755 ${DATAVOL}

# download cached feed data if needed.
if [ ! -e ${DATAVOL}/scap-data/feed.xml ]; then 
	wget -O ${DATAVOL}/feed_data.tgz https://storage.googleapis.com/openvas-feed-data/feed_data.tgz
    tar -C ${DATAVOL} -zxf ${DATAVOL}/feed_data.tgz
    rm ${DATAVOL}/feed_data.tgz
	chown -R gvm:gvm cert-data  data-objects  plugins  scap-data
	_rebuild=true
fi

# configure dirs for redis
mkdir -p /var/lib/gvm/redis
chown gvm:gvm /var/lib/gvm/redis
mkdir -p /var/log/redis
chown -R gvm:gvm /var/log/redis

# configure dirs for postgres
mkdir -p ${PGDATA}
chown postgres:postgres ${PGDATA}

# start redis
echo "Starting Redis"
supervisorctl start redis 

echo "Testing redis status..."
while  [ "$(redis-cli -s /var/run/gvm/redis.sock ping)" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
done
echo "Redis ready."

# start postgres
echo "Starting Postgres"
supervisorctl start postgres
# wait for postgres to start
echo "Testing Postgres status..."
while ! gosu gvm psql gvmd -c "SELECT NOW();" ; do
	sleep 2
done
echo "Postgres is ready."

# if gvm certs dont exist, create them.
if [ ! -e ${DATAVOL}/CA/cacert.pem ]; then
	gosu gvm /usr/bin/gvm-manage-certs -a
fi

# Check for users, and create admin
while ! [[ $(gosu gvm /usr/sbin/gvmd --get-users) ]] ; do 
	echo "Creating admin user"
	gosu gvm /usr/sbin/gvmd --create-user=admin
	gosu gvm /usr/sbin/gvmd --user=admin --new-password=admin
	# set feed import owner
	userUUID=$(gosu gvm gvmd --get-users --verbose|grep admin|cut -d' ' -f2)
	gosu gvm gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value $userUUID
	sleep 1
done

if [ -n "$OV_PASSWORD" ]; then
	echo "Setting admin password"
	gosu gvm /usr/sbin/gvmd --user=admin --new-password=$OV_PASSWORD
fi

# if requested, update feeds.  This could take a while
if [ "x$OV_UPDATE" -eq "xyes" ]; then
	gosu gvm greenbone-feed-sync --type GVMD_DATA
	gosu gvm greenbone-feed-sync --type CERT
	gosu gvm greenbone-feed-sync --type SCAP
	gosu gvm /usr/bin/greenbone-nvt-sync
fi

echo "Starting ospd-openvas"
supervisorctl start ospd-openvas

while ! supervisorctl  status ospd-openvas ; do
	echo failed
	sleep 1
done
echo "ospd-openvas is running"

# Update VT info into redis store from VT files
gosu gvm openvas -u

if [ "x$_rebuild" -eq "xtrue" ]; then
	gosu gvm gvmd --rebuild-scap
	gosu gvm gvmd --rebuild
fi

echo "Starting gvmd"
supervisorctl start gvmd

echo "Starting gsad"
supervisorctl start gsad



