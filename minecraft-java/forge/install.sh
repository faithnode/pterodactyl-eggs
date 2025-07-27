#!/bin/bash

PROMOTIONS=$(curl -sSL https://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json)

echo -e "Getting minecraft version"
if [[ -z ${_INSTALL_MINECRAFT_VERSION} || ${_INSTALL_MINECRAFT_VERSION,,} == "latest" ]]; then
  _INSTALL_MINECRAFT_VERSION=$(echo $PROMOTIONS | jq -r '.promos | to_entries | last | .key');
  _INSTALL_MINECRAFT_VERSION=${_INSTALL_MINECRAFT_VERSION%%-*}
fi

echo -e "Getting forge version"
FORGE_VERSION=$(echo $PROMOTIONS | jq -r ".promos | to_entries | .[] | select(.key | startswith(\"${_INSTALL_MINECRAFT_VERSION}\")) | .value" | head -1);

DOWNLOAD_LINK=https://maven.minecraftforge.net/net/minecraftforge/forge/${_INSTALL_MINECRAFT_VERSION}-${FORGE_VERSION}/forge-${_INSTALL_MINECRAFT_VERSION}-${FORGE_VERSION}-installer.jar

if [[ -n $(curl -X HEAD -I $DOWNLOAD_LINK | head -n 1 | grep 404) ]]; then
  echo "Minecraft version ${_INSTALL_MINECRAFT_VERSION} not found";
  exit 1;
fi

echo -e "Downloading forge installer"
curl -sSL -o installer.jar $DOWNLOAD_LINK

if [ -e ./forge*.jar ]; then
  echo -e "Removing old jars";
  rm -r ./forge*.jar || true
fi

echo -e "Installing forge"
java -jar installer.jar --installServer

echo -e "Removing installer"
rm installer.jar installer.jar.log || true

if [ ! -e ./run.sh ]; then
  echo -e "Creating installation script"
  echo "java -jar forge*.jar" > "run.sh";
fi

echo -e "Agree eula";
echo "eula=true" > "eula.txt";

echo -e "Install Complete"