#!/bin/bash
set -e
createuser -DRS gvm
createdb -O gvm gvmd

psql -v ON_ERROR_STOP=1 gvmd <<-EOSQL
    create role dba with superuser noinherit;
    grant dba to gvm;
    create extension "uuid-ossp";
    create extension "pgcrypto";
EOSQL