#!/bin/sh
set -eu

DATA_DIR="/var/lib/mysql"
RUNTIME_DIR="/run/mysqld"

mkdir -p "$RUNTIME_DIR" "$DATA_DIR"
chown -R mysql:mysql "$RUNTIME_DIR" "$DATA_DIR"

FIRST_RUN=0
if [ ! -d "$DATA_DIR/mysql" ]; then
  FIRST_RUN=1
  echo "[MariaDB] Initializing database..."
  mysql_install_db --user=mysql --ldata="$DATA_DIR" >/dev/null

  : "${MARIADB_DATABASE:?}"
  : "${MARIADB_USER:?}"
  DB_PASSWORD="$(cat /run/secrets/db_password)"

  echo "[MariaDB] Creating database (bootstrap)..."
  mariadbd --bootstrap --user=mysql --datadir="$DATA_DIR" <<SQL
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SQL

  # Prepare one-time init SQL for users/grants (runs at first normal start)
  cat > /tmp/init.sql <<SQL
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'wordpress.%' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'wordpress.%';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';

-- OPTIONAL: also set root@localhost password to the same secret
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';

-- OPTIONAL: remove anonymous users if they exist
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'%';

FLUSH PRIVILEGES;
SQL
  echo "[MariaDB] Initialization SQL prepared."
fi

echo "[MariaDB] Starting server..."
if [ "$FIRST_RUN" -eq 1 ]; then
  # No backgrounding; mariadbd becomes PID 1 and runs init.sql once
  exec mariadbd --user=mysql --bind-address=0.0.0.0 \
       --datadir="$DATA_DIR" --init-file=/tmp/init.sql
else
  exec mariadbd --user=mysql --bind-address=0.0.0.0 --datadir="$DATA_DIR"
fi
