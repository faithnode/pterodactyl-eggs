#!/bin/bash

if [[ -z $_INSTALL_WATERFALL_VERSION || ${_INSTALL_WATERFALL_VERSION,,} == "latest" ]]; then
  echo -e "Getting latest version";
  _INSTALL_WATERFALL_VERSION=$(curl -s https://api.papermc.io/v2/projects/waterfall | jq -r '.versions[-1]');
else
  if [[ -z $(curl -s https://api.papermc.io/v2/projects/waterfall | jq -r ".versions[] | select(. == \"${_INSTALL_WATERFALL_VERSION}\")") ]]; then
    echo "Version $_INSTALL_WATERFALL_VERSION not found";
    exit 1;
  fi
fi

echo -e "Getting latest build"
WATERFALL_LAST_BUILD=$(curl -s https://api.papermc.io/v2/projects/waterfall/versions/${_INSTALL_WATERFALL_VERSION} | jq -r '.builds[-1]')

echo -e "Getting download link"
DOWNLOAD_LINK=https://api.papermc.io/v2/projects/waterfall/versions/${_INSTALL_WATERFALL_VERSION}/builds/${WATERFALL_LAST_BUILD}/downloads/waterfall-${_INSTALL_WATERFALL_VERSION}-${WATERFALL_LAST_BUILD}.jar

echo -e "Removing old jars"
rm -r ./waterfall*.jar || true

echo -e "Downloading ${DOWNLOAD_LINK}"
curl ${DOWNLOAD_LINK} -o waterfall-${_INSTALL_WATERFALL_VERSION}-${WATERFALL_LAST_BUILD}.jar

echo -e "Install complete"