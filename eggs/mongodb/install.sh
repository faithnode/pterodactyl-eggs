#!/bin/bash
if [ ! -d /mnt/server/ ]; then
    mkdir /mnt/server/
fi

cd /mnt/server/

cp /etc/mongod.conf.orig /mnt/server/mongod.conf

mkdir mongodb logs

mongod --port 27017 --dbpath /mnt/server/mongodb/ --logpath /mnt/server/logs/mongo.log --fork

mongo --eval "db.getSiblingDB('admin').createUser({user: '${MONGO_USER}', pwd: '${MONGO_USER_PASS}', roles: ['root']})"

mongo --eval "db.getSiblingDB('admin').shutdownServer()"
