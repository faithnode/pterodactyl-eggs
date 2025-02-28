#!/bin/bash

VERSION=$_INSTALL_MINECRAFT_VERSION;

echo -e "Getting promotions";
PROMOTIONS=$(curl https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json);

if [[ -z $VERSION || ${VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  MINECRAFT_VERSION="$(echo "$PROMOTIONS" | jq -r '.promos | to_entries | last | .key')";
else
  MINECRAFT_VERSION=$(echo "$PROMOTIONS" | jq -r "$(printf '.promos | to_entries | last(.[] | select(.key | startswith("%s"))) | .key' "$_INSTALL_MINECRAFT_VERSION")");
  if [[ -z "$FORGE_VERSION" ]]; then
    fatal "Version $VERSION not found";
  fi
fi

FORGE_VERSION="$(echo "$PROMOTIONS" | jq -r "$(printf '.promos["%s"]' "$MINECRAFT_VERSION")")";
MINECRAFT_VERSION="${MINECRAFT_VERSION%%-*}";

INSTALLER_JARFILE="forge-$MINECRAFT_VERSION-$FORGE_VERSION-installer.jar";

DOWNLOAD_LINK="https://maven.minecraftforge.net/net/minecraftforge/forge/$MINECRAFT_VERSION-$FORGE_VERSION/$INSTALLER_JARFILE";

echo -e "Removing old jars";
rm -rf ./forge*.jar;

echo -e "Downloading forge installer"
curl -o "$INSTALLER_JARFILE" "$DOWNLOAD_LINK"

echo -e "Installing forge"
java -jar "$INSTALLER_JARFILE" --installServer

echo -e "Removing installer"
rm -rf "$INSTALLER_JARFILE" "$INSTALLER_JARFILE.log"

if [ ! -e ./run.sh ]; then
  echo -e "Creating installation script"
  echo "java -jar forge*.jar" > "run.sh";
fi

echo -e "Agree eula";
echo "eula=true" > "eula.txt";