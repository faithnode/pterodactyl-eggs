#!/bin/ash

apk add --no-cache curl

if [ ! -d /mnt/server ]; then
    mkdir /mnt/server/
fi

cd /mnt/server/

if [ ! -d /mnt/server/redis.conf ]; then
    curl https://raw.githubusercontent.com/parkervcp/eggs/master/database/redis/redis-6/redis.conf -o redis.conf
fi

sleep 5
echo -e "Install complete. Made this to not have issues."
