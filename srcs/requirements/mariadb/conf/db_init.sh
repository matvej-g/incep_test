#!/bin/sh
set -e

DB="${MARIADB_DATABASE:-wpdb}"
USER="${MARIADB_USER:-wpuser}"
PASS="$(cat /run/secrets/db_password)"

mariadb -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${USER}'@'%' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON \`${DB}\`.* TO '${USER}'@'%';
FLUSH PRIVILEGES;
SQL

