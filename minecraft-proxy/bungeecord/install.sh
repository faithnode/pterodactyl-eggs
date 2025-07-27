#!/bin/bash

if [[ -z $_INSTALL_BUNGEECORD_VERSION || ${_INSTALL_BUNGEECORD_VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  DOWNLOAD_LINK=https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar
else
  DOWNLOAD_LINK=https://ci.md-5.net/job/BungeeCord/$_INSTALL_BUNGEECORD_VERSION/artifact/bootstrap/target/BungeeCord.jar
  if [[ -n $(curl -X HEAD -I $DOWNLOAD_LINK | head -n 1 | grep 404) ]]; then
    echo "Version $_INSTALL_BUNGEECORD_VERSION not found";
    exit 1;
  fi
fi

echo -e "Downloading ${DOWNLOAD_LINK}"
curl ${DOWNLOAD_LINK} -o bungeecord.jar || echo "Version $_INSTALL_BUNGEECORD_VERSION not found" && exit 1;

echo -e "Install complete"