#!/bin/bash
apt -y --no-install-recommends install libstdc++6 lib32gcc-s1 ca-certificates

export WINEARCH=win64
export WINEPREFIX=/home/container/.wine64

cd /tmp
mkdir -p /mnt/server/steamcmd
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /mnt/server/steamcmd
cd /mnt/server/steamcmd

chown -R root:root /mnt
export HOME=/mnt/server

./steamcmd.sh +login anonymous +@sSteamCmdForcePlatformType windows +force_install_dir /mnt/server +app_update ${APPID} ${EXTRA_FLAGS} validate +quit

mkdir -p /mnt/server/.steam/sdk32
cp -v linux32/steamclient.so ../.steam/sdk32/steamclient.so

mkdir -p /mnt/server/.steam/sdk64
cp -v linux64/steamclient.so ../.steam/sdk64/steamclient.so

mkdir -p /home/container/.wine64
export WINEARCH=win64
export WINEPREFIX=/home/container/.wine64

mkdir -p $HOME/TheForestDedicatedServer_Data/forest/config/
cat <<EOT > $HOME/TheForestDedicatedServer_Data/forest/config/config.cfg
// Dedicated Server Settings.
// Server IP address - Note: If you have a router, this address is the internal address, and you need to configure ports forwarding, append the current game port here as well
serverIP
// Steam Communication Port - Note: If you have a router you will need to open this port.
serverSteamPort
// Game Communication Port - Note: If you have a router you will need to open this port.
serverGamePort
// Query Communication Port - Note: If you have a router you will need to open this port.
serverQueryPort
// Server display name
serverName
// Maximum number of players
serverPlayers 5
// Server password. blank means no password
serverPassword
// Server administration password. blank means no password
serverPasswordAdmin
// Your Steam account name. blank means anonymous (see Steam server account bellow)
serverSteamAccount
// Enable VAC (Valve Anti Cheat) on the server. off by default, uncomment to enable
enableVAC on
// Time between server auto saves in minutes
serverAutoSaveInterval 15
// Game difficulty mode. Must be set to "Peaceful" "Normal" or "Hard"
difficulty Normal
// New or continue a game. Must be set to "New" or "Continue"
initType New
// Slot to save the game. Must be set 1 2 3 4 or 5
slot 1
// Show event log. Must be set "off" or "on"
showLogs off
// Contact email for server admin
serverContact email@gmail.com
// No enemies. Must be set to "on" or "off"
veganMode off
// No enemies during day time. Must be set to "on" or "off"
vegetarianMode off
// Reset all structure holes when loading a save. Must be set to "on" or "off"
resetHolesMode off
// Regrow 10% of cut down trees when sleeping. Must be set to "on" or "off"
treeRegrowMode off
// Allow building destruction. Must be set to "on" or "off"
allowBuildingDestruction on
// Allow enemies in creative games. Must be set to "on" or "off"
allowEnemiesCreativeMode off
// Allow clients to use the built in development console. Must be set to "on" or "off"
allowCheats off
// Allows defining a custom folder for save slots, leave empty to use the default location
saveFolderPath
// Target FPS when no client is connected
targetFpsIdle 5
// Target FPS when there is at least one client connected
targetFpsActive 60
EOT
