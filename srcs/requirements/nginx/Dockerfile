FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    nginx \
    openssl

RUN mkdir -p /etc/nginx/ssl

COPY requirements/nginx/conf/default /etc/nginx/sites-available/.

COPY requirements/bonus/index.html /var/www/static/index.html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
