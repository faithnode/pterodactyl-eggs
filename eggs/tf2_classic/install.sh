#!/bin/bash
apt -y update
apt -y --no-install-recommends install curl lib32gcc1 ca-certificates p7zip-full wget

if [ "${STEAM_USER}" == "" ]; then
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
fi

cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd
cd /mnt/server/steamcmd

chown -R root:root /mnt
export HOME=/mnt/server

./steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +force_install_dir /mnt/server +app_update "244310" ${EXTRA_FLAGS} +quit

mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so

mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so

cd /mnt/server
wget -v https://chapo.services/tf2c/tf2classic-${GAMEVERSION}.7z -O tf2classic.7z
7z x tf2classic.7z -y

cd /mnt/server/bin
ln -s vphysics_srv.so vphysics.so
ln -s studiorender_srv.so studiorender.so
ln -s soundemittersystem_srv.so soundemittersystem.so
ln -s shaderapiempty_srv.so shaderapiempty.so
ln -s scenefilecache_srv.so scenefilecache.so
ln -s replay_srv.so replay.so
ln -s materialsystem_srv.so materialsystem.so
