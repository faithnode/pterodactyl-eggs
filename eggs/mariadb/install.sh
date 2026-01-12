#!/bin/bash

set -x

apt-get -y update
apt-get -y install curl

useradd -d /home/container -m container -s /bin/bash

chown container: /mnt/server/

if [ -f /mnt/server/.my.cnf ]; then
    mv /mnt/server/.my.cnf /mnt/server/custom.my.cnf
    runuser -l container -c 'curl https://raw.githubusercontent.com/parkervcp/eggs/master/database/sql/mariadb/install.my.cnf > /mnt/server/.my.cnf'
else
    runuser -l container -c 'curl https://raw.githubusercontent.com/parkervcp/eggs/master/database/sql/mariadb/install.my.cnf > /mnt/server/.my.cnf'
fi

runuser -l container -c 'mkdir -p /mnt/server/run/mysqld'
runuser -l container -c 'mkdir -p /mnt/server/log/mysql'
runuser -l container -c 'mkdir /mnt/server/mysql'

runuser -l container -c 'mysql_install_db --defaults-file=/mnt/server/.my.cnf'

if [ -f /mnt/server/custom.my.cnf ]; then
    mv /mnt/server/custom.my.cnf /mnt/server/.my.cnf
else
    curl https://raw.githubusercontent.com/parkervcp/eggs/master/database/sql/mariadb/my.cnf > /mnt/server/.my.cnf
fi

exit
