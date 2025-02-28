#!/bin/bash

VERSION=$_INSTALL_MINECRAFT_VERSION;

echo -e "Getting versions";
VERSIONS="$(curl https://meta.fabricmc.net/v2/versions/game | jq)"

if [[ -z $VERSION || ${VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  MINECRAFT_VERSION="$(echo "$VERSIONS" | jq -r 'last(.[] | select(.stable == true ) | .version)')";
else
  MINECRAFT_VERSION="$(echo "$VERSIONS" | jq -r "$(printf 'last(.[] | select(.version == "%s") | .version)' "$VERSION")")";
  if [[ -z "$VERSION" ]]; then
    fatal "Version $VERSION not found";
  fi
fi

echo -e "Getting fabric latest version";
FABRIC_VERSION=$(curl https://meta.fabricmc.net/v2/versions/installer | jq -r 'last(.[] | select(.stable == true)) | .version' | head -n1)

echo -e "Getting fabric loader latest version";
FABRIC_LOADER_VERSION=$(curl https://meta.fabricmc.net/v2/versions/loader | jq -r 'last(.[] | select(.stable == true)) | .version' | head -n1)

INSTALLER_JARFILE="fabric-installer-$FABRIC_VERSION.jar"

echo -e "Downloading fabric installer";
curl -o "$INSTALLER_JARFILE" "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$FABRIC_VERSION/$INSTALLER_JARFILE"

echo -e "Installing fabric";
java -jar "$INSTALLER_JARFILE" server -mcversion "$MINECRAFT_VERSION" -loader "$FABRIC_LOADER_VERSION" -downloadMinecraft

echo -e "Removing installer"
rm -rf "$INSTALLER_JARFILE"

echo -e "Agree eula";
echo "eula=true" > "eula.txt";
