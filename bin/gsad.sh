#!/bin/bash

exec /usr/sbin/gsad -f --listen=0.0.0.0 --port=${LISTEN_PORT} --http-only --no-redirect --verbose --mlisten=127.0.0.1 --mport=9390