#!/bin/bash

apt -y update
apt -y --no-install-recommends install curl lib32gcc-s1 ca-certificates

if [ "${STEAM_USER}" == "" ]; then
    echo -e "Using anonymous user."
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "user set to ${STEAM_USER}"
fi

cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd
cd /mnt/server/steamcmd

chown -R root:root /mnt
export HOME=/mnt/server

./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +force_install_dir /mnt/server +app_update ${SRCDS_APPID} ${EXTRA_FLAGS} validate +quit

mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so
mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so

mkdir -p /mnt/server/DoNotStarveTogether/config/server/
if [ ! -f /mnt/server/DoNotStarveTogether/config/server/cluster_token.txt ]; then
    echo "${SERVER_TOKEN}" >> /mnt/server/DoNotStarveTogether/config/server/cluster_token.txt
fi

if [ ! -f /mnt/server/DoNotStarveTogether/config/server/cluster.ini ]; then
    curl -sSL https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/steamcmd_servers/dont_starve/server.cluster.ini -o /mnt/server/DoNotStarveTogether/config/server/cluster.ini
fi

mkdir -p /mnt/server/DoNotStarveTogether/config/server/Master/
if [ ! -f /mnt/server/DoNotStarveTogether/config/server/Master/server.ini ]; then
    curl -sSL https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/steamcmd_servers/dont_starve/server.master.ini -o /mnt/server/DoNotStarveTogether/config/server/Master/server.ini
fi

if [ ! -z ${MASTER_WORLDGEN}  ] && [ ! -f /mnt/server/DoNotStarveTogether/config/server/Master/worldgenoverride.lua ]; then
    curl -sSL ${MASTER_WORLDGEN} -o /mnt/server/DoNotStarveTogether/config/server/Master/worldgenoverride.lua
fi

mkdir -p /mnt/server/DoNotStarveTogether/config/server/Caves/
if [ ! -f /mnt/server/DoNotStarveTogether/config/server/Caves/server.ini ]; then
    curl -sSL https://raw.githubusercontent.com/parkervcp/eggs/master/game_eggs/steamcmd_servers/dont_starve/server.caves.ini -o /mnt/server/DoNotStarveTogether/config/server/Caves/server.ini
fi

if [ ! -z ${CAVES_WORLDGEN} ] && [ ! -f /mnt/server/DoNotStarveTogether/config/server/Caves/worldgenoverride.lua ]; then
    curl -sSL ${CAVES_WORLDGEN} -o /mnt/server/DoNotStarveTogether/config/server/Caves/worldgenoverride.lua
fi

echo -e "Install complete"
