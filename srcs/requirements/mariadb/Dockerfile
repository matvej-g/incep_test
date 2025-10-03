FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Server config
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Entry + init
COPY conf/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY conf/db_init.sh     /usr/local/bin/db_init.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/db_init.sh \
    && mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE 3306
# entrypoint is the "main program"
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# CMD is optional here; entrypoint script launches mysqld itself
