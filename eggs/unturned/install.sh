#!/bin/bash
DEBIAN_FRONTEND=noninteractive

apt -y update
apt -y --no-install-recommends install curl lib32gcc1 ca-certificates

if [ "}" == "" ]; then
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

./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +force_install_dir /mnt/server +app_update "1110390" ${EXTRA_FLAGS} validate +quit

mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so /mnt/server/.steam/sdk32/steamclient.so

mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so /mnt/server/.steam/sdk64/steamclient.so

cd /mnt/server/
ln -s ../../../steamcmd/linux64/steamclient.so Unturned_Headless_Data/Plugins/x86_64/steamclient.so
ln -s ../Extras/Rocket.Unturned/ Modules/
