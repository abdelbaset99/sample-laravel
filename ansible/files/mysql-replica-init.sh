#!/bin/bash
set -e

ROOT_PASS=$(cat /run/secrets/mysql_root_password)
REPL_PASS=$(cat /run/secrets/mysql_password)
PRIMARY_HOST="mysql-primary" 

echo "[custom-entrypoint] Starting custom MySQL replica entrypoint..."

/usr/local/bin/docker-entrypoint.sh mysqld &
MYSQL_PID=$!
sleep 30 # Allow time for MySQL to start

echo "[custom-entrypoint] Waiting for MySQL to start..."
until mysqladmin ping --silent; do
  sleep 5
done

echo "[custom-entrypoint] Waiting for primary at ${PRIMARY_HOST}:3306..."
until mysqladmin ping -h"${PRIMARY_HOST}" -uroot -p"${ROOT_PASS}" --silent; do
  sleep 5
done

echo "[custom-entrypoint] Primary is reachable, configuring replication..."

mysql -uroot -p"${ROOT_PASS}" <<EOSQL
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='${PRIMARY_HOST}',
  SOURCE_USER='repl',
  SOURCE_PASSWORD='${REPL_PASS}',
  SOURCE_AUTO_POSITION=1;
START REPLICA;
SHOW REPLICA STATUS\G
EOSQL

echo "[custom-entrypoint] Replication configured."

wait $MYSQL_PID