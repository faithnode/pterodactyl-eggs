#!/bin/bash

VERSION=$_INSTALL_BUNGEECORD_VERSION

if [[ -z $VERSION || ${VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  DOWNLOAD_LINK=https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar
else
  DOWNLOAD_LINK=https://ci.md-5.net/job/BungeeCord/$VERSION/artifact/bootstrap/target/BungeeCord.jar
  curl --header 'Range: bytes=0-1' -o /dev/null "$DOWNLOAD_LINK" || fatal "Version $VERSION not found"
fi

echo -e "Downloading bungeecord.jar"
curl "$DOWNLOAD_LINK" -o bungeecord.jar;
