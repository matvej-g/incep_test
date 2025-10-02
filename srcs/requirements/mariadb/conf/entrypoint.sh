#!/bin/sh
set -e

DATA_DIR="/var/lib/mysql"
RUNTIME_DIR="/run/mysqld"

mkdir -p "$RUNTIME_DIR"
chown -R mysql:mysql "$RUNTIME_DIR" "$DATA_DIR"

# Initialize data dir on first run
if [ ! -d "$DATA_DIR/mysql" ]; then
  echo "[MariaDB] Initializing data directory..."
  mysql_install_db --user=mysql --ldata="$DATA_DIR" >/dev/null
  FIRST_RUN=1
else
  FIRST_RUN=0
fi

# Start mysqld in background
echo "[MariaDB] Starting server..."
mysqld --user=mysql --bind-address=0.0.0.0 &
MYSQLD_PID=$!

# Make sure we forward stop signals to mysqld (since we skipped tini)
trap "echo '[MariaDB] Stopping...'; kill -TERM $MYSQLD_PID; wait $MYSQLD_PID" INT TERM

# Wait until ready to accept connections
echo "[MariaDB] Waiting for server to be ready..."
until mariadb-admin ping --silent; do
  sleep 1
done

# On first run, execute bootstrap (create DB/user/grants)
if [ "$FIRST_RUN" -eq 1 ] && [ -x /usr/local/bin/db_init.sh ]; then
  echo "[MariaDB] Bootstrapping database..."
  /usr/local/bin/db_init.sh
  echo "[MariaDB] Bootstrap done."
fi

# Keep container alive by waiting on mysqld
wait $MYSQLD_PID