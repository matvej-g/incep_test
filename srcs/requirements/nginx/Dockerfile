FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    nginx \
    openssl

RUN mkdir -p /etc/nginx/ssl

COPY /conf/default /etc/nginx/sites-available/.

CMD ["nginx", "-g", "daemon off;"]
