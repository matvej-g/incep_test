#!/bin/bash

set -euo pipefail
# -e (exit on error), -u (treat unset variables as errors), -o pipefall (fail on any pipe element)

WEBROOT="/var/www/html"

# check if Variables are set  :  "${VARIABLE:?ERROR MESSAGE}"
: "${WORDPRESS_DB_HOST:?}"
: "${WORDPRESS_DB_NAME:?}"
: "${WORDPRESS_DB_USER:?}"
: "${WORDPRESS_ADMIN_USER:?}"
: "${WORDPRESS_USER:?}"
: "${DOMAIN_NAME:?}"

export HTTP_HOST="$DOMAIN_NAME"

# read mounted secrets
DB_PASS="$(cat /run/secrets/db_password)"
ADMIN_PASS="$(cat /run/secrets/wp_root_password)"
USER_PASS="$(cat /run/secrets/wp_user_password)"

# check if wp command is available, if not install wp-cli
if ! command -v wp >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
  chmod +x /usr/local/bin/wp
fi

# -p dont complain if it already exist
mkdir -p "$WEBROOT"
cd "$WEBROOT"
# check if wordpress core files exist
if [ ! -f wp-settings.php ]; then
  wp core download --allow-root --path="$WEBROOT"
fi

# check if wp-config exist
if [ ! -f wp-config.php ]; then
  wp config create \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="$WORDPRESS_DB_HOST" \
    --allow-root \
    --path="$WEBROOT"
fi

# check wp-data base 
until wp db check --quiet --allow-root --path="$WEBROOT"; do
  echo "Waiting for database at $WORDPRESS_DB_HOST ..."
  sleep 2
done

if ! wp core is-installed --allow-root --path="$WEBROOT"; then
  wp core install \
    --url="https://${DOMAIN_NAME}" \
    --title="My Inception" \
    --admin_user="$WORDPRESS_ADMIN_USER" \
    --admin_password="$ADMIN_PASS" \
    --admin_email="mgering_root@${DOMAIN_NAME}.fr" \
    --skip-email \
    --allow-root \
    --path="$WEBROOT"
fi

if ! wp user get "$WORDPRESS_USER" --field=ID --allow-root --path="$WEBROOT" >/dev/null 2>&1; then
  wp user create "$WORDPRESS_USER" "mgering@${DOMAIN_NAME}.fr" \
    --role=editor \
    --user_pass="$USER_PASS" \
    --allow-root \
    --path="$WEBROOT"
fi

# run php-fpm in foreground pid 1
exec php-fpm8.2 -F
