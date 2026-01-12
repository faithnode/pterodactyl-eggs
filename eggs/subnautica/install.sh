#!/bin/bash

dpkg --add-architecture i386
apt update
apt -y --no-install-recommends install curl unzip libstdc++6 lib32gcc1 ca-certificates libsdl2-2.0-0:i386

latest_NitroxMod=$(curl --silent "https://api.github.com/repos/SubnauticaNitrox/Nitrox/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "${NITROX_VERSION}" ] || [ "${NITROX_VERSION}" == "latest" ]; then
  DL_VERSION=$latest_NitroxMod
else
  DL_VERSION=${NITROX_VERSION}
fi

cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd
cd /mnt/server/steamcmd

chown -R root:root /mnt
export HOME=/mnt/server

GUARDCODE="${STEAM_GUARDCODE}"
if [ -z $GUARDCODE ]
then
    echo ""
    echo "### You did not specify a Steam Guardcode"
    echo "### A new one should be send to you shortly"
    echo "### Enter it in the startup-config after this installation is finished and reinstall the Server"
    sleep 10
    timeout 60 ./steamcmd.sh +login ${STEAM_USERNAME} ${STEAM_PASSWORD} +quit
    exit 1
fi

[ ! -d "$HOME/subnautica" ] && mkdir $HOME/subnautica
./steamcmd.sh +set_steam_guard_code ${STEAM_GUARDCODE} +login ${STEAM_USERNAME} ${STEAM_PASSWORD} +@sSteamCmdForcePlatformType windows +force_install_dir $HOME/subnautica +app_update ${APPID} ${EXTRA_FLAGS} validate +quit
status=$?

if [ $status -ne 0 ]
then
    echo ""
    echo "### The Download was not successful"
    echo "### Probably the entered Guardcode was wrong"
    echo "### A new one should be send to you shortly"
    echo "### Enter it in the startup-config after this installation is finished and reinstall the Server"
    sleep 10
    sleep 10
    timeout 30 ./steamcmd.sh +login ${STEAM_USERNAME} ${STEAM_PASSWORD} +quit
    exit 1
fi

mkdir -p $HOME/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so

mkdir -p $HOME/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so

[ -d "$HOME/nitrox" ] && rm -r $HOME/nitrox
mkdir $HOME/nitrox
cd $HOME/nitrox
curl -sL https://github.com/SubnauticaNitrox/Nitrox/releases/download/${DL_VERSION}/Nitrox.${DL_VERSION}.zip -o Nitrox.${DL_VERSION}.zip
unzip $HOME/nitrox/Nitrox.${DL_VERSION}.zip

echo "/home/container/subnautica" > $HOME/path.txt

if [ -e $HOME/server.cfg ]; then
    echo "server settings exists"
else
    echo "writing server default settings"
    cat <<EOT > $HOME/server.cfg
    Seed=
    ServerPort=11000
    SaveInterval=120000
    PostSaveCommandPath=
    MaxConnections=100
    DisableConsole=False
    DisableAutoSave=False
    SaveName=world
    ServerPassword=
    AdminPassword=PleaseChangeMe
    GameMode=SURVIVAL
    SerializerMode=JSON
    DefaultPlayerPerm=PLAYER
    DefaultOxygenValue=45
    DefaultMaxOxygenValue=45
    DefaultHealthValue=80
    DefaultHungerValue=50.5
    DefaultThirstValue=90.5
    DefaultInfectionValue=0.1
    AutoPortForward=False
EOT
fi
