#!/bin/bash
apt -y update
apt -y --no-install-recommends --no-install-suggests install curl lib32gcc-s1 ca-certificates

if [ "${STEAM_USER}" == "" ]; then
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
fi

cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd

mkdir -p /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
tar -xzvf steamcmd.tar.gz -C /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
mkdir -p /mnt/server/steamapps
cd /mnt/server/steamcmd

chown -R root:root /mnt
export HOME=/mnt/server

./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +force_install_dir /mnt/server +app_update ${SRCDS_APPID} ${EXTRA_FLAGS} +quit

mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so

mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so

cd /mnt/server/Engine/Binaries/ThirdParty/SteamCMD/Linux
ln -sf ../../../../../Steam/steamapps steamapps
cd /mnt/server
