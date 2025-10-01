FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysqli \
    curl

COPY /conf/www.conf /etc/php/8.2/fpm/pool.d/.
COPY conf/init.sh .

RUN chmod +x init.sh

CMD ["./init.sh"]
