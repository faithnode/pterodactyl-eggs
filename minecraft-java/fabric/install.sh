#!/bin/bash

if [[ -z $_INSTALL_MINECRAFT_VERSION || ${_INSTALL_MINECRAFT_VERSION,,} == "latest" ]]; then
  echo -e "Getting minecraft latest version";
  _INSTALL_MINECRAFT_VERSION=$(curl -sSL https://meta.fabricmc.net/v2/versions/game | jq -r '.[] | select(.stable == true )|.version' | head -n1)
fi

echo -e "Getting fabric latest version";
FABRIC_VERSION=$(curl -sSL https://meta.fabricmc.net/v2/versions/installer | jq -r '.[] | select(.stable == true )|.version' | head -n1)

echo -e "Getting fabric loader latest version";
FABRIC_LOADER_VERSION=$(curl -sSL https://meta.fabricmc.net/v2/versions/loader | jq -r '.[] | select(.stable == true )|.version' | head -n1)

echo -e "Downloading fabric";
wget -O fabric-installer.jar https://maven.fabricmc.net/net/fabricmc/fabric-installer/$FABRIC_VERSION/fabric-installer-$FABRIC_VERSION.jar

echo -e "Installing fabric";
java -jar fabric-installer.jar server -mcversion $_INSTALL_MINECRAFT_VERSION -loader $FABRIC_LOADER_VERSION -downloadMinecraft

echo -e "Removing installer"
rm "fabric-installer.jar" || true

echo -e "Agree eula";
echo "eula=true" > "eula.txt";

echo -e "Install Complete"