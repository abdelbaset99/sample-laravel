#!/bin/bash
set -e

ROOT_PASS=$(cat /run/secrets/mysql_root_password)
REPL_PASS=$(cat /run/secrets/mysql_password)

echo "[custom-entrypoint] Starting custom MySQL primary entrypoint..."

/usr/local/bin/docker-entrypoint.sh mysqld &
MYSQL_PID=$!
sleep 30 # Allow time for MySQL to start

echo "[custom-entrypoint] Waiting for MySQL to start..."
until mysqladmin ping --silent; do
  sleep 5
done

echo "[custom-entrypoint] MySQL is ready, setting up database and replication user..."

mysql <<EOSQL
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED WITH mysql_native_password BY '${REPL_PASS}';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
EOSQL

echo "[custom-entrypoint] Setup complete."

wait $MYSQL_PID