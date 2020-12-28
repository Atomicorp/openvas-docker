#!/bin/bash
set -x 

OV_PASSWORD=${OV_PASSWORD:-admin}
OV_UPDATE=${OV_UPDATE:-no}
LISTEN_PORT=${LISTEN_PORT:-80}
KEY_FILE=${DATAVOL}/private/CA/clientkey.pem
CERT_FILE=${DATAVOL}/CA/clientcert.pem
CA_FILE=${DATAVOL}/CA/cacert.pem
export DATAVOL=${DATAVOL:-/var/lib/gvm}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-openvas}
export PGDATA=${PGDATA:-${DATAVOL}/pgsql/data}

# generate config files from templates.
confd -onetime -backend env

# if we are not in build mode, check if we need to restore lib/gvm
if [ -z "$BUILD" ]; then
	if [ ! -e ${DATAVOL}/plugins ] && [ -e /var/lib/gvm.backup ]; then
		chown gvm:gvm ${DATAVOL}
		chmod 775 ${DATAVOL}
		mv /var/lib/gvm.backup/* ${DATAVOL}/
	fi
fi

# start redis
echo "Starting Redis"
gosu gvm redis-server /etc/redis.conf &

echo "Testing redis status..."
while  [ "$(redis-cli -s /var/run/gvm/redis.sock ping)" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
done
echo "Redis ready."

# start postgres
echo "Starting Postgres"
gosu postgres /postgres_entrypoint.sh postgres &
# wait for postgres to start
echo "Testing Postgres status..."
while ! gosu gvm psql gvmd -c "\d" ; do
	sleep 2
done

if [  ! -d /usr/share/gvm/gsa/locale ]; then
	mkdir -p /usr/share/gvm/gsa/locale
fi

echo "Starting gvmd"
gosu gvm /usr/sbin/gvmd

echo "Starting ospd-openvas"
export PYTHONPATH=/opt/atomicorp/lib/python3.6/site-packages
gosu gvm /opt/atomicorp/bin/ospd-openvas --pid-file /var/run/ospd/ospd-openvas.pid --unix-socket=/var/run/ospd/ospd.sock --log-file /var/log/gvm/ospd-scanner.log --lock-file-dir /var/run/gvm/

# Check for users, and create admin
while ! [[ $(gosu gvm /usr/sbin/gvmd --get-users) ]] ; do 
	echo "Creating admin user"
	gosu gvm /usr/sbin/gvmd --create-user=admin
	gosu gvm /usr/sbin/gvmd --user=admin --new-password=admin
	tail -10 /var/log/gvm/gvmd.log
	sleep 1
done

if [ -n "$OV_PASSWORD" ]; then
	echo "Setting admin password"
	gosu gvm /usr/sbin/gvmd --user=admin --new-password=$OV_PASSWORD
fi

if [ -z "$BUILD" ]; then
	echo "Starting gsad"
	/usr/sbin/gsad --listen=0.0.0.0 --port=${LISTEN_PORT} --http-only --no-redirect --verbose --munix-socket=/var/run/gvm/gvmd.sock
	echo "Tailing logs"
	tail -F /var/log/gvm/*
fi
