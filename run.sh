#!/bin/bash

DATAVOL=/var/lib/gvm/
OV_PASSWORD=${OV_PASSWORD:-admin}
OV_UPDATE=${OV_UPDATE:0}
ADDRESS=127.0.0.1
KEY_FILE=/var/lib/gvm/private/CA/clientkey.pem
CERT_FILE=/var/lib/gvm/CA/clientcert.pem
CA_FILE=/var/lib/gvm/CA/cacert.pem


redis-server /etc/redis.conf &

echo "Testing redis status..."
X="$(redis-cli -s /tmp/redis.sock ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli -s /tmp/redis.sock ping)"
done
echo "Redis ready."

# Check certs
if [ ! -f /var/lib/gvm/CA/cacert.pem ]; then
	/usr/bin/gvm-manage-certs -a
fi

if [ "$OV_UPDATE" == "yes" ];then
	/usr/sbin/greenbone-nvt-sync 
	/usr/sbin/greenbone-certdata-sync 
	/usr/sbin/greenbone-scapdata-sync
fi

if [  ! -d /usr/share/gvm/gsa/locale ]; then
	mkdir -p /usr/share/gvm/gsa/locale
fi

echo "Restarting services"
/usr/sbin/openvassd 
/usr/sbin/gvmd
/usr/sbin/gsad --listen=0.0.0.0 --port=80 --http-only --no-redirect --verbose

echo
echo -n "Checking for scanners: "
SCANNER=$(/usr/sbin/gvmd --get-scanners)
echo "Done"

if ! echo $SCANNER | grep -q nmap ; then
        echo "Adding nmap scanner"
        /usr/bin/ospd-nmap --bind-address $ADDRESS --port 40001 --key-file $KEY_FILE --cert-file $CERT_FILE --ca-file $CA_FILE &
        /usr/sbin/gvmd  --create-scanner=ospd-nmap --scanner-host=localhost --scanner-port=40001 --scanner-type=OSP --scanner-ca-pub=/var/lib/gvm/CA/cacert.pem --scanner-key-pub=/var/lib/gvm/CA/clientcert.pem --scanner-key-priv=/var/lib/gvm/private/CA/clientkey.pem
        echo
else
	/usr/bin/ospd-nmap --bind-address $ADDRESS --port 40001 --key-file $KEY_FILE --cert-file $CERT_FILE --ca-file $CA_FILE &

fi


#echo "Reloading NVTs"
#gvmd --rebuild --progress

# Check for users, and create admin
if ! [[ $(/usr/sbin/gvmd --get-users) ]] ; then 
	echo "Creating admin user"
	/usr/sbin/gvmd --create-user=admin
	/usr/sbin/gvmd --user=admin --new-password=admin
fi

if [ -n "$OV_PASSWORD" ]; then
	echo "Setting admin password"
	/usr/sbin/gvmd --user=admin --new-password=$OV_PASSWORD
fi

cat /tmp/output.txt

#echo "Checking setup"
#/usr/bin/openvas-check-setup --v9


if [ -z "$BUILD" ]; then
	echo "Tailing logs"
	tail -F /var/log/gvm/*
fi
