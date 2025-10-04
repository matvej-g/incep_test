#!/bin/sh
set -eu
DATA_DIR="/var/lib/mysql"
RUNTIME_DIR="/run/mysqld"

mkdir -p "$RUNTIME_DIR" "$DATA_DIR"
chown -R mysql:mysql "$RUNTIME_DIR" "$DATA_DIR"

if [ ! -d "$DATA_DIR/mysql" ]; then
  echo "[MariaDB] Initializing database..."
  mysql_install_db --user=mysql --ldata="$DATA_DIR" >/dev/null

  : "${MARIADB_DATABASE:?}"
  : "${MARIADB_USER:?}"
  DB_PASSWORD="$(cat /run/secrets/db_password)"

  echo "[MariaDB] Creating database..."
  # Only create the database during bootstrap
  mariadbd --bootstrap --user=mysql --datadir="$DATA_DIR" <<SQL
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SQL

  # Start server temporarily to create users
  echo "[MariaDB] Starting temporary server to create users..."
  mariadbd --user=mysql --datadir="$DATA_DIR" --skip-networking --socket="$RUNTIME_DIR/mysqld.sock" &
  pid="$!"
  
  # Wait for server to start
  for i in $(seq 30); do
    if mariadb-admin --socket="$RUNTIME_DIR/mysqld.sock" ping >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  # Create users and grant privileges
  echo "[MariaDB] Creating users and granting privileges..."
  mariadb --socket="$RUNTIME_DIR/mysqld.sock" <<SQL
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

  # Stop temporary server
  if ! mariadb-admin --socket="$RUNTIME_DIR/mysqld.sock" shutdown; then
    kill "$pid"
    wait "$pid" 2>/dev/null || true
  fi
  
  echo "[MariaDB] Initialization complete."
fi

echo "[MariaDB] Starting server..."
exec mariadbd --user=mysql --bind-address=0.0.0.0 --datadir="$DATA_DIR"