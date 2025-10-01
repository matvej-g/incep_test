FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    mariadb-server

COPY /conf/50-server.cnf /etc/mysql/mariadb.conf.d/.
COPY /conf/init.sql /etc/mysql/init.sql
COPY /conf/install.sh .

RUN mkdir /run/mysqld && chmod +x install.sh

CMD ["./install.sh"]
